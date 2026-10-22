DateTime? parseServerTime(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return DateTime.tryParse(
    RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(text) ? text : '${text}Z',
  );
}

class District {
  final int id;
  final String nameAr;
  final String? nameEn;
  final String city;

  District({
    required this.id,
    required this.nameAr,
    this.nameEn,
    required this.city,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] as int,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String?,
      city: json['city'] as String? ?? 'المدينة المنورة',
    );
  }
}

class StoreOffer {
  final DateTime? lastVerifiedAt;
  final DateTime? priceExpiresAt;
  final String? priceSourceType;
  final String? priceSourceName;
  final String? sourcePriceAgeText;
  final String priceKind;
  final bool priceVerified;
  final bool stockKnown;
  final String? sourceUrl;
  final int id;
  final String storeCode;
  final String storeNameAr;
  final String? branchNameAr;
  final int priceHalalas;
  final double priceSar;
  final double? originalPriceSar;
  final bool isOnSale;
  final bool isInStock;
  final String productUrl;
  final String? deepLink;
  final String? promoConditions;
  final double? deliveryFeeSar;
  final double? totalLandedSar;
  final String totalStatus;
  final String totalStatusText;
  final bool isCheapestProduct;
  final bool isCheapestTotal;
  final double? unitPricePer100gSar;

  StoreOffer({
    this.lastVerifiedAt,
    this.priceExpiresAt,
    this.priceSourceType,
    this.priceSourceName,
    this.sourcePriceAgeText,
    this.priceKind = 'listed',
    this.priceVerified = false,
    this.stockKnown = false,
    this.sourceUrl,
    required this.id,
    required this.storeCode,
    required this.storeNameAr,
    this.branchNameAr,
    required this.priceHalalas,
    required this.priceSar,
    this.originalPriceSar,
    required this.isOnSale,
    required this.isInStock,
    required this.productUrl,
    this.deepLink,
    this.promoConditions,
    this.deliveryFeeSar,
    this.totalLandedSar,
    required this.totalStatus,
    required this.totalStatusText,
    required this.isCheapestProduct,
    required this.isCheapestTotal,
    this.unitPricePer100gSar,
  });

  factory StoreOffer.fromJson(Map<String, dynamic> json) {
    return StoreOffer(
      lastVerifiedAt: parseServerTime(json['last_verified_at']),
      priceExpiresAt: parseServerTime(json['price_expires_at']),
      priceSourceType: json['price_source_type'] as String?,
      priceSourceName: json['price_source_name'] as String?,
      sourcePriceAgeText: json['source_price_age_text'] as String?,
      priceKind: json['price_kind'] as String? ?? 'listed',
      priceVerified: json['price_verified'] == true,
      stockKnown: json['stock_known'] == true,
      sourceUrl: json['source_url'] as String?,
      id: json['id'] as int? ?? 0,
      storeCode: json['store_code'] as String? ?? '',
      storeNameAr: json['store_name_ar'] as String? ?? '',
      branchNameAr: json['branch_name_ar'] as String?,
      priceHalalas: json['price_halalas'] as int? ?? 0,
      priceSar: (json['price_sar'] as num?)?.toDouble() ?? 0.0,
      originalPriceSar: (json['original_price_sar'] as num?)?.toDouble(),
      isOnSale: json['is_on_sale'] as bool? ?? false,
      isInStock: json['is_in_stock'] as bool? ?? false,
      productUrl: json['product_url'] as String? ?? '',
      deepLink: json['deep_link'] as String?,
      promoConditions: json['promo_conditions'] as String?,
      deliveryFeeSar: (json['delivery_fee_sar'] as num?)?.toDouble(),
      totalLandedSar: (json['total_landed_sar'] as num?)?.toDouble(),
      totalStatus:
          json['total_status'] as String? ?? 'REQUIRES_STORE_CONFIRMATION',
      totalStatusText:
          json['total_status_text'] as String? ?? 'الإجمالي يُؤكد لدى المتجر',
      isCheapestProduct: json['is_cheapest_product'] as bool? ?? false,
      isCheapestTotal: json['is_cheapest_total'] as bool? ?? false,
      unitPricePer100gSar: (json['unit_price_per_100g_sar'] as num?)
          ?.toDouble(),
    );
  }

