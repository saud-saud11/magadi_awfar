import pytest
from app.services.matcher import strict_matcher

def test_no_size_confusion_nutella_500g():
    """Verify that asking for 500g does NOT match 400g or 750g or 825g."""
    query = strict_matcher.parse_query("نوتيلا 500 جرام")
    assert query.target_amount == 500.0
    assert query.target_unit == "g"

    # Test 400g jar -> MUST NOT match
    assert strict_matcher.is_exact_match(query, "نوتيلا شوكولاتة قابلة للدهن", "400 جرام") is False
    # Test 750g jar -> MUST NOT match
    assert strict_matcher.is_exact_match(query, "نوتيلا شوكولاتة بالبندق", "750g") is False
    # Test 825g jar -> MUST NOT match
    assert strict_matcher.is_exact_match(query, "نوتيلا برطمان", "825 جرام") is False
    # Test 500g jar (if ever existed) -> MUST match
    assert strict_matcher.is_exact_match(query, "نوتيلا عبوة 500 جرام", "500g") is True

def test_arabic_and_english_numerals():
    """Verify normalization of Eastern Arabic digits (٥٠٠ جرام)."""
    q_arabic = strict_matcher.parse_query("نوتيلا ٥٠٠ غرام")
    q_english = strict_matcher.parse_query("Nutella 500g")
    
    assert q_arabic.target_amount == 500.0
    assert q_english.target_amount == 500.0
    assert q_arabic.target_unit == "g"
    assert q_english.target_unit == "g"

def test_fractions_and_colloquial_units():
    """Verify 'نصف كيلو' translates to 500g."""
    q_half_kg = strict_matcher.parse_query("نوتيلا نصف كيلو")
    assert q_half_kg.target_amount == 500.0
    assert q_half_kg.target_unit == "g"

    q_quarter_kg = strict_matcher.parse_query("جبنة ربع كيلو")
    assert q_quarter_kg.target_amount == 250.0
    assert q_quarter_kg.target_unit == "g"

def test_bundle_pack_distinction():
    """Verify that a 2-pack bundle is not confused with a single bottle."""
    q_single = strict_matcher.parse_query("نوتيلا 400 جرام")
    assert q_single.pack_count == 1
    
    # Bundle item: 2x 400g
    assert strict_matcher.is_exact_match(q_single, "نوتيلا عرض حبتين 400 جرام", "2x 400g") is False

def test_unit_price_calculation():
    """Verify price per 100g calculation."""
    # 24.95 SAR for 400g -> (24.95 / 400) * 100 = 6.24 SAR / 100g
    unit_price = strict_matcher.calculate_unit_price_per_100g_or_ml(2495, 400.0, "g")
    assert unit_price == 6.24

    # 34.99 SAR for 750g -> (34.99 / 750) * 100 = 4.67 SAR / 100g
    unit_price_750 = strict_matcher.calculate_unit_price_per_100g_or_ml(3499, 750.0, "g")
    assert unit_price_750 == 4.67
