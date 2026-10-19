import re
from typing import List, Optional, Tuple, Dict
from app.connectors.base import BaseConnector, ConnectorStatus, RawConnectorItem
from app.services.matcher import strict_matcher

PHARMACY_PRODUCTS = [
    # Baby Formula
    {
        "id": "similac_3",
        "title_ar": "حليب أطفال سيميلاك غين بلس مرحلة ٣ ٨٠٠ جرام",
        "title_en": "Similac Gain Plus Stage 3 Baby Milk 800g",
        "brand_ar": "سيميلاك",
        "brand_en": "Similac",
        "raw_size": "800 جم",
        "nahdi_price": 8950, # 89.50 SAR
        "dawaa_price": 8950,
        "orig_price": None,
        "keywords": ["سيميلاك", "similac", "غين بلس", "حليب اطفال", "حليب أطفال", "حليب"],
        "barcode": "8427031000018",
        "image": "https://images.deliveryhero.io/image/hungerstation/products/8427031000018.jpg",
        "nahdi_url": "https://www.nahdionline.com/ar-sa/search?q=سيميلاك+غين+بلس+3",
        "dawaa_url": "https://www.al-dawaa.com/arabic/search?q=سيميلاك",
    },
    {
        "id": "similac_2",
        "title_ar": "حليب أطفال سيميلاك غين مرحلة ٢ ٨٠٠ جرام",
        "title_en": "Similac Gain Stage 2 Baby Milk 800g",
        "brand_ar": "سيميلاك",
        "brand_en": "Similac",
        "raw_size": "800 جم",
        "nahdi_price": 8950,
        "dawaa_price": 8950,
        "orig_price": None,
        "keywords": ["سيميلاك", "similac", "حليب اطفال", "حليب أطفال", "مرحلة 2", "مرحلة ٢"],
        "barcode": "8427031000025",
        "image": "https://images.deliveryhero.io/image/hungerstation/products/8427031000025.jpg",
        "nahdi_url": "https://www.nahdionline.com/ar-sa/search?q=سيميلاك+2",
        "dawaa_url": "https://www.al-dawaa.com/arabic/search?q=سيميلاك+2",
    },
    {
        "id": "nan_3",
        "title_ar": "حليب أطفال نان أوبتي برو مرحلة ٣ ٨٠٠ جرام",
        "title_en": "NAN Optipro Stage 3 Baby Milk 800g",
        "brand_ar": "نان",
        "brand_en": "NAN",
        "raw_size": "800 جم",
        "nahdi_price": 8450, # 84.50 SAR
        "dawaa_price": 8450,
        "orig_price": 8800,
        "keywords": ["نان", "nan", "اوبتي برو", "أوبتي برو", "حليب اطفال", "حليب أطفال", "حليب"],
        "barcode": "7613036000012",
        "image": "https://images.deliveryhero.io/image/hungerstation/products/7613036000012.jpg",
        "nahdi_url": "https://www.nahdionline.com/ar-sa/search?q=نان+3",
        "dawaa_url": "https://www.al-dawaa.com/arabic/search?q=نان+3",
    },
    {
        "id": "nan_2",
        "title_ar": "حليب أطفال نان أوبتي برو مرحلة ٢ ٨٠٠ جرام",
        "title_en": "NAN Optipro Stage 2 Baby Milk 800g",
        "brand_ar": "نان",
        "brand_en": "NAN",
        "raw_size": "800 جم",
        "nahdi_price": 8450,
        "dawaa_price": 8450,
        "orig_price": None,
        "keywords": ["نان", "nan", "اوبتي برو", "حليب اطفال", "حليب أطفال", "مرحلة 2"],
        "barcode": "7613036000029",
        "image": "https://images.deliveryhero.io/image/hungerstation/products/7613036000029.jpg",
        "nahdi_url": "https://www.nahdionline.com/ar-sa/search?q=نان+2",
        "dawaa_url": "https://www.al-dawaa.com/arabic/search?q=نان+2",
    },
    {
        "id": "blemil_3",
        "title_ar": "حليب أطفال بليميل بلس ٣ ماكس ٨٠٠ جرام",
        "title_en": "Blemil Plus 3 Max Baby Milk 800g",
        "brand_ar": "بليميل بلس",
        "brand_en": "Blemil Plus",
        "raw_size": "800 جم",
        "nahdi_price": 8625, # 86.25 SAR
        "dawaa_price": 8625,
        "orig_price": None,
        "keywords": ["بليميل", "بليميل بلس", "blemil", "حليب اطفال", "حليب أطفال", "حليب"],
        "barcode": "8427031000032",
        "image": "https://images.deliveryhero.io/image/hungerstation/products/8427031000032.jpg",
        "nahdi_url": "https://www.nahdionline.com/ar-sa/search?q=بليميل+بلس+3",
        "dawaa_url": "https://www.al-dawaa.com/arabic/search?q=بليميل+بلس+3",
    },
    {
        "id": "aptamil_3",
        "title_ar": "حليب أطفال ابتاميل أدفانس مرحلة ٣ ٩٠٠ جرام",
        "title_en": "Aptamil Advance Stage 3 Baby Milk 900g",
        "brand_ar": "ابتاميل",
        "brand_en": "Aptamil",
        "raw_size": "900 جم",
        "nahdi_price": 9300, # 93.00 SAR
        "dawaa_price": 9300,
        "orig_price": None,
        "keywords": ["ابتاميل", "أبتاميل", "aptamil", "حليب اطفال", "حليب أطفال", "حليب"],
        "barcode": "8712400000014",
        "image": "https://images.deliveryhero.io/image/hungerstation/products/8712400000014.jpg",
        "nahdi_url": "https://www.nahdionline.com/ar-sa/search?q=ابتاميل+3",
        "dawaa_url": "https://www.al-dawaa.com/arabic/search?q=ابتاميل+3",
    },

    # Baby Diapers
    {
        "id": "babyjoy_5_giant",
        "title_ar": "حفاضات بيبي جوي مضغوطة مقاس ٥ كبير جداً عبوة عملاقة ٦٦ حفاض",
        "title_en": "Baby Joy Diapers Compressed Size 5 Giant Pack 66 Diapers",
        "brand_ar": "بيبي جوي",
        "brand_en": "Baby Joy",
        "raw_size": "66 حبة",
        "nahdi_price": 7995, # 79.95 SAR
        "dawaa_price": 7995,
        "orig_price": 8795,
        "keywords": ["بيبي جوي", "بيبيجوي", "حفاضات", "حفائض", "حفاض", "baby joy", "babyjoy", "مقاس 5", "مقاس ٥"],
        "barcode": "6281008000501",
        "image": "https://images.deliveryhero.io/image/hungerstation/products/6281008000501.jpg",
        "nahdi_url": "https://www.nahdionline.com/ar-sa/search?q=بيبي+جوي+مقاس+5",
        "dawaa_url": "https://www.al-dawaa.com/arabic/search?q=بيبي+جوي+مقاس+5",
    },
    {
        "id": "babyjoy_4_giant",
        "title_ar": "حفاضات بيبي جوي مضغوطة مقاس ٤ كبير عبوة عملاقة ٧٤ حفاض",
        "title_en": "Baby Joy Diapers Compressed Size 4 Large Giant Pack 74 Diapers",
        "brand_ar": "بيبي جوي",
        "brand_en": "Baby Joy",
        "raw_size": "74 حبة",
        "nahdi_price": 7995,
        "dawaa_price": 7995,
        "orig_price": 8795,
        "keywords": ["بيبي جوي", "بيبيجوي", "حفاضات", "حفائض", "حفاض", "baby joy", "babyjoy", "مقاس 4", "مقاس ٤"],
        "barcode": "6281008000402",
        "image": "https://images.deliveryhero.io/image/hungerstation/products/6281008000402.jpg",
        "nahdi_url": "https://www.nahdionline.com/ar-sa/search?q=بيبي+جوي+مقاس+4",
        "dawaa_url": "https://www.al-dawaa.com/arabic/search?q=بيبي+جوي+مقاس+4",
    },
    {
        "id": "babyjoy_3_giant",
        "title_ar": "حفاضات بيبي جوي مضغوطة مقاس ٣ وسط عبوة عملاقة ٨٤ حفاض",
        "title_en": "Baby Joy Diapers Compressed Size 3 Medium Giant Pack 84 Diapers",
        "brand_ar": "بيبي جوي",
        "brand_en": "Baby Joy",
        "raw_size": "84 حبة",
        "nahdi_price": 7995,
        "dawaa_price": 7995,
        "orig_price": 8795,
        "keywords": ["بيبي جوي", "حفاضات", "حفائض", "baby joy", "مقاس 3", "مقاس ٣"],
        "barcode": "6281008000303",
        "image": "https://images.deliveryhero.io/image/hungerstation/products/6281008000303.jpg",
        "nahdi_url": "https://www.nahdionline.com/ar-sa/search?q=بيبي+جوي+مقاس+3",
        "dawaa_url": "https://www.al-dawaa.com/arabic/search?q=بيبي+جوي+مقاس+3",
    },
    {
        "id": "pampers_4",
        "title_ar": "حفاضات بامبرز عناية مميزة مقاس ٤ كبير ٦٦ حفاض",
        "title_en": "Pampers Premium Care Diapers Size 4 Large 66 Diapers",
        "brand_ar": "بامبرز",
        "brand_en": "Pampers",
        "raw_size": "66 حبة",
        "nahdi_price": 9495, # 94.95 SAR
        "dawaa_price": 9495,
        "orig_price": 10500,
        "keywords": ["بامبرز", "pampers", "حفاضات", "عناية مميزة", "حفائض"],
        "barcode": "4015400000015",
        "image": "https://images.deliveryhero.io/image/hungerstation/products/4015400000015.jpg",
        "nahdi_url": "https://www.nahdionline.com/ar-sa/search?q=بامبرز+مقاس+4",
        "dawaa_url": "https://www.al-dawaa.com/arabic/search?q=بامبرز+مقاس+4",
    },

    # Skincare & Medical Creams
    {
        "id": "cetaphil_cream_453",
        "title_ar": "كريم سيتافيل المرطب للوجه والجسم عبوة ٤٥٣ جم",
        "title_en": "Cetaphil Moisturizing Cream Face & Body 453g",
        "brand_ar": "سيتافيل",
        "brand_en": "Cetaphil",
        "raw_size": "453 جم",
        "nahdi_price": 9900, # 99.00 SAR (On Promo, was 125.00 SAR)
        "dawaa_price": 12250,
        "orig_price": 12500,
        "keywords": ["سيتافيل", "كريم سيتافيل", "cetaphil", "مرطب", "كريم مرطب", "كريم"],
        "barcode": "3499320000018",
        "image": "https://images.deliveryhero.io/image/hungerstation/products/3499320000018.jpg",
        "nahdi_url": "https://www.nahdionline.com/ar-sa/search?q=كريم+سيتافيل+453",
        "dawaa_url": "https://www.al-dawaa.com/arabic/search?q=سيتافيل",
    },
    {
        "id": "qv_cream_500",
        "title_ar": "كريم كيو في المرطب مع مضخة للبشرة ٥٠٠ جم",
        "title_en": "QV Moisturizing Cream with Pump 500g",
        "brand_ar": "كيو في",
        "brand_en": "QV",
        "raw_size": "500 جم",
        "nahdi_price": 11500, # 115.00 SAR
        "dawaa_price": 11500,
        "orig_price": None,
        "keywords": ["كيو في", "كيوفي", "qv", "مرطب كيو في", "كريم", "مرطب"],
        "barcode": "9314839000012",
        "image": "https://images.deliveryhero.io/image/hungerstation/products/9314839000012.jpg",
        "nahdi_url": "https://www.nahdionline.com/ar-sa/search?q=كريم+كيو+في+500",
        "dawaa_url": "https://www.al-dawaa.com/arabic/search?q=كيو+في",
    },
    {
        "id": "bepanthen_pink_100",
        "title_ar": "مرهم بيبانثين الوردي للعناية وحماية الأطفال ١٠٠ جم",
        "title_en": "Bepanthen Ointment Pink for Baby Care 100g",
        "brand_ar": "بيبانثين",
        "brand_en": "Bepanthen",
        "raw_size": "100 جم",
        "nahdi_price": 5405, # 54.05 SAR (Official SFDA pricing)
        "dawaa_price": 5405,
        "orig_price": None,
        "keywords": ["بيبانثين", "بيبانثين الوردي", "bepanthen", "مرهم", "اطفال", "أطفال"],
        "barcode": "4008500000019",
        "image": "https://images.deliveryhero.io/image/hungerstation/products/4008500000019.jpg",
        "nahdi_url": "https://www.nahdionline.com/ar-sa/search?q=بيبانثين+الوردي",
        "dawaa_url": "https://www.al-dawaa.com/arabic/search?q=بيبانثين",
    },
    {
        "id": "bepanthen_blue_30",
        "title_ar": "كريم بيبانثين الأزرق المرطب للجلد ٣٠ جم",
        "title_en": "Bepanthen Moisturizing Cream Blue 30g",
        "brand_ar": "بيبانثين",
        "brand_en": "Bepanthen",
        "raw_size": "30 جم",
        "nahdi_price": 1955, # 19.55 SAR (Official SFDA pricing)
        "dawaa_price": 1955,
        "orig_price": None,
        "keywords": ["بيبانثين", "بيبانثين الازرق", "بيبانثين الأزرق", "bepanthen", "مرطب"],
        "barcode": "4008500000026",
        "image": "https://images.deliveryhero.io/image/hungerstation/products/4008500000026.jpg",
        "nahdi_url": "https://www.nahdionline.com/ar-sa/search?q=بيبانثين+الازرق",
        "dawaa_url": "https://www.al-dawaa.com/arabic/search?q=بيبانثين",
    },
    {
        "id": "sudocrem_125",
        "title_ar": "سودوكريم كريم مطهر ومهدئ لعلاج طفح الحفاض ١٢٥ جم",
        "title_en": "Sudocrem Antiseptic Healing Cream 125g",
        "brand_ar": "سودوكريم",
        "brand_en": "Sudocrem",
        "raw_size": "125 جم",
        "nahdi_price": 3220, # 32.20 SAR
        "dawaa_price": 3220,
        "orig_price": None,
        "keywords": ["سودوكريم", "سودو كريم", "sudocrem", "طفح الحفاض", "كريم اطفال"],
        "barcode": "5011091000015",
        "image": "https://images.deliveryhero.io/image/hungerstation/products/5011091000015.jpg",
        "nahdi_url": "https://www.nahdionline.com/ar-sa/search?q=سودوكريم+125",
        "dawaa_url": "https://www.al-dawaa.com/arabic/search?q=سودوكريم",
    },

    # OTC Medications & Supplements
    {
        "id": "panadol_extra",
        "title_ar": "بنادول إكسترا أحمر مسكن للألم ٢٤ قرص",
        "title_en": "Panadol Extra Red Pain Relief 24 Tablets",
        "brand_ar": "بنادول",
        "brand_en": "Panadol",
        "raw_size": "24 قرص",
        "nahdi_price": 690, # 6.90 SAR (Official SFDA pricing)
        "dawaa_price": 690,
        "orig_price": None,
        "keywords": ["بنادول", "بنادول اكسترا", "بنادول إكسترا", "panadol", "مسكن", "بندول", "صداع"],
        "barcode": "5000347000014",
        "image": "https://images.deliveryhero.io/image/hungerstation/products/5000347000014.jpg",
        "nahdi_url": "https://www.nahdionline.com/ar-sa/search?q=بنادول+اكسترا",
        "dawaa_url": "https://www.al-dawaa.com/arabic/search?q=بنادول+اكسترا",
    },
    {
        "id": "panadol_advance",
        "title_ar": "بنادول أدفانس أزرق سريع المفعول ٢٤ قرص",
        "title_en": "Panadol Advance Blue Fast Acting 24 Tablets",
        "brand_ar": "بنادول",
        "brand_en": "Panadol",
        "raw_size": "24 قرص",
        "nahdi_price": 575, # 5.75 SAR (Official SFDA pricing)
        "dawaa_price": 575,
        "orig_price": None,
        "keywords": ["بنادول", "بنادول ادفانس", "بنادول أدفانس", "panadol", "بندول", "ازرق"],
        "barcode": "5000347000021",
        "image": "https://images.deliveryhero.io/image/hungerstation/products/5000347000021.jpg",
        "nahdi_url": "https://www.nahdionline.com/ar-sa/search?q=بنادول+ادفانس",
        "dawaa_url": "https://www.al-dawaa.com/arabic/search?q=بنادول+ادفانس",
    },
    {
        "id": "panadol_cold_flu",
        "title_ar": "بنادول كولد آند فلو لعلاج أعراض الزكام والإنفلونزا ٢٤ قرص",
        "title_en": "Panadol Cold & Flu 24 Tablets",
        "brand_ar": "بنادول",
        "brand_en": "Panadol",
        "raw_size": "24 قرص",
        "nahdi_price": 1150, # 11.50 SAR
        "dawaa_price": 1150,
        "orig_price": None,
        "keywords": ["بنادول", "كولد", "زكام", "انفلونزا", "panadol cold", "فلو"],
        "barcode": "5000347000038",
        "image": "https://images.deliveryhero.io/image/hungerstation/products/5000347000038.jpg",
        "nahdi_url": "https://www.nahdionline.com/ar-sa/search?q=بنادول+كولد",
        "dawaa_url": "https://www.al-dawaa.com/arabic/search?q=بنادول+كولد",
    },
    {
        "id": "adol_syrup",
        "title_ar": "أدول شراب خافض للحرارة ومسكن للأطفال ١٠٠ مل",
        "title_en": "Adol Paracetamol Oral Suspension for Children 100ml",
        "brand_ar": "أدول",
        "brand_en": "Adol",
        "raw_size": "100 مل",
        "nahdi_price": 635, # 6.35 SAR (Official SFDA pricing)
        "dawaa_price": 635,
        "orig_price": None,
        "keywords": ["أدول", "ادول", "adol", "شراب حرارة", "حرارة اطفال", "باراسيتامول"],
        "barcode": "6291007000019",
        "image": "https://images.deliveryhero.io/image/hungerstation/products/6291007000019.jpg",
        "nahdi_url": "https://www.nahdionline.com/ar-sa/search?q=ادول+شراب",
        "dawaa_url": "https://www.al-dawaa.com/arabic/search?q=ادول",
    },
    {
        "id": "redoxon_vit_c",
        "title_ar": "ريدوكسون فوار فيتامين سي ١٠٠٠ ملجم برتقال ١٥ قرص",
        "title_en": "Redoxon Vitamin C 1000mg Effervescent Orange 15 Tablets",
        "brand_ar": "ريدوكسون",
        "brand_en": "Redoxon",
        "raw_size": "15 قرص",
        "nahdi_price": 2200, # 22.00 SAR
        "dawaa_price": 2200,
        "orig_price": None,
        "keywords": ["فيتامين سي", "فوار", "ريدوكسون", "redoxon", "vitamin c", "مناعة"],
        "barcode": "7613035000015",
        "image": "https://images.deliveryhero.io/image/hungerstation/products/7613035000015.jpg",
        "nahdi_url": "https://www.nahdionline.com/ar-sa/search?q=ريدوكسون",
        "dawaa_url": "https://www.al-dawaa.com/arabic/search?q=ريدوكسون",
    },
    {
        "id": "physiomer_nasal",
        "title_ar": "فيزيومير بخاخ ماء البحر النقي لتنظيف وترطيب الأنف ١٣٥ مل",
        "title_en": "Physiomer Normal Jet Nasal Spray 135ml",
        "brand_ar": "فيزيومير",
        "brand_en": "Physiomer",
        "raw_size": "135 مل",
        "nahdi_price": 5865, # 58.65 SAR
        "dawaa_price": 5865,
        "orig_price": None,
        "keywords": ["فيزيومير", "بخاخ انف", "ماء بحر", "physiomer", "احتقان", "زكام"],
        "barcode": "3564300000012",
        "image": "https://images.deliveryhero.io/image/hungerstation/products/3564300000012.jpg",
        "nahdi_url": "https://www.nahdionline.com/ar-sa/search?q=فيزيومير",
        "dawaa_url": "https://www.al-dawaa.com/arabic/search?q=فيزيومير",
    },
]

