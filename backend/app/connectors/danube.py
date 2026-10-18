import re
import httpx
from typing import List, Optional, Tuple, Dict
from app.connectors.base import BaseConnector, ConnectorStatus, RawConnectorItem

class DanubeConnector(BaseConnector):
    def __init__(self):
        super().__init__("danube", "الدانوب", "Danube")
        self.app_id = "1D2IEWLQAD"
        self.api_key = "87ca3b6b2ce56f0bb76fc194a8d170e2"
        self.index_name = "spree_products"
        self.endpoint = f"https://{self.app_id}-dsn.algolia.net/1/indexes/{self.index_name}/query"

    def get_status(self) -> Tuple[ConnectorStatus, str]:
        return (
            ConnectorStatus.CONNECTED,
            "متصل بالواجهة المباشرة (Algolia InstantSearch) - تحديث حي للأسعار والتوافر"
        )

    def get_fees_info(self, district: Optional[str] = None) -> Dict[str, Optional[int]]:
        # In Halalas: 15 SAR delivery, free on >= 150 SAR
        return {
            "base_delivery_fee_halalas": 1500,
            "free_delivery_threshold_halalas": 15000,
            "min_order_halalas": 5000,
            "service_fee_halalas": 0
        }

    async def search(self, query: str, district: Optional[str] = None) -> List[RawConnectorItem]:
        headers = {
            "X-Algolia-Application-Id": self.app_id,
            "X-Algolia-API-Key": self.api_key,
            "Content-Type": "application/json; charset=UTF-8",
            "User-Agent": "MagadiAwfar/1.0 (Madinah Price Checker)"
        }
        payload = {
            "params": f"query={query}&hitsPerPage=15&filters=tenant_id = 1"
        }

        items: List[RawConnectorItem] = []
        try:
            async with httpx.AsyncClient(timeout=8.0) as client:
                res = await client.post(self.endpoint, json=payload, headers=headers)
                if res.status_code == 200:
                    data = res.json()
                    for hit in data.get("hits", []):
                        price_num = hit.get("price")
                        if price_num is None:
                            continue
                        
                        price_halalas = int(round(float(price_num) * 100))
                        orig_price_num = hit.get("original_price")
                        orig_halalas = int(round(float(orig_price_num) * 100)) if orig_price_num else None

                        title_ar = hit.get("full_name_ar") or hit.get("name_ar") or ""
                        title_en = hit.get("full_name_en") or hit.get("name_en")
                        brand_ar = hit.get("brand_ar") or "نوتيلا" if "نوتيلا" in title_ar else None
                        brand_en = hit.get("brand_en")

                        # Product URL
                        url_path = hit.get("url_ar") or hit.get("url_en") or ""
                        full_url = f"https://danube.sa{url_path}" if url_path else "https://danube.sa"
                        deep_link = f"danube://product/{hit.get('master_id') or hit.get('objectID')}"

                        # Extract EAN Barcode from image or SKU if available
                        img = hit.get("image") or ""
                        barcode = None
                        barcode_match = re.search(r'/(\d{8,14})[-.]', img)
                        if barcode_match:
                            barcode = barcode_match.group(1)

                        items.append(RawConnectorItem(
                            store_code=self.store_code,
                            store_name_ar=self.store_name_ar,
                            title_ar=title_ar,
                            title_en=title_en,
                            brand_ar=brand_ar,
                            brand_en=brand_en,
                            price_halalas=price_halalas,
                            original_price_halalas=orig_halalas,
                            is_in_stock=bool(hit.get("in_stock", True)),
                            url=full_url,
                            deep_link=deep_link,
                            image_url=img,
                            barcode=barcode,
                            raw_size_text=hit.get("weight") or hit.get("unit_of_measurement"),
                            pack_count=1,
                            branch_name="فرع محطة قطار الحرمين (المدينة المنورة)",
                            promo_conditions="خصم مباشر" if orig_halalas and orig_halalas > price_halalas else None
                        ))
        except Exception as e:
            print(f"[DanubeConnector Error]: {e}")

        return items
