import '../models/models.dart';
import 'product_matching.dart';

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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/047/562/product/shalan-basmati-rice-10-kg.jpg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/014/600/product/890600109002.jpg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/911/product/80176800-1.jpg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/911/product/80176800-1.jpg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/911/product/80176800-1.jpg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/121/321/product/628103910216.jpeg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/128/687/product/628103917531.jpg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/108/673/product/628103911231.jpeg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/128/688/product/628100706688.jpg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/101/924/product/628100707005.jpeg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/095/266/product/6281006141209_1.jpg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/095/266/product/6281006141209_1.jpg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/111/280/product/70999332463.jpeg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/125/547/product/628100706020.jpg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/087/571/product/6281011702181.png',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/144/038/product/506330500821.jpg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/088/044/product/Al_Osra_Fine_White_Sugar_5___1_KG_6285525000436.png',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/111/280/product/70999332463.jpeg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/061/288/product/539152305727.jpg',
    },
    // Baby Joy Diapers (Size 5, 4)
    {
      'id': 1102,
      'name_ar': 'حفاضات بيبي جوي مضغوطة مقاس ٥ كبير جداً عبوة عملاقة ٦٦ حفاض',
      'brand_ar': 'بيبي جوي',
      'barcode': '6281008000501',
      'category': 'حليب ورعاية الأطفال',
      'amount': 66.0,
      'unit': 'حبة',
      'keywords': [
        'بيبي جوي',
        'بيبيجوي',
        'حفاضات',
        'حفايض',
        'baby joy',
        'babyjoy',
        'مقاس 5',
        'مقاس ٥',
      ],
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/058/598/product/6281017353141.PT01.jpg',
    },
    {
      'id': 1103,
      'name_ar': 'حفاضات بيبي جوي مضغوطة مقاس ٤ كبير عبوة عملاقة ٧٤ حفاض',
      'brand_ar': 'بيبي جوي',
      'barcode': '6281008000402',
      'category': 'حليب ورعاية الأطفال',
      'amount': 74.0,
      'unit': 'حبة',
      'keywords': [
        'بيبي جوي',
        'بيبيجوي',
        'حفاضات',
        'حفايض',
        'baby joy',
        'مقاس 4',
        'مقاس ٤',
      ],
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/058/549/product/6281017353097.PT02.jpg',
    },
    // NAN Optipro 3
    {
      'id': 1104,
      'name_ar': 'حليب أطفال نان أوبتي برو مرحلة ٣ ٨٠٠ جرام',
      'brand_ar': 'نان',
      'barcode': '7613036000012',
      'category': 'حليب ورعاية الأطفال',
      'amount': 800.0,
      'unit': 'g',
      'keywords': ['نان', 'nan', 'حليب اطفال', 'حليب نان'],
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/139/649/product/628705074013.jpg',
    },
    // Panadol Extra
    {
      'id': 1801,
      'name_ar': 'بنادول إكسترا أحمر مسكن للألم ٢٤ قرص',
      'brand_ar': 'بنادول',
      'barcode': '5000347000014',
      'category': 'الأدوية والرعاية الصحية',
      'amount': 24.0,
      'unit': 'حبة',
      'keywords': [
        'بنادول',
        'بانادول',
        'بندول',
        'panadol',
        'مسكن',
        'صداع',
        'اكسترا',
      ],
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/097/254/product/Panadol_Advance_-_3D_Packshots___Thumbnail_page-0001.jpg',
    },
    // Cetaphil Cream 453g
    {
      'id': 1802,
      'name_ar': 'كريم سيتافيل المرطب للوجه والجسم عبوة ٤٥٣ جم',
      'brand_ar': 'سيتافيل',
      'barcode': '3499320000018',
      'category': 'الأدوية والرعاية الصحية',
      'amount': 453.0,
      'unit': 'g',
      'keywords': ['سيتافيل', 'cetaphil', 'مرطب', 'كريم مرطب', 'كريم'],
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/107/971/product/60602985.jpg',
    },
    // Bepanthen Pink 100g
    {
      'id': 1803,
      'name_ar': 'مرهم بيبانثين الوردي للعناية وحماية الأطفال ١٠٠ جم',
      'brand_ar': 'بيبانثين',
      'barcode': '4008500000019',
      'category': 'حليب ورعاية الأطفال',
      'amount': 100.0,
      'unit': 'g',
      'keywords': ['بيبانثين', 'بيبانثين الوردي', 'bepanthen', 'مرهم'],
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/127/010/product/6285074002974.jpg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/116/262/product/6281014302227.01.jpg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/022/223/product/490293111068.jpg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/138/431/product/628110149436.jpg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/128/056/product/6281013222762_2.jpg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/128/687/product/628103917531.jpg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/133/353/product/6281006710009_1.png',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/022/619/product/GOODY_SPAGHETTI__20_450GM.jpg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/053/656/product/goody-ditalini-rigati-pasta-no-14-450g.jpg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/095/266/product/6281006141209_1.jpg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/128/687/product/628103917531.jpg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/041/493/product/762221085249.jpg',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/048/727/product/2_tide-protect-antibacterial-ls-automatic-2-25kg.png',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/095/266/product/6281006141209_1.jpg',
    },
    // Drinks & Sodas
    {
      'id': 1701,
      'name_ar': 'مشروب غازي بيبسي علبة ٣٢٥ مل',
      'brand_ar': 'بيبسي',
      'barcode': '6281004000012',
      'category': 'عبوات فردية (بالحبّة)',
      'amount': 325.0,
      'unit': 'ml',
      'pack_count': 1,
      'pack_type': 'single',
      'pack_label_ar': 'بالحبّة (مفرد)',
      'keywords': ['بيبسي', 'pepsi', 'مشروب غازي', 'علبة بيبسي', 'حبة بيبسي'],
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/133/397/product/12000059780_1.png',
    },
    {
      'id': 1704,
      'name_ar': 'بيبسي مشروب غازي حزمة ٦ × ٣٢٥ مل',
      'brand_ar': 'بيبسي',
      'barcode': '6281004000067',
      'category': 'حزم وكراتين (عروض شدّات)',
      'amount': 325.0,
      'unit': 'ml',
      'pack_count': 6,
      'pack_type': 'bundle',
      'pack_label_ar': 'حزمة (6 علب)',
      'keywords': [
        'بيبسي',
        'pepsi',
        'حزمة بيبسي',
        'شدة بيبسي',
        'شدة',
        'حزمة',
        '6 علب',
      ],
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/133/397/product/12000059780_1.png',
    },
    {
      'id': 1705,
      'name_ar': 'بيبسي مشروب غازي كرتون ٢٤ × ٣٢٥ مل',
      'brand_ar': 'بيبسي',
      'barcode': '6281004000241',
      'category': 'حزم وكراتين (عروض شدّات)',
      'amount': 325.0,
      'unit': 'ml',
      'pack_count': 24,
      'pack_type': 'bundle',
      'pack_label_ar': 'كرتون (24 علبة)',
      'keywords': [
        'بيبسي',
        'pepsi',
        'كرتون بيبسي',
        'كرتون',
        '24 علبة',
        '24 حبة',
      ],
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/133/397/product/12000059780_1.png',
    },
    {
      'id': 1706,
      'name_ar': 'مشروب غازي بيبسي قارورة عائلية ٢.٢٥ لتر',
      'brand_ar': 'بيبسي',
      'barcode': '6281004002252',
      'category': 'عبوات فردية (بالحبّة)',
      'amount': 2250.0,
      'unit': 'ml',
      'pack_count': 1,
      'pack_type': 'single',
      'pack_label_ar': 'قارورة عائلية (بالحبّة)',
      'keywords': ['بيبسي', 'pepsi', 'قارورة', 'عائلي', '2.25 لتر'],
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/133/397/product/12000059780_1.png',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/133/493/product/12000022913_1.png',
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
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/026/784/product/628110006903.jpg',
    },
    // Malt & Barley Beverages (موسي، بربيكان، هولستن)
    {
      'id': 1801,
      'name_ar': 'موسي شراب شعير كلاسيك خالي من الكحول ٣٣٠ مل',
      'brand_ar': 'موسي',
      'barcode': '7614400000018',
      'category': 'المشروبات الغازية والعصائر',
      'amount': 330.0,
      'unit': 'ml',
      'pack_count': 1,
      'pack_type': 'single',
      'pack_label_ar': 'بالحبّة (مفرد)',
      'keywords': [
        'موسي',
        'moussy',
        'شعير',
        'شراب شعير',
        'مشروب شعير',
        'موسي كلاسيك',
        'سادة',
      ],
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/097/254/product/Panadol_Advance_-_3D_Packshots___Thumbnail_page-0001.jpg',
    },
    {
      'id': 1802,
      'name_ar': 'موسي شراب شعير بنكهة الرمان خالي من الكحول ٣٣٠ مل',
      'brand_ar': 'موسي',
      'barcode': '7614400000025',
      'category': 'المشروبات الغازية والعصائر',
      'amount': 330.0,
      'unit': 'ml',
      'pack_count': 1,
      'pack_type': 'single',
      'pack_label_ar': 'بالحبّة (مفرد)',
      'keywords': ['موسي', 'moussy', 'شعير', 'شراب شعير', 'رمان', 'موسي رمان'],
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/107/971/product/60602985.jpg',
    },
    {
      'id': 1803,
      'name_ar': 'بربيكان شراب شعير سادة زجاجة ٣٢٥ مل',
      'brand_ar': 'بربيكان',
      'barcode': '6281034900013',
      'category': 'المشروبات الغازية والعصائر',
      'amount': 325.0,
      'unit': 'ml',
      'pack_count': 1,
      'pack_type': 'single',
      'pack_label_ar': 'بالحبّة (مفرد)',
      'keywords': [
        'بربيكان',
        'barbican',
        'شعير',
        'شراب شعير',
        'سادة',
        'مشروب شعير',
      ],
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/127/010/product/6285074002974.jpg',
    },
    {
      'id': 1804,
      'name_ar': 'بربيكان شراب شعير بنكهة التفاح حزمة ٦ × ٢٥٠ مل',
      'brand_ar': 'بربيكان',
      'barcode': '6281034900020',
      'category': 'المشروبات الغازية والعصائر',
      'amount': 250.0,
      'unit': 'ml',
      'pack_count': 6,
      'pack_type': 'bundle',
      'pack_label_ar': 'حزمة (6 علب)',
      'keywords': [
        'بربيكان',
        'barbican',
        'شعير',
        'شراب شعير',
        'تفاح',
        'شدة بربيكان',
        'حزمة',
      ],
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/013/593/product/7616297.jpg',
    },
    {
      'id': 1805,
      'name_ar': 'هولستن شراب شعير كلاسيك زجاجة ٣٣٠ مل',
      'brand_ar': 'هولستن',
      'barcode': '4008854000012',
      'category': 'المشروبات الغازية والعصائر',
      'amount': 330.0,
      'unit': 'ml',
      'pack_count': 1,
      'pack_type': 'single',
      'pack_label_ar': 'بالحبّة (مفرد)',
      'keywords': [
        'هولستن',
        'holsten',
        'شعير',
        'شراب شعير',
        'مشروب شعير',
        'كلاسيك',
      ],
      'image':
          'https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/078/981/product/3219110457551.jpg',
    },
  ];

  static String _normalize(String s) {
    var text = s.toLowerCase();
    text = text.replaceAll(RegExp(r'[\u064B-\u0652]'), ''); // tashkeel
    text = text.replaceAll(RegExp(r'[إأآا]'), 'ا');
    text = text.replaceAll('ة', 'ه');
    text = text.replaceAll(RegExp(r'[يى]'), 'ي');
    return text.trim();
  }

  static String _stripAl(String w) {
    if (w.startsWith('ال') && w.length > 3) {
      return w.substring(2);
    }
    return w;
  }

  static const Set<String> _genericStopwords = {
    'شراب',
    'مشروب',
    'عصير',
    'علبة',
    'علبه',
    'كرتون',
    'حبة',
    'حبه',
    'طازج',
    'كبير',
    'صغير',
    'وسط',
    'اصلي',
    'كيلو',
    'كجم',
    'جرام',
    'غرام',
    'جم',
    'مل',
    'لتر',
    'سادة',
    'ساده',
    'فاخر',
    'سعر',
    'عرض',
  };

  static SearchResult search({
    required String query,
    String district = 'سلطانة',
    String sortBy = 'cheapest_product',
  }) {
    final normQuery = _normalize(query);
    final tokens = normQuery
        .split(RegExp(r'[\s\-_,.]+'))
        .where((t) => t.length >= 2)
        .toList();

    List<Map<String, dynamic>> matched = [];
    List<Map<String, dynamic>> alternatives = [];

    final nonStopTokens = tokens
        .where(
          (t) =>
              !_genericStopwords.contains(t) &&
              !_genericStopwords.contains(_stripAl(t)),
        )
        .toList();

    for (var item in _staples) {
      final nameNorm = _normalize(item['name_ar'] as String);
      final brandNorm = _normalize(item['brand_ar'] as String? ?? '');
      final keywordsNorm = (item['keywords'] as List<String>)
          .map(_normalize)
          .toList();
      final haystack = '$nameNorm $brandNorm ${keywordsNorm.join(' ')}';

      final terms = nonStopTokens
          .where(
            (t) =>
                !RegExp(r'^\d+(?:\.\d+)?$').hasMatch(t) &&
                ![
                  'جرام',
                  'غرام',
                  'جم',
                  'كجم',
                  'كيلو',
                  'g',
                  'kg',
                  'مل',
                  'ml',
                  'لتر',
                  'l',
                ].contains(t),
          )
          .toList();
      final isMatch =
          normQuery.isEmpty ||
          (terms.isNotEmpty
              ? terms.every(
                  (t) => haystack.contains(t) || haystack.contains(_stripAl(t)),
                )
              : tokens.any((t) => haystack.contains(t)));

      if (isMatch) {
        final product = _buildProductItem(item, district, sortBy);
        if (ProductMatching.exactSize(query, product)) {
          matched.add(item);
        } else {
          alternatives.add(item);
        }
      }
    }

    if (matched.isEmpty && alternatives.isEmpty) {
      // Do NOT inject staples or unrelated products!
      return SearchResult(
        query: query,
        districtName: district,
        exactSizeMatched: false,
        statusMessage: 'لم نجد نتائج مطابقة لبحث «$query» في الكتالوج الحالي.',
        disclaimer:
            'تأكد من كتابة اسم الصنف بدقة أو جرب البحث بكلمات عامة مثل: حليب، أرز، زيت، عصير، بيبسي.',
        matchedProducts: const [],
        alternativeSizes: const [],
        subCategories: const ['الكل'],
        sourcesSummary: const [],
      );
    }

    // If user specified an exact target amount, separate alternatives; otherwise show all matching variants
    final matchedProducts = matched
        .map((m) => _buildProductItem(m, district, sortBy))
        .toList();
    final altProducts = alternatives
        .map((m) => _buildProductItem(m, district, sortBy))
        .toList();

    final List<String> cats = [];
    for (var p in matchedProducts) {
      if (p.subCategory != null &&
          p.subCategory!.isNotEmpty &&
          !cats.contains(p.subCategory!)) {
        cats.add(p.subCategory!);
      }
    }

    return SearchResult(
      query: query,
      districtName: district,
      exactSizeMatched: matchedProducts.isNotEmpty,
      statusMessage: 'اقتراحات من كتالوج المنتجات؛ لم نتحقق من أسعارها الآن',
      disclaimer:
          'هذه أسماء أصناف محفوظة، وليست عروضًا أو تأكيدًا للتوفر. حاول تحديث البحث.',
      matchedProducts: matchedProducts,
      alternativeSizes: altProducts,
      subCategories: cats.isNotEmpty
          ? cats
          : ['الكل', 'الألبان', 'الأرز', 'الزيوت', 'الحلويات'],
      sourcesSummary: const [],
    );
  }

  static ProductItem _buildProductItem(
    Map<String, dynamic> raw,
    String district,
    String sortBy,
  ) {
    final double amount = (raw['amount'] as num).toDouble();
    final String unit = raw['unit'] as String;
    final int packCount = raw['pack_count'] as int? ?? 1;
    final String packType =
        raw['pack_type'] as String? ?? (packCount > 1 ? 'bundle' : 'single');
    final String? packLabel = raw['pack_label_ar'] as String?;
    final List<StoreOffer> offers = [];

    return ProductItem(
      id: -(raw['id'] as int),
      gtinBarcode: null,
      nameAr: raw['name_ar'] as String,
      brandAr: raw['brand_ar'] as String?,
      subCategory: raw['category'] as String?,
      subCategoryRank: 1,
      normalizedSizeAmount: amount,
      normalizedSizeUnit: unit,
      packCount: packCount,
      packType: packType,
      packLabelAr: packLabel,
      imageUrl: raw['image'] as String?,
      offers: offers,
    );
  }

  static String? lookupImage(String query) {
    if (query.trim().isEmpty) return null;
    final norm = _normalize(query);
    for (var item in _staples) {
      final name = _normalize(item['name_ar'] as String);
      if (name == norm) {
        final img = item['image'] as String?;
        if (img != null && img.isNotEmpty && img.startsWith('http')) {
          return img;
        }
      }
    }
    return null;
  }
}