  bool get isFresh =>
      priceVerified &&
      priceHalalas > 0 &&
      lastVerifiedAt != null &&
      (priceExpiresAt == null || DateTime.now().isBefore(priceExpiresAt!)) &&
      DateTime.now().difference(lastVerifiedAt!.toLocal()) >= Duration.zero &&
      DateTime.now().difference(lastVerifiedAt!.toLocal()) <
          const Duration(hours: 24);
  bool get canCompare => isFresh && (!stockKnown || isInStock);
  bool get isStartingFrom => priceKind == 'starting_from';
  bool get isIndicative =>
      isStartingFrom || priceSourceType == 'amazon_public_page';
  String get priceLabel =>
      '${isStartingFrom ? 'ابتداءً من ' : ''}${priceSar.toStringAsFixed(2)} ر.س';
  String get verificationText {
    if (!isFresh) return 'السعر يحتاج تحديثًا';
    if (priceSourceType == 'aggregator') {
      return 'سعر مرصود عبر ${priceSourceName ?? 'مصدر مقارنة'} • بحسب المصدر عند القراءة: ${sourcePriceAgeText ?? 'وقت التحديث غير مؤكد'} • التوفر يُؤكّد لدى المتجر';
    }
    final minutes = DateTime.now()
        .difference(lastVerifiedAt!.toLocal())
        .inMinutes;
    final age = minutes < 1
        ? 'الآن'
        : minutes < 60
        ? 'منذ $minutes دقيقة'
        : 'منذ ${minutes ~/ 60} ساعة';
    if (priceSourceType == 'amazon_public_page') {
      return 'سعر استرشادي ظاهر في أمازون • قُرئ $age • التوفر والتوصيل للمدينة يُؤكدان لدى المتجر';
    }
    return 'تم جلب السعر $age • ${stockKnown ? (isInStock ? 'متوفر حسب المصدر' : 'غير متوفر') : 'التوفر يُؤكّد لدى المتجر'}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'store_code': storeCode,
    'store_name_ar': storeNameAr,
    'branch_name_ar': branchNameAr,
    'price_halalas': priceHalalas,
    'price_sar': priceSar,
    'original_price_sar': originalPriceSar,
    'is_on_sale': isOnSale,
    'is_in_stock': isInStock,
    'product_url': productUrl,
    'deep_link': deepLink,
    'promo_conditions': promoConditions,
    'delivery_fee_sar': deliveryFeeSar,
    'total_landed_sar': totalLandedSar,
    'total_status': totalStatus,
    'total_status_text': totalStatusText,
    'is_cheapest_product': isCheapestProduct,
    'is_cheapest_total': isCheapestTotal,
    'unit_price_per_100g_sar': unitPricePer100gSar,
    'last_verified_at': lastVerifiedAt?.toUtc().toIso8601String(),
    'price_expires_at': priceExpiresAt?.toUtc().toIso8601String(),
    'price_source_type': priceSourceType,
    'price_source_name': priceSourceName,
    'source_price_age_text': sourcePriceAgeText,
    'price_kind': priceKind,
    'price_verified': priceVerified,
    'stock_known': stockKnown,
    'source_url': sourceUrl,
  };

