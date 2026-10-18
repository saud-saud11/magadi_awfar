from typing import Optional, Dict, Any, List
from dataclasses import dataclass

@dataclass
class CalculatedOffer:
    price_halalas: int
    price_sar: float
    delivery_fee_halalas: Optional[int]
    delivery_fee_sar: Optional[float]
    service_fee_halalas: Optional[int]
    total_landed_halalas: Optional[int]
    total_landed_sar: Optional[float]
    total_status: str  # "CONFIRMED" or "REQUIRES_STORE_CONFIRMATION"
    total_status_text: str
    is_cheapest_product: bool = False
    is_cheapest_total: bool = False

class PriceCalculator:
    """Accurate financial calculation engine in Halalas (integer cents) avoiding floating-point rounding."""

    @staticmethod
    def halalas_to_sar(halalas: Optional[int]) -> Optional[float]:
        if halalas is None:
            return None
        return round(halalas / 100.0, 2)

    @staticmethod
    def sar_to_halalas(sar: float) -> int:
        return int(round(sar * 100.0))

    def calculate_landed_offer(
        self,
        product_price_halalas: int,
        fees_info: Dict[str, Optional[int]],
        promo_discount_halalas: int = 0
    ) -> CalculatedOffer:
        base_delivery = fees_info.get("base_delivery_fee_halalas")
        free_threshold = fees_info.get("free_delivery_threshold_halalas")
        service_fee = fees_info.get("service_fee_halalas") or 0

        # Check if delivery fee is known
        if base_delivery is None:
            # Unknown fees must NEVER be treated as 0!
            return CalculatedOffer(
                price_halalas=product_price_halalas,
                price_sar=round(product_price_halalas / 100.0, 2),
                delivery_fee_halalas=None,
                delivery_fee_sar=None,
                service_fee_halalas=None,
                total_landed_halalas=None,
                total_landed_sar=None,
                total_status="REQUIRES_STORE_CONFIRMATION",
                total_status_text="الإجمالي يُؤكد لدى المتجر"
            )

        # Free delivery threshold check
        effective_delivery = base_delivery
        if free_threshold and product_price_halalas >= free_threshold:
            effective_delivery = 0

        total_landed = product_price_halalas + effective_delivery + service_fee - promo_discount_halalas
        if total_landed < 0:
            total_landed = 0

        return CalculatedOffer(
            price_halalas=product_price_halalas,
            price_sar=round(product_price_halalas / 100.0, 2),
            delivery_fee_halalas=effective_delivery,
            delivery_fee_sar=round(effective_delivery / 100.0, 2),
            service_fee_halalas=service_fee,
            total_landed_halalas=total_landed,
            total_landed_sar=round(total_landed / 100.0, 2),
            total_status="CONFIRMED",
            total_status_text="مؤكد شامل الرسوم"
        )

    def rank_offers(self, offers: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Ranks offers and assigns is_cheapest_product and is_cheapest_total flags."""
        if not offers:
            return []

        # Find min product price
        min_product_price = min(o["price_halalas"] for o in offers)
        for o in offers:
            o["is_cheapest_product"] = (o["price_halalas"] == min_product_price)

        # Find min confirmed total price (only among offers with CONFIRMED status)
        confirmed_totals = [
            o["total_landed_halalas"]
            for o in offers
            if o.get("total_status") == "CONFIRMED" and o.get("total_landed_halalas") is not None
        ]

        min_total = min(confirmed_totals) if confirmed_totals else None

        for o in offers:
            if min_total is not None and o.get("total_landed_halalas") == min_total:
                o["is_cheapest_total"] = True
            else:
                o["is_cheapest_total"] = False

        return offers

price_calculator = PriceCalculator()
