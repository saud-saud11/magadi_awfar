import asyncio
import sys
import os

sys.path.insert(0, r"C:\Users\drsau\.gemini\antigravity\scratch\magadi_awfar\backend")
sys.stdout.reconfigure(encoding='utf-8')

from app.connectors.manager import connector_manager
from app.services.matcher import strict_matcher

async def debug_search():
    query = "نوتيلا"
    district = "سلطانة"
    parsed = strict_matcher.parse_query(query)
    print(f"Parsed query: brand={parsed.brand}, amount={parsed.target_amount}, unit={parsed.target_unit}")
    
    items = await connector_manager.search_all(query, district)
    print(f"\nTotal raw items fetched: {len(items)}")
    
    # Store breakdown
    stores = {}
    for it in items:
        stores[it.store_code] = stores.get(it.store_code, 0) + 1
    print(f"Items per store: {stores}")
    
    print("\n--- Items details ---")
    grouped = {}
    for it in items:
        amount, unit, pack = strict_matcher.parse_size_and_unit(f"{it.title_ar} {it.raw_size_text or ''}")
        brand = it.brand_ar or parsed.brand or "عام"
        key = f"{brand}_{amount}_{unit}_{pack}"
        
        if key not in grouped:
            grouped[key] = []
        grouped[key].append((it.store_code, it.title_ar, it.price_halalas, it.raw_size_text, amount, unit))
        
    print(f"\nTotal distinct product groups: {len(grouped)}")
    for k, v in grouped.items():
        print(f"\nGroup [{k}] -> {len(v)} offers from stores: {[x[0] for x in v]}")
        for x in v:
            print(f"   * {x[0]}: '{x[1]}' (raw_size: '{x[3]}', amount: {x[4]} {x[5]}, price: {x[2]/100} SAR)")

asyncio.run(debug_search())
