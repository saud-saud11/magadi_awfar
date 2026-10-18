from typing import List, Optional, Tuple, Dict
from app.connectors.base import BaseConnector, ConnectorStatus, RawConnectorItem

class HungerstationConnector(BaseConnector):
    def __init__(self):
        super().__init__("hungerstation", "هنقرستيشن", "Hungerstation")

    def get_status(self) -> Tuple[ConnectorStatus, str]:
        return (
            ConnectorStatus.REQUIRES_SETUP,
            "يتطلب شراكة تجارية رسمية ومفاتيح الربط (client_id و client_secret عبر developer.hungerstation.com)"
        )

    def get_fees_info(self, district: Optional[str] = None) -> Dict[str, Optional[int]]:
        # Unknown dynamic delivery fees for delivery app unless client token is active!
        # Returning None enforces "الإجمالي يُؤكد لدى المتجر" per strict rules!
        return {
            "base_delivery_fee_halalas": None,
            "free_delivery_threshold_halalas": None,
            "min_order_halalas": None,
            "service_fee_halalas": None
        }

    async def search(self, query: str, district: Optional[str] = None) -> List[RawConnectorItem]:
        # Without credentials, returns empty or reference offer with unconfirmed delivery fees
        return []

class NinjaConnector(BaseConnector):
    def __init__(self):
        super().__init__("ninja", "نينجا (توصيل سريع)", "Ninja App")

    def get_status(self) -> Tuple[ConnectorStatus, str]:
        return (
            ConnectorStatus.REQUIRES_SETUP,
            "دارك ستور مغلق: يتطلب اتفاقية وصول لبيانات كتالوج المستودعات المظلمة السريعة"
        )

    def get_fees_info(self, district: Optional[str] = None) -> Dict[str, Optional[int]]:
        return {
            "base_delivery_fee_halalas": None,
            "free_delivery_threshold_halalas": None,
            "min_order_halalas": None,
            "service_fee_halalas": None
        }

    async def search(self, query: str, district: Optional[str] = None) -> List[RawConnectorItem]:
        return []

class KeetaConnector(BaseConnector):
    def __init__(self):
        super().__init__("keeta", "كيتا (Keemart)", "Keeta")

    def get_status(self) -> Tuple[ConnectorStatus, str]:
        return (
            ConnectorStatus.REQUIRES_SETUP,
            "منصة Meituan مغلقة: تتطلب اعتماد حساب متجر وشراكة تقنية رسمية للربط الكتالوجي"
        )

    def get_fees_info(self, district: Optional[str] = None) -> Dict[str, Optional[int]]:
        return {
            "base_delivery_fee_halalas": None,
            "free_delivery_threshold_halalas": None,
            "min_order_halalas": None,
            "service_fee_halalas": None
        }

    async def search(self, query: str, district: Optional[str] = None) -> List[RawConnectorItem]:
        return []

class AmazonNowConnector(BaseConnector):
    def __init__(self):
        super().__init__("amazon_now", "Amazon Now", "Amazon Now")

    def get_status(self) -> Tuple[ConnectorStatus, str]:
        return (
            ConnectorStatus.UNSUPPORTED,
            "غير مدعوم حاليًا: لا تتوفر واجهة برمجة مخصصة لمخازن Amazon Now بالمدينة المنورة، وأسعار Amazon.sa العامة لا تعكس التوصيل الفوري المحلي"
        )

    def get_fees_info(self, district: Optional[str] = None) -> Dict[str, Optional[int]]:
        return {
            "base_delivery_fee_halalas": None,
            "free_delivery_threshold_halalas": None,
            "min_order_halalas": None,
            "service_fee_halalas": None
        }

    async def search(self, query: str, district: Optional[str] = None) -> List[RawConnectorItem]:
        return []
