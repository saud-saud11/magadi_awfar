import re
from typing import List, Optional, Dict, Any
from app.connectors.base import RawConnectorItem
from app.services.matcher import strict_matcher

# Rich multi-category staple catalog for Saudi Arabia / Madinah
STAPLE_CATALOG = [
    # Dairy & Milk (المراعي، السعودية)
    {
        "keywords": ["حليب", "مراعي", "almarai", "milk", "لبن"],
        "brand_ar": "المراعي",
        "brand_en": "Almarai",
        "variants": [
            {"title_ar": "حليب المراعي كامل الدسم ٢ لتر", "title_en": "Almarai Fresh Milk Full Fat 2L", "raw_size": "2 لتر", "barcode": "6281007000021", "danube": 1100, "panda": 1050, "othaim": 1025, "tamimi": 1095, "noon_minutes": 1050, "amazon_sa": 1075, "carrefour": 1050},
            {"title_ar": "حليب المراعي قليل الدسم ٢ لتر", "title_en": "Almarai Fresh Milk Low Fat 2L", "raw_size": "2 لتر", "barcode": "6281007000038", "danube": 1100, "panda": 1050, "othaim": 1025, "tamimi": 1095, "noon_minutes": 1050, "amazon_sa": 1075, "carrefour": 1050},
            {"title_ar": "حليب المراعي كامل الدسم ١ لتر", "title_en": "Almarai Fresh Milk Full Fat 1L", "raw_size": "1 لتر", "barcode": "6281007000014", "danube": 600, "panda": 575, "othaim": 550, "tamimi": 595, "noon_minutes": 575, "amazon_sa": 585, "carrefour": 575},
            {"title_ar": "لبن المراعي طازج ٢ لتر", "title_en": "Almarai Fresh Laban 2L", "raw_size": "2 لتر", "barcode": "6281007000106", "danube": 1000, "panda": 950, "othaim": 925, "tamimi": 995, "noon_minutes": 950, "amazon_sa": 975, "carrefour": 950},
            {"title_ar": "زبادي المراعي طازج كامل الدسم ١ كجم", "title_en": "Almarai Fresh Yoghurt Full Fat 1kg", "raw_size": "1 كجم", "barcode": "6281007000205", "danube": 750, "panda": 700, "othaim": 675, "tamimi": 725, "noon_minutes": 700, "amazon_sa": 725, "carrefour": 700},
        ]
    },
    {
        "keywords": ["حليب السعودية", "السعودية", "saudia"],
        "brand_ar": "السعودية",
        "brand_en": "Saudia",
        "variants": [
            {"title_ar": "حليب السعودية كامل الدسم طويل الأجل ١ لتر", "title_en": "Saudia Full Fat Milk 1L", "raw_size": "1 لتر", "barcode": "6281018000018", "danube": 650, "panda": 600, "othaim": 595, "tamimi": 625, "noon_minutes": 600, "amazon_sa": 600, "carrefour": 600},
            {"title_ar": "حليب السعودية كامل الدسم طويل الأجل ٢ لتر", "title_en": "Saudia Full Fat Milk 2L", "raw_size": "2 لتر", "barcode": "6281018000025", "danube": 1150, "panda": 1100, "othaim": 1075, "tamimi": 1125, "noon_minutes": 1100, "amazon_sa": 1095, "carrefour": 1100},
            {"title_ar": "حليب السعودية قليل الدسم طويل الأجل ١ لتر", "title_en": "Saudia Low Fat Milk 1L", "raw_size": "1 لتر", "barcode": "6281018000032", "danube": 650, "panda": 600, "othaim": 595, "tamimi": 625, "noon_minutes": 600, "amazon_sa": 600, "carrefour": 600},
            {"title_ar": "حليب السعودية خالي من اللاكتوز ١ لتر", "title_en": "Saudia Lactose Free Milk 1L", "raw_size": "1 لتر", "barcode": "6281018000049", "danube": 850, "panda": 800, "othaim": 795, "tamimi": 825, "noon_minutes": 800, "amazon_sa": 800, "carrefour": 800},
            {"title_ar": "حليب السعودية كامل الدسم عبوة صغيرة ٢٠٠ مل", "title_en": "Saudia Full Fat Milk 200ml", "raw_size": "200 مل", "barcode": "6281018000056", "danube": 250, "panda": 225, "othaim": 200, "tamimi": 225, "noon_minutes": 225, "amazon_sa": 225, "carrefour": 225},
        ]
    },
    # Rice & Grains (أرز الشعلان، أبو كاس، باب الهند)
    {
        "keywords": ["ارز", "أرز", "شعلان", "rice", "شعلان", "مزه", "بسمتي"],
        "brand_ar": "الشعلان",
        "brand_en": "Al Shalan",
        "variants": [
            {"title_ar": "أرز الشعلان مزة بسمتي هندي ١٠ كجم", "title_en": "Al Shalan Basmati Sella Rice 10kg", "raw_size": "10 كجم", "barcode": "6281033000010", "danube": 8495, "panda": 7995, "othaim": 7895, "tamimi": 8250, "noon_minutes": 8100, "amazon_sa": 7995, "carrefour": 8195},
            {"title_ar": "أرز الشعلان مزة بسمتي هندي ٥ كجم", "title_en": "Al Shalan Basmati Sella Rice 5kg", "raw_size": "5 كجم", "barcode": "6281033000027", "danube": 4495, "panda": 4195, "othaim": 4095, "tamimi": 4350, "noon_minutes": 4250, "amazon_sa": 4195, "carrefour": 4295},
        ]
    },
    # Cooking Oils (زيت عافية، نور، شمس)
    {
        "keywords": ["زيت", "عافيه", "عافية", "oil", "ذرة", "نور", "شمس"],
        "brand_ar": "عافية",
        "brand_en": "Afia",
        "variants": [
            {"title_ar": "زيت عافية ذرة نقي ١.٥ لتر", "title_en": "Afia Pure Corn Oil 1.5L", "raw_size": "1.5 لتر", "barcode": "6281017000011", "danube": 2595, "panda": 2295, "othaim": 2195, "tamimi": 2350, "noon_minutes": 2250, "amazon_sa": 2295, "carrefour": 2350},
            {"title_ar": "زيت عافية ذرة نقي ٢.٩ لتر", "title_en": "Afia Pure Corn Oil 2.9L", "raw_size": "2.9 لتر", "barcode": "6281017000028", "danube": 4795, "panda": 4295, "othaim": 4195, "tamimi": 4450, "noon_minutes": 4350, "amazon_sa": 4295, "carrefour": 4395},
        ]
    },
    # Sugar & Staples (سكر الأسرة)
    {
        "keywords": ["سكر", "الاسره", "الأسرة", "sugar"],
        "brand_ar": "الأسرة",
        "brand_en": "Al Osra",
        "variants": [
            {"title_ar": "سكر الأسرة نقي ناعم ٥ كجم", "title_en": "Al Osra Fine White Sugar 5kg", "raw_size": "5 كجم", "barcode": "6281026000019", "danube": 2395, "panda": 2150, "othaim": 2095, "tamimi": 2250, "noon_minutes": 2150, "amazon_sa": 2195, "carrefour": 2195},
            {"title_ar": "سكر الأسرة نقي ناعم ١٠ كجم", "title_en": "Al Osra Fine White Sugar 10kg", "raw_size": "10 كجم", "barcode": "6281026000026", "danube": 4595, "panda": 4195, "othaim": 4050, "tamimi": 4295, "noon_minutes": 4200, "amazon_sa": 4195, "carrefour": 4250},
        ]
    },
    # Tea & Beverages (شاي ليبتون، ربيع)
    {
        "keywords": ["شاي", "ليبتون", "lipton", "tea", "ربيع"],
        "brand_ar": "ليبتون",
        "brand_en": "Lipton",
        "variants": [
            {"title_ar": "شاي ليبتون العلامة الصفراء ١٠٠ كيس", "title_en": "Lipton Yellow Label Tea 100 Bags", "raw_size": "100 كيس", "barcode": "6281006000015", "danube": 1750, "panda": 1595, "othaim": 1550, "tamimi": 1695, "noon_minutes": 1595, "amazon_sa": 1550, "carrefour": 1625},
            {"title_ar": "شاي ليبتون العلامة الصفراء فرط ٤٠٠ جرام", "title_en": "Lipton Yellow Label Loose Tea 400g", "raw_size": "400 جرام", "barcode": "6281006000022", "danube": 2195, "panda": 1950, "othaim": 1895, "tamimi": 2050, "noon_minutes": 1995, "amazon_sa": 1950, "carrefour": 1995},
        ]
    },
    # Bakery & Toast (لوزين توست)
    {
        "keywords": ["توست", "خبز", "لوزين", "toast", "bread", "lusine"],
        "brand_ar": "لوزين",
        "brand_en": "Lusine",
        "variants": [
            {"title_ar": "خبز توست أبيض فاخر لوزين ٦٠٠ جرام", "title_en": "Lusine White Sliced Toast Bread 600g", "raw_size": "600 جرام", "barcode": "6281030000012", "danube": 550, "panda": 500, "othaim": 495, "tamimi": 525, "noon_minutes": 500, "amazon_sa": 500, "carrefour": 500},
            {"title_ar": "خبز توست بر أسمر لوزين ٦٠٠ جرام", "title_en": "Lusine Brown Sliced Toast Bread 600g", "raw_size": "600 جرام", "barcode": "6281030000029", "danube": 600, "panda": 550, "othaim": 525, "tamimi": 575, "noon_minutes": 550, "amazon_sa": 550, "carrefour": 550},
        ]
    },
    # Eggs (بيض طازج)
    {
        "keywords": ["بيض", "egg", "eggs"],
        "brand_ar": "فقيه",
        "brand_en": "Fakieh",
        "variants": [
            {"title_ar": "بيض مائدة طازج كبير طبق ٣٠ حبة", "title_en": "Fresh Large Table Eggs 30 Pack", "raw_size": "30 حبة", "barcode": "6281039000014", "danube": 2150, "panda": 1995, "othaim": 1895, "tamimi": 2050, "noon_minutes": 1950, "amazon_sa": 2000, "carrefour": 1950},
        ]
    },
    # Cheeses (جبنة بوك، كيري)
    {
        "keywords": ["جبن", "جبنة", "كاسات", "بوك", "cheese", "puck"],
        "brand_ar": "بوك",
        "brand_en": "Puck",
        "variants": [
            {"title_ar": "جبنة بوك كريم قابلة للدهن ٥٠٠ جرام", "title_en": "Puck Cream Cheese Spread 500g", "raw_size": "500 جرام", "barcode": "5760466710014", "danube": 1895, "panda": 1695, "othaim": 1650, "tamimi": 1795, "noon_minutes": 1695, "amazon_sa": 1695, "carrefour": 1725},
            {"title_ar": "جبنة بوك كريم قابلة للدهن ٩١٠ جرام", "title_en": "Puck Cream Cheese Spread 910g", "raw_size": "910 جرام", "barcode": "5760466710021", "danube": 3295, "panda": 2895, "othaim": 2795, "tamimi": 2995, "noon_minutes": 2895, "amazon_sa": 2850, "carrefour": 2950},
        ]
    },
    {
        "keywords": ["كيري", "kiri", "جبن كيري", "جبنة كيري"],
        "brand_ar": "كيري",
        "brand_en": "Kiri",
        "variants": [
            {"title_ar": "جبنة كيري مربعات ٢٤ قطعة ٤٣٢ جرام", "title_en": "Kiri Cream Cheese 24 Portions 432g", "raw_size": "432 جرام", "barcode": "3073780800018", "danube": 2350, "panda": 2195, "othaim": 2095, "tamimi": 2250, "noon_minutes": 2150, "amazon_sa": 2195, "carrefour": 2195},
            {"title_ar": "جبنة كيري مربعات ١٢ قطعة ٢١٦ جرام", "title_en": "Kiri Cream Cheese 12 Portions 216g", "raw_size": "216 جرام", "barcode": "3073780800025", "danube": 1250, "panda": 1150, "othaim": 1095, "tamimi": 1195, "noon_minutes": 1150, "amazon_sa": 1150, "carrefour": 1150},
            {"title_ar": "جبنة كيري مربعات ٦ قطع ١٠٨ جرام", "title_en": "Kiri Cream Cheese 6 Portions 108g", "raw_size": "108 جرام", "barcode": "3073780800032", "danube": 700, "panda": 625, "othaim": 595, "tamimi": 650, "noon_minutes": 625, "amazon_sa": 625, "carrefour": 625},
        ]
    },
    # Chocolate & Hazelnut Spreads (نوتيلا، نوسيلا)
    {
        "keywords": ["نوتيلا", "nutella", "نوسيلا", "nocilla", "شوكولاتة دهن"],
        "brand_ar": "نوتيلا",
        "brand_en": "Nutella",
        "variants": [
            {"title_ar": "نوتيلا كريمة البندق مع الكاكاو ٤٠٠ جرام", "title_en": "Nutella Hazelnut Spread with Cocoa 400g", "raw_size": "400 جرام", "barcode": "80176800", "danube": 2495, "panda": 2295, "othaim": 2195, "tamimi": 2350, "noon_minutes": 2250, "amazon_sa": 2250, "carrefour": 2295},
            {"title_ar": "نوتيلا كريمة البندق مع الكاكاو ٧٥٠ جرام", "title_en": "Nutella Hazelnut Spread with Cocoa 750g", "raw_size": "750 جرام", "barcode": "80176817", "danube": 3695, "panda": 3450, "othaim": 3395, "tamimi": 3550, "noon_minutes": 3450, "amazon_sa": 3450, "carrefour": 3495},
            {"title_ar": "نوسيلا كريمة شوكولاتة البندق خالية من السكر ٥٠٠ جرام", "title_en": "Nocilla Hazelnut Cocoa Spread 500g", "raw_size": "500 جرام", "barcode": "8410047100015", "danube": 2695, "panda": 2495, "othaim": 2395, "tamimi": 2550, "noon_minutes": 2450, "amazon_sa": 2450, "carrefour": 2495},
        ]
    },
    # Juices & Drinks (عصير المراعي)
    {
        "keywords": ["عصير", "برتقال", "juice"],
        "brand_ar": "المراعي",
        "brand_en": "Almarai",
        "variants": [
            {"title_ar": "عصير برتقال المراعي طازج ١ لتر", "title_en": "Almarai Fresh Orange Juice 1L", "raw_size": "1 لتر", "barcode": "6281007000304", "danube": 750, "panda": 700, "othaim": 675, "tamimi": 725, "noon_minutes": 700, "amazon_sa": 700, "carrefour": 700},
        ]
    },
    # Tuna (تونة قودي)
    {
        "keywords": ["تونه", "تونة", "قودي", "tuna", "goody"],
        "brand_ar": "قودي",
        "brand_en": "Goody",
        "variants": [
            {"title_ar": "لحم تونة خفيف قودي بالزيت ١٨٥ جرام", "title_en": "Goody Light Meat Tuna in Oil 185g", "raw_size": "185 جرام", "barcode": "6281048000012", "danube": 850, "panda": 795, "othaim": 750, "tamimi": 825, "noon_minutes": 795, "amazon_sa": 775, "carrefour": 795},
        ]
    },
    # Baby Formula / Pharmacies (سيميلاك، نان)
    {
        "keywords": ["نان", "سيميلاك", "حليب اطفال", "nan", "similac"],
        "brand_ar": "نستله",
        "brand_en": "Nestle",
        "variants": [
            {"title_ar": "حليب أطفال نان أوبتي برو ١ عبوة ٨٠٠ جرام", "title_en": "Nan Optipro 1 Infant Formula 800g", "raw_size": "800 جرام", "barcode": "7613035220014", "danube": 8800, "panda": 8600, "othaim": 8550, "tamimi": 8700, "noon_minutes": 8650, "amazon_sa": 8500, "nahdi": 8600, "dawaa": 8600, "carrefour": 8600},
            {"title_ar": "حليب أطفال سيميلاك جولد ١ عبوة ٨٠٠ جرام", "title_en": "Similac Gold 1 Infant Formula 800g", "raw_size": "800 جرام", "barcode": "8427030000015", "danube": 9200, "panda": 8950, "othaim": 8900, "tamimi": 9100, "noon_minutes": 8950, "amazon_sa": 8900, "nahdi": 8950, "dawaa": 8950, "carrefour": 9000},
        ]
    }
]

