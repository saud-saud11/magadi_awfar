import asyncio
import sys
import os

sys.path.insert(0, r"C:\Users\drsau\.gemini\antigravity\scratch\magadi_awfar\backend")
sys.stdout.reconfigure(encoding='utf-8')

from app.connectors.manager import connector_manager

async def test_baby():
    items = await connector_manager.search_all("سيميلاك", "سلطانة")
    stores = set(it.store_code for it in items)
    print(f"\nQuery 'سيميلاك': {len(items)} items from stores: {stores}")

asyncio.run(test_baby())
