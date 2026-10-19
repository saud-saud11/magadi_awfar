import json
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from app.database import get_db
from app.models.models import PantryItem, Product, StoreOffer, District
from app.schemas.pantry import (
    PantryItemCreate, PantryItemUpdate, PantryItemOut, PantrySummaryOut
)
from app.services.price_monitor_service import price_monitor_service, STORE_NAMES

router = APIRouter(prefix="/pantry", tags=["مقاضي البيت - Watchlist & Price Tracking"])

def _build_pantry_out(item: PantryItem, db: Session) -> PantryItemOut:
    product = item.product
    
    # Calculate savings compared to baseline
    baseline_sar = round(item.baseline_price_halalas / 100.0, 2)
    current_sar = round(item.last_lowest_price_halalas / 100.0, 2)
    diff = round(baseline_sar - current_sar, 2)
    savings_amount = diff if diff > 0 else 0.0
    savings_pct = round((diff / baseline_sar) * 100, 1) if (diff > 0 and baseline_sar > 0) else 0.0
    
    # Check if there is an active sale offer
    best_offer = db.query(StoreOffer).filter(
        StoreOffer.product_id == product.id,
        StoreOffer.store.has(code=item.last_lowest_store_code)
    ).first()
    is_on_sale = best_offer.is_on_sale if best_offer else False

    store_name_ar = STORE_NAMES.get(item.last_lowest_store_code, item.last_lowest_store_code)
    specific_stores = json.loads(item.specific_store_codes) if item.specific_store_codes else None

    # Pack label
    if product.pack_count > 1:
        pack_label = f"حزمة ({product.pack_count} حبات)"
    else:
        pack_label = "بالحبّة (مفرد)"

    return PantryItemOut(
        id=item.id,
        device_uuid=item.device_uuid,
        product_id=product.id,
        product_name_ar=product.name_ar,
        product_name_en=product.name_en,
        brand_ar=product.brand_ar,
        image_url=product.image_url,
        normalized_size_amount=product.normalized_size_amount,
        normalized_size_unit=product.normalized_size_unit,
        pack_count=product.pack_count,
        pack_label_ar=pack_label,
        usual_quantity=item.usual_quantity,
        baseline_price_sar=baseline_sar,
        baseline_store_code=item.baseline_store_code,
        current_lowest_price_sar=current_sar,
        current_lowest_store_code=item.last_lowest_store_code,
        current_lowest_store_name_ar=store_name_ar,
        savings_amount_sar=savings_amount,
        savings_percent=savings_pct,
        is_price_dropped=savings_amount > 0,
        is_on_sale=is_on_sale,
        target_price_sar=round(item.target_price_halalas / 100.0, 2) if item.target_price_halalas else None,
        target_discount_percent=item.target_discount_percent,
        specific_store_codes=specific_stores,
        is_alert_enabled=item.is_alert_enabled,
        track_landed_total=item.track_landed_total,
        last_checked_at=item.last_checked_at,
        created_at=item.created_at
    )

@router.get("", response_model=PantrySummaryOut)
def get_pantry_items(device_uuid: str = Query(..., description="Device UUID"), db: Session = Depends(get_db)):
    """Retrieve full persistent watchlist for a user device."""
    items = db.query(PantryItem).filter(PantryItem.device_uuid == device_uuid).all()
    
    out_items = [_build_pantry_out(i, db) for i in items]
    
    total_est = sum(i.current_lowest_price_sar * i.usual_quantity for i in out_items)
    total_savings = sum(i.savings_amount_sar * i.usual_quantity for i in out_items)
    active_alerts = sum(1 for i in out_items if i.is_alert_enabled)

    status_info = price_monitor_service.get_monitoring_status()

    return PantrySummaryOut(
        device_uuid=device_uuid,
        items_count=len(out_items),
        active_alerts_count=active_alerts,
        total_estimated_monthly_sar=round(total_est, 2),
        total_potential_savings_sar=round(total_savings, 2),
        monitoring_status=f"مراقبة نشطة على الخادم (كل {status_info['interval_minutes']} دقيقة)",
        items=out_items
    )

