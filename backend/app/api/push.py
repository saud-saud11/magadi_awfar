from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from app.database import get_db
from app.security import require_device
from app.config import settings
from app.models.models import PushSubscription, NotificationLog, PantryItem, Product
from app.schemas.pantry import (
    PushSubscriptionCreate, AlertPreferencesUpdate, NotificationLogOut
)
from app.services.web_push_service import web_push_service

router = APIRouter(prefix="/push", tags=["إشعارات Push والتنبيهات"], dependencies=[Depends(require_device)])

@router.post("/subscribe")
def register_push_subscription(data: PushSubscriptionCreate, db: Session = Depends(get_db)):
    """Register or update browser/device Web Push or FCM credentials."""
    if not web_push_service.configured:
        raise HTTPException(503, 'خدمة التنبيهات لم تُهيأ على الخادم بعد')
    if data.platform != 'web' or not web_push_service.valid_endpoint(data.endpoint) or not data.p256dh_key or not data.auth_key:
        raise HTTPException(422, 'اشتراك Web Push غير صالح')
    if data.daily_digest_enabled:
        raise HTTPException(422, 'الملخص اليومي غير متاح بعد')
    sub = db.query(PushSubscription).filter(PushSubscription.device_uuid == data.device_uuid).first()
    if sub:
        sub.platform = data.platform
        sub.endpoint = data.endpoint or sub.endpoint
        sub.p256dh_key = data.p256dh_key or sub.p256dh_key
        sub.auth_key = data.auth_key or sub.auth_key
        sub.fcm_token = data.fcm_token or sub.fcm_token
        sub.enable_quiet_hours = data.enable_quiet_hours
        sub.quiet_hours_start = data.quiet_hours_start
        sub.quiet_hours_end = data.quiet_hours_end
        sub.daily_digest_enabled = data.daily_digest_enabled
        sub.is_active = True
        sub.updated_at = datetime.utcnow()
    else:
        sub = PushSubscription(
            device_uuid=data.device_uuid,
            platform=data.platform,
            endpoint=data.endpoint,
            p256dh_key=data.p256dh_key,
            auth_key=data.auth_key,
            fcm_token=data.fcm_token,
            enable_quiet_hours=data.enable_quiet_hours,
            quiet_hours_start=data.quiet_hours_start,
            quiet_hours_end=data.quiet_hours_end,
            daily_digest_enabled=data.daily_digest_enabled,
            is_active=True
        )
        db.add(sub)
    db.commit()
    return {"status": "success", "message": "تم تسجيل اشتراك الإشعارات بنجاح"}

@router.get("/history", response_model=List[NotificationLogOut])
def get_notification_history(device_uuid: str = Query(...), db: Session = Depends(get_db)):
    """Retrieve full in-app notification history (accessible even if system Push was denied)."""
    logs = db.query(NotificationLog).filter(
        NotificationLog.device_uuid == device_uuid
    ).order_by(NotificationLog.sent_at.desc()).limit(50).all()

    return [
        NotificationLogOut(
            id=log.id,
            device_uuid=log.device_uuid,
            pantry_item_id=log.pantry_item_id,
            event_type=log.event_type,
            title=log.title,
            body=log.body,
            store_code=log.store_code,
            store_name_ar=log.store_name_ar,
            old_price_sar=round(log.old_price_halalas / 100.0, 2) if log.old_price_halalas else None,
            new_price_sar=round(log.new_price_halalas / 100.0, 2),
            savings_sar=round((log.old_price_halalas - log.new_price_halalas) / 100.0, 2) if (log.old_price_halalas and log.old_price_halalas > log.new_price_halalas) else None,
            deep_link=log.deep_link,
            sent_at=log.sent_at
        )
        for log in logs
    ]