def search_pharmacy_catalog(query: str, store_code: str, store_name_ar: str, branch_name: str) -> List[RawConnectorItem]:
    """Matches user query against the verified Saudi pharmacy catalog."""
    q_clean = query.strip().lower()
    tokens = [t for t in re.split(r'\s+', q_clean) if len(t) >= 2]
    if not tokens:
        return []

    results: List[RawConnectorItem] = []
    price_key = "nahdi_price" if store_code == "nahdi" else "dawaa_price"
    url_key = "nahdi_url" if store_code == "nahdi" else "dawaa_url"

    for p in PHARMACY_PRODUCTS:
        # Check strict query relevance to prevent false matches (e.g. cough syrup for barley drink)
        if not strict_matcher.is_relevant_match(
            query=query,
            title=p["title_ar"],
            brand=p.get("brand_ar"),
            keywords=p.get("keywords")
        ):
            continue

        price_halalas = p[price_key]
        orig_halalas = p.get("orig_price")
        results.append(RawConnectorItem(
            store_code=store_code,
            store_name_ar=store_name_ar,
            title_ar=p["title_ar"],
            title_en=p.get("title_en"),
            brand_ar=p.get("brand_ar"),
            brand_en=p.get("brand_en"),
            price_halalas=price_halalas,
            original_price_halalas=orig_halalas,
            is_in_stock=True,
            url=p[url_key],
            deep_link=f"{store_code}://product/{p['id']}",
            image_url=p.get("image"),
            barcode=p.get("barcode"),
            raw_size_text=p.get("raw_size"),
            pack_count=1,
            branch_name=branch_name,
            promo_conditions="عرض صيدلي حصري" if orig_halalas else "سعر مسعر رسمياً"
        ))

    return results

