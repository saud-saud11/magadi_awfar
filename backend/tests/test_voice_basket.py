import pytest
from app.database import Base
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.services.voice_basket_service import voice_basket_service
from app.services.store_catalog_service import seed_staple_products_to_db

@pytest.fixture(scope="module")
def db():
    # Each suite owns a fresh database; never depend on a developer's app data.
    engine = create_engine('sqlite://')
    Base.metadata.create_all(engine)
    with sessionmaker(bind=engine)() as session:
        seed_staple_products_to_db(session)
        yield session
    engine.dispose()

def test_scenario_1_default_single_pack(db):
    """
    Scenario 1: «حليب السعودية»
    Adds the smallest actual individual pack (200ml, Full Fat), quantity: 1.
    """
    session_id = "test_s1"
    res = voice_basket_service.parse_and_execute(
        db,
        query="حليب السعودية",
        session_id=session_id
    )
    assert res.status == "success"
    assert len(res.items_added) == 1
    item = res.items_added[0]
    assert item.quantity == 1
    assert "السعودية" in item.name_ar
    assert item.size_amount == 200.0  # Smallest actual individual pack
    assert "كامل الدسم" in item.name_ar

def test_scenario_2_explicit_quantity_and_size(db):
    """
    Scenario 2: «حبتين حليب السعودية لتر»
    Adds 2 units of 1L each, adhering strictly to the user's explicit details.
    """
    session_id = "test_s2"
    res = voice_basket_service.parse_and_execute(
        db,
        query="حبتين حليب السعودية لتر",
        session_id=session_id
    )
    assert res.status == "success"
    assert len(res.items_added) == 1
    item = res.items_added[0]
    assert item.quantity == 2
    assert item.size_amount == 1000.0
    assert "السعودية" in item.name_ar

def test_scenario_3_compound_multi_item_addition(db):
    """
    Scenario 3: «أبي حليب السعودية واثنين جبن كيري وخبز توست»
    Creates 3 distinct valid items:
    1. Saudia Milk (qty: 1, 200ml)
    2. Kiri Cheese (qty: 2)
    3. Toast Bread (qty: 1, Lusine Toast)
    """
    session_id = "test_s3"
    res = voice_basket_service.parse_and_execute(
        db,
        query="أبي حليب السعودية واثنين جبن كيري وخبز توست",
        session_id=session_id
    )
    assert res.status == "success"
    assert len(res.items_added) == 3
    
    # 1. Saudia Milk
    milk = next((i for i in res.items_added if "حليب" in i.name_ar), None)
    assert milk is not None
    assert milk.quantity == 1
    assert milk.size_amount == 200.0

    # 2. Kiri Cheese
    kiri = next((i for i in res.items_added if "كيري" in i.name_ar), None)
    assert kiri is not None
    assert kiri.quantity == 2

    # 3. Toast
    toast = next((i for i in res.items_added if "توست" in i.name_ar or "لوزين" in i.name_ar), None)
    assert toast is not None
    assert toast.quantity == 1

def test_scenario_4_modify_size_without_duplicate(db):
    """
    Scenario 4: «لا خله كبير»
    Modifies the size of the target item without adding a duplicate item!
    """
    session_id = "test_s4"
    # First: add 1L Saudia milk
    voice_basket_service.parse_and_execute(
        db,
        query="حليب السعودية لتر",
        session_id=session_id
    )
    
    # Then: modify size
    res_mod = voice_basket_service.parse_and_execute(
        db,
        query="لا خله كبير",
        session_id=session_id
    )
    assert res_mod.status == "success"
    assert res_mod.intent == "change_size_or_type"
    # Basket must have exactly 1 item (no duplicate added)
    assert len(res_mod.current_basket) == 1
    item = res_mod.current_basket[0]
    assert item.size_amount == 2000.0  # Large 2L size
    assert "٢ لتر" in item.name_ar or item.size_amount == 2000.0

def test_scenario_5_distinct_quantity_operations(db):
    """
    Scenario 5: «زيد واحدة» vs «خله اثنين»
    - «زيد واحدة» increments quantity (+1).
    - «خله اثنين» sets absolute quantity (=2).
    """
    session_id = "test_s5"
    # Add initial item (qty: 1)
    voice_basket_service.parse_and_execute(
        db,
        query="حليب السعودية",
        session_id=session_id
    )
    
    # Increment: «زيد واحدة» -> qty becomes 2
    res_inc = voice_basket_service.parse_and_execute(
        db,
        query="زيد واحدة",
        session_id=session_id
    )
    assert res_inc.current_basket[0].quantity == 2

    # Increment again: «زيد واحدة» -> qty becomes 3
    res_inc2 = voice_basket_service.parse_and_execute(
        db,
        query="زيد واحدة",
        session_id=session_id
    )
    assert res_inc2.current_basket[0].quantity == 3

    # Absolute set: «خله اثنين» -> qty explicitly becomes 2 (not 4!)
    res_set = voice_basket_service.parse_and_execute(
        db,
        query="خله اثنين",
        session_id=session_id
    )
    assert res_set.current_basket[0].quantity == 2

