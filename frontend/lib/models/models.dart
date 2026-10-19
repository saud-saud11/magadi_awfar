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
      id: json['id'] as int? ?? 0,
      storeCode: json['store_code'] as String? ?? '',
      storeNameAr: json['store_name_ar'] as String? ?? '',
      branchNameAr: json['branch_name_ar'] as String?,
      priceHalalas: json['price_halalas'] as int? ?? 0,
      priceSar: (json['price_sar'] as num?)?.toDouble() ?? 0.0,
      originalPriceSar: (json['original_price_sar'] as num?)?.toDouble(),
      isOnSale: json['is_on_sale'] as bool? ?? false,
      isInStock: json['is_in_stock'] as bool? ?? true,
      productUrl: json['product_url'] as String? ?? '',
      deepLink: json['deep_link'] as String?,
      promoConditions: json['promo_conditions'] as String?,
      deliveryFeeSar: (json['delivery_fee_sar'] as num?)?.toDouble(),
      totalLandedSar: (json['total_landed_sar'] as num?)?.toDouble(),
      totalStatus: json['total_status'] as String? ?? 'REQUIRES_STORE_CONFIRMATION',
      totalStatusText: json['total_status_text'] as String? ?? 'الإجمالي يُؤكد لدى المتجر',
      isCheapestProduct: json['is_cheapest_product'] as bool? ?? false,
      isCheapestTotal: json['is_cheapest_total'] as bool? ?? false,
      unitPricePer100gSar: (json['unit_price_per_100g_sar'] as num?)?.toDouble(),
    );
  }
}

class ProductItem {
  final int id;
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

  bool get isBundle =>
      packCount > 1 ||
      (packType == 'bundle') ||
      nameAr.contains('كرتون') ||
      nameAr.contains('شدة') ||
      nameAr.contains('شدّة') ||
      nameAr.contains('حزمة') ||
      nameAr.contains('ربطة');

  String get displayPackBadge {
    if (packLabelAr != null && packLabelAr!.isNotEmpty && packLabelAr != 'بالحبّة') {
      return packLabelAr!;
    }
    if (isBundle) {
      if (nameAr.contains('كرتون')) return packCount > 1 ? 'كرتون ($packCount علبة)' : 'كرتون عائلي';
      if (nameAr.contains('شدة') || nameAr.contains('شدّة')) return packCount > 1 ? 'شدّة ($packCount علب)' : 'شدّة توفير';
      if (packCount > 1) return 'حزمة ($packCount حبات)';
      return 'حزمة توفير';
    }
    return 'بالحبّة (مفرد)';
  }

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    var rawOffers = json['offers'] as List<dynamic>? ?? [];
    return ProductItem(
      id: json['id'] as int? ?? 0,
      gtinBarcode: json['gtin_barcode'] as String?,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      brandAr: json['brand_ar'] as String?,
      subCategory: json['sub_category'] as String?,
      subCategoryRank: json['sub_category_rank'] as int? ?? 10,
      normalizedSizeAmount: (json['normalized_size_amount'] as num?)?.toDouble(),
      normalizedSizeUnit: json['normalized_size_unit'] as String?,
      packCount: json['pack_count'] as int? ?? 1,
      packType: json['pack_type'] as String?,
      packLabelAr: json['pack_label_ar'] as String?,
      imageUrl: json['image_url'] as String?,
      offers: rawOffers.map((o) => StoreOffer.fromJson(o as Map<String, dynamic>)).toList(),
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
      disclaimer: json['disclaimer'] as String? ?? 'الأرخص بين العروض المطابقة التي تم فحصها لموقعك',
      matchedProducts: matched.map((p) => ProductItem.fromJson(p as Map<String, dynamic>)).toList(),
      alternativeSizes: alts.map((p) => ProductItem.fromJson(p as Map<String, dynamic>)).toList(),
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

  SourceInfo({
    required this.code,
    required this.nameAr,
    required this.status,
    required this.statusText,
    required this.isEnabled,
  });

  factory SourceInfo.fromJson(Map<String, dynamic> json) {
    return SourceInfo(
      code: json['code'] as String? ?? '',
      nameAr: json['name_ar'] as String? ?? '',
      status: json['status'] as String? ?? 'requires_setup',
      statusText: json['status_text'] as String? ?? '',
      isEnabled: json['is_enabled'] as bool? ?? true,
    );
  }
}

class VoiceBasketItem {
  final int productId;
  final String nameAr;
  final String? brandAr;
  int quantity;
  final double? sizeAmount;
  final String? sizeUnit;
  final String? imageUrl;
  final String? notes;