@router.post("/test")
async def send_test_notification(device_uuid: str = Query(...), db: Session = Depends(get_db)):
    """Dispatches an instant test notification to verify device connectivity."""
    sub = db.query(PushSubscription).filter(PushSubscription.device_uuid == device_uuid).first()
    
    payload = web_push_service.format_notification_payload(
        title="🔔 تجربة تنبيهات مقاضي البيت",
        body="تم تفعيل إشعارات مقاضي أوفر بنجاح! ستصلك التنبيهات عند رصد انخفاض أثناء الفحص الدوري.",
        product_id=1,
        store_code="danube",
        store_name_ar="الدانوب",
        new_price_sar=18.50,
        old_price_sar=22.00,
        deep_link="/pantry"
    )

    if not sub or not sub.is_active:
        raise HTTPException(409, 'فعّل التنبيهات لهذا الجهاز أولًا')
    sent = await web_push_service.send_web_push({
        'endpoint': sub.endpoint, 'p256dh_key': sub.p256dh_key, 'auth_key': sub.auth_key,
    }, payload)
    if not sent: raise HTTPException(503, 'تعذر إرسال التنبيه؛ تحقق من إعدادات الخادم والاشتراك')
    return {'status': 'success', 'message': 'تم إرسال التنبيه إلى مزود الإشعارات'}

@router.get('/config')
def get_push_config(device_uuid: str = Depends(require_device), db: Session = Depends(get_db)):
    sub = db.query(PushSubscription).filter(PushSubscription.device_uuid == device_uuid).first()
    return {'enabled': web_push_service.configured,
            'registered': bool(sub and sub.is_active and sub.endpoint),
            'public_key': settings.VAPID_PUBLIC_KEY if web_push_service.configured else None}

@router.get("/preferences")
def get_alert_preferences(device_uuid: str = Query(...), db: Session = Depends(get_db)):
    """Fetch user's alert, quiet hours, and daily digest preferences."""
    sub = db.query(PushSubscription).filter(PushSubscription.device_uuid == device_uuid).first()
    if not sub:
        return {
            "device_uuid": device_uuid,
            "enable_quiet_hours": True,
            "quiet_hours_start": "23:00",
            "quiet_hours_end": "07:00",
            "daily_digest_enabled": False,
        }
    return {
        "device_uuid": device_uuid,
        "enable_quiet_hours": sub.enable_quiet_hours,
        "quiet_hours_start": sub.quiet_hours_start,
        "quiet_hours_end": sub.quiet_hours_end,
        "daily_digest_enabled": sub.daily_digest_enabled,
    }

@router.put("/preferences")
def update_alert_preferences(
    data: AlertPreferencesUpdate,
    device_uuid: str = Query(...),
    db: Session = Depends(get_db)
):
    """Update supported alert preferences."""
    if data.daily_digest_enabled:
        raise HTTPException(422, "الملخص اليومي غير متاح بعد")
    sub = db.query(PushSubscription).filter(PushSubscription.device_uuid == device_uuid).first()
    if not sub:
        sub = PushSubscription(
            device_uuid=device_uuid,
            enable_quiet_hours=data.enable_quiet_hours if data.enable_quiet_hours is not None else True,
            quiet_hours_start=data.quiet_hours_start or "23:00",
            quiet_hours_end=data.quiet_hours_end or "07:00",
            daily_digest_enabled=data.daily_digest_enabled if data.daily_digest_enabled is not None else False,
            is_active=True
        )
        db.add(sub)
    else:
        if data.enable_quiet_hours is not None:
            sub.enable_quiet_hours = data.enable_quiet_hours
        if data.quiet_hours_start:
            sub.quiet_hours_start = data.quiet_hours_start
        if data.quiet_hours_end:
            sub.quiet_hours_end = data.quiet_hours_end
        if data.daily_digest_enabled is not None:
            sub.daily_digest_enabled = data.daily_digest_enabled
        sub.updated_at = datetime.utcnow()
    db.commit()
    return {"status": "success", "message": "تم تحديث تفضيلات التنبيهات وساعات الهدوء بنجاح"}

@router.delete("/history")
def clear_notification_history(device_uuid: str = Query(...), db: Session = Depends(get_db)):
    """Clear in-app notification history logs for this device."""
    deleted_count = db.query(NotificationLog).filter(NotificationLog.device_uuid == device_uuid).delete()
    db.commit()
    return {"status": "success", "deleted_count": deleted_count, "message": "تم مسح سجل التنبيهات بنجاح"}

