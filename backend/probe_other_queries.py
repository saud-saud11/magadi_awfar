import asyncio
import sys
import os

sys.path.insert(0, r"C:\Users\drsau\.gemini\antigravity\scratch\magadi_awfar\backend")
sys.stdout.reconfigure(encoding='utf-8')

from app.connectors.manager import connector_manager

queries = ["حليب المراعي", "أرز الشعلان", "زيت عافية", "شاي ليبتون", "بيض", "سكر"]

async def test_queries():
    for q in queries:
        items = await connector_manager.search_all(q, "سلطانة")
        stores = set(it.store_code for it in items)
        print(f"\nQuery '{q}': {len(items)} items from stores: {stores}")

asyncio.run(test_queries())