  StoreOffer copyWith({
    DateTime? lastVerifiedAt,
    DateTime? priceExpiresAt,
    String? priceSourceType,
    String? priceSourceName,
    String? sourcePriceAgeText,
    String? priceKind,
    bool? priceVerified,
    bool? stockKnown,
    String? sourceUrl,
    int? id,
    String? storeCode,
    String? storeNameAr,
    String? branchNameAr,
    int? priceHalalas,
    double? priceSar,
    double? originalPriceSar,
    bool? isOnSale,
    bool? isInStock,
    String? productUrl,
    String? deepLink,
    String? promoConditions,
    double? deliveryFeeSar,
    double? totalLandedSar,
    String? totalStatus,
    String? totalStatusText,
    bool? isCheapestProduct,
    bool? isCheapestTotal,
    double? unitPricePer100gSar,
  }) {
    return StoreOffer(
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      priceExpiresAt: priceExpiresAt ?? this.priceExpiresAt,
      priceSourceType: priceSourceType ?? this.priceSourceType,
      priceSourceName: priceSourceName ?? this.priceSourceName,
      sourcePriceAgeText: sourcePriceAgeText ?? this.sourcePriceAgeText,
      priceKind: priceKind ?? this.priceKind,
      priceVerified: priceVerified ?? this.priceVerified,
      stockKnown: stockKnown ?? this.stockKnown,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      id: id ?? this.id,
      storeCode: storeCode ?? this.storeCode,
      storeNameAr: storeNameAr ?? this.storeNameAr,
      branchNameAr: branchNameAr ?? this.branchNameAr,
      priceHalalas: priceHalalas ?? this.priceHalalas,
      priceSar: priceSar ?? this.priceSar,
      originalPriceSar: originalPriceSar ?? this.originalPriceSar,
      isOnSale: isOnSale ?? this.isOnSale,
      isInStock: isInStock ?? this.isInStock,
      productUrl: productUrl ?? this.productUrl,
      deepLink: deepLink ?? this.deepLink,
      promoConditions: promoConditions ?? this.promoConditions,
      deliveryFeeSar: deliveryFeeSar ?? this.deliveryFeeSar,
      totalLandedSar: totalLandedSar ?? this.totalLandedSar,
      totalStatus: totalStatus ?? this.totalStatus,
      totalStatusText: totalStatusText ?? this.totalStatusText,
      isCheapestProduct: isCheapestProduct ?? this.isCheapestProduct,
      isCheapestTotal: isCheapestTotal ?? this.isCheapestTotal,
      unitPricePer100gSar: unitPricePer100gSar ?? this.unitPricePer100gSar,
    );
  }
}

class ProductItem {
  final int id;
  final String? canonicalId;
  final List<int> catalogProductIds;
  final String? matchingMethod;
  final String? quantityStatus;
  final String? gtinBarcode;
  final String nameAr;
  final String? nameEn;
  final String? brandAr;
  final String? subCategory;
  final int subCategoryRank;
  final double? normalizedSizeAmount;
  final String? normalizedSizeUnit;
  final int packCount;
  final String? packType;
  final String? packLabelAr;
  final String? imageUrl;
  final List<StoreOffer> offers;

  ProductItem({
    required this.id,
    this.canonicalId,
    this.catalogProductIds = const [],
    this.matchingMethod,
    this.quantityStatus,
    this.gtinBarcode,
    required this.nameAr,
    this.nameEn,
    this.brandAr,
    this.subCategory,
    this.subCategoryRank = 10,
    this.normalizedSizeAmount,
    this.normalizedSizeUnit,
    required this.packCount,
    this.packType,
    this.packLabelAr,
    this.imageUrl,
    required this.offers,
  });

  bool get hasExactQuantity =>
      normalizedSizeAmount != null &&
      normalizedSizeAmount! > 0 &&
      (quantityStatus == null || quantityStatus == 'exact');

  String get displaySize {
    if (!hasExactQuantity) return 'الحجم أو عدد العبوات غير مؤكد';
    final amount = normalizedSizeAmount!;
    final unit = normalizedSizeUnit == 'ml'
        ? 'مل'
        : normalizedSizeUnit == 'count'
        ? 'قطعة'
        : 'جرام';
    final number = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toString();
    return '$number $unit';
  }

  bool get isBundle =>
      packCount > 1 ||
      (packType == 'bundle') ||
      nameAr.contains('كرتون') ||
      nameAr.contains('شدة') ||
      nameAr.contains('شدّة') ||
      nameAr.contains('حزمة') ||
      nameAr.contains('ربطة');

