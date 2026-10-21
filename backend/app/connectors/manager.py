import asyncio
from typing import List, Dict, Any, Optional
from app.connectors.base import BaseConnector, RawConnectorItem
from app.connectors.danube import DanubeConnector
from app.connectors.unavailable import UnavailableConnector

class ConnectorManager:
    def __init__(self):
        self.connectors = {'danube': DanubeConnector()}
        names = {'panda':'بنده', 'othaim':'أسواق العثيم', 'tamimi':'أسواق التميمي',
                 'noon_minutes':'نون منتس', 'amazon_sa':'أمازون السعودية', 'nahdi':'النهدي',
                 'dawaa':'الدواء', 'carrefour':'كارفور', 'lulu':'لولو', 'hungerstation':'هنقرستيشن',
                 'ninja':'نينجا', 'keeta':'كيتا', 'amazon_now':'أمازون ناو'}
        for code, name in names.items(): self.connectors[code] = UnavailableConnector(code, name, code)

    def get_connector(self, code: str) -> Optional[BaseConnector]:
        return self.connectors.get(code)

    def get_all_statuses(self) -> List[Dict[str, Any]]:
        statuses = []
        for code, conn in self.connectors.items():
            status, reason = conn.get_status()
            statuses.append({
                "code": code,
                "name_ar": conn.store_name_ar,
                "name_en": conn.store_name_en,
                "status": status.value,
                "status_text": reason,
                "is_enabled": conn.is_enabled
            })
        return statuses

    async def search_all(self, query: str, district: Optional[str] = None) -> List[RawConnectorItem]:
        """Query all enabled connectors concurrently + live real-time market scraper."""
        active_connectors = [c for c in self.connectors.values() if c.is_enabled]
        
        async def safe_search(connector: BaseConnector) -> List[RawConnectorItem]:
            try:
                return await connector.search(query, district)
            except Exception as e:
                print(f"[ConnectorManager] Error running {connector.store_code}: {e}")
                return []

        tasks = [safe_search(c) for c in active_connectors]

        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        all_items: List[RawConnectorItem] = []
        for res in results:
            if isinstance(res, list):
                all_items.extend(item for item in res if item.price_verified and item.fetched_at and item.price_halalas > 0)
                
        return all_items

connector_manager = ConnectorManager()
