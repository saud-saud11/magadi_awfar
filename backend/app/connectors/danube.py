import re
from datetime import datetime
from urllib.parse import urljoin, urlparse
import httpx
from typing import List, Optional, Tuple, Dict
from app.connectors.base import BaseConnector, ConnectorStatus, RawConnectorItem

class DanubeConnector(BaseConnector):
    def __init__(self):
        super().__init__("danube", "الدانوب", "Danube")
        self.last_ok = False
        self.app_id = "1D2IEWLQAD"
        self.api_key = "87ca3b6b2ce56f0bb76fc194a8d170e2"
        self.index_name = "spree_products"
        self.endpoint = f"https://{self.app_id}-dsn.algolia.net/1/indexes/{self.index_name}/query"

    def get_status(self) -> Tuple[ConnectorStatus, str]:
        return (
            ConnectorStatus.CONNECTED if self.last_ok else ConnectorStatus.UNDER_INVESTIGATION,
            "آخر طلب لمصدر المتجر نجح؛ تغطية الحي والرسوم غير مؤكدة" if self.last_ok else "بانتظار اتصال ناجح بمصدر المتجر"
        )

    def get_fees_info(self, district: Optional[str] = None) -> Dict[str, Optional[int]]:
        return dict(base_delivery_fee_halalas=None, free_delivery_threshold_halalas=None,
                    min_order_halalas=None, service_fee_halalas=None)

    async def search(self, query: str, district: Optional[str] = None) -> List[RawConnectorItem]:
        headers = {
            "X-Algolia-Application-Id": self.app_id,
            "X-Algolia-API-Key": self.api_key,
            "Content-Type": "application/json; charset=UTF-8",
            "User-Agent": "MagadiAwfar/1.0 (Madinah Price Checker)"
        }
        payload = {
            "query": query, "hitsPerPage": 30, "filters": "tenant_id = 1"
        }

        self.last_ok = False
        items: List[RawConnectorItem] = []
        try:
            async with httpx.AsyncClient(timeout=8.0) as client:
                res = await client.post(self.endpoint, json=payload, headers=headers)
                if res.status_code == 200:
                    self.last_ok = True
                    data = res.json()
                    for hit in data.get("hits", []):
                        price_num = hit.get("price")
                        if price_num is None:
                            continue
                        
                        price_halalas = int(round(float(price_num) * 100))
                        if price_halalas <= 0:
                            continue
                        orig_price_num = hit.get("original_price")
                        orig_halalas = int(round(float(orig_price_num) * 100)) if orig_price_num else None

                        title_ar = hit.get("full_name_ar") or hit.get("name_ar") or ""
                        title_en = hit.get("full_name_en") or hit.get("name_en")
                        brand_ar = hit.get("brand_ar")
                        if not brand_ar and "نوتيلا" in title_ar:
                            brand_ar = "نوتيلا"
                        if brand_ar and brand_ar not in title_ar:
                            title_ar = f"{brand_ar} {title_ar}"
                        brand_en = hit.get("brand_en")

                        # Product URL
                        url_path = hit.get("url_ar") or hit.get("url_en") or ""
                        full_url = urljoin("https://danube.sa", url_path) if url_path else "https://danube.sa"
                        if urlparse(full_url).scheme != 'https' or urlparse(full_url).hostname != 'danube.sa':
                            full_url = 'https://danube.sa'
                        deep_link = None

                        # Extract EAN Barcode from image or SKU if available
                        img = hit.get("image") or ""
                        barcode = None
                        barcode_match = re.search(r'/(\d{8,14})[-.]', img)
                        if barcode_match:
                            barcode = barcode_match.group(1)
                        barcode = str(hit.get('barcode') or hit.get('ean') or barcode or '')
                        from app.services.verified_offers import valid_barcode
                        if not valid_barcode(barcode): barcode = None

                        items.append(RawConnectorItem(
                            store_code=self.store_code,
                            store_name_ar=self.store_name_ar,
                            title_ar=title_ar,
                            title_en=title_en,
                            brand_ar=brand_ar,
                            brand_en=brand_en,
                            price_halalas=price_halalas,
                            original_price_halalas=orig_halalas,
                            is_in_stock=hit.get("in_stock") is True,
                            stock_known=isinstance(hit.get("in_stock"), bool),
                            price_verified=True, source_url=full_url, fetched_at=datetime.utcnow(),
                            url=full_url,
                            deep_link=deep_link,
                            image_url=img,
                            barcode=barcode,
                            raw_size_text=hit.get("weight") or hit.get("unit_of_measurement"),
                            pack_count=1,
                            branch_name="كتالوج المتجر الإلكتروني؛ تغطية الحي غير مؤكدة",
                            promo_conditions="خصم مباشر" if orig_halalas and orig_halalas > price_halalas else None
                        ))
        except Exception as e:
            print(f"[DanubeConnector Error]: {e}")

        return items
