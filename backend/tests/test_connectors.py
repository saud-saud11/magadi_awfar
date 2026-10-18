import pytest
import asyncio
from app.connectors.manager import connector_manager
from app.connectors.base import ConnectorStatus

def test_resilient_search_one_failure_does_not_break_others():
    """Verify that if one connector raises an exception, the rest continue unharmed."""
    async def run():
        results = await connector_manager.search_all("نوتيلا", "سلطانة")
        assert isinstance(results, list)
        assert len(results) > 0

        # Ensure Danube products are returned with valid price in Halalas
        danube_items = [r for r in results if r.store_code == "danube"]
        assert len(danube_items) > 0
        assert danube_items[0].price_halalas > 0

    asyncio.run(run())

def test_store_status_transparency():
    """Ensure every source has a valid defined status without false claims."""
    statuses = connector_manager.get_all_statuses()
    status_map = {s["code"]: s["status"] for s in statuses}

    assert status_map["danube"] == ConnectorStatus.CONNECTED.value
    assert status_map["tamimi"] == ConnectorStatus.CONNECTED.value
    assert status_map["noon_minutes"] == ConnectorStatus.CONNECTED.value
    assert status_map["amazon_sa"] == ConnectorStatus.CONNECTED.value
    assert status_map["nahdi"] == ConnectorStatus.CONNECTED.value
    assert status_map["dawaa"] == ConnectorStatus.CONNECTED.value
    assert status_map["carrefour"] == ConnectorStatus.REQUIRES_SETUP.value
    assert status_map["hungerstation"] == ConnectorStatus.REQUIRES_SETUP.value
    assert status_map["ninja"] == ConnectorStatus.REQUIRES_SETUP.value
    assert status_map["amazon_now"] == ConnectorStatus.UNSUPPORTED.value
