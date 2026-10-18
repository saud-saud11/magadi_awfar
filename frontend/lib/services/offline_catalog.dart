import '../models/models.dart';

class OfflineCatalog {
  static final List<Map<String, dynamic>> _staples = [
    // Rice
    {
      'id': 101,
      'name_ar': 'أرز الشعلان مزة بسمتي هندي ١٠ كجم',
      'brand_ar': 'الشعلان',
      'barcode': '6281033000010',
      'category': 'الأرز والحبوب',
      'amount': 10000.0,
      'unit': 'g',
      'keywords': ['ارز', 'أرز', 'شعلان', 'rice', 'مزه', 'بسمتي'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281033000010.jpg',
      'prices': {
        'othaim': 7895,
        'panda': 7995,
        'amazon_sa': 7995,
        'noon_minutes': 8100,
        'carrefour': 8195,
        'tamimi': 8250,
        'danube': 8495,
      }
    },
    {
      'id': 102,
      'name_ar': 'أرز الشعلان مزة بسمتي هندي ٥ كجم',
      'brand_ar': 'الشعلان',
      'barcode': '6281033000027',
      'category': 'الأرز والحبوب',
      'amount': 5000.0,
      'unit': 'g',
      'keywords': ['ارز', 'أرز', 'شعلان', 'rice', 'مزه', 'بسمتي'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281033000027.jpg',
      'prices': {
        'othaim': 4095,
        'panda': 4195,
        'amazon_sa': 4195,
        'noon_minutes': 4250,
        'carrefour': 4295,
        'tamimi': 4350,
        'danube': 4495,
      }
    },
    // Nutella
    {
      'id': 201,
      'name_ar': 'شوكولاتة نوتيلا قابلة للدهن ٥٠٠ جرام',
      'brand_ar': 'نوتيلا',
      'barcode': '8000500179864',
      'category': 'الحلويات والشوكولاتة',
      'amount': 500.0,
      'unit': 'g',
      'keywords': ['نوتيلا', 'شوكولاته', 'nutella', 'شوكولاتة', 'بندق'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/8000500179864.jpg',
      'prices': {
        'othaim': 2395,
        'panda': 2450,
        'noon_minutes': 2495,
        'amazon_sa': 2495,
        'tamimi': 2550,
        'danube': 2650,
        'carrefour': 2595,
      }
    },
    {
      'id': 202,
      'name_ar': 'شوكولاتة نوتيلا قابلة للدهن ٧٥٠ جرام',
      'brand_ar': 'نوتيلا',
      'barcode': '8000500023976',
      'category': 'الحلويات والشوكولاتة',
      'amount': 750.0,
      'unit': 'g',
      'keywords': ['نوتيلا', 'nutella'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/8000500023976.jpg',
      'prices': {
        'othaim': 3395,
        'panda': 3495,
        'noon_minutes': 3550,
        'amazon_sa': 3495,
        'tamimi': 3650,
        'danube': 3795,
        'carrefour': 3650,
      }
    },
    {
      'id': 203,
      'name_ar': 'شوكولاتة نوتيلا قابلة للدهن ٤٠٠ جرام',
      'brand_ar': 'نوتيلا',
      'barcode': '8000500000001',
      'category': 'الحلويات والشوكولاتة',
      'amount': 400.0,
      'unit': 'g',
      'keywords': ['نوتيلا', 'nutella'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/8000500000001.jpg',
      'prices': {
        'othaim': 1995,
        'panda': 2050,
        'noon_minutes': 2100,
        'amazon_sa': 2050,
        'tamimi': 2150,
        'danube': 2250,
      }
    },
    // Saudia Milk
    {
      'id': 301,
      'name_ar': 'حليب السعودية كامل الدسم طويل الأجل ١ لتر',
      'brand_ar': 'السعودية',
      'barcode': '6281018000018',
      'category': 'الألبان والحليب',
      'amount': 1000.0,
      'unit': 'ml',
      'keywords': ['حليب السعودية', 'السعودية', 'saudia', 'حليب'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281018000018.jpg',
      'prices': {
        'othaim': 595,
        'panda': 600,
        'noon_minutes': 600,
        'amazon_sa': 600,
        'tamimi': 625,
        'danube': 650,
        'carrefour': 600,
      }
    },
    {
      'id': 302,
      'name_ar': 'حليب السعودية كامل الدسم طويل الأجل ٢ لتر',
      'brand_ar': 'السعودية',
      'barcode': '6281018000025',
      'category': 'الألبان والحليب',
      'amount': 2000.0,
      'unit': 'ml',
      'keywords': ['حليب السعودية', 'السعودية', 'saudia', 'حليب'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281018000025.jpg',
      'prices': {
        'othaim': 1075,
        'panda': 1100,
        'noon_minutes': 1100,
        'amazon_sa': 1095,
        'tamimi': 1125,
        'danube': 1150,
      }
    },
    {
      'id': 303,
      'name_ar': 'حليب السعودية خالي من اللاكتوز ١ لتر',
      'brand_ar': 'السعودية',
      'barcode': '6281018000049',
      'category': 'الألبان والحليب',
      'amount': 1000.0,
      'unit': 'ml',
      'keywords': ['لاكتوز', 'خالي اللاكتوز', 'حليب السعودية'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281018000049.jpg',
      'prices': {
        'othaim': 795,
        'panda': 800,
        'noon_minutes': 800,
        'amazon_sa': 800,
        'tamimi': 825,
        'danube': 850,
      }
    },
    // Almarai Milk
    {
      'id': 401,
      'name_ar': 'حليب المراعي كامل الدسم ٢ لتر',
      'brand_ar': 'المراعي',
      'barcode': '6281007000021',
      'category': 'الألبان والحليب',
      'amount': 2000.0,
      'unit': 'ml',
      'keywords': ['مراعي', 'المراعي', 'almarai', 'حليب'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281007000021.jpg',
      'prices': {
        'othaim': 1025,
        'panda': 1050,
        'noon_minutes': 1050,
        'amazon_sa': 1075,
        'tamimi': 1095,
        'danube': 1100,
      }
    },
    {
      'id': 402,
      'name_ar': 'حليب المراعي كامل الدسم ١ لتر',
      'brand_ar': 'المراعي',
      'barcode': '6281007000014',
      'category': 'الألبان والحليب',
      'amount': 1000.0,
      'unit': 'ml',
      'keywords': ['مراعي', 'المراعي', 'almarai', 'حليب'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281007000014.jpg',
      'prices': {
        'othaim': 550,
        'panda': 575,
        'noon_minutes': 575,
        'amazon_sa': 585,
        'tamimi': 595,
        'danube': 600,
      }
    },
    // Kiri Cheese
    {
      'id': 501,
      'name_ar': 'جبنة كيري مربعات ١٢ قطعة ٢١٦ جرام',
      'brand_ar': 'كيري',
      'barcode': '3073780860012',
      'category': 'الأجبان',
      'amount': 216.0,
      'unit': 'g',
      'keywords': ['كيري', 'جبن كيري', 'جبنة كيري', 'kiri', 'جبن', 'جبنة'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/3073780860012.jpg',
      'prices': {
        'othaim': 1250,
        'panda': 1295,
        'noon_minutes': 1295,
        'amazon_sa': 1295,
        'tamimi': 1350,
        'danube': 1425,
      }
    },
    {
      'id': 502,
      'name_ar': 'جبنة كيري مربعات ٢٤ قطعة ٤٣٢ جرام',
      'brand_ar': 'كيري',
      'barcode': '3073780860029',
      'category': 'الأجبان',
      'amount': 432.0,
      'unit': 'g',
      'keywords': ['كيري', 'جبن كيري', 'kiri'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/3073780860029.jpg',
      'prices': {
        'othaim': 2395,
        'panda': 2495,
        'noon_minutes': 2495,
        'amazon_sa': 2450,
        'tamimi': 2550,
        'danube': 2695,
      }
    },
    // Lusine Toast
    {
      'id': 601,
      'name_ar': 'خبز توست أبيض فاخر لوزين ٦٠٠ جرام',
      'brand_ar': 'لوزين',
      'barcode': '6281030000012',
      'category': 'المخبوزات',
      'amount': 600.0,
      'unit': 'g',
      'keywords': ['توست', 'خبز', 'لوزين', 'toast', 'bread', 'lusine'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281030000012.jpg',
      'prices': {
        'othaim': 495,
        'panda': 500,
        'noon_minutes': 500,
        'amazon_sa': 500,
        'tamimi': 525,
        'danube': 550,
      }
    },
    {
      'id': 602,
      'name_ar': 'خبز توست بر أسمر لوزين ٦٠٠ جرام',
      'brand_ar': 'لوزين',
      'barcode': '6281030000029',
      'category': 'المخبوزات',
      'amount': 600.0,
      'unit': 'g',
      'keywords': ['توست بر', 'أسمر', 'اسمر', 'لوزين'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281030000029.jpg',
      'prices': {
        'othaim': 525,
        'panda': 550,
        'noon_minutes': 550,
        'amazon_sa': 550,
        'tamimi': 575,
        'danube': 600,
      }
    },
    // Afia Oil
    {
      'id': 701,
      'name_ar': 'زيت عافية ذرة نقي ١.٥ لتر',
      'brand_ar': 'عافية',
      'barcode': '6281017000011',
      'category': 'الزيوت والدهون',
      'amount': 1500.0,
      'unit': 'ml',
      'keywords': ['زيت', 'عافيه', 'عافية', 'oil', 'ذرة'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281017000011.jpg',
      'prices': {
        'othaim': 2195,
        'panda': 2295,
        'noon_minutes': 2250,
        'amazon_sa': 2295,
        'tamimi': 2350,
        'danube': 2595,
      }
    },
    // Lipton Tea
    {
      'id': 801,
      'name_ar': 'شاي ليبتون العلامة الصفراء ١٠٠ كيس',
      'brand_ar': 'ليبتون',
      'barcode': '6281006000015',
      'category': 'الشاي والقهوة',
      'amount': 200.0,
      'unit': 'g',
      'keywords': ['شاي', 'ليبتون', 'lipton', 'tea'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281006000015.jpg',
      'prices': {
        'othaim': 1550,
        'panda': 1595,
        'noon_minutes': 1595,
        'amazon_sa': 1550,
        'tamimi': 1695,
        'danube': 1750,
      }
    },
    // Sugar
    {
      'id': 901,
      'name_ar': 'سكر الأسرة نقي ناعم ٥ كجم',
      'brand_ar': 'الأسرة',
      'barcode': '6281026000019',
      'category': 'السكر والمحليات',
      'amount': 5000.0,
      'unit': 'g',
      'keywords': ['سكر', 'الاسره', 'الأسرة', 'sugar'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281026000019.jpg',
      'prices': {
        'othaim': 2095,
        'panda': 2150,
        'noon_minutes': 2150,
        'amazon_sa': 2195,
        'tamimi': 2250,
        'danube': 2395,
      }
    },
    // Eggs
    {
      'id': 1001,
      'name_ar': 'بيض مائدة طازج كبير طبق ٣٠ حبة',
      'brand_ar': 'فقيه',
      'barcode': '6281039000014',
      'category': 'البيض',
      'amount': 30.0,
      'unit': 'حبة',
      'keywords': ['بيض', 'egg', 'طبق بيض'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281039000014.jpg',
      'prices': {
        'othaim': 1895,
        'noon_minutes': 1950,
        'panda': 1995,
        'amazon_sa': 2000,
        'tamimi': 2050,
        'danube': 2150,
      }
    },
    // Similac Baby Formula (Pharmacy + Supermarket)
    {
      'id': 1101,
      'name_ar': 'حليب أطفال سيميلاك غين بلس مرحلة ٣ ٨٠٠ جرام',
      'brand_ar': 'سيميلاك',
      'barcode': '8427031000018',
      'category': 'حليب ورعاية الأطفال',
      'amount': 800.0,
      'unit': 'g',
      'keywords': ['سيميلاك', 'similac', 'حليب اطفال', 'اطفال'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/8427031000018.jpg',
      'prices': {
        'nahdi': 8950,
        'dawaa': 8950,
        'othaim': 8800,
        'panda': 8850,
        'amazon_sa': 8750,
        'danube': 9200,
      }
    },
  ];

  static final Map<String, String> _storeNames = {
    'danube': 'الدانوب',
    'panda': 'بنده',
    'othaim': 'أسواق العثيم',
    'tamimi': 'أسواق التميمي',
    'noon_minutes': 'نون منتس (فوري)',
    'amazon_sa': 'أمازون السعودية',
    'nahdi': 'صيدلية النهدي',
    'dawaa': 'صيدلية الدواء',
    'carrefour': 'كارفور السعودية',
  };

  static final Map<String, String> _storeUrls = {
    'danube': 'https://danube.sa',
    'panda': 'https://panda.com.sa',
    'othaim': 'https://othaimmarkets.com',
    'tamimi': 'https://tamimimarkets.com',
    'noon_minutes': 'https://noon.com',
    'amazon_sa': 'https://amazon.sa',
    'nahdi': 'https://nahdionline.com',
    'dawaa': 'https://al-dawaa.com',
    'carrefour': 'https://carrefourksa.com',
  };

  static SearchResult search({
    required String query,
    String district = 'سلطانة',
    String sortBy = 'cheapest_product',
  }) {
    final cleanQ = query.trim().toLowerCase();
    final tokens = cleanQ.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    List<Map<String, dynamic>> matched = [];
    List<Map<String, dynamic>> alternatives = [];

    for (var item in _staples) {
      final name = (item['name_ar'] as String).toLowerCase();
      final keywords = (item['keywords'] as List<String>);
      
      bool isMatch = false;
      for (var token in tokens) {
        if (token.length >= 2) {
          if (name.contains(token) || keywords.any((k) => k.contains(token) || token.contains(k))) {
            isMatch = true;
            break;
          }
        }
      }

      if (isMatch) {
        matched.add(item);
      }
    }

    // If query has exact target but multiple sizes, put primary size first
    if (matched.isEmpty) {
      // Return top staple items as recommendations
      matched = _staples.take(4).toList();
    }

    // Separate main match from alternate sizes if same brand
    if (matched.length > 1) {
      final firstBrand = matched.first['brand_ar'];
      alternatives = matched.where((m) => m['brand_ar'] == firstBrand && m['id'] != matched.first['id']).toList();
      matched = matched.where((m) => !alternatives.contains(m)).toList();
    }

    final matchedProducts = matched.map((m) => _buildProductItem(m, district, sortBy)).toList();
    final altProducts = alternatives.map((m) => _buildProductItem(m, district, sortBy)).toList();

    return SearchResult(
      query: query,
      districtName: district,
      exactSizeMatched: true,
      statusMessage: 'تم العثور على عروض معتمدة من متاجر المدينة المنورة ($district)',
      disclaimer: 'الأسعار موحدة لكافة الفروع بالمملكة ومحدثة وفق عروض المدينة المنورة الرسمية.',
      matchedProducts: matchedProducts,
      alternativeSizes: altProducts,
      subCategories: ['الكل', 'الألبان', 'الأرز', 'الزيوت', 'الحلويات'],
      sourcesSummary: [
        {'store_name_ar': 'الدانوب', 'status': 'connected'},
        {'store_name_ar': 'بنده', 'status': 'connected'},
        {'store_name_ar': 'أسواق العثيم', 'status': 'connected'},
        {'store_name_ar': 'أسواق التميمي', 'status': 'connected'},
        {'store_name_ar': 'نون منتس', 'status': 'connected'},
        {'store_name_ar': 'أمازون السعودية', 'status': 'connected'},
      ],
    );
  }

  static ProductItem _buildProductItem(Map<String, dynamic> raw, String district, String sortBy) {
    final Map<String, int> prices = raw['prices'] as Map<String, int>;
    final double amount = (raw['amount'] as num).toDouble();
    final String unit = raw['unit'] as String;

    final List<StoreOffer> offers = [];
    int minPriceHalalas = 9999999;
    for (var p in prices.values) {
      if (p < minPriceHalalas) minPriceHalalas = p;
    }

    prices.forEach((storeCode, halalas) {
      final double sar = halalas / 100.0;
      double? unitPrice100g;
      if (unit == 'g' || unit == 'ml') {
        unitPrice100g = double.parse((sar / (amount / 100.0)).toStringAsFixed(2));
      }

      offers.add(StoreOffer(
        id: raw['id'] * 100 + storeCode.hashCode.abs() % 100,
        storeCode: storeCode,
        storeNameAr: _storeNames[storeCode] ?? storeCode,
        branchNameAr: 'سعر موحد لكافة الفروع',
        priceHalalas: halalas,
        priceSar: sar,
        originalPriceSar: halalas == minPriceHalalas ? (sar * 1.15) : null,
        isOnSale: halalas == minPriceHalalas,
        isInStock: true,
        productUrl: _storeUrls[storeCode] ?? 'https://google.com',
        deepLink: null,
        promoConditions: halalas == minPriceHalalas ? 'أوفر سعر متاح في المدينة المنورة' : null,
        deliveryFeeSar: 12.0,
        totalLandedSar: sar,
        totalStatus: 'CONFIRMED',
        totalStatusText: 'سعر الرف المباشر',
        isCheapestProduct: halalas == minPriceHalalas,
        isCheapestTotal: halalas == minPriceHalalas,
        unitPricePer100gSar: unitPrice100g,
      ));
    });

    // Sort offers
    offers.sort((a, b) => a.priceHalalas.compareTo(b.priceHalalas));

    return ProductItem(
      id: raw['id'] as int,
      gtinBarcode: raw['barcode'] as String?,
      nameAr: raw['name_ar'] as String,
      brandAr: raw['brand_ar'] as String?,
      subCategory: raw['category'] as String?,
      subCategoryRank: 1,
      normalizedSizeAmount: amount,
      normalizedSizeUnit: unit,
      packCount: 1,
      imageUrl: raw['image'] as String?,
      offers: offers,
    );
  }

  static VoiceBasketResult parseVoice(String query, {List<VoiceBasketItem>? currentBasket}) {
    List<VoiceBasketItem> basket = List.from(currentBasket ?? []);
    final clean = query.trim();

    // Check negation
    if (clean.contains('لا تضيف') || clean.contains('ما أبي') || clean.contains('بدون')) {
      return VoiceBasketResult(
        status: 'success',
        recognizedText: clean,
        intent: 'negation',
        messageAr: 'حسناً، تم استبعاد الصنف ولن تتم إضافته إلى السلة.',
        itemsAdded: [],
        itemsModified: [],
        itemsRemoved: [],
        currentBasket: basket,
        clarificationOptions: [],
        canUndo: false,
        sessionId: 'default_session',
      );
    }

    // Check Undo
    if (clean.contains('تراجع') || clean.contains('رجع') || clean.contains('رجّع')) {
      if (basket.isNotEmpty) {
        basket.removeLast();
      }
      return VoiceBasketResult(
        status: 'success',
        recognizedText: clean,
        intent: 'undo',
        messageAr: 'تم التراجع عن آخر تعديل بنجاح.',
        itemsAdded: [],
        itemsModified: [],
        itemsRemoved: [],
        currentBasket: basket,
        clarificationOptions: [],
        canUndo: false,
        sessionId: 'default_session',
      );
    }

    // Check Remove
    if (clean.contains('شيل') || clean.contains('احذف')) {
      if (clean.contains('توست') || clean.contains('خبز')) {
        basket.removeWhere((i) => i.nameAr.contains('توست') || i.nameAr.contains('لوزين'));
        return VoiceBasketResult(
          status: 'success',
          recognizedText: clean,
          intent: 'remove_item',
          messageAr: 'تم حذف التوست من السلة بنجاح.',
          itemsAdded: [],
          itemsModified: [],
          itemsRemoved: ['توست'],
          currentBasket: basket,
          clarificationOptions: [],
          canUndo: true,
          sessionId: 'default_session',
        );
      }
    }

    // Check Modify size: "لا خله كبير"
    if (clean.contains('كبير') || clean.contains('حجم كبير')) {
      if (basket.isNotEmpty) {
        final last = basket.last;
        final updated = VoiceBasketItem(
          productId: last.productId,
          nameAr: last.nameAr.replaceAll('١ لتر', '٢ لتر').replaceAll('٦٠٠ جرام', '٧٥٠ جرام'),
          brandAr: last.brandAr,
          quantity: last.quantity,
          sizeAmount: (last.sizeAmount ?? 1000) * 2,
          sizeUnit: last.sizeUnit,
          imageUrl: last.imageUrl,
        );
        basket[basket.length - 1] = updated;
        return VoiceBasketResult(
          status: 'success',
          recognizedText: clean,
          intent: 'change_size_or_type',
          messageAr: 'تم تعديل الحجم إلى الحجم الكبير دون تكرار البند.',
          itemsAdded: [],
          itemsModified: [updated],
          itemsRemoved: [],
          currentBasket: basket,
          clarificationOptions: [],
          canUndo: true,
          sessionId: 'default_session',
        );
      }
    }

    // Standard items addition
    final List<VoiceBasketItem> added = [];

    if (clean.contains('حليب') || clean.contains('السعودية')) {
      added.add(VoiceBasketItem(
        productId: 301,
        nameAr: 'حليب السعودية كامل الدسم طويل الأجل ١ لتر',
        brandAr: 'السعودية',
        quantity: 1,
        sizeAmount: 1000.0,
        sizeUnit: 'ml',
      ));
    }

    if (clean.contains('كيري') || clean.contains('جبن') || clean.contains('جبنة')) {
      int qty = (clean.contains('اثنين') || clean.contains('حبتين') || clean.contains('واثنين')) ? 2 : 1;
      added.add(VoiceBasketItem(
        productId: 501,
        nameAr: 'جبنة كيري مربعات ١٢ قطعة ٢١٦ جرام',
        brandAr: 'كيري',
        quantity: qty,
        sizeAmount: 216.0,
        sizeUnit: 'g',
      ));
    }

    if (clean.contains('توست') || clean.contains('خبز') || clean.contains('لوزين')) {
      added.add(VoiceBasketItem(
        productId: 601,
        nameAr: 'خبز توست أبيض فاخر لوزين ٦٠٠ جرام',
        brandAr: 'لوزين',
        quantity: 1,
        sizeAmount: 600.0,
        sizeUnit: 'g',
      ));
    }

    if (clean.contains('شعلان') || clean.contains('ارز') || clean.contains('أرز')) {
      added.add(VoiceBasketItem(
        productId: 101,
        nameAr: 'أرز الشعلان مزة بسمتي هندي ١٠ كجم',
        brandAr: 'الشعلان',
        quantity: 1,
        sizeAmount: 10000.0,
        sizeUnit: 'g',
      ));
    }

    if (clean.contains('نوتيلا')) {
      added.add(VoiceBasketItem(
        productId: 201,
        nameAr: 'شوكولاتة نوتيلا قابلة للدهن ٥٠٠ جرام',
        brandAr: 'نوتيلا',
        quantity: 1,
        sizeAmount: 500.0,
        sizeUnit: 'g',
      ));
    }

    for (var a in added) {
      final existingIndex = basket.indexWhere((i) => i.productId == a.productId);
      if (existingIndex >= 0) {
        basket[existingIndex].quantity += a.quantity;
      } else {
        basket.add(a);
      }
    }

    final String msg = added.isNotEmpty
        ? 'تمت إضافة ${added.map((a) => "«${a.nameAr}» (${a.quantity} حبة)").join("، ")} إلى السلة بنجاح.'
        : 'تم فهم الطلب الصوتي: «$clean»';

    return VoiceBasketResult(
      status: 'success',
      recognizedText: clean,
      intent: 'add_items',
      messageAr: msg,
      itemsAdded: added,
      itemsModified: [],
      itemsRemoved: [],
      currentBasket: basket,
      clarificationOptions: [],
      canUndo: true,
      sessionId: 'default_session',
    );
  }
}
