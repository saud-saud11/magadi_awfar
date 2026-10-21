import json
import re
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.models import Product, StoreOffer, Store, SearchLog
from app.schemas.schemas import SearchResponse, ProductOut, StoreOfferOut
from app.connectors.manager import connector_manager
from app.services.matcher import strict_matcher
from app.services.price_calculator import price_calculator

router = APIRouter(prefix='/search', tags=['Search & Compare'])

@router.get('', response_model=SearchResponse)
async def search_and_compare(q: str = Query(..., min_length=1, max_length=200), district: str = 'سلطانة',
                             sort_by: str = 'cheapest_product', db: Session = Depends(get_db)):
    parsed = strict_matcher.parse_query(q)
    raw_items = await connector_manager.search_all(q, district)
    # A size constraint separates alternatives; it must not exclude them from relevance.
    relevance_query = re.sub(r'\d+(?:\.\d+)?\s*(?:جرام|غرام|جم|كجم|kg|g|مل|ml|لتر|l)\b', '', strict_matcher.normalize_text(q)).strip()
    barcode_query = q.strip().isdigit() and len(q.strip()) in (8, 12, 13, 14)
    groups = {}
    for item in raw_items:
        if not item.price_verified or not item.fetched_at or item.price_halalas <= 0: continue
        if barcode_query:
            if item.barcode != q.strip(): continue
        elif not strict_matcher.is_relevant_match(relevance_query, item.title_ar, item.brand_ar): continue
        amount, unit, pack = strict_matcher.parse_size_and_unit(f'{item.title_ar} {item.raw_size_text or ""}')
        pack = max(pack, item.pack_count)
        key = strict_matcher.generate_product_key(item.title_ar, item.brand_ar or '', amount, unit, pack, item.barcode)
        if key not in groups:
            product = db.query(Product).filter(Product.name_ar == item.title_ar,
                Product.normalized_size_amount == amount, Product.normalized_size_unit == unit,
                Product.pack_count == pack).first()
            if product is None:
                product = Product(name_ar=item.title_ar, category='بقالة', normalized_size_amount=amount,
                                  normalized_size_unit=unit, pack_count=pack)
                db.add(product); db.flush()
            product.name_en, product.brand_ar = item.title_en, item.brand_ar
            product.image_url, product.gtin_barcode = item.image_url, item.barcode
            category, rank = strict_matcher.get_product_sub_category(item.title_ar)
            groups[key] = ProductOut(id=product.id, name_ar=item.title_ar, name_en=item.title_en,
                gtin_barcode=item.barcode, brand_ar=item.brand_ar, category='بقالة', sub_category=category,
                sub_category_rank=rank, normalized_size_amount=amount, normalized_size_unit=unit,
                pack_count=pack, pack_type='bundle' if pack > 1 else 'single', image_url=item.image_url, offers=[])
        output = groups[key]
        store = db.query(Store).filter(Store.code == item.store_code).first()
        if store is None:
            store = Store(code=item.store_code, name_ar=item.store_name_ar, name_en=item.store_code)
            db.add(store); db.flush()
        store.status = 'connected'; store.last_sync_at = item.fetched_at
        # These observations are an online catalog scope, never a guessed local branch.
        saved = db.query(StoreOffer).filter(StoreOffer.product_id == output.id,
            StoreOffer.store_id == store.id, StoreOffer.branch_id.is_(None)).first()
        if saved is None:
            saved = StoreOffer(product_id=output.id, store_id=store.id, product_url=item.url, price_halalas=item.price_halalas)
            db.add(saved)
        saved.price_halalas = item.price_halalas
        saved.original_price_halalas = item.original_price_halalas
        saved.is_on_sale = bool(item.original_price_halalas and item.original_price_halalas > item.price_halalas)
        saved.is_in_stock, saved.product_url = item.is_in_stock, item.url
        saved.deep_link, saved.promo_conditions = item.deep_link, item.promo_conditions
        saved.last_verified_at = item.fetched_at
        saved.raw_data_json = json.dumps({'verified': True, 'stock_known': item.stock_known,
            'source_url': item.source_url, 'scope': 'online_catalog', 'coverage_verified': False})
        db.flush()
        calc = price_calculator.calculate_landed_offer(item.price_halalas, connector_manager.get_connector(item.store_code).get_fees_info(district))
        offer = StoreOfferOut(id=saved.id, store_code=item.store_code, store_name_ar=item.store_name_ar,
            branch_name_ar=item.branch_name, price_halalas=item.price_halalas, price_sar=item.price_halalas / 100,
            original_price_sar=item.original_price_halalas / 100 if saved.is_on_sale else None,
            is_on_sale=saved.is_on_sale, is_in_stock=item.is_in_stock, stock_known=item.stock_known,
            price_verified=True, source_url=item.source_url, product_url=item.url, deep_link=item.deep_link,
            promo_conditions=item.promo_conditions, last_verified_at=item.fetched_at,
            delivery_fee_sar=calc.delivery_fee_sar, total_landed_sar=calc.total_landed_sar,
            total_status=calc.total_status, total_status_text=calc.total_status_text,
            unit_price_per_100g_sar=item.price_halalas / (amount * pack) if amount and pack == 1 and unit in ('g','ml') else None)
        output.offers = [o for o in output.offers if o.store_code != item.store_code] + [offer]
    matched, alternatives = [], []
    for product in groups.values():
        eligible = [o for o in product.offers if not o.stock_known or o.is_in_stock]
        cheapest = min((o.price_halalas for o in eligible), default=None)
        for offer in product.offers: offer.is_cheapest_product = offer in eligible and offer.price_halalas == cheapest
        product.offers.sort(key=lambda o: (o.stock_known and not o.is_in_stock, o.price_halalas))
        exact = (parsed.target_amount is None or (parsed.target_amount == product.normalized_size_amount and parsed.target_unit == product.normalized_size_unit and parsed.pack_count == product.pack_count))
        (matched if exact else alternatives).append(product)
    db.add(SearchLog(query=q, district_name=district, matched_products_count=len(matched)))
    db.commit()
    return SearchResponse(query=q, district_name=district, exact_size_matched=bool(matched),
        status_message='الأسعار المتاحة من المصادر التي استجابت' if groups else 'لم نحصل على أسعار موثقة لهذا البحث الآن',
        disclaimer='أسعار المنتجات قبل الرسوم. تغطية الحي والتوفر النهائي يُؤكّدان لدى المتجر.',
        matched_products=matched, alternative_sizes=alternatives,
        sub_categories=list(dict.fromkeys(p.sub_category for p in groups.values() if p.sub_category)),
        sources_summary=connector_manager.get_all_statuses())
