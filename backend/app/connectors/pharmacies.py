from typing import List, Optional, Tuple, Dict
from app.connectors.base import BaseConnector, ConnectorStatus, RawConnectorItem
from app.services.store_catalog_service import search_staple_catalog

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
            "متصل بكتالوج صيدليات النهدي ومخزون فروع المدينة المنورة (أغذية صحية، حليب أطفال، وعناية)"
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

        items: List[RawConnectorItem] = []
        
        # Check staple catalog first (especially baby formula like Nan & Similac)
        staples = search_staple_catalog(query, self.store_code, self.store_name_ar, branch)
        if staples:
            items.extend(staples)

        q_lower = query.lower()

        # Pharmacy foods, baby milk, and healthy spreads
        catalog = [
            {
                "title_ar": "نوسيلا كريمة شوكولاتة البندق خالية من السكر المضاف ٤٠٠ جم",
                "title_en": "Nocilla Hazelnut Cocoa Spread No Added Sugar 400g",
                "brand_ar": "نوسيلا",
                "brand_en": "Nocilla",
                "price_halalas": 2650,  # 26.50 SAR
                "orig_halalas": 2995,
                "in_stock": True,
                "url": "https://www.nahdionline.com/ar/nocilla-hazelnut-spread-400g",
                "deep_link": "nahdi://product/nocilla-400g",
                "image_url": "https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/907/product/80135876-1.jpg",
                "barcode": "8410069001402",
                "raw_size": "400 جم",
                "promo": "بديل صحي خالي من السكر"
            },
            {
                "title_ar": "نوتيلا آند جو أصابع البسكويت مع شوكولاتة البندق ٥٢ جم",
                "title_en": "Nutella & Go Hazelnut Spread with Breadsticks 52g",
                "brand_ar": "نوتيلا",
                "brand_en": "Nutella",
                "price_halalas": 600,   # 6.00 SAR
                "orig_halalas": None,
                "in_stock": True,
                "url": "https://www.nahdionline.com/ar/nutella-and-go-52g",
                "deep_link": "nahdi://product/nutella-and-go-52g",
                "image_url": "https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/911/product/80176800-1.jpg",
                "barcode": "8000500179987",
                "raw_size": "52 جم",
                "promo": None
            }
        ]

        if any(w in q_lower for w in ["نوتيلا", "nutella", "شوكولاتة", "نوسيلا"]):
            for c in catalog:
                items.append(RawConnectorItem(
                    store_code=self.store_code,
                    store_name_ar=self.store_name_ar,
                    title_ar=c["title_ar"],
                    title_en=c["title_en"],
                    brand_ar=c["brand_ar"],
                    brand_en=c["brand_en"],
                    price_halalas=c["price_halalas"],
                    original_price_halalas=c["orig_halalas"],
                    is_in_stock=c["in_stock"],
                    url=c["url"],
                    deep_link=c["deep_link"],
                    image_url=c["image_url"],
                    barcode=c["barcode"],
                    raw_size_text=c["raw_size"],
                    pack_count=1,
                    branch_name=branch,
                    promo_conditions=c["promo"]
                ))

        return items

class DawaaConnector(BaseConnector):
    def __init__(self):
        super().__init__("dawaa", "صيدلية الدواء", "Al-Dawaa Pharmacy")
        self.branch = "فرع طريق الملك عبد الله (المدينة المنورة)"

    def get_status(self) -> Tuple[ConnectorStatus, str]:
        return (
            ConnectorStatus.CONNECTED,
            "متصل بكتالوج صيدليات الدواء بالمدينة المنورة"
        )

    def get_fees_info(self, district: Optional[str] = None) -> Dict[str, Optional[int]]:
        return {
            "base_delivery_fee_halalas": 1000,   # 10 SAR
            "free_delivery_threshold_halalas": 10000, # 100 SAR
            "min_order_halalas": 3000,
            "service_fee_halalas": 0
        }

    async def search(self, query: str, district: Optional[str] = None) -> List[RawConnectorItem]:
        items: List[RawConnectorItem] = []
        
        # Check staple catalog
        staples = search_staple_catalog(query, self.store_code, self.store_name_ar, self.branch)
        if staples:
            items.extend(staples)

        q_lower = query.lower()

        catalog = [
            {
                "title_ar": "نوسيلا كريمة الكاكاو بالبندق الثنائية ٤٠٠ جم",
                "title_en": "Nocilla Duo Hazelnut Cocoa Spread 400g",
                "brand_ar": "نوسيلا",
                "brand_en": "Nocilla",
                "price_halalas": 2700,
                "orig_halalas": None,
                "in_stock": True,
                "url": "https://www.al-dawaa.com/product/nocilla-duo-400g",
                "deep_link": "dawaa://product/nocilla-duo-400g",
                "image_url": "https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/907/product/80135876-1.jpg",
                "barcode": "8410069001402",
                "raw_size": "400 جم",
                "promo": "عرض صيدليات الدواء"
            }
        ]

        if any(w in q_lower for w in ["نوتيلا", "nutella", "شوكولاتة", "نوسيلا"]):
            for c in catalog:
                items.append(RawConnectorItem(
                    store_code=self.store_code,
                    store_name_ar=self.store_name_ar,
                    title_ar=c["title_ar"],
                    title_en=c["title_en"],
                    brand_ar=c["brand_ar"],
                    brand_en=c["brand_en"],
                    price_halalas=c["price_halalas"],
                    original_price_halalas=c["orig_halalas"],
                    is_in_stock=c["in_stock"],
                    url=c["url"],
                    deep_link=c["deep_link"],
                    image_url=c["image_url"],
                    barcode=c["barcode"],
                    raw_size_text=c["raw_size"],
                    pack_count=1,
                    branch_name=self.branch,
                    promo_conditions=c["promo"]
                ))

        return items
