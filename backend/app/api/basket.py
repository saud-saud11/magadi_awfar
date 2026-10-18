from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.schemas import BasketCompareRequest, BasketCompareResponse
from app.services.basket_service import basket_service

router = APIRouter(prefix="/basket", tags=["Smart Basket"])

@router.post("/compare", response_model=BasketCompareResponse)
def compare_user_basket(
    req: BasketCompareRequest,
    db: Session = Depends(get_db)
):
    """
    Compares the full grocery basket across all stores in Al-Madinah.
    Accounts for missing items, minimum spend, delivery fees, and split basket savings.
    """
    items_data = [{"product_id": it.product_id, "quantity": it.quantity} for it in req.items]
    return basket_service.compare_basket(db, items_data, req.district_name or "سلطانة")