@router.post("", response_model=PantryItemOut)
def add_pantry_item(data: PantryItemCreate, db: Session = Depends(get_db)):
    """Add a product to pantry watchlist with baseline price registration."""
    product = db.query(Product).filter(Product.id == data.product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="المنتج غير موجود في الكتالوج")

    # Check if already in user's pantry
    existing = db.query(PantryItem).filter(
        PantryItem.device_uuid == data.device_uuid,
        PantryItem.product_id == data.product_id
    ).first()

    # Determine initial lowest confirmed price as baseline
    lowest_offer = db.query(StoreOffer).filter(
        StoreOffer.product_id == product.id,
        StoreOffer.price_halalas > 0
    ).order_by(StoreOffer.price_halalas.asc()).first()

    baseline_price = lowest_offer.price_halalas if lowest_offer else 2500
    baseline_store = lowest_offer.store.code if lowest_offer else "othaim"

    district = db.query(District).filter(District.name_ar == data.district_name).first() if data.district_name else None

    target_halalas = int(round(data.target_price_sar * 100)) if data.target_price_sar else None
    stores_json = json.dumps(data.specific_store_codes) if data.specific_store_codes else None

    if existing:
        existing.usual_quantity = data.usual_quantity
        existing.target_price_halalas = target_halalas
        existing.target_discount_percent = data.target_discount_percent
        existing.specific_store_codes = stores_json
        existing.is_alert_enabled = data.is_alert_enabled
        existing.track_landed_total = data.track_landed_total
        db.commit()
        db.refresh(existing)
        return _build_pantry_out(existing, db)

    item = PantryItem(
        device_uuid=data.device_uuid,
        product_id=data.product_id,
        district_id=district.id if district else None,
        usual_quantity=data.usual_quantity,
        baseline_price_halalas=baseline_price,
        baseline_store_code=baseline_store,
        target_price_halalas=target_halalas,
        target_discount_percent=data.target_discount_percent,
        specific_store_codes=stores_json,
        is_alert_enabled=data.is_alert_enabled,
        track_landed_total=data.track_landed_total,
        last_lowest_price_halalas=baseline_price,
        last_lowest_store_code=baseline_store,
        last_checked_at=datetime.utcnow()
    )
    db.add(item)
    db.commit()
    db.refresh(item)

    return _build_pantry_out(item, db)

@router.put("/{item_id}", response_model=PantryItemOut)
def update_pantry_item(item_id: int, data: PantryItemUpdate, db: Session = Depends(get_db)):
    """Update settings or quantity for a tracked pantry item."""
    item = db.query(PantryItem).filter(PantryItem.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="الصنف غير موجود في مقاضي البيت")

    if data.usual_quantity is not None:
        item.usual_quantity = data.usual_quantity
    if data.target_price_sar is not None:
        item.target_price_halalas = int(round(data.target_price_sar * 100))
    if data.target_discount_percent is not None:
        item.target_discount_percent = data.target_discount_percent
    if data.specific_store_codes is not None:
        item.specific_store_codes = json.dumps(data.specific_store_codes)
    if data.is_alert_enabled is not None:
        item.is_alert_enabled = data.is_alert_enabled
    if data.track_landed_total is not None:
        item.track_landed_total = data.track_landed_total

    db.commit()
    db.refresh(item)
    return _build_pantry_out(item, db)

@router.delete("/{item_id}")
def delete_pantry_item(item_id: int, db: Session = Depends(get_db)):
    """Remove item from watchlist."""
    item = db.query(PantryItem).filter(PantryItem.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="الصنف غير موجود")
    db.delete(item)
    db.commit()
    return {"status": "success", "message": "تم حذف الصنف من مقاضي البيت بنجاح"}

@router.post("/{item_id}/toggle-alert")
def toggle_item_alert(item_id: int, db: Session = Depends(get_db)):
    """Toggle alerts on/off for a single item."""
    item = db.query(PantryItem).filter(PantryItem.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="الصنف غير موجود")
    item.is_alert_enabled = not item.is_alert_enabled
    db.commit()
    state_str = "مفعلة" if item.is_alert_enabled else "معطلة مؤقتاً"
    return {"status": "success", "is_alert_enabled": item.is_alert_enabled, "message": f"تنبيهات الصنف أصبحت {state_str}"}

@router.post("/toggle-all")
def toggle_all_alerts(device_uuid: str = Query(...), enabled: bool = Query(...), db: Session = Depends(get_db)):
    """Enable or disable all alerts for a device."""
    items = db.query(PantryItem).filter(PantryItem.device_uuid == device_uuid).all()
    for i in items:
        i.is_alert_enabled = enabled
    db.commit()
    state_str = "تفعيل" if enabled else "إيقاف"
    return {"status": "success", "updated_count": len(items), "message": f"تم {state_str} جميع تنبيهات مقاضي البيت"}

@router.post("/trigger-check")
async def trigger_monitoring_check(db: Session = Depends(get_db)):
    """Manual trigger for server monitoring cycle (useful for verification)."""
    stats = await price_monitor_service.run_single_monitoring_cycle(db)
    return {"status": "success", "stats": stats}
