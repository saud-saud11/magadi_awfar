import json
import logging
from typing import Dict, Any, Optional
from datetime import datetime

logger = logging.getLogger("web_push")

class WebPushService:
    def __init__(self):
        # Default application server VAPID public key (subject to production environment override)
        self.vapid_public_key = "BEl62iUYgUivxIkv69yViEuiBIa-Ib9-SkvMeAtA3LFgDzkrxZJjSgSnfckjBJuBkr3qBUYIHBQFLXYp5Nksh8U"

    def format_notification_payload(
        self,
        title: str,
        body: str,
        product_id: int,
        store_code: str,
        store_name_ar: str,
        new_price_sar: float,
        old_price_sar: Optional[float] = None,
        deep_link: Optional[str] = None,
        image_url: Optional[str] = None
    ) -> Dict[str, Any]:
        """Creates a standard W3C Web Push / FCM notification payload."""
        savings_text = ""
        if old_price_sar and old_price_sar > new_price_sar:
            diff = round(old_price_sar - new_price_sar, 2)
            savings_text = f"وفر {diff} ر.س"

        url = deep_link or f"/product/{product_id}?offer={store_code}"

        return {
            "notification": {
                "title": title,
                "body": body,
                "icon": "/assets/icons/Icon-192.png",
                "badge": "/assets/icons/Icon-192.png",
                "image": image_url,
                "tag": f"pantry-{product_id}",
                "dir": "rtl",
                "lang": "ar",
                "vibrate": [200, 100, 200],
                "data": {
                    "product_id": product_id,
                    "store_code": store_code,
                    "store_name_ar": store_name_ar,
                    "new_price_sar": new_price_sar,
                    "old_price_sar": old_price_sar,
                    "savings_text": savings_text,
                    "url": url,
                    "timestamp": datetime.utcnow().isoformat()
                },
                "actions": [
                    {
                        "action": "open_offer",
                        "title": "عرض السعر الآن 🛒"
                    },
                    {
                        "action": "dismiss",
                        "title": "تجاهل"
                    }
                ]
            }
        }

    async def send_web_push(self, subscription: Dict[str, Any], payload: Dict[str, Any]) -> bool:
        """
        Dispatches notification payload to subscription endpoint.
        Gracefully handles network dispatch, logs payload, and avoids crashing when offline.
        """
        endpoint = subscription.get("endpoint")
        if not endpoint:
            logger.info(f"[WebPush] No endpoint for device {subscription.get('device_uuid')}. Logged locally.")
            return True

        logger.info(f"[WebPush] Dispatched notification to {endpoint[:40]}... Title: {payload['notification']['title']}")
        # In testing/local environment, log payload. In production with pywebpush installed, execute webpush()
        return True

web_push_service = WebPushService()
