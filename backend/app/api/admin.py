from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Dict, Any
from app.database import get_db
from app.security import require_admin
from app.models.models import Store, Product, StoreOffer, SearchLog
from app.connectors.manager import connector_manager
from app.schemas.schemas import AdminStoreUpdate

router = APIRouter(prefix="/admin", tags=["Admin & Reliability"], dependencies=[Depends(require_admin)])

@router.get("/sources")
def get_sources_dashboard(db: Session = Depends(get_db)):
    """Returns detailed status of each connector, product count, and error state."""
    statuses = connector_manager.get_all_statuses()
    total_products = db.query(Product).count()
    total_offers = db.query(StoreOffer).count()
    recent_searches = db.query(SearchLog).order_by(SearchLog.created_at.desc()).limit(10).all()

    return {
        "sources": statuses,
        "metrics": {
            "total_products_indexed": total_products,
            "total_offers_monitored": total_offers,
            "recent_searches_count": len(recent_searches),
            "stale_offers_count": 0
        },
        "recent_searches": [
            {"query": s.query, "district": s.district_name, "time": s.created_at}
            for s in recent_searches
        ]
    }

@router.post("/sources/{code}/toggle")
def toggle_source(code: str):
    """Enable or disable a specific store connector."""
    conn = connector_manager.get_connector(code)
    if not conn:
        raise HTTPException(status_code=404, detail="المتجر غير موجود")
    conn.is_enabled = not conn.is_enabled
    return {
        "code": code,
        "name_ar": conn.store_name_ar,
        "is_enabled": conn.is_enabled,
        "message": f"تم {'تفعيل' if conn.is_enabled else 'إيقاف'} موصل {conn.store_name_ar}"
    }

@router.put("/sources/{code}/settings")
def update_source_settings(code: str, update: AdminStoreUpdate, db: Session = Depends(get_db)):
    """Configure store update interval or delivery fee overrides."""
    store = db.query(Store).filter(Store.code == code).first()
    if not store:
        raise HTTPException(status_code=404, detail="المتجر غير مسجل بقاعدة البيانات")

    if update.is_enabled is not None:
        store.is_enabled = update.is_enabled
        conn = connector_manager.get_connector(code)
        if conn:
            conn.is_enabled = update.is_enabled
            
    if update.update_interval_minutes is not None:
        store.update_interval_minutes = update.update_interval_minutes
    if update.base_delivery_fee_halalas is not None:
        store.base_delivery_fee_halalas = update.base_delivery_fee_halalas

    db.commit()
    return {"status": "success", "message": "تم تحديث إعدادات المتجر بنجاح"}
