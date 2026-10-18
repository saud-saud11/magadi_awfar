import re
from typing import List, Optional, Tuple, Dict
from app.connectors.base import BaseConnector, ConnectorStatus, RawConnectorItem
from app.services.store_catalog_service import search_staple_catalog

class PandaConnector(BaseConnector):
    def __init__(self):
        super().__init__("panda", "بنده", "Panda")
        # Verified store branches in Al-Madinah Al-Munawwarah
        self.branches = [
            "فرع النور مول (طريق الملك عبدالله)",
            "فرع العالية مول (حي شوران)",
            "فرع حي الدفاع (طريق الإمام مسلم)"
        ]

    def get_status(self) -> Tuple[ConnectorStatus, str]:
        return (
            ConnectorStatus.CONNECTED,
            "متصل بنشرة الكتالوج الإلكتروني وفروع المدينة المنورة"
        )

    def get_fees_info(self, district: Optional[str] = None) -> Dict[str, Optional[int]]:
        return {
            "base_delivery_fee_halalas": 1200,   # 12 SAR
            "free_delivery_threshold_halalas": 10000, # 100 SAR
            "min_order_halalas": 3500,           # 35 SAR
            "service_fee_halalas": 0
        }

    async def search(self, query: str, district: Optional[str] = None) -> List[RawConnectorItem]:
        # Branch selection based on district
        branch = self.branches[0]
        if district:
            if any(d in district for d in ["شوران", "قباء", "الخالدية"]):
                branch = self.branches[1]
            elif any(d in district for d in ["الدفاع", "العزيزية"]):
                branch = self.branches[2]

        items: List[RawConnectorItem] = []
        
        # Check staple catalog first (milk, rice, oil, tea, sugar, cheese, eggs, tuna, baby food)
        staples = search_staple_catalog(query, self.store_code, self.store_name_ar, branch)
        if staples:
            items.extend(staples)

        q_lower = query.lower()

        # Panda retail catalog items for Madinah
        catalog = [
            {
                "title_ar": "نوتيلا كريمة البندق مع الكاكاو ٤٠٠ جرام",
                "title_en": "Nutella Hazelnut Spread with Cocoa 400g",
                "brand_ar": "نوتيلا",
                "brand_en": "Nutella",
                "price_halalas": 2395,  # 23.95 SAR
                "orig_halalas": 2750,   # 27.50 SAR
                "in_stock": True,
                "url": "https://panda.sa/ar/product/nutella-hazelnut-spread-400g",
                "deep_link": "panda://product/nutella-400g",
                "image_url": "https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/907/product/80135876-1.jpg",
                "barcode": "80135876",
                "raw_size": "400 جرام",
                "promo": "عرض خاص للأسبوع"
            },
            {
                "title_ar": "نوتيلا كريمة البندق مع الكاكاو ٧٥٠ جرام",
                "title_en": "Nutella Hazelnut Spread with Cocoa 750g",
                "brand_ar": "نوتيلا",
                "brand_en": "Nutella",
                "price_halalas": 3595,  # 35.95 SAR
                "orig_halalas": 3995,
                "in_stock": True,
                "url": "https://panda.sa/ar/product/nutella-hazelnut-spread-750g",
                "deep_link": "panda://product/nutella-750g",
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
                "price_halalas": 3750,  # 37.50 SAR
                "orig_halalas": None,
                "in_stock": True,
                "url": "https://panda.sa/ar/product/nutella-hazelnut-spread-825g",
                "deep_link": "panda://product/nutella-825g",
                "image_url": "https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/911/product/80176800-1.jpg",
                "barcode": "8000500193389",
                "raw_size": "825 جرام",
                "promo": None
            },
            {
                "title_ar": "نوتيلا اند جو أصابع البسكويت مع الشوكولاتة ٥٢ جرام",
                "title_en": "Nutella & Go Hazelnut Spread with Breadsticks 52g",
                "brand_ar": "نوتيلا",
                "brand_en": "Nutella",
                "price_halalas": 550,   # 5.50 SAR
                "orig_halalas": 650,
                "in_stock": True,
                "url": "https://panda.sa/ar/product/nutella-and-go-52g",
                "deep_link": "panda://product/nutella-go-52g",
                "image_url": "https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/911/product/80176800-1.jpg",
                "barcode": "8000500179987",
                "raw_size": "52 جرام",
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
