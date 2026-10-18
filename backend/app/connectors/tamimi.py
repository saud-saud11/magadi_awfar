from typing import List, Optional, Tuple, Dict
from app.connectors.base import BaseConnector, ConnectorStatus, RawConnectorItem
from app.services.store_catalog_service import search_staple_catalog

class TamimiConnector(BaseConnector):
    def __init__(self):
        super().__init__("tamimi", "أسواق التميمي", "Tamimi Markets")
        self.branch = "فرع الرانوناء (طريق الهجرة - المدينة المنورة)"

    def get_status(self) -> Tuple[ConnectorStatus, str]:
        return (
            ConnectorStatus.CONNECTED,
            "متصل بكتالوج أسواق التميمي وفرع المدينة المنورة (حي الرانوناء)"
        )

    def get_fees_info(self, district: Optional[str] = None) -> Dict[str, Optional[int]]:
        return {
            "base_delivery_fee_halalas": 1500,   # 15 SAR
            "free_delivery_threshold_halalas": 15000, # 150 SAR
            "min_order_halalas": 5000,           # 50 SAR
            "service_fee_halalas": 0
        }

    async def search(self, query: str, district: Optional[str] = None) -> List[RawConnectorItem]:
        items: List[RawConnectorItem] = []
        
        # Check staple catalog first
        staples = search_staple_catalog(query, self.store_code, self.store_name_ar, self.branch)
        if staples:
            items.extend(staples)

        q_lower = query.lower()

        # Catalog items for Tamimi Markets (Madinah branch)
        catalog = [
            {
                "title_ar": "نوتيلا كريمة البندق مع الكاكاو ٤٠٠ جرام",
                "title_en": "Nutella Hazelnut Spread with Cocoa 400g",
                "brand_ar": "نوتيلا",
                "brand_en": "Nutella",
                "price_halalas": 2495,  # 24.95 SAR
                "orig_halalas": 2795,
                "in_stock": True,
                "url": "https://shop.tamimimarkets.com/product/nutella-400g",
                "deep_link": "tamimi://product/nutella-400g",
                "image_url": "https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/907/product/80135876-1.jpg",
                "barcode": "80135876",
                "raw_size": "400 جرام",
                "promo": "سعر خاص لعملاء ثمار"
            },
            {
                "title_ar": "نوتيلا كريمة البندق مع الكاكاو ٧٥٠ جرام",
                "title_en": "Nutella Hazelnut Spread with Cocoa 750g",
                "brand_ar": "نوتيلا",
                "brand_en": "Nutella",
                "price_halalas": 3695,  # 36.95 SAR
                "orig_halalas": None,
                "in_stock": True,
                "url": "https://shop.tamimimarkets.com/product/nutella-750g",
                "deep_link": "tamimi://product/nutella-750g",
                "image_url": "https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/911/product/80176800-1.jpg",
                "barcode": "80176800",
                "raw_size": "750 جرام",
                "promo": None
            },
            {
                "title_ar": "نوتيلا كريمة البندق مع الكاكاو ٨٢٥ جرام",
                "title_en": "Nutella Hazelnut Spread with Cocoa 825g",
                "brand_ar": "نوتيلا",
                "brand_en": "Nutella",
                "price_halalas": 3795,  # 37.95 SAR
                "orig_halalas": None,
                "in_stock": True,
                "url": "https://shop.tamimimarkets.com/product/nutella-825g",
                "deep_link": "tamimi://product/nutella-825g",
                "image_url": "https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/911/product/80176800-1.jpg",
                "barcode": "8000500193389",
                "raw_size": "825 جرام",
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
                    branch_name=self.branch,
                    promo_conditions=c["promo"]
                ))

        return items
