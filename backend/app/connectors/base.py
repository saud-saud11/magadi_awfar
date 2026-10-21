from abc import ABC, abstractmethod
from enum import Enum
from typing import List, Optional, Tuple, Dict, Any
from dataclasses import dataclass
from datetime import datetime

class ConnectorStatus(str, Enum):
    CONNECTED = "connected"                      # متصل
    REQUIRES_SETUP = "requires_setup"            # يحتاج إعدادًا ومفاتيح
    UNDER_INVESTIGATION = "under_investigation"  # تحت الفحص
    PAUSED = "paused"                            # متوقف مؤقتًا
    UNSUPPORTED = "unsupported"                  # غير مدعوم حاليًا

@dataclass
class RawConnectorItem:
    store_code: str
    store_name_ar: str
    title_ar: str
    title_en: Optional[str]
    brand_ar: Optional[str]
    brand_en: Optional[str]
    price_halalas: int
    original_price_halalas: Optional[int]
    is_in_stock: bool
    url: str
    deep_link: Optional[str]
    image_url: Optional[str]
    barcode: Optional[str]
    raw_size_text: Optional[str]
    pack_count: int = 1
    branch_name: Optional[str] = None
    promo_conditions: Optional[str] = None
    price_verified: bool = False
    stock_known: bool = False
    source_url: Optional[str] = None
    fetched_at: Optional[datetime] = None

class BaseConnector(ABC):
    def __init__(self, store_code: str, store_name_ar: str, store_name_en: str):
        self.store_code = store_code
        self.store_name_ar = store_name_ar
        self.store_name_en = store_name_en
        self.is_enabled = True

    @abstractmethod
    async def search(self, query: str, district: Optional[str] = None) -> List[RawConnectorItem]:
        """Search products for a specific district in Al-Madinah Al-Munawwarah."""
        pass

    @abstractmethod
    def get_status(self) -> Tuple[ConnectorStatus, str]:
        """Returns the connector status and human-readable explanation in Arabic."""
        pass

    @abstractmethod
    def get_fees_info(self, district: Optional[str] = None) -> Dict[str, Optional[int]]:
        """Returns base delivery fee, service fee, and free threshold in Halalas."""
        pass
