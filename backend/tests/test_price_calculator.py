import pytest
from app.services.price_calculator import price_calculator

def test_halalas_financial_precision():
    """Verify integer calculations prevent floating-point rounding errors."""
    price = price_calculator.sar_to_halalas(34.99)
    assert price == 3499
    assert price_calculator.halalas_to_sar(3499) == 34.99

def test_unknown_fees_are_not_zero():
    """
    Critical Rule: Unknown fees must NEVER be treated as 0!
    If delivery fee is None, total must require store confirmation and cannot be labeled cheapest total.
    """
    unknown_fees = {
        "base_delivery_fee_halalas": None,
        "free_delivery_threshold_halalas": None,
        "service_fee_halalas": None
    }
    
    calc = price_calculator.calculate_landed_offer(2500, unknown_fees)
    assert calc.total_landed_halalas is None
    assert calc.total_status == "REQUIRES_STORE_CONFIRMATION"
    assert "الإجمالي يُؤكد لدى المتجر" in calc.total_status_text

def test_ranking_never_awards_cheapest_total_to_unknown_fees():
    """An offer with unknown delivery fees should NEVER get is_cheapest_total = True."""
    offers = [
        {
            "store_code": "unknown_store",
            "price_halalas": 2000,  # Cheaper product, but fees unknown
            "total_landed_halalas": None,
            "total_status": "REQUIRES_STORE_CONFIRMATION"
        },
        {
            "store_code": "danube",
            "price_halalas": 2500,
            "total_landed_halalas": 4000, # 2500 + 1500 delivery
            "total_status": "CONFIRMED"
        }
    ]

    ranked = price_calculator.rank_offers(offers)
    assert ranked[0]["is_cheapest_product"] is True
    assert ranked[0]["is_cheapest_total"] is False  # Must NOT be cheapest total!
    assert ranked[1]["is_cheapest_total"] is True   # The only confirmed total

def test_free_delivery_threshold():
    """Verify that orders exceeding free delivery threshold get 0 delivery fee."""
    fees = {
        "base_delivery_fee_halalas": 1500,
        "free_delivery_threshold_halalas": 10000, # 100 SAR
        "service_fee_halalas": 0
    }
    # Below threshold (50 SAR)
    calc_below = price_calculator.calculate_landed_offer(5000, fees)
    assert calc_below.delivery_fee_halalas == 1500
    assert calc_below.total_landed_halalas == 6500

    # Above threshold (120 SAR)
    calc_above = price_calculator.calculate_landed_offer(12000, fees)
    assert calc_above.delivery_fee_halalas == 0
    assert calc_above.total_landed_halalas == 12000
