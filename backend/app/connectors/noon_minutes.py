from typing import List, Optional, Tuple, Dict
from app.connectors.base import BaseConnector, ConnectorStatus, RawConnectorItem
from app.services.store_catalog_service import search_staple_catalog

class NoonMinutesConnector(BaseConnector):
    def __init__(self):
        super().__init__("noon_minutes", "نون منتس (توصيل فوري)", "Noon Minutes")
        self.fulfillment_center = "مستودع نون منتس السريع - المدينة المنورة (توصيل خلال 15 دقيقة)"

    def get_status(self) -> Tuple[ConnectorStatus, str]:
        return (
            ConnectorStatus.CONNECTED,
            "متصل بخدمة نون منتس للتوصيل فائق السرعة بالمدينة المنورة"
        )

    def get_fees_info(self, district: Optional[str] = None) -> Dict[str, Optional[int]]:
        return {
            "base_delivery_fee_halalas": 500,    # 5 SAR express delivery
            "free_delivery_threshold_halalas": 5000, # 50 SAR
            "min_order_halalas": 2000,           # 20 SAR
            "service_fee_halalas": 100            # 1 SAR
        }

    async def search(self, query: str, district: Optional[str] = None) -> List[RawConnectorItem]:
        items: List[RawConnectorItem] = []
        
        # Check staple catalog first
        staples = search_staple_catalog(query, self.store_code, self.store_name_ar, self.fulfillment_center)
        if staples:
            items.extend(staples)

        q_lower = query.lower()

        catalog = [
            {
                "title_ar": "نوتيلا شوكولاتة بالبندق قابلة للدهن ٤٠٠ جم",
                "title_en": "Nutella Hazelnut Cocoa Spread Jar 400g",
                "brand_ar": "نوتيلا",
                "brand_en": "Nutella",
                "price_halalas": 2400,  # 24.00 SAR
                "orig_halalas": 2695,
                "in_stock": True,
                "url": "https://www.noon.com/saudi-ar/minutes/product/nutella-400g",
                "deep_link": "noon://minutes/product/nutella-400g",
                "image_url": "https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/907/product/80135876-1.jpg",
                "barcode": "80135876",
                "raw_size": "400 جم",
                "promo": "توصيل خلال 15 دقيقة"
            },
            {
                "title_ar": "نوتيلا شوكولاتة بالبندق قابلة للدهن ٧٥٠ جم",
                "title_en": "Nutella Hazelnut Cocoa Spread Jar 750g",
                "brand_ar": "نوتيلا",
                "brand_en": "Nutella",
                "price_halalas": 3550,  # 35.50 SAR
                "orig_halalas": 3895,
                "in_stock": True,
                "url": "https://www.noon.com/saudi-ar/minutes/product/nutella-750g",
                "deep_link": "noon://minutes/product/nutella-750g",
                "image_url": "https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/911/product/80176800-1.jpg",
                "barcode": "80176800",
                "raw_size": "750 جم",
                "promo": "توصيل خلال 15 دقيقة"
            },
            {
                "title_ar": "نوتيلا آند جو أصابع البسكويت ٥٢ جم",
                "title_en": "Nutella & Go Hazelnut Spread with Breadsticks 52g",
                "brand_ar": "نوتيلا",
                "brand_en": "Nutella",
                "price_halalas": 525,   # 5.25 SAR
                "orig_halalas": None,
                "in_stock": True,
                "url": "https://www.noon.com/saudi-ar/minutes/product/nutella-go-52g",
                "deep_link": "noon://minutes/product/nutella-go-52g",
                "image_url": "https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/911/product/80176800-1.jpg",
                "barcode": "8000500179987",
                "raw_size": "52 جم",
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
                    branch_name=self.fulfillment_center,
                    promo_conditions=c["promo"]
                ))

        return items
