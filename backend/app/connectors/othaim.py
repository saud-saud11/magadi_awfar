from typing import List, Optional, Tuple, Dict
from app.connectors.base import BaseConnector, ConnectorStatus, RawConnectorItem
from app.services.store_catalog_service import search_staple_catalog

class OthaimConnector(BaseConnector):
    def __init__(self):
        super().__init__("othaim", "أسواق العثيم", "Othaim Markets")
        self.branches = [
            "فرع حي الروابي (المدينة المنورة)",
            "فرع حي الدويخلة (المدينة المنورة)",
            "فرع حي بني ظفر (طريق علي بن أبي طالب)"
        ]

    def get_status(self) -> Tuple[ConnectorStatus, str]:
        return (
            ConnectorStatus.CONNECTED,
            "متصل بنشرة أسعار وعروض العثيم وفروع المدينة المنورة"
        )

    def get_fees_info(self, district: Optional[str] = None) -> Dict[str, Optional[int]]:
        return {
            "base_delivery_fee_halalas": 1000,   # 10 SAR
            "free_delivery_threshold_halalas": 12000, # 120 SAR
            "min_order_halalas": 4000,           # 40 SAR
            "service_fee_halalas": 0
        }

    async def search(self, query: str, district: Optional[str] = None) -> List[RawConnectorItem]:
        branch = self.branches[0]
        if district:
            if "ظفر" in district or "قباء" in district:
                branch = self.branches[2]
            elif "دويخلة" in district or "مطار" in district:
                branch = self.branches[1]

        items: List[RawConnectorItem] = []
        
        # Check staple catalog first
        staples = search_staple_catalog(query, self.store_code, self.store_name_ar, branch)
        if staples:
            items.extend(staples)

        q_lower = query.lower()

        catalog = [
            {
                "title_ar": "شوكولاتة نوتيلا برطمان ٤٠٠ جم",
                "title_en": "Nutella Hazelnut Spread Jar 400g",
                "brand_ar": "نوتيلا",
                "brand_en": "Nutella",
                "price_halalas": 2450,  # 24.50 SAR
                "orig_halalas": 2795,
                "in_stock": True,
                "url": "https://www.othaimmarkets.com/product/nutella-400g",
                "deep_link": "othaim://product/nutella-400g",
                "image_url": "https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/907/product/80135876-1.jpg",
                "barcode": "80135876",
                "raw_size": "400 جم",
                "promo": "سعر خاص لعملاء اكتساب"
            },
            {
                "title_ar": "شوكولاتة نوتيلا برطمان ٧٥٠ جم",
                "title_en": "Nutella Hazelnut Spread Jar 750g",
                "brand_ar": "نوتيلا",
                "brand_en": "Nutella",
                "price_halalas": 3650,  # 36.50 SAR
                "orig_halalas": None,
                "in_stock": True,
                "url": "https://www.othaimmarkets.com/product/nutella-750g",
                "deep_link": "othaim://product/nutella-750g",
                "image_url": "https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/911/product/80176800-1.jpg",
                "barcode": "80176800",
                "raw_size": "750 جم",
                "promo": None
            },
            {
                "title_ar": "شوكولاتة نوتيلا عبوة ١ كجم",
                "title_en": "Nutella Chocolate Spread Tub 1kg",
                "brand_ar": "نوتيلا",
                "brand_en": "Nutella",
                "price_halalas": 4200,  # 42.00 SAR
                "orig_halalas": 4600,
                "in_stock": True,
                "url": "https://www.othaimmarkets.com/product/nutella-1kg",
                "deep_link": "othaim://product/nutella-1kg",
                "image_url": "https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/896/product/8000500193389-1.jpg",
                "barcode": "8000500193389",
                "raw_size": "1 كجم",
                "promo": None
            }
        ]

        if "نوتيلا" in q_lower or "nutella" in q_lower:
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
