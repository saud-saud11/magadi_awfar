import json
import logging
import asyncio
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime, time
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models.models import (
    PantryItem, Product, StoreOffer, Store, District,
    PushSubscription, NotificationLog
)
from app.connectors.manager import connector_manager
from app.services.matcher import strict_matcher
from app.services.web_push_service import web_push_service

logger = logging.getLogger("price_monitor")

STORE_NAMES = {
    "danube": "الدانوب",
    "panda": "بنده",
    "othaim": "أسواق العثيم",
    "tamimi": "أسواق التميمي",
    "noon_minutes": "نون منتس",
    "amazon_sa": "أمازون السعودية",
    "nahdi": "صيدلية النهدي",
    "dawaa": "صيدلية الدواء",
    "carrefour": "كارفور السعودية",
}

class PriceMonitorService:
    def __init__(self):
        self.is_running = False
        self._interval_minutes = 30
        self._last_run_at: Optional[datetime] = None
        self._last_stats: Dict[str, Any] = {
            "items_checked": 0,
            "alerts_generated": 0,
            "dedup_skipped": 0,
            "status": "idle"
        }

    def get_monitoring_status(self) -> Dict[str, Any]:
        return {
            "is_active": self.is_running,
            "interval_minutes": self._interval_minutes,
            "last_run_at": self._last_run_at,
            "stats": self._last_stats
        }

    def is_in_quiet_hours(self, sub: PushSubscription) -> bool:
        """Check if current time in Saudi Arabia (UTC+3) falls in user quiet hours."""
        if not sub.enable_quiet_hours:
            return False
        try:
            now_hour = (datetime.utcnow().hour + 3) % 24
            now_minute = datetime.utcnow().minute
            now_t = time(now_hour, now_minute)

            start_h, start_m = map(int, sub.quiet_hours_start.split(":"))
            end_h, end_m = map(int, sub.quiet_hours_end.split(":"))
            start_t = time(start_h, start_m)
            end_t = time(end_h, end_m)

            if start_t > end_t:
                # Spans midnight, e.g. 23:00 to 07:00
                return now_t >= start_t or now_t < end_t
            else:
                return start_t <= now_t < end_t
        except Exception:
            return False

    async def run_single_monitoring_cycle(self, db: Session) -> Dict[str, Any]:
        """
        Executes one full deduplicated monitoring cycle across all active pantry items.
        Safe, idempotent, and records price changes accurately.
        """
        self._last_run_at = datetime.utcnow()
        active_items = db.query(PantryItem).filter(PantryItem.is_alert_enabled == True).all()

        if not active_items:
            self._last_stats = {
                "items_checked": 0,
                "alerts_generated": 0,
                "dedup_skipped": 0,
                "status": "active - 0 subscribers"
            }
            return self._last_stats

        # 1. Deduplicate product queries: group by (product_id, district_name)
        product_district_groups: Dict[Tuple[int, str], List[PantryItem]] = {}
        for item in active_items:
            dist_name = item.district.name_ar if item.district else "سلطانة"
            key = (item.product_id, dist_name)
            if key not in product_district_groups:
                product_district_groups[key] = []
            product_district_groups[key].append(item)

        total_alerts = 0
        total_skipped = 0

        for (prod_id, dist_name), subscribers in product_district_groups.items():
            product = db.query(Product).filter(Product.id == prod_id).first()
            if not product:
                continue

            # Query store connectors once for this product in this district
            query_term = f"{product.brand_ar or ''} {product.name_ar}".strip()
            raw_items = await connector_manager.search_all(query_term, dist_name)

            # Filter with strict matching: must strictly match this exact product, size, and pack
            valid_offers: List[Dict[str, Any]] = []
            for raw in raw_items:
                # Source failure guard: price must be valid positive integer
                if not raw.price_halalas or raw.price_halalas <= 0:
                    continue

                # Verify strict size and pack count match
                amount, unit, pack = strict_matcher.parse_size_and_unit(f"{raw.title_ar} {raw.raw_size_text or ''}")
                
                # Rule: Smaller pack is NEVER considered a price drop for a larger item
                if product.pack_count > 1 and pack != product.pack_count:
                    continue
                if product.normalized_size_amount and amount:
                    if abs(amount - product.normalized_size_amount) > (product.normalized_size_amount * 0.15):
                        continue

                # Check relevance
                if not strict_matcher.is_relevant_match(product.name_ar, raw.title_ar, raw.brand_ar):
                    continue

                valid_offers.append({
                    "store_code": raw.store_code,
                    "store_name_ar": STORE_NAMES.get(raw.store_code, raw.store_name_ar),
                    "price_halalas": raw.price_halalas,
                    "original_price_halalas": raw.original_price_halalas,
                    "is_on_sale": bool(raw.original_price_halalas and raw.original_price_halalas > raw.price_halalas),
                    "url": raw.url,
                    "promo_conditions": raw.promo_conditions
                })

            if not valid_offers:
                # Source unavailable or no valid price found: NEVER treat as zero!
                continue

            # Sort valid offers by price ascending
            valid_offers.sort(key=lambda o: o["price_halalas"])
            best_offer = valid_offers[0]
            best_price = best_offer["price_halalas"]
            best_store = best_offer["store_code"]

            # 2. Process each subscriber for this product
            for item in subscribers:
                # Allowed stores filter
                allowed_stores = json.loads(item.specific_store_codes) if item.specific_store_codes else None
                if allowed_stores and best_store not in allowed_stores:
                    # Find best within allowed stores
                    filtered = [o for o in valid_offers if o["store_code"] in allowed_stores]
                    if not filtered:
                        continue
                    current_best = filtered[0]
                else:
                    current_best = best_offer

                curr_price = current_best["price_halalas"]
                curr_store = current_best["store_code"]
                curr_store_name = current_best["store_name_ar"]

                # Compare against baseline and previous reading
                prev_price = item.last_lowest_price_halalas
                prev_store = item.last_lowest_store_code
                baseline = item.baseline_price_halalas

                # Evaluate if alert conditions are met
                should_alert = False
                event_type = "price_drop"
                title = ""
                body = ""

                # Target price check
                if item.target_price_halalas and curr_price <= item.target_price_halalas:
                    should_alert = True
                    event_type = "target_reached"
                    title = f"🎯 وصل السعر المستهدف: {product.name_ar}"
                    body = f"أصبح متوفراً بسعر {curr_price/100:.2f} ر.س لدى {curr_store_name} (هدفك كان {item.target_price_halalas/100:.2f} ر.س)."

                # Percentage drop check
                elif item.target_discount_percent and baseline > 0:
                    pct_drop = ((baseline - curr_price) / baseline) * 100
                    if pct_drop >= item.target_discount_percent and curr_price < prev_price:
                        should_alert = True
                        event_type = "discount_reached"
                        title = f"🏷️ خصم {pct_drop:.0f}% على {product.name_ar}"
                        body = f"انخفض السعر إلى {curr_price/100:.2f} ر.س لدى {curr_store_name} (السابق {baseline/100:.2f} ر.س)."

                # Standard price drop or cheaper competitor
                elif curr_price < prev_price and prev_price > 0:
                    should_alert = True
                    diff_sar = (prev_price - curr_price) / 100.0

                    if curr_store == prev_store:
                        # Same store dropped price
                        event_type = "store_drop"
                        title = f"📉 انخفاض سعر {product.name_ar}"
                        body = f"انخفض السعر لدى {curr_store_name} من {prev_price/100:.2f} إلى {curr_price/100:.2f} ر.س (توفير {diff_sar:.2f} ر.س)."
                    else:
                        # Found cheaper at another store
                        prev_store_name = STORE_NAMES.get(prev_store, prev_store)
                        event_type = "competitor_cheaper"
                        title = f"✨ سعر أرخص لدى {curr_store_name}"
                        body = f"وجدنا {product.name_ar} بسعر {curr_price/100:.2f} ر.س لدى {curr_store_name} (أقل من {prev_store_name} بـ {diff_sar:.2f} ر.س)."

                # Verified new promotional offer
                elif current_best["is_on_sale"] and curr_price < baseline:
                    should_alert = True
                    event_type = "promo_offer"
                    title = f"🔥 عرض ترويجي موثق: {product.name_ar}"
                    promo_cond = current_best.get("promo_conditions") or ""
                    cond_str = f" ({promo_cond})" if promo_cond else ""
                    body = f"عرض خاص لدى {curr_store_name} بسعر {curr_price/100:.2f} ر.س{cond_str}."

                # Update latest recorded snapshot on pantry item
                item.last_lowest_price_halalas = curr_price
                item.last_lowest_store_code = curr_store
                item.last_checked_at = datetime.utcnow()
                db.commit()

                if not should_alert:
                    continue

                # 3. Idempotency Key check: prevents sending duplicate alerts in subsequent checks
                idempotency_key = f"{item.device_uuid}_{item.id}_{curr_store}_{curr_price}_{event_type}"
                existing_log = db.query(NotificationLog).filter(
                    NotificationLog.idempotency_key == idempotency_key
                ).first()

                if existing_log:
                    total_skipped += 1
                    continue

                # 4. Check user subscription and quiet hours
                sub = db.query(PushSubscription).filter(
                    PushSubscription.device_uuid == item.device_uuid,
                    PushSubscription.is_active == True
                ).first()

                is_quiet = False
                if sub and self.is_in_quiet_hours(sub):
                    is_quiet = True

                # Record in notification logs regardless of push permissions (in-app history)
                notif_log = NotificationLog(
                    device_uuid=item.device_uuid,
                    pantry_item_id=item.id,
                    idempotency_key=idempotency_key,
                    event_type=event_type,
                    title=title,
                    body=body,
                    store_code=curr_store,
                    store_name_ar=curr_store_name,
                    old_price_halalas=prev_price if prev_price > 0 else None,
                    new_price_halalas=curr_price,
                    deep_link=f"/product/{product.id}?offer={curr_store}",
                    is_sent=not is_quiet
                )
                db.add(notif_log)
                db.commit()

                # Dispatch Web Push if not in quiet hours
                if sub and not is_quiet:
                    payload = web_push_service.format_notification_payload(
                        title=title,
                        body=body,
                        product_id=product.id,
                        store_code=curr_store,
                        store_name_ar=curr_store_name,
                        new_price_sar=curr_price / 100.0,
                        old_price_sar=(prev_price / 100.0) if prev_price > 0 else None,
                        deep_link=notif_log.deep_link,
                        image_url=product.image_url
                    )
                    sub_dict = {
                        "endpoint": sub.endpoint,
                        "p256dh_key": sub.p256dh_key,
                        "auth_key": sub.auth_key,
                        "device_uuid": sub.device_uuid
                    }
                    asyncio.create_task(web_push_service.send_web_push(sub_dict, payload))

                total_alerts += 1

        self._last_stats = {
            "items_checked": len(active_items),
            "alerts_generated": total_alerts,
            "dedup_skipped": total_skipped,
            "status": "active"
        }
        return self._last_stats

    async def start_background_loop(self):
        """Continuous background task running on the server."""
        self.is_running = True
        logger.info("[PriceMonitor] Background monitoring loop started.")
        while self.is_running:
            try:
                db = SessionLocal()
                try:
                    await self.run_single_monitoring_cycle(db)
                finally:
                    db.close()
            except Exception as e:
                logger.error(f"[PriceMonitor] Error during cycle: {e}")
            await asyncio.sleep(self._interval_minutes * 60)

    def stop_background_loop(self):
        self.is_running = False

price_monitor_service = PriceMonitorService()