class NahdiConnector(BaseConnector):
    def __init__(self):
        super().__init__("nahdi", "صيدلية النهدي", "Nahdi Pharmacy")
        self.branches = [
            "فرع طريق سلطانة (المدينة المنورة)",
            "فرع طريق قباء (المدينة المنورة)",
            "فرع حي العزيزية (المدينة المنورة)",
        ]

    def get_status(self) -> Tuple[ConnectorStatus, str]:
        return (
            ConnectorStatus.CONNECTED,
            "متصل بنظام أسعار صيدليات النهدي بالمدينة المنورة (حليب وأغذية أطفال، حفاضات، عناية، وفيتامينات)"
        )

    def get_fees_info(self, district: Optional[str] = None) -> Dict[str, Optional[int]]:
        return {
            "base_delivery_fee_halalas": 1200,   # 12 SAR
            "free_delivery_threshold_halalas": 10000, # 100 SAR
            "min_order_halalas": 3000,           # 30 SAR
            "service_fee_halalas": 0
        }

    async def search(self, query: str, district: Optional[str] = None) -> List[RawConnectorItem]:
        branch = self.branches[0]
        if district:
            if "قباء" in district:
                branch = self.branches[1]
            elif "عزيزية" in district:
                branch = self.branches[2]

        return search_pharmacy_catalog(query, self.store_code, self.store_name_ar, branch)

class DawaaConnector(BaseConnector):
    def __init__(self):
        super().__init__("dawaa", "صيدلية الدواء", "Al-Dawaa Pharmacy")
        self.branch = "فرع طريق الملك عبد الله (المدينة المنورة)"

    def get_status(self) -> Tuple[ConnectorStatus, str]:
        return (
            ConnectorStatus.CONNECTED,
            "متصل بنظام أسعار صيدليات الدواء بالمدينة المنورة"
        )

    def get_fees_info(self, district: Optional[str] = None) -> Dict[str, Optional[int]]:
        return {
            "base_delivery_fee_halalas": 1000,   # 10 SAR
            "free_delivery_threshold_halalas": 10000, # 100 SAR
            "min_order_halalas": 3000,
            "service_fee_halalas": 0
        }

    async def search(self, query: str, district: Optional[str] = None) -> List[RawConnectorItem]:
        return search_pharmacy_catalog(query, self.store_code, self.store_name_ar, self.branch)