  VoiceBasketItem({
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
      packCount: 1,
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
      itemsAdded: added.map((i) => VoiceBasketItem.fromJson(i as Map<String, dynamic>)).toList(),
      itemsModified: modified.map((i) => VoiceBasketItem.fromJson(i as Map<String, dynamic>)).toList(),
      itemsRemoved: removed.map((r) => r.toString()).toList(),
      currentBasket: current.map((i) => VoiceBasketItem.fromJson(i as Map<String, dynamic>)).toList(),
      clarificationQuestion: json['clarification_question'] as String?,
      clarificationOptions: options.map((o) => o.toString()).toList(),
      canUndo: json['can_undo'] as bool? ?? false,
      sessionId: json['session_id'] as String? ?? 'default_session',
    );
  }
}

class PantryItemModel {
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
      lastLowestPriceSar: (json['last_lowest_price_sar'] as num?)?.toDouble() ?? 0.0,
      lastLowestStoreCode: json['last_lowest_store_code'] as String?,
      lastLowestStoreName: json['last_lowest_store_name'] as String?,
      targetPriceSar: (json['target_price_sar'] as num?)?.toDouble(),
      dropPercentageThreshold: (json['drop_percentage_threshold'] as num?)?.toDouble(),
      storeCodes: (json['store_codes'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      isAlertEnabled: json['is_alert_enabled'] as bool? ?? true,
      lastCheckedAt: json['last_checked_at'] != null ? DateTime.tryParse(json['last_checked_at'].toString()) : null,
      lastAlertSentAt: json['last_alert_sent_at'] != null ? DateTime.tryParse(json['last_alert_sent_at'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      priceDropSar: (json['price_drop_sar'] as num?)?.toDouble() ?? 0.0,
      priceDropPercentage: (json['price_drop_percentage'] as num?)?.toDouble() ?? 0.0,
      hasPriceDrop: json['has_price_drop'] as bool? ?? false,
      isTargetMet: json['is_target_met'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'device_uuid': deviceUuid,
    'product_id': productId,
    'product_name_ar': productNameAr,
    'product_name_en': productNameEn,
    'brandAr': brandAr,
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
      totalItems: json['total_items'] as int? ?? 0,
      activeAlertsCount: json['active_alerts_count'] as int? ?? 0,
      itemsWithDropsCount: json['items_with_drops_count'] as int? ?? 0,
      totalPotentialSavingsSar: (json['total_potential_savings_sar'] as num?)?.toDouble() ?? 0.0,
      items: rawItems.map((i) => PantryItemModel.fromJson(i as Map<String, dynamic>)).toList(),
    );
  }
}

class NotificationLogItem {
  final int id;
  final String titleAr;
  final String bodyAr;
  final String eventType;
  final Map<String, dynamic>? payload;
  final bool isRead;
  final DateTime? createdAt;

  NotificationLogItem({
    required this.id,
    required this.titleAr,
    required this.bodyAr,
    required this.eventType,
    this.payload,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationLogItem.fromJson(Map<String, dynamic> json) {
    return NotificationLogItem(
      id: json['id'] as int? ?? 0,
      titleAr: json['title_ar'] as String? ?? '',
      bodyAr: json['body_ar'] as String? ?? '',
      eventType: json['event_type'] as String? ?? 'info',
      payload: json['payload'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}