  String get displayPackBadge {
    if (!hasExactQuantity) return 'عبوة غير مؤكدة';
    if (normalizedSizeUnit == 'count' && packCount == 1) return 'عبوة واحدة';
    if (packLabelAr != null &&
        packLabelAr!.isNotEmpty &&
        packLabelAr != 'بالحبّة') {
      return packLabelAr!;
    }
    if (isBundle) {
      if (nameAr.contains('كرتون')) {
        return packCount > 1 ? 'كرتون ($packCount علبة)' : 'كرتون عائلي';
      }
      if (nameAr.contains('شدة') || nameAr.contains('شدّة')) {
        return packCount > 1 ? 'شدّة ($packCount علب)' : 'شدّة توفير';
      }
      if (packCount > 1) return 'حزمة ($packCount حبات)';
      return 'حزمة توفير';
    }
    return 'بالحبّة (مفرد)';
  }

  StoreOffer? get lowestOffer {
    final valid = offers.where((o) => o.canCompare).toList()
      ..sort((a, b) => a.priceHalalas.compareTo(b.priceHalalas));
    return valid.isEmpty ? null : valid.first;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'canonical_id': canonicalId,
    'catalog_product_ids': catalogProductIds,
    'matching_method': matchingMethod,
    'quantity_status': quantityStatus,
    'gtin_barcode': gtinBarcode,
    'name_ar': nameAr,
    'name_en': nameEn,
    'brand_ar': brandAr,
    'sub_category': subCategory,
    'sub_category_rank': subCategoryRank,
    'normalized_size_amount': normalizedSizeAmount,
    'normalized_size_unit': normalizedSizeUnit,
    'pack_count': packCount,
    'pack_type': packType,
    'pack_label_ar': packLabelAr,
    'image_url': imageUrl,
    'offers': offers.map((o) => o.toJson()).toList(),
  };

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    var rawOffers = json['offers'] as List<dynamic>? ?? [];
    return ProductItem(
      id: json['id'] as int? ?? 0,
      canonicalId: json['canonical_id'] as String?,
      catalogProductIds: (json['catalog_product_ids'] as List<dynamic>? ?? [])
          .whereType<int>()
          .toList(),
      matchingMethod: json['matching_method'] as String?,
      quantityStatus: json['quantity_status'] as String?,
      gtinBarcode: json['gtin_barcode'] as String?,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      brandAr: json['brand_ar'] as String?,
      subCategory: json['sub_category'] as String?,
      subCategoryRank: json['sub_category_rank'] as int? ?? 10,
      normalizedSizeAmount: (json['normalized_size_amount'] as num?)
          ?.toDouble(),
      normalizedSizeUnit: json['normalized_size_unit'] as String?,
      packCount: json['pack_count'] as int? ?? 1,
      packType: json['pack_type'] as String?,
      packLabelAr: json['pack_label_ar'] as String?,
      imageUrl: json['image_url'] as String?,
      offers: rawOffers
          .map((o) => StoreOffer.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SearchResult {
  final String query;
  final String? districtName;
  final bool exactSizeMatched;
  final String statusMessage;
  final String disclaimer;
  final List<ProductItem> matchedProducts;
  final List<ProductItem> alternativeSizes;
  final List<String> subCategories;
  final List<dynamic> sourcesSummary;

  SearchResult({
    required this.query,
    this.districtName,
    required this.exactSizeMatched,
    required this.statusMessage,
    required this.disclaimer,
    required this.matchedProducts,
    required this.alternativeSizes,
    this.subCategories = const [],
    required this.sourcesSummary,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    var matched = json['matched_products'] as List<dynamic>? ?? [];
    var alts = json['alternative_sizes'] as List<dynamic>? ?? [];
    var rawCats = json['sub_categories'] as List<dynamic>? ?? [];
    return SearchResult(
      query: json['query'] as String? ?? '',
      districtName: json['district_name'] as String?,
      exactSizeMatched: json['exact_size_matched'] as bool? ?? true,
      statusMessage: json['status_message'] as String? ?? '',
      disclaimer:
          json['disclaimer'] as String? ??
          'الأرخص بين العروض المطابقة التي تم فحصها لموقعك',
      matchedProducts: matched
          .map((p) => ProductItem.fromJson(p as Map<String, dynamic>))
          .toList(),
      alternativeSizes: alts
          .map((p) => ProductItem.fromJson(p as Map<String, dynamic>))
          .toList(),
      subCategories: rawCats.map((c) => c.toString()).toList(),
      sourcesSummary: json['sources_summary'] as List<dynamic>? ?? [],
    );
  }
}

class SourceInfo {
  final String code;
  final String nameAr;
  final String status;
  final String statusText;
  final bool isEnabled;
  final bool supportsAlerts;
  final String? websiteUrl;
  final String? searchUrl;
  final String category;

  SourceInfo({
    required this.code,
    required this.nameAr,
    required this.status,
    required this.statusText,
    required this.isEnabled,
    this.supportsAlerts = true,
    this.websiteUrl,
    this.searchUrl,
    this.category = 'grocery',
  });

  factory SourceInfo.fromJson(Map<String, dynamic> json) {
    return SourceInfo(
      code: json['code'] as String? ?? '',
      nameAr: json['name_ar'] as String? ?? '',
      status: json['status'] as String? ?? 'requires_setup',
      statusText:
          (json['status_text'] ?? json['status_message']) as String? ?? '',
      isEnabled: json['is_enabled'] as bool? ?? true,
      supportsAlerts: json['supports_alerts'] as bool? ?? true,
      websiteUrl: json['website_url'] as String?,
      searchUrl: json['search_url'] as String?,
      category: json['category'] as String? ?? 'grocery',
    );
  }
}

class VoiceBasketItem {
  final int productId;
  final int packCount;
  final String nameAr;
  final String? brandAr;
  int quantity;
  final double? sizeAmount;
  final String? sizeUnit;
  final String? imageUrl;
  final String? notes;

  VoiceBasketItem({
    this.packCount = 1,
    required this.productId,
    required this.nameAr,
    this.brandAr,
    required this.quantity,
    this.sizeAmount,
    this.sizeUnit,
    this.imageUrl,
    this.notes,
  });

  factory VoiceBasketItem.fromJson(Map<String, dynamic> json) {
    return VoiceBasketItem(
      packCount: json['pack_count'] as int? ?? 1,
      productId: json['product_id'] as int? ?? 0,
      nameAr: json['name_ar'] as String? ?? '',
      brandAr: json['brand_ar'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      sizeAmount: (json['size_amount'] as num?)?.toDouble(),
      sizeUnit: json['size_unit'] as String?,
      imageUrl: json['image_url'] as String?,
      notes: json['notes'] as String?,
    );
  }

  ProductItem toProductItem() {
    return ProductItem(
      id: productId,
      nameAr: nameAr,
      brandAr: brandAr,
      normalizedSizeAmount: sizeAmount,
      normalizedSizeUnit: sizeUnit,
      packCount: packCount,
      imageUrl: imageUrl,
      offers: [],
    );
  }
}

class VoiceBasketResult {
  final String status;
  final String recognizedText;
  final String intent;
  final String messageAr;
  final List<VoiceBasketItem> itemsAdded;
  final List<VoiceBasketItem> itemsModified;
  final List<String> itemsRemoved;
  final List<VoiceBasketItem> currentBasket;
  final String? clarificationQuestion;
  final List<String> clarificationOptions;
  final bool canUndo;
  final String sessionId;

  VoiceBasketResult({
    required this.status,
    required this.recognizedText,
    required this.intent,
    required this.messageAr,
    required this.itemsAdded,
    required this.itemsModified,
    required this.itemsRemoved,
    required this.currentBasket,
    this.clarificationQuestion,
    required this.clarificationOptions,
    required this.canUndo,
    required this.sessionId,
  });

  factory VoiceBasketResult.fromJson(Map<String, dynamic> json) {
    var added = json['items_added'] as List<dynamic>? ?? [];
    var modified = json['items_modified'] as List<dynamic>? ?? [];
    var removed = json['items_removed'] as List<dynamic>? ?? [];
    var current = json['current_basket'] as List<dynamic>? ?? [];
    var options = json['clarification_options'] as List<dynamic>? ?? [];

    return VoiceBasketResult(
      status: json['status'] as String? ?? 'success',
      recognizedText: json['recognized_text'] as String? ?? '',
      intent: json['intent'] as String? ?? '',
      messageAr: json['message_ar'] as String? ?? '',
      itemsAdded: added
          .map((i) => VoiceBasketItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      itemsModified: modified
          .map((i) => VoiceBasketItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      itemsRemoved: removed.map((r) => r.toString()).toList(),
      currentBasket: current
          .map((i) => VoiceBasketItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      clarificationQuestion: json['clarification_question'] as String?,
      clarificationOptions: options.map((o) => o.toString()).toList(),
      canUndo: json['can_undo'] as bool? ?? false,
      sessionId: json['session_id'] as String? ?? 'default_session',
    );
  }
}

class PantryItemModel {
  final bool serverSynced;
  final bool hasVerifiedPrice;
  final double? normalizedSizeAmount;
  final String? normalizedSizeUnit;
  final int id;
  final String deviceUuid;
  final int productId;
  final String productNameAr;
  final String? productNameEn;
  final String? brandAr;
  final String? packLabelAr;
  final int packCount;
  final String? imageUrl;
  final int usualQuantity;
  final double baselinePriceSar;
  final String? baselineStoreCode;
  final String? baselineStoreName;
  final double lastLowestPriceSar;
  final String? lastLowestStoreCode;
  final String? lastLowestStoreName;
  final double? targetPriceSar;
  final double? dropPercentageThreshold;
  final List<String>? storeCodes;
  final bool isAlertEnabled;
  final DateTime? lastCheckedAt;
  final DateTime? lastAlertSentAt;
  final DateTime? createdAt;
  final double priceDropSar;
  final double priceDropPercentage;
  final bool hasPriceDrop;
  final bool isTargetMet;

  PantryItemModel({
    this.serverSynced = false,
    this.hasVerifiedPrice = false,
    this.normalizedSizeAmount,
    this.normalizedSizeUnit,
    required this.id,
    required this.deviceUuid,
    required this.productId,
    required this.productNameAr,
    this.productNameEn,
    this.brandAr,
    this.packLabelAr,
    required this.packCount,
    this.imageUrl,
    required this.usualQuantity,
    required this.baselinePriceSar,
    this.baselineStoreCode,
    this.baselineStoreName,
    required this.lastLowestPriceSar,
    this.lastLowestStoreCode,
    this.lastLowestStoreName,
    this.targetPriceSar,
    this.dropPercentageThreshold,
    this.storeCodes,
    required this.isAlertEnabled,
    this.lastCheckedAt,
    this.lastAlertSentAt,
    this.createdAt,
    required this.priceDropSar,
    required this.priceDropPercentage,
    required this.hasPriceDrop,
    required this.isTargetMet,
  });

  factory PantryItemModel.fromJson(Map<String, dynamic> json) {
    return PantryItemModel(
      serverSynced: json['server_synced'] == true,
      hasVerifiedPrice: json['has_verified_price'] == true,
      normalizedSizeAmount: (json['normalized_size_amount'] as num?)
          ?.toDouble(),
      normalizedSizeUnit: json['normalized_size_unit'] as String?,
      id: json['id'] as int? ?? 0,
      deviceUuid: json['device_uuid'] as String? ?? '',
      productId: json['product_id'] as int? ?? 0,
      productNameAr: json['product_name_ar'] as String? ?? '',
      productNameEn: json['product_name_en'] as String?,
      brandAr: json['brand_ar'] as String?,
      packLabelAr: json['pack_label_ar'] as String?,
      packCount: json['pack_count'] as int? ?? 1,
      imageUrl: json['image_url'] as String?,
      usualQuantity: json['usual_quantity'] as int? ?? 1,
      baselinePriceSar: (json['baseline_price_sar'] as num?)?.toDouble() ?? 0.0,
      baselineStoreCode: json['baseline_store_code'] as String?,
      baselineStoreName: json['baseline_store_name'] as String?,
      lastLowestPriceSar:
          (json['current_lowest_price_sar'] as num?)?.toDouble() ??
          (json['last_lowest_price_sar'] as num?)?.toDouble() ??
          0.0,
      lastLowestStoreCode:
          (json['current_lowest_store_code'] as String?) ??
          (json['last_lowest_store_code'] as String?),
      lastLowestStoreName:
          (json['current_lowest_store_name_ar'] as String?) ??
          (json['last_lowest_store_name'] as String?),
      targetPriceSar: (json['target_price_sar'] as num?)?.toDouble(),
      dropPercentageThreshold:
          (json['target_discount_percent'] as num?)?.toDouble() ??
          (json['drop_percentage_threshold'] as num?)?.toDouble(),
      storeCodes:
          (json['specific_store_codes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['store_codes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
      isAlertEnabled: json['is_alert_enabled'] as bool? ?? true,
      lastCheckedAt: parseServerTime(json['last_checked_at']),
      lastAlertSentAt: json['last_alert_sent_at'] != null
          ? DateTime.tryParse(json['last_alert_sent_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      priceDropSar:
          (json['savings_amount_sar'] as num?)?.toDouble() ??
          (json['price_drop_sar'] as num?)?.toDouble() ??
          0.0,
      priceDropPercentage:
          (json['savings_percent'] as num?)?.toDouble() ??
          (json['price_drop_percentage'] as num?)?.toDouble() ??
          0.0,
      hasPriceDrop:
          json['is_price_dropped'] as bool? ??
          json['has_price_drop'] as bool? ??
          false,
      isTargetMet: json['is_target_met'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'server_synced': serverSynced,
    'has_verified_price': hasVerifiedPrice,
    'normalized_size_amount': normalizedSizeAmount,
    'normalized_size_unit': normalizedSizeUnit,
    'id': id,
    'device_uuid': deviceUuid,
    'product_id': productId,
    'product_name_ar': productNameAr,
    'product_name_en': productNameEn,
    'brand_ar': brandAr,
    'pack_label_ar': packLabelAr,
    'pack_count': packCount,
    'image_url': imageUrl,
    'usual_quantity': usualQuantity,
    'baseline_price_sar': baselinePriceSar,
    'baseline_store_code': baselineStoreCode,
    'baseline_store_name': baselineStoreName,
    'last_lowest_price_sar': lastLowestPriceSar,
    'last_lowest_store_code': lastLowestStoreCode,
    'last_lowest_store_name': lastLowestStoreName,
    'target_price_sar': targetPriceSar,
    'drop_percentage_threshold': dropPercentageThreshold,
    'store_codes': storeCodes,
    'is_alert_enabled': isAlertEnabled,
    'last_checked_at': lastCheckedAt?.toIso8601String(),
    'last_alert_sent_at': lastAlertSentAt?.toIso8601String(),
    'created_at': createdAt?.toIso8601String(),
    'price_drop_sar': priceDropSar,
    'price_drop_percentage': priceDropPercentage,
    'has_price_drop': hasPriceDrop,
    'is_target_met': isTargetMet,
  };

  ProductItem toProductItem() {
    return ProductItem(
      id: productId,
      nameAr: productNameAr,
      nameEn: productNameEn,
      brandAr: brandAr,
      normalizedSizeAmount: normalizedSizeAmount,
      normalizedSizeUnit: normalizedSizeUnit,
      packCount: packCount,
      packLabelAr: packLabelAr,
      imageUrl: imageUrl,
      offers: [],
    );
  }
}

class PantrySummaryModel {
  final int totalItems;
  final int activeAlertsCount;
  final int itemsWithDropsCount;
  final double totalPotentialSavingsSar;
  final List<PantryItemModel> items;

  PantrySummaryModel({
    required this.totalItems,
    required this.activeAlertsCount,
    required this.itemsWithDropsCount,
    required this.totalPotentialSavingsSar,
    required this.items,
  });

  factory PantrySummaryModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List<dynamic>? ?? [];
    return PantrySummaryModel(
      totalItems:
          json['total_items'] as int? ??
          json['items_count'] as int? ??
          rawItems.length,
      activeAlertsCount: json['active_alerts_count'] as int? ?? 0,
      itemsWithDropsCount: json['items_with_drops_count'] as int? ?? 0,
      totalPotentialSavingsSar:
          (json['total_potential_savings_sar'] as num?)?.toDouble() ?? 0.0,
      items: rawItems
          .map((i) => PantryItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class NotificationLogItem {
  final int id;
  final int? pantryItemId;
  final String titleAr;
  final String bodyAr;
  final String eventType;
  final String? storeCode;
  final String? storeNameAr;
  final double? oldPriceSar;
  final double? newPriceSar;
  final double? savingsSar;
  final String? deepLink;
  final Map<String, dynamic>? payload;
  final bool isRead;
  final DateTime? createdAt;

  NotificationLogItem({
    required this.id,
    this.pantryItemId,
    required this.titleAr,
    required this.bodyAr,
    required this.eventType,
    this.storeCode,
    this.storeNameAr,
    this.oldPriceSar,
    this.newPriceSar,
    this.savingsSar,
    this.deepLink,
    this.payload,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationLogItem.fromJson(Map<String, dynamic> json) {
    return NotificationLogItem(
      id: json['id'] as int? ?? 0,
      pantryItemId: json['pantry_item_id'] as int?,
      titleAr:
          (json['title_ar'] as String?) ?? (json['title'] as String?) ?? '',
      bodyAr: (json['body_ar'] as String?) ?? (json['body'] as String?) ?? '',
      eventType: json['event_type'] as String? ?? 'info',
      storeCode: json['store_code'] as String?,
      storeNameAr: json['store_name_ar'] as String?,
      oldPriceSar: (json['old_price_sar'] as num?)?.toDouble(),
      newPriceSar: (json['new_price_sar'] as num?)?.toDouble(),
      savingsSar: (json['savings_sar'] as num?)?.toDouble(),
      deepLink: json['deep_link'] as String?,
      payload: json['payload'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'].toString())
          : (json['created_at'] != null
                ? DateTime.tryParse(json['created_at'].toString())
                : null),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pantry_item_id': pantryItemId,
    'title_ar': titleAr,
    'body_ar': bodyAr,
    'event_type': eventType,
    'store_code': storeCode,
    'store_name_ar': storeNameAr,
    'old_price_sar': oldPriceSar,
    'new_price_sar': newPriceSar,
    'savings_sar': savingsSar,
    'deep_link': deepLink,
    'payload': payload,
    'is_read': isRead,
    'sent_at': createdAt?.toIso8601String(),
  };
}

class AlertPreferencesModel {
  final bool enableQuietHours;
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool dailyDigestEnabled;

  const AlertPreferencesModel({
    this.enableQuietHours = true,
    this.quietHoursStart = '23:00',
    this.quietHoursEnd = '07:00',
    this.dailyDigestEnabled = false,
  });

  factory AlertPreferencesModel.fromJson(Map<String, dynamic> json) {
    return AlertPreferencesModel(
      enableQuietHours: json['enable_quiet_hours'] as bool? ?? true,
      quietHoursStart: json['quiet_hours_start'] as String? ?? '23:00',
      quietHoursEnd: json['quiet_hours_end'] as String? ?? '07:00',
      dailyDigestEnabled: json['daily_digest_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'enable_quiet_hours': enableQuietHours,
    'quiet_hours_start': quietHoursStart,
    'quiet_hours_end': quietHoursEnd,
    'daily_digest_enabled': dailyDigestEnabled,
  };
}
