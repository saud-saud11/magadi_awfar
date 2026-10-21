import json
from datetime import datetime, timedelta, timezone


def is_verified_offer(offer, *, in_stock=True):
    """Legacy seeded prices are never treated as source observations."""
    try:
        provenance = json.loads(offer.raw_data_json or '{}')
    except (ValueError, TypeError):
        return False
    if not isinstance(provenance, dict) or not offer.last_verified_at: return False
    observed = offer.last_verified_at
    if observed.tzinfo: observed = observed.astimezone(timezone.utc).replace(tzinfo=None)
    age = datetime.utcnow() - observed
    return (provenance.get('verified') is True and offer.price_halalas > 0
            and timedelta(0) <= age < timedelta(hours=24)
            and (not in_stock or (provenance.get('stock_known') and offer.is_in_stock)))


def valid_barcode(value):
    if not value.isascii() or not value.isdigit() or len(value) not in (8, 12, 13, 14): return False
    total = sum(int(digit) * (3 if i % 2 == 0 else 1) for i, digit in enumerate(reversed(value[:-1])))
    return (-total) % 10 == int(value[-1])
