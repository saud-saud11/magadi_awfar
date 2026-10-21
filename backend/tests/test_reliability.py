"""Regression coverage for source truth, device isolation and real delivery outcomes."""
import asyncio
import json
from datetime import datetime, timedelta
from types import SimpleNamespace
from unittest.mock import AsyncMock

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from app.database import Base, get_db
from app.models.models import Product, Store, StoreOffer, PantryItem, PushSubscription, NotificationLog
from app.connectors.base import RawConnectorItem
from app.connectors.manager import connector_manager
from app.api import search, pantry, push, voice, admin
from app.services.price_monitor_service import PriceMonitorService
from app.services.web_push_service import web_push_service
from app.services.basket_service import basket_service
from app.config import settings

A, B = 'a' * 64, 'b' * 64

def raw(size=500, price=1800, pack=1, stock=True, verified=True):
    return RawConnectorItem(store_code='danube', store_name_ar='الدانوب',
        title_ar=f'نوتيلا {size} جرام' + (f' × {pack}' if pack > 1 else ''), title_en=None,
        brand_ar='نوتيلا', brand_en=None, price_halalas=price, original_price_halalas=None,
        is_in_stock=stock, url='https://danube.sa/product', deep_link=None, image_url=None,
        barcode=None, raw_size_text=None, pack_count=pack, price_verified=verified,
        stock_known=True, source_url='https://danube.sa/product', fetched_at=datetime.utcnow())

@pytest.fixture
def db():
    engine = create_engine('sqlite://', connect_args={'check_same_thread': False}, poolclass=StaticPool)
    Base.metadata.create_all(engine)
    with sessionmaker(bind=engine)() as session:
        yield session
    engine.dispose()

@pytest.fixture
def client(db):
    app = FastAPI()
    for router in [search.router, pantry.router, push.router, voice.router, admin.router]:
        app.include_router(router, prefix='/api/v1')
    app.dependency_overrides[get_db] = lambda: db
    with TestClient(app) as client:
        yield client


def seed(db, *, baseline=2500, version=2):
    p = Product(name_ar='نوتيلا 500 جرام', brand_ar='نوتيلا', normalized_size_amount=500,
                normalized_size_unit='g', pack_count=1)
    st = Store(code='danube', name_ar='الدانوب', name_en='Danube', is_enabled=True)
    db.add_all([p, st]); db.flush()
    item = PantryItem(device_uuid=A, product_id=p.id, baseline_version=version,
        baseline_price_halalas=baseline, baseline_store_code='danube',
        last_lowest_price_halalas=baseline, last_lowest_store_code='danube',
        is_alert_enabled=True, usual_quantity=1, last_checked_at=datetime.utcnow())
    db.add(item); db.commit()
    return p, st, item


def test_search_keeps_sizes_packs_and_real_ids(client, db, monkeypatch):
    monkeypatch.setattr(connector_manager, 'search_all', AsyncMock(return_value=[raw(), raw(750), raw(pack=6)]))
    first = client.get('/api/v1/search', params={'q': 'نوتيلا 500 جرام'})
    assert first.status_code == 200, first.text
    data = first.json()
    assert len(data['matched_products']) == 1
    assert len(data['alternative_sizes']) == 2
    p = data['matched_products'][0]
    offer = p['offers'][0]
    assert offer['price_sar'] == 18 and offer['price_verified']
    assert offer['total_landed_sar'] is None and offer['delivery_fee_sar'] is None
    second = client.get('/api/v1/search', params={'q': 'نوتيلا 500 جرام'}).json()
    assert second['matched_products'][0]['id'] == p['id']
    assert db.query(StoreOffer).count() == 3


def test_device_ownership_and_admin_guard(client, db, monkeypatch):
    _, _, item = seed(db)
    assert client.put(f'/api/v1/pantry/{item.id}', json={'usual_quantity': 2}).status_code == 401
    assert client.put(f'/api/v1/pantry/{item.id}', headers={'Authorization': f'Bearer {B}'}, json={'usual_quantity': 2}).status_code == 404
    assert client.delete(f'/api/v1/pantry/{item.id}', headers={'Authorization': f'Bearer {B}'}).status_code == 404
    assert client.get('/api/v1/pantry', params={'device_uuid': A}, headers={'Authorization': f'Bearer {B}'}).status_code == 403
    result = client.put(f'/api/v1/pantry/{item.id}', headers={'Authorization': f'Bearer {A}'}, json={'usual_quantity': 2})
    assert result.status_code == 200, result.text
    monkeypatch.setattr(settings, 'ADMIN_TOKEN', 'test-admin-only')
    assert client.get('/api/v1/admin/sources').status_code == 403


def test_voice_session_cannot_be_impersonated(client, db):
    p, _, _ = seed(db)
    headers = {'Authorization': f'Bearer {A}'}
    assert client.post('/api/v1/voice/parse', headers=headers, json={'query': 'نوتيلا', 'session_id': B}).status_code == 403
    assert client.get(f'/api/v1/voice/session/{B}', headers=headers).status_code == 403
    assert client.post('/api/v1/voice/undo', headers=headers).json()['session_id'] == A


def test_push_never_claims_success_without_transport(client, monkeypatch):
    monkeypatch.setattr(settings, 'VAPID_PRIVATE_KEY', '')
    headers = {'Authorization': f'Bearer {A}'}
    assert not client.get('/api/v1/push/config', headers=headers).json()['enabled']
    assert client.post('/api/v1/push/test', params={'device_uuid': A}, headers=headers).status_code == 409
    assert client.post('/api/v1/push/subscribe', headers=headers, json={'device_uuid': A, 'endpoint': 'https://fcm.googleapis.com/x'}).status_code == 503
    assert not asyncio.run(web_push_service.send_web_push({}, {}))


