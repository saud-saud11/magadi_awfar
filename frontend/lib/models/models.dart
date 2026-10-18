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
    this.imageUrl,
    required this.offers,
  });

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

