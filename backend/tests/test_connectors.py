import asyncio
from datetime import datetime
from types import SimpleNamespace
from unittest.mock import AsyncMock
from app.connectors.manager import ConnectorManager
from app.connectors.base import ConnectorStatus


def test_failure_isolated_and_unverified_prices_filtered():
    manager = ConnectorManager()
    real = SimpleNamespace(price_verified=True, fetched_at=datetime.utcnow(), price_halalas=1800)
    fake = SimpleNamespace(price_verified=False, fetched_at=datetime.utcnow(), price_halalas=1700)
    manager.connectors = {
        'failure': SimpleNamespace(is_enabled=True, store_code='failure', search=AsyncMock(side_effect=RuntimeError('offline'))),
        'working': SimpleNamespace(is_enabled=True, store_code='working', search=AsyncMock(return_value=[real, fake])),
    }
    assert asyncio.run(manager.search_all('نوتيلا', 'سلطانة')) == [real]


def test_unconnected_sources_never_claim_connected():
    statuses = {s['code']: s['status'] for s in ConnectorManager().get_all_statuses()}
    assert statuses['danube'] == ConnectorStatus.UNDER_INVESTIGATION.value
    assert all(value == ConnectorStatus.REQUIRES_SETUP.value for code, value in statuses.items() if code != 'danube')