@pytest.mark.parametrize('endpoint', ['http://127.0.0.1/a', 'https://example.com', 'https://fcm.googleapis.com.evil.test/x', 'https://fcm.googleapis.com:bad/x', 'https://user@fcm.googleapis.com/a'])
def test_push_endpoint_validation(endpoint):
    assert not web_push_service.valid_endpoint(endpoint)


def test_push_payload_and_transport_result(monkeypatch):
    import pywebpush
    monkeypatch.setattr(settings, 'VAPID_PUBLIC_KEY', 'test-public')
    monkeypatch.setattr(settings, 'VAPID_PRIVATE_KEY', 'test-private')
    monkeypatch.setattr(settings, 'VAPID_SUBJECT', 'mailto:test@example.org')
    subscription = {'endpoint':'https://fcm.googleapis.com/test', 'p256dh_key':'test', 'auth_key':'test'}
    payload = web_push_service.format_notification_payload('عنوان', 'نص', 1, 'danube', 'الدانوب', 18)
    calls = []
    monkeypatch.setattr(pywebpush, 'webpush', lambda **kwargs: calls.append(kwargs))
    assert asyncio.run(web_push_service.send_web_push(subscription, payload))
    sent = json.loads(calls[0]['data'])
    assert sent['title'] == 'عنوان' and '?view=pantry' in sent['data']['deep_link']
    def fail(**kwargs): raise RuntimeError('transport unavailable')
    monkeypatch.setattr(pywebpush, 'webpush', fail)
    assert not asyncio.run(web_push_service.send_web_push(subscription, payload))


@pytest.mark.parametrize('candidate', [raw(size=450), raw(pack=6), raw(stock=False), raw(verified=False)])
def test_monitor_rejects_wrong_size_pack_stock_or_provenance(db, monkeypatch, candidate):
    _, _, item = seed(db)
    monkeypatch.setattr(connector_manager, 'search_all', AsyncMock(return_value=[candidate]))
    asyncio.run(PriceMonitorService().run_single_monitoring_cycle(db, A))
    assert item.last_lowest_price_halalas == 2500
    assert db.query(NotificationLog).count() == 0


def test_monitor_rebaselines_legacy_without_fake_discount(db, monkeypatch):
    _, _, item = seed(db, baseline=9000, version=0)
    monkeypatch.setattr(connector_manager, 'search_all', AsyncMock(return_value=[raw()]))
    asyncio.run(PriceMonitorService().run_single_monitoring_cycle(db, A))
    assert item.baseline_version == 2 and item.baseline_price_halalas == 1800
    assert db.query(NotificationLog).count() == 0


def test_monitor_failed_delivery_retries_after_quiet_without_duplicates(db, monkeypatch):
    _, _, item = seed(db)
    db.add(PushSubscription(device_uuid=A, endpoint='https://fcm.googleapis.com/test', p256dh_key='test', auth_key='test', is_active=True)); db.commit()
    monkeypatch.setattr(connector_manager, 'search_all', AsyncMock(return_value=[raw()]))
    transport = AsyncMock(return_value=False)
    monkeypatch.setattr(web_push_service, 'send_web_push', transport)
    service = PriceMonitorService()
    monkeypatch.setattr(service, 'is_in_quiet_hours', lambda _: True)
    asyncio.run(service.run_single_monitoring_cycle(db, A))
    log = db.query(NotificationLog).one()
    assert not log.is_sent and transport.await_count == 0
    monkeypatch.setattr(service, 'is_in_quiet_hours', lambda _: False)
    asyncio.run(service.run_single_monitoring_cycle(db, A))
    assert not log.is_sent and transport.await_count == 1
    transport.return_value = True
    asyncio.run(service.run_single_monitoring_cycle(db, A))
    assert log.is_sent and db.query(NotificationLog).count() == 1
    asyncio.run(service.run_single_monitoring_cycle(db, A))
    assert transport.await_count == 2


def test_basket_never_completes_with_unknown_or_unverified_product(db):
    p, store, _ = seed(db)
    offer = StoreOffer(product_id=p.id, store_id=store.id, price_halalas=1800, product_url='https://danube.sa', is_in_stock=True,
                       raw_data_json='{}', last_verified_at=datetime.utcnow())
    db.add(offer); db.commit()
    request = [{'product_id': p.id, 'quantity': 2}, {'product_id': 999, 'quantity': 1}]
    assert basket_service.compare_basket(db, request).stores == []
    offer.raw_data_json = json.dumps({'verified':True, 'stock_known':True}); db.commit()
    result = basket_service.compare_basket(db, request).stores[0]
    assert not result.is_complete and result.subtotal_halalas == 3600
    assert result.total_sar is None and len(result.missing_items) == 1
    offer.last_verified_at = datetime.utcnow() - timedelta(days=2)
    assert basket_service.compare_basket(db, request).stores == []


def test_voice_size_is_not_quantity_and_missing_sku_is_not_invented(db):
    from app.services.voice_basket_service import VoiceBasketService
    seed(db)
    service = VoiceBasketService()
    result = service.parse_and_execute(db, 'نوتيلا 500 جرام', session_id=A)
    assert result.current_basket[0].quantity == 1
    assert result.current_basket[0].size_amount == 500
    previous = result.current_basket[0].product_id
    missing = service.parse_and_execute(db, 'نوتيلا 450 جرام', session_id=A)
    assert len(missing.current_basket) == 1
    assert missing.current_basket[0].product_id == previous
    unknown = service.parse_and_execute(db, 'منتج غير موجود نهائيا', session_id=B)
    assert unknown.current_basket == []
