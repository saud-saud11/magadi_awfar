import asyncio
import re
import html as html_lib
from typing import List, Optional, Dict
from urllib.parse import quote
import httpx
from app.connectors.base import RawConnectorItem

# In-memory search cache to ensure blazing fast response times
_SEARCH_CACHE: Dict[str, List[RawConnectorItem]] = {}

SELLER_MAP = {
    "othaim": ("othaim", "أسواق العثيم", "Othaim Markets"),
    "tamimi": ("tamimi", "أسواق التميمي", "Tamimi Markets"),
    "carrefour": ("carrefour", "كارفور", "Carrefour"),
    "panda": ("panda", "بنده", "Panda"),
    "danube": ("danube", "الدانوب", "Danube"),
    "lulu": ("lulu", "لولو هايبرماركت", "LuLu Hypermarket"),
    "amazon": ("amazon_sa", "أمازون السعودية", "Amazon SA"),
    "noon": ("noon_minutes", "نون مينتس", "Noon Minutes"),
}

async def fetch_live_market_items(query: str, district: Optional[str] = None) -> List[RawConnectorItem]:
    """
    Fetch real-time grocery prices across Saudi supermarkets for ANY query.
    Returns parsed RawConnectorItem objects with exact prices in Halalas.
    """
    q_clean = query.strip()
    if not q_clean:
        return []

    cache_key = q_clean.lower()
    if cache_key in _SEARCH_CACHE:
        return _SEARCH_CACHE[cache_key]

    url = f"https://supermarket.kanbkam.com/sa/ar/search/{quote(q_clean)}"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "ar,en;q=0.9",
        "Referer": "https://supermarket.kanbkam.com/sa/ar/",
    }

    raw_html = ""
    try:
        async with httpx.AsyncClient(timeout=8.0, follow_redirects=True) as client:
            resp = await client.get(url, headers=headers)
            if resp.status_code == 200:
                raw_html = resp.text
    except Exception as e:
        print(f"[LiveMarketScraper] HTTP fetch error for '{q_clean}': {e}")
        return []

    if not raw_html:
        return []

    cards = raw_html.split("thumbnail-new")
    items: List[RawConnectorItem] = []

    for card in cards[1:]:
        seller_m = re.search(r"sm-icon-seller\s+icon-([a-zA-Z0-9_-]+)", card)
        title_m = re.search(r"<h3>(.*?)</h3>", card, re.S)
        price_m = re.search(r"<p>\s*([0-9.]+)\s*<span>(?:ريال سعودي|SAR)", card)
        img_m = re.search(r'<img[^>]+src=["\']([^"\']+)["\']', card)
        link_m = re.search(r'href=["\']([^"\']+)["\']', card)
        old_price_m = re.search(r'class="old-price">\s*([0-9.]+)', card)

        if not (title_m and price_m):
            continue

        raw_seller = seller_m.group(1).lower() if seller_m else "othaim"
        seller_info = SELLER_MAP.get(raw_seller)
        if not seller_info:
            store_code = raw_seller
            store_name_ar = f"متجر {raw_seller}"
            store_name_en = raw_seller.capitalize()
        else:
            store_code, store_name_ar, store_name_en = seller_info

        # Clean title
        raw_title = re.sub(r"<[^>]+>", "", title_m.group(1)).strip()
        title_ar = html_lib.unescape(raw_title)

        try:
            price_sar = float(price_m.group(1))
            price_halalas = int(round(price_sar * 100))
        except (ValueError, TypeError):
            continue

        orig_halalas = None
        if old_price_m:
            try:
                orig_sar = float(old_price_m.group(1))
                orig_halalas = int(round(orig_sar * 100))
            except (ValueError, TypeError):
                orig_halalas = None

        img_url = img_m.group(1) if img_m else None
        if img_url and img_url.startswith("//"):
            img_url = "https:" + img_url

        prod_url = link_m.group(1) if link_m else ""
        if prod_url and prod_url.startswith("/"):
            prod_url = "https://supermarket.kanbkam.com" + prod_url

        # Extract size text if present
        size_match = re.search(r'(\d+(?:\.\d+)?)\s*(جرام|غرام|جم|كجم|كيلو|مل|لتر|قطع|قطعة|حبة|حبات)', title_ar)
        raw_size = size_match.group(0) if size_match else None

        # Extract pack count if multi-pack
        pack_count = 1
        pack_m = re.search(r'(\d+)\s*(?:حبة|قطعة|علبة|كيس|حبات|قطع|x|×)', title_ar)
        if pack_m:
            try:
                cnt = int(pack_m.group(1))
                if 2 <= cnt <= 100:
                    pack_count = cnt
            except ValueError:
                pass

        branch_label = "فرع المدينة المنورة"
        if district:
            branch_label = f"فرع المدينة المنورة ({district})"

        items.append(RawConnectorItem(
            store_code=store_code,
            store_name_ar=store_name_ar,
            title_ar=title_ar,
            title_en=None,
            brand_ar=None,
            brand_en=None,
            price_halalas=price_halalas,
            original_price_halalas=orig_halalas,
            is_in_stock=True,
            url=prod_url,
            deep_link=None,
            image_url=img_url,
            barcode=None,
            raw_size_text=raw_size,
            pack_count=pack_count,
            branch_name=branch_label,
            promo_conditions="عرض تخفيض حصري" if orig_halalas else None
        ))

    if len(_SEARCH_CACHE) > 100:
        _SEARCH_CACHE.clear()
    _SEARCH_CACHE[cache_key] = items

    return items
