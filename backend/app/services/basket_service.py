"""Compare observed item prices within one store and one branch scope."""
from collections import defaultdict
from app.models.models import Product, StoreOffer, Store
from app.schemas.schemas import StoreBasketResult, BasketCompareResponse
from app.services.verified_offers import is_verified_offer


class BasketService:
    def compare_basket(self, db_session, items, district_name="سلطانة"):
        products = {p.id: p for p in db_session.query(Product).filter(
            Product.id.in_([i['product_id'] for i in items])).all()}
        grouped = defaultdict(dict)
        stores = {}
        for offer, store in db_session.query(StoreOffer, Store).join(Store).filter(
            Store.is_enabled == True, StoreOffer.product_id.in_(products)).all():
            if not is_verified_offer(offer, in_stock=False) or not offer.is_in_stock:
                # Unknown stock can still have an observed price, but cannot complete a basket.
                continue
            key = (store.id, offer.branch_id)
            stores[key] = store
            old = grouped[key].get(offer.product_id)
            if old is None or offer.price_halalas < old.price_halalas:
                grouped[key][offer.product_id] = offer
        results = []
        for key, offers in grouped.items():
            store = stores[key]
            missing = [products[i['product_id']].name_ar if i['product_id'] in products
                       else f"صنف غير معروف ({i['product_id']})" for i in items if i['product_id'] not in offers]
            subtotal = sum(offers[i['product_id']].price_halalas * i['quantity']
                           for i in items if i['product_id'] in offers)
            results.append(StoreBasketResult(
                store_code=store.code, store_name_ar=store.name_ar,
                branch_id=key[1], store_logo=store.logo_url,
                is_complete=bool(items) and not missing,
                available_items_count=len(items)-len(missing), total_items_count=len(items),
                missing_items=missing, subtotal_halalas=subtotal, subtotal_sar=subtotal / 100,
                total_status_text='مجموع المنتجات فقط؛ التغطية والتوصيل والرسوم تُؤكد لدى المتجر',
                is_cheapest_complete_basket=False))
        results.sort(key=lambda r: (not r.is_complete, r.subtotal_halalas))
        return BasketCompareResponse(district_name=district_name, stores=results, split_basket_suggestion=None)


basket_service = BasketService()
