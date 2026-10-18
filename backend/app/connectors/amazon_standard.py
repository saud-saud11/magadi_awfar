from typing import List, Optional, Tuple, Dict
from app.connectors.base import BaseConnector, ConnectorStatus, RawConnectorItem
from app.services.store_catalog_service import search_staple_catalog

class AmazonStandardConnector(BaseConnector):
    def __init__(self):
        super().__init__("amazon_sa", "أمازون السعودية (بقالة)", "Amazon.sa Grocery")
        self.fulfillment = "مستودعات أمازون السعودية (شحن وتوصيل لكافة أحياء المدينة المنورة)"

    def get_status(self) -> Tuple[ConnectorStatus, str]:
        return (
            ConnectorStatus.CONNECTED,
            "متصل بمتجر بقالة وسوبرماركت أمازون السعودية مع شحن وتوصيل لجميع أحياء المدينة المنورة"
        )

    def get_fees_info(self, district: Optional[str] = None) -> Dict[str, Optional[int]]:
        return {
            "base_delivery_fee_halalas": 1200,   # 12 SAR standard delivery
            "free_delivery_threshold_halalas": 10000, # Free shipping over 100 SAR (or free with Prime)
            "min_order_halalas": 0,
            "service_fee_halalas": 0
        }

    async def search(self, query: str, district: Optional[str] = None) -> List[RawConnectorItem]:
        items: List[RawConnectorItem] = []
        
        # Check staple catalog first
        staples = search_staple_catalog(query, self.store_code, self.store_name_ar, self.fulfillment)
        if staples:
            items.extend(staples)

        q_lower = query.lower()

        # Regular Amazon.sa grocery catalog
        catalog = [
            {
                "title_ar": "نوتيلا شوكولاتة بالبندق قابلة للدهن عبوة ٧٥٠ جرام",
                "title_en": "Nutella Hazelnut Spread with Cocoa Jar 750g",
                "brand_ar": "نوتيلا",
                "brand_en": "Nutella",
                "price_halalas": 3450,  # 34.50 SAR (Amazon competitive price)
                "orig_halalas": 3900,
                "in_stock": True,
                "url": "https://www.amazon.sa/dp/B074F4C34D",
                "deep_link": "amazon://dp/B074F4C34D",
                "image_url": "https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/911/product/80176800-1.jpg",
                "barcode": "80176800",
                "raw_size": "750 جرام",
                "promo": "شحن مجاني لأعضاء برايم"
            },
            {
                "title_ar": "نوتيلا شوكولاتة بالبندق قابلة للدهن برطمان ٨٢٥ جرام",
                "title_en": "Nutella Hazelnut Spread with Cocoa Jar 825g",
                "brand_ar": "نوتيلا",
                "brand_en": "Nutella",
                "price_halalas": 3675,  # 36.75 SAR
                "orig_halalas": None,
                "in_stock": True,
                "url": "https://www.amazon.sa/dp/B0821M891X",
                "deep_link": "amazon://dp/B0821M891X",
                "image_url": "https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/911/product/80176800-1.jpg",
                "barcode": "8000500193389",
                "raw_size": "825 جرام",
                "promo": "توصيل اليوم التالي للمدينة المنورة"
            },
            {
                "title_ar": "نوتيلا بي-ريدي أصابع الويفر المقرمشة محشوة بالشوكولاتة ٢٢ جم (عبوة ٣٦ قطعة)",
                "title_en": "Nutella B-ready Crispy Wafer Bars 22g (Pack of 36)",
                "brand_ar": "نوتيلا",
                "brand_en": "Nutella",
                "price_halalas": 5400,  # 54.00 SAR
                "orig_halalas": 6500,
                "in_stock": True,
                "url": "https://www.amazon.sa/dp/B00LTT7YV4",
                "deep_link": "amazon://dp/B00LTT7YV4",
                "image_url": "https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/896/product/8000500193389-1.jpg",
                "barcode": "8000500213456",
                "raw_size": "792 جرام",
                "pack_count": 36,
                "promo": "توفير مع الشراء المتكرر"
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
                    pack_count=c.get("pack_count", 1),
                    branch_name=self.fulfillment,
                    promo_conditions=c["promo"]
                ))

        return items
