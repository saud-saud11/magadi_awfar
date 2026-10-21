from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.security import require_device
from app.models.models import PriceAlert, Product, District
from app.schemas.schemas import PriceAlertCreate, PriceAlertOut

router = APIRouter(prefix="/alerts", tags=["Price Alerts"], dependencies=[Depends(require_device)])

@router.post("", response_model=PriceAlertOut)
def create_price_alert(data: PriceAlertCreate, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == data.product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="المنتج غير موجود")

    district = db.query(District).filter(District.name_ar == data.district_name).first()

    target_halalas = int(round(data.target_price_sar * 100))

    alert = PriceAlert(
        product_id=data.product_id,
        district_id=district.id if district else None,
        target_price_halalas=target_halalas,
        device_id=data.device_id,
        is_active=True
    )
    db.add(alert)
    db.commit()
    db.refresh(alert)

    return PriceAlertOut(
        id=alert.id,
        product_id=alert.product_id,
        target_price_halalas=alert.target_price_halalas,
        target_price_sar=round(alert.target_price_halalas / 100.0, 2),
        is_active=alert.is_active,
        created_at=alert.created_at
    )

@router.get("/{device_id}", response_model=List[PriceAlertOut])
def get_user_alerts(device_id: str, db: Session = Depends(get_db)):
    alerts = db.query(PriceAlert).filter(PriceAlert.device_id == device_id, PriceAlert.is_active == True).all()
    return [
        PriceAlertOut(
            id=a.id,
            product_id=a.product_id,
            target_price_halalas=a.target_price_halalas,
            target_price_sar=round(a.target_price_halalas / 100.0, 2),
            is_active=a.is_active,
            created_at=a.created_at
        )
        for a in alerts
    ]
