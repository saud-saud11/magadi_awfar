import asyncio
from typing import List, Dict, Any, Optional
from app.connectors.base import BaseConnector, RawConnectorItem
from app.connectors.danube import DanubeConnector
from app.connectors.panda import PandaConnector
from app.connectors.othaim import OthaimConnector
from app.connectors.carrefour import CarrefourConnector
from app.connectors.tamimi import TamimiConnector
from app.connectors.noon_minutes import NoonMinutesConnector
from app.connectors.pharmacies import NahdiConnector, DawaaConnector
from app.connectors.amazon_standard import AmazonStandardConnector
from app.connectors.delivery_apps import (
    HungerstationConnector, NinjaConnector, KeetaConnector, AmazonNowConnector
)

from app.connectors.live_market_scraper import fetch_live_market_items

class ConnectorManager:
    def __init__(self):
        self.connectors: Dict[str, BaseConnector] = {
            "danube": DanubeConnector(),
            "panda": PandaConnector(),
            "othaim": OthaimConnector(),
            "tamimi": TamimiConnector(),
            "noon_minutes": NoonMinutesConnector(),
            "amazon_sa": AmazonStandardConnector(),
            "nahdi": NahdiConnector(),
            "dawaa": DawaaConnector(),
            "carrefour": CarrefourConnector(),
            "hungerstation": HungerstationConnector(),
            "ninja": NinjaConnector(),
            "keeta": KeetaConnector(),
            "amazon_now": AmazonNowConnector(),
        }

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

        async def safe_live_scraper() -> List[RawConnectorItem]:
            try:
                return await fetch_live_market_items(query, district)
            except Exception as e:
                print(f"[ConnectorManager] Error running live_market_scraper: {e}")
                return []

        tasks = [safe_search(c) for c in active_connectors]
        tasks.append(safe_live_scraper())

        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        all_items: List[RawConnectorItem] = []
        for res in results:
            if isinstance(res, list):
                all_items.extend(res)
                
        return all_items

connector_manager = ConnectorManager()
