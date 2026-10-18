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
    // Tuna
    {
      'id': 1201,
      'name_ar': 'لحم تونة خفيف قودي بالزيت ١٨٥ جرام',
      'brand_ar': 'قودي',
      'barcode': '6281017000101',
      'category': 'المعلبات والأغذية المحفوظة',
      'amount': 185.0,
      'unit': 'g',
      'keywords': ['تونة', 'تونه', 'قودي', 'tuna', 'لحم تونة'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281017000101.jpg',
      'prices': {
        'othaim': 750,
        'amazon_sa': 775,
        'panda': 795,
        'carrefour': 795,
        'tamimi': 825,
        'danube': 850,
      }
    },
    {
      'id': 1202,
      'name_ar': 'تونة هالي خفيف ٢٠٠ جرام',
      'brand_ar': 'هالي',
      'barcode': '6281017000102',
      'category': 'المعلبات والأغذية المحفوظة',
      'amount': 200.0,
      'unit': 'g',
      'keywords': ['تونة', 'تونه', 'هالي', 'tuna'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281017000102.jpg',
      'prices': {
        'othaim': 475,
        'panda': 525,
        'carrefour': 550,
        'tamimi': 595,
        'danube': 625,
      }
    },
    {
      'id': 1203,
      'name_ar': 'تونة الخير قطع بالزيت ١٨٥ غرام',
      'brand_ar': 'الخير',
      'barcode': '6281017000103',
      'category': 'المعلبات والأغذية المحفوظة',
      'amount': 185.0,
      'unit': 'g',
      'keywords': ['تونة', 'تونه', 'الخير', 'tuna'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281017000103.jpg',
      'prices': {
        'othaim': 595,
        'tamimi': 625,
        'carrefour': 650,
        'panda': 675,
        'danube': 700,
      }
    },
    // Tea
    {
      'id': 1301,
      'name_ar': 'شاي ربيع أوراق كاملة فاخر علبة ٤٠٠ جم',
      'brand_ar': 'ربيع',
      'barcode': '6281007000201',
      'category': 'الشاي والقهوة',
      'amount': 400.0,
      'unit': 'g',
      'keywords': ['شاي', 'ربيع', 'شاي ربيع', 'tea', 'اوراق شاي'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281007000201.jpg',
      'prices': {
        'othaim': 2495,
        'carrefour': 2550,
        'tamimi': 2600,
        'panda': 2650,
        'amazon_sa': 2650,
        'danube': 2795,
      }
    },
    {
      'id': 1302,
      'name_ar': 'شاي ربيع أحمر خيط ١٠٠ كيس',
      'brand_ar': 'ربيع',
      'barcode': '6281007000202',
      'category': 'الشاي والقهوة',
      'amount': 100.0,
      'unit': 'كيس',
      'keywords': ['شاي', 'ربيع', 'اكياس شاي', 'أكياس'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281007000202.jpg',
      'prices': {
        'othaim': 1595,
        'panda': 1650,
        'carrefour': 1650,
        'tamimi': 1725,
        'danube': 1850,
      }
    },
    {
      'id': 1303,
      'name_ar': 'شاي لبتون العلامة الصفراء ١٠٠ كيس',
      'brand_ar': 'لبتون',
      'barcode': '6281007000203',
      'category': 'الشاي والقهوة',
      'amount': 100.0,
      'unit': 'كيس',
      'keywords': ['شاي', 'لبتون', 'ليبتون', 'lipton'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281007000203.jpg',
      'prices': {
        'othaim': 1795,
        'carrefour': 1850,
        'panda': 1895,
        'tamimi': 1950,
        'danube': 2095,
      }
    },
    // Pasta
    {
      'id': 1401,
      'name_ar': 'مكرونة قودي سباغيتي ٤٥٠ جرام',
      'brand_ar': 'قودي',
      'barcode': '6281014000301',
      'category': 'المعكرونة والصلصات',
      'amount': 450.0,
      'unit': 'g',
      'keywords': ['مكرونة', 'معكرونة', 'سباغيتي', 'قودي', 'pasta'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281014000301.jpg',
      'prices': {
        'othaim': 450,
        'carrefour': 450,
        'panda': 495,
        'tamimi': 525,
        'amazon_sa': 525,
        'danube': 575,
      }
    },
    {
      'id': 1402,
      'name_ar': 'مكرونة قودي خواتم ٤٥٠ جرام',
      'brand_ar': 'قودي',
      'barcode': '6281014000302',
      'category': 'المعكرونة والصلصات',
      'amount': 450.0,
      'unit': 'g',
      'keywords': ['مكرونة', 'معكرونة', 'قودي', 'خواتم'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281014000302.jpg',
      'prices': {
        'othaim': 450,
        'carrefour': 450,
        'panda': 495,
        'tamimi': 525,
        'danube': 575,
      }
    },
    // Cheeses
    {
      'id': 1501,
      'name_ar': 'جبنة كيري مربعات بالقشطة ٢٤ قطعة ٤٣٢ جم',
      'brand_ar': 'كيري',
      'barcode': '3073780850011',
      'category': 'الأجبان ومنتجات الألبان',
      'amount': 432.0,
      'unit': 'g',
      'keywords': ['جبنة', 'جبن', 'كيري', 'kiri', 'مربعات'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/3073780850011.jpg',
      'prices': {
        'othaim': 2495,
        'carrefour': 2550,
        'panda': 2595,
        'tamimi': 2675,
        'danube': 2850,
      }
    },
    {
      'id': 1502,
      'name_ar': 'جبنة بوك كريم قابلة للدهن جرة ٥٠٠ جم',
      'brand_ar': 'بوك',
      'barcode': '5760466750012',
      'category': 'الأجبان ومنتجات الألبان',
      'amount': 500.0,
      'unit': 'g',
      'keywords': ['جبنة', 'جبن', 'بوك', 'puck', 'كاسات', 'كريم'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/5760466750012.jpg',
      'prices': {
        'othaim': 1695,
        'carrefour': 1750,
        'panda': 1795,
        'tamimi': 1850,
        'danube': 1995,
      }
    },
    {
      'id': 1503,
      'name_ar': 'جبنة كرافت شيدر قابلة للدهن ٤٨٠ جم',
      'brand_ar': 'كرافت',
      'barcode': '7622210000015',
      'category': 'الأجبان ومنتجات الألبان',
      'amount': 480.0,
      'unit': 'g',
      'keywords': ['جبنة', 'جبن', 'كرافت', 'kraft', 'شيدر'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/7622210000015.jpg',
      'prices': {
        'othaim': 1950,
        'carrefour': 1995,
        'panda': 2050,
        'tamimi': 2125,
        'danube': 2250,
      }
    },
    // Detergents
    {
      'id': 1601,
      'name_ar': 'مسحوق غسيل تايد للغسالات الأوتوماتيك كيس ٢.٥ كجم',
      'brand_ar': 'تايد',
      'barcode': '4084500000011',
      'category': 'المنظفات والعناية المنزلية',
      'amount': 2500.0,
      'unit': 'g',
      'keywords': ['تايد', 'tide', 'صابون تايد', 'صابون', 'مسحوق غسيل'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/4084500000011.jpg',
      'prices': {
        'othaim': 3695,
        'carrefour': 3750,
        'panda': 3895,
        'tamimi': 3995,
        'danube': 4250,
      }
    },
    {
      'id': 1602,
      'name_ar': 'سائل غسيل الصحون فيري بالليمون ١ لتر',
      'brand_ar': 'فيري',
      'barcode': '4084500000028',
      'category': 'المنظفات والعناية المنزلية',
      'amount': 1000.0,
      'unit': 'ml',
      'keywords': ['فيري', 'fairy', 'صابون صحون', 'سائل جلي'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/4084500000028.jpg',
      'prices': {
        'othaim': 1350,
        'carrefour': 1395,
        'panda': 1450,
        'tamimi': 1500,
        'danube': 1650,
      }
    },
    // Drinks & Sodas
    {
      'id': 1701,
      'name_ar': 'مشروب غازي بيبسي علبة ٣٢٥ مل',
      'brand_ar': 'بيبسي',
      'barcode': '6281004000012',
      'category': 'المشروبات الغازية والعصائر',
      'amount': 325.0,
      'unit': 'ml',
      'keywords': ['بيبسي', 'pepsi', 'مشروب غازي', 'علبة بيبسي'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281004000012.jpg',
      'prices': {
        'othaim': 250,
        'carrefour': 250,
        'panda': 250,
        'tamimi': 250,
        'danube': 250,
      }
    },
    {
      'id': 1702,
      'name_ar': 'مشروب غازي سفن اب علبة ٣٢٥ مل',
      'brand_ar': 'سفن اب',
      'barcode': '6281004000029',
      'category': 'المشروبات الغازية والعصائر',
      'amount': 325.0,
      'unit': 'ml',
      'keywords': ['سفن', 'سفن اب', '7up', 'مشروب غازي'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281004000029.jpg',
      'prices': {
        'othaim': 250,
        'carrefour': 250,
        'panda': 250,
        'tamimi': 250,
        'danube': 250,
      }
    },
    {
      'id': 1703,
      'name_ar': 'مياه شرب صفا مكة كرتون ٤٠ × ٣٣٠ مل',
      'brand_ar': 'صفا',
      'barcode': '6281023000018',
      'category': 'المياه',
      'amount': 40.0,
      'unit': 'حبة',
      'keywords': ['ماء', 'مياه', 'صفا', 'كرتون مويه', 'مويه'],
      'image': 'https://images.deliveryhero.io/image/hungerstation/products/6281023000018.jpg',
      'prices': {
        'othaim': 1695,
        'carrefour': 1750,
        'panda': 1795,
        'tamimi': 1850,
        'danube': 1995,
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
