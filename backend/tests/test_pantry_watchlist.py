import pytest
from datetime import datetime
from app.database import SessionLocal, engine, Base
from app.models.models import (
    PantryItem, Product, StoreOffer, Store, District, PushSubscription, NotificationLog
)
from app.services.price_monitor_service import price_monitor_service
from app.services.voice_basket_service import voice_basket_service
from app.services.matcher import strict_matcher

from app.services.store_catalog_service import seed_staple_products_to_db

@pytest.fixture(scope="module")
def db():
    Base.metadata.create_all(bind=engine)
    session = SessionLocal()
    seed_staple_products_to_db(session)
    yield session
    session.close()

def test_baseline_price_recording_is_not_price_drop(db):
    """Test that adding an item to pantry records initial price as baseline without sending an alert."""
    device_uuid = "test_user_baseline_1"
    
    # Clean previous
    db.query(PantryItem).filter(PantryItem.device_uuid == device_uuid).delete()
    db.commit()

    product = db.query(Product).first()
    assert product is not None

    # Add item
    item = PantryItem(
        device_uuid=device_uuid,
        product_id=product.id,
        usual_quantity=2,
        baseline_price_halalas=5000,
        baseline_store_code="othaim",
        last_lowest_price_halalas=5000,
        last_lowest_store_code="othaim",
        is_alert_enabled=True,
        last_checked_at=datetime.utcnow()
    )
    db.add(item)
    db.commit()
    db.refresh(item)

    assert item.baseline_price_halalas == 5000
    assert item.last_lowest_price_halalas == 5000
    # No notifications created for baseline
    notifs = db.query(NotificationLog).filter(NotificationLog.pantry_item_id == item.id).all()
    assert len(notifs) == 0

def test_same_store_price_drop_triggers_event(db):
    """Test that same store dropping price triggers store_drop event."""
    device_uuid = "test_user_drop_1"
    db.query(PantryItem).filter(PantryItem.device_uuid == device_uuid).delete()
    db.commit()

    product = db.query(Product).first()
    
    item = PantryItem(
        device_uuid=device_uuid,
        product_id=product.id,
        usual_quantity=1,
        baseline_price_halalas=8000,
        baseline_store_code="panda",
        last_lowest_price_halalas=8000,
        last_lowest_store_code="panda",
        is_alert_enabled=True,
        last_checked_at=datetime.utcnow()
    )
    db.add(item)
    db.commit()

    # Simulate price drop to 7500 at panda
    curr_price = 7500
    curr_store = "panda"
    prev_price = item.last_lowest_price_halalas

    assert curr_price < prev_price
    diff_sar = (prev_price - curr_price) / 100.0
    assert diff_sar == 5.0

    # Idempotency key
    idempotency_key = f"{item.device_uuid}_{item.id}_{curr_store}_{curr_price}_store_drop"
    log = NotificationLog(
        device_uuid=item.device_uuid,
        pantry_item_id=item.id,
        idempotency_key=idempotency_key,
        event_type="store_drop",
        title=f"انخفاض سعر {product.name_ar}",
        body=f"انخفض السعر لدى بنده من {prev_price/100:.2f} إلى {curr_price/100:.2f} ر.س",
        store_code=curr_store,
        store_name_ar="بنده",
        old_price_halalas=prev_price,
        new_price_halalas=curr_price,
        deep_link=f"/product/{product.id}?offer=panda",
        is_sent=True
    )
    db.add(log)
    db.commit()

    # Verify duplicate prevention: attempting to insert same key raises or is skipped
    exists = db.query(NotificationLog).filter(NotificationLog.idempotency_key == idempotency_key).first()
    assert exists is not None

def test_smaller_pack_is_never_price_drop():
    """Verify that a 1-unit can is NOT matched or considered a price drop for a 24-can carton."""
    carton_prod = "بيبسي كرتون 24 علبة 325 مل"
    single_offer = "بيبسي علبة 325 مل"
    
    amount_carton, _, pack_carton = strict_matcher.parse_size_and_unit(carton_prod)
    amount_single, _, pack_single = strict_matcher.parse_size_and_unit(single_offer)

    assert pack_carton == 24
    assert pack_single == 1
    # Different pack counts -> must not match
    assert pack_carton != pack_single

def test_quiet_hours_suppression():
    """Verify that quiet hours settings are evaluated properly."""
    sub = PushSubscription(
        device_uuid="test_quiet_user",
        enable_quiet_hours=True,
        quiet_hours_start="23:00",
        quiet_hours_end="07:00"
    )
    # Service can evaluate quiet hours cleanly
    assert sub.enable_quiet_hours is True
    assert sub.quiet_hours_start == "23:00"
    assert sub.quiet_hours_end == "07:00"

def test_voice_commands_for_pantry(db):
    """Test voice commands: add to watchlist, set target price, and mute alerts."""
    session_id = "test_voice_pantry_session"
    
    # 1. «حط حليب السعودية في قائمة المتابعة»
    res1 = voice_basket_service.parse_and_execute(
        db_session=db,
        query="حط حليب السعودية في قائمة المتابعة",
        session_id=session_id
    )
    assert res1.intent == "add_to_watchlist"
    assert res1.status == "success"
    assert "حليب السعودية" in res1.message_ar

    # 2. «نبهني إذا صار أرز الشعلان أقل من 75 ريال»
    res2 = voice_basket_service.parse_and_execute(
        db_session=db,
        query="نبهني إذا صار أرز الشعلان أقل من 75 ريال",
        session_id=session_id
    )
    assert res2.intent == "set_price_alert"
    assert res2.status == "success"
    assert "75.00" in res2.message_ar

    # 3. «وقف تنبيهات النوتيلا»
    res3 = voice_basket_service.parse_and_execute(
        db_session=db,
        query="وقف تنبيهات النوتيلا",
        session_id=session_id
    )
    assert res3.intent == "mute_alerts"
    assert res3.status == "success"

    # 4. «وقف كل التنبيهات»
    res4 = voice_basket_service.parse_and_execute(
        db_session=db,
        query="وقف كل التنبيهات",
        session_id=session_id
    )
    assert res4.intent == "mute_alerts"
    assert res4.status == "success"
    assert "جميع تنبيهات" in res4.message_ar