def search_staple_catalog(query: str, store_code: str, store_name_ar: str, branch_name: Optional[str] = None) -> List[RawConnectorItem]:
    """Finds matching catalog items for a store across all Saudi grocery staples."""
    q_norm = strict_matcher.normalize_text(query)
    results: List[RawConnectorItem] = []

    for category in STAPLE_CATALOG:
        # Check if query matches any category keyword
        matched_kw = any(strict_matcher.normalize_text(kw) in q_norm or q_norm in strict_matcher.normalize_text(kw) for kw in category["keywords"])
        if not matched_kw:
            # Also check if any variant title matches
            matched_kw = any(q_norm in strict_matcher.normalize_text(v["title_ar"]) for v in category["variants"])

        if matched_kw:
            for v in category["variants"]:
                # Check if this store has a price defined for this variant
                price = v.get(store_code)
                if price is not None:
                    url = f"https://{store_code}.sa/product/{v['barcode']}"
                    deep_link = f"{store_code}://product/{v['barcode']}"
                    
                    # Original price simulation (if on sale)
                    orig_price = int(round(price * 1.15)) if price < v.get("danube", price) else None

                    results.append(RawConnectorItem(
                        store_code=store_code,
                        store_name_ar=store_name_ar,
                        title_ar=v["title_ar"],
                        title_en=v["title_en"],
                        brand_ar=category["brand_ar"],
                        brand_en=category["brand_en"],
                        price_halalas=price,
                        original_price_halalas=orig_price,
                        is_in_stock=True,
                        url=url,
                        deep_link=deep_link,
                        image_url="https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/911/product/80176800-1.jpg",
                        barcode=v["barcode"],
                        raw_size_text=v["raw_size"],
                        pack_count=1,
                        branch_name=branch_name,
                        promo_conditions="عرض الأسبوع الترويجي" if orig_price else None
                    ))

    return results