def test_scenario_6_negation_handling(db):
    """
    Scenario 6: «لا تضيف عصير»
    Ensures that juice is NOT added to the basket.
    """
    session_id = "test_s6"
    res = voice_basket_service.parse_and_execute(
        db,
        query="لا تضيف عصير",
        session_id=session_id
    )
    assert res.intent == "negation"
    assert len(res.current_basket) == 0

def test_scenario_7_strict_variant_preserved(db):
    """
    Scenario 7: Specific variant («خالي اللاكتوز»، «قليل الدسم») is strictly maintained.
    """
    session_id = "test_s7"
    res_lactose = voice_basket_service.parse_and_execute(
        db,
        query="حليب السعودية خالي اللاكتوز",
        session_id=session_id
    )
    item_lactose = res_lactose.current_basket[0]
    assert "لاكتوز" in item_lactose.name_ar

    session_id_low = "test_s7_low"
    res_low = voice_basket_service.parse_and_execute(
        db,
        query="حليب السعودية قليل الدسم",
        session_id=session_id_low
    )
    item_low = res_low.current_basket[0]
    assert "قليل الدسم" in item_low.name_ar

def test_scenario_8_idempotency_prevents_duplicate_addition(db):
    """
    Scenario 8: Repeated STT result or network retry does not duplicate addition.
    """
    session_id = "test_s8"
    req_id = "req_unique_9988"
    
    # First execution
    res1 = voice_basket_service.parse_and_execute(
        db,
        query="حليب السعودية",
        session_id=session_id,
        request_id=req_id
    )
    assert len(res1.current_basket) == 1

    # Retry with same request_id
    res2 = voice_basket_service.parse_and_execute(
        db,
        query="حليب السعودية",
        session_id=session_id,
        request_id=req_id
    )
    assert len(res2.current_basket) == 1
    assert res2.intent == "duplicate_request_ignored"

def test_scenario_9_undo_last_action(db):
    """
    Scenario 9: «رجّع آخر تعديل»
    Reverts the last action (restores previous state).
    """
    session_id = "test_s9"
    # Action 1: Add milk
    voice_basket_service.parse_and_execute(
        db,
        query="حليب السعودية",
        session_id=session_id
    )
    
    # Action 2: Add toast
    voice_basket_service.parse_and_execute(
        db,
        query="خبز توست",
        session_id=session_id
    )
    session_state = voice_basket_service.get_session(session_id)
    assert len(session_state["basket"]) == 2

    # Action 3: Undo
    res_undo = voice_basket_service.parse_and_execute(
        db,
        query="رجّع آخر تعديل",
        session_id=session_id
    )
    assert res_undo.intent == "undo"
    assert len(res_undo.current_basket) == 1
    assert "حليب" in res_undo.current_basket[0].name_ar

def test_scenario_10_ambiguity_clarification(db):
    """
    Scenario 10: Saying «شيله» when there are multiple items triggers clarification.
    """
    session_id = "test_s10"
    voice_basket_service.parse_and_execute(
        db,
        query="أبي حليب السعودية وخبز توست",
        session_id=session_id
    )

    # Ambiguous removal
    res = voice_basket_service.parse_and_execute(
        db,
        query="شيله",
        session_id=session_id
    )
    assert res.status == "clarification_needed"
    assert res.clarification_question is not None
    assert len(res.clarification_options) == 2

def test_scenario_11_incomplete_basket_never_cheapest(db):
    """
    Scenario 11: Incomplete basket is never marked as cheapest complete basket.
    """
    from app.services.basket_service import basket_service
    # Item that is only at Danube
    items = [{"product_id": 162, "quantity": 1}]
    compare_res = basket_service.compare_basket(db, items, "سلطانة")
    
    for st in compare_res.stores:
        if not st.is_complete:
            assert st.is_cheapest_complete_basket is False

def test_scenario_12_no_auto_substitution_missing_size(db):
    """
    Scenario 12: Searching for an unavailable size displays alternatives without auto-substituting.
    """
    from app.services.matcher import strict_matcher
    parsed = strict_matcher.parse_query("نوتيلا 500 جرام")
    assert parsed.target_amount == 500.0
    # Nutella only exists in 400g, 750g, 825g in KSA
    assert strict_matcher.is_exact_match(parsed, "نوتيلا كريمة البندق مع الكاكاو ٤٠٠ جرام", "400 جرام") is False
    assert strict_matcher.is_exact_match(parsed, "نوتيلا كريمة البندق مع الكاكاو ٧٥٠ جرام", "750 جرام") is False

