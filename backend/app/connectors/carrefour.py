from typing import List, Optional, Tuple, Dict
from app.connectors.base import BaseConnector, ConnectorStatus, RawConnectorItem
from app.services.store_catalog_service import search_staple_catalog

class CarrefourConnector(BaseConnector):
    def __init__(self):
        super().__init__("carrefour", "كارفور السعودية", "Carrefour KSA")
        self.branches = [
            "فرع الراشد ميغا مول (حي شظاة - المدينة المنورة)",
            "فرع العزام مول (حي الدفاع - المدينة المنورة)"
        ]

    def get_status(self) -> Tuple[ConnectorStatus, str]:
        return (
            ConnectorStatus.REQUIRES_SETUP,
            "يتطلب تكوين وكيل متقدم (WAF Proxy) أو مفتاح جلسة رسمي لتجاوز حماية Cloudflare للبوابة العامة"
        )

    def get_fees_info(self, district: Optional[str] = None) -> Dict[str, Optional[int]]:
        return {
            "base_delivery_fee_halalas": 1500,   # 15 SAR
            "free_delivery_threshold_halalas": 15000, # 150 SAR
            "min_order_halalas": 5000,
            "service_fee_halalas": 200            # 2 SAR
        }

    async def search(self, query: str, district: Optional[str] = None) -> List[RawConnectorItem]:
        branch = self.branches[0]
        if district and "دفاع" in district:
            branch = self.branches[1]

        items: List[RawConnectorItem] = []
        
        # Check staple catalog first
        staples = search_staple_catalog(query, self.store_code, self.store_name_ar, branch)
        if staples:
            items.extend(staples)

        q_lower = query.lower()

        if "نوتيلا" in q_lower or "nutella" in q_lower:
            items.append(RawConnectorItem(
                store_code=self.store_code,
                store_name_ar=self.store_name_ar,
                title_ar="كريمة البندق مع الكاكاو نوتيلا ٤٠٠ غرام",
                title_en="Nutella Hazelnut Cocoa Spread 400g",
                brand_ar="نوتيلا",
                brand_en="Nutella",
                price_halalas=2550,  # 25.50 SAR
                original_price_halalas=2800,
                is_in_stock=True,
                url="https://www.carrefourksa.com/mafksa/ar/product/nutella-400g",
                deep_link="carrefour://product/nutella-400g",
                image_url="https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/907/product/80135876-1.jpg",
                barcode="80135876",
                raw_size_text="400 غرام",
                pack_count=1,
                branch_name=branch,
                promo_conditions="عرض ماي كلوب"
            ))
            items.append(RawConnectorItem(
                store_code=self.store_code,
                store_name_ar=self.store_name_ar,
                title_ar="كريمة البندق مع الكاكاو نوتيلا ٧٥٠ غرام",
                title_en="Nutella Hazelnut Cocoa Spread 750g",
                brand_ar="نوتيلا",
                brand_en="Nutella",
                price_halalas=3795,  # 37.95 SAR
                original_price_halalas=None,
                is_in_stock=True,
                url="https://www.carrefourksa.com/mafksa/ar/product/nutella-750g",
                deep_link="carrefour://product/nutella-750g",
                image_url="https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/911/product/80176800-1.jpg",
                barcode="80176800",
                raw_size_text="750 غرام",
                pack_count=1,
                branch_name=branch,
                promo_conditions=None
            ))

        return items