def seed_staple_products_to_db(db_session) -> int:
    """
    Seeds all STAPLE_CATALOG items and their store offers into the database.
    Ensures that Product and StoreOffer rows exist with real IDs for baskets.
    """
    from app.models.models import Product, Store, StoreOffer
    from app.services.matcher import strict_matcher

    stores_map = {s.code: s.id for s in db_session.query(Store).all()}
    count = 0

    for cat in STAPLE_CATALOG:
        brand_ar = cat["brand_ar"]
        brand_en = cat["brand_en"]
        for v in cat["variants"]:
            amount, unit, pack = strict_matcher.parse_size_and_unit(v["raw_size"])
            sub_cat, sub_cat_rank = strict_matcher.get_product_sub_category(v["title_ar"])
            
            # Find or create Product
            prod = db_session.query(Product).filter(Product.gtin_barcode == v["barcode"]).first()
            if not prod:
                prod = Product(
                    gtin_barcode=v["barcode"],
                    name_ar=v["title_ar"],
                    name_en=v.get("title_en"),
                    brand_ar=brand_ar,
                    brand_en=brand_en,
                    category="بقالة",
                    normalized_size_amount=amount,
                    normalized_size_unit=unit,
                    pack_count=pack,
                    image_url="https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/911/product/80176800-1.jpg"
                )
                db_session.add(prod)
                db_session.flush()
                count += 1
            else:
                # Update details if needed
                prod.name_ar = v["title_ar"]
                prod.normalized_size_amount = amount
                prod.normalized_size_unit = unit

            # Add offers for stores that have prices defined
            for store_code, store_id in stores_map.items():
                price = v.get(store_code)
                if price is not None:
                    offer = db_session.query(StoreOffer).filter(
                        StoreOffer.product_id == prod.id,
                        StoreOffer.store_id == store_id
                    ).first()
                    if not offer:
                        orig_price = int(round(price * 1.15)) if price < v.get("danube", price) else None
                        offer = StoreOffer(
                            store_id=store_id,
                            product_id=prod.id,
                            price_halalas=price,
                            original_price_halalas=orig_price,
                            is_on_sale=(orig_price is not None),
                            is_in_stock=True,
                            product_url=f"https://{store_code}.sa/product/{v['barcode']}",
                            deep_link=f"{store_code}://product/{v['barcode']}",
                            promo_conditions="عرض ترويجي" if orig_price else None
                        )
                        db_session.add(offer)

    db_session.commit()
    return count

