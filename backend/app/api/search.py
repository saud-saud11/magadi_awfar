from datetime import datetime
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any
from app.database import get_db
from app.models.models import Product, StoreOffer, Store, SearchLog
from app.schemas.schemas import SearchResponse, ProductOut, StoreOfferOut
from app.connectors.manager import connector_manager
from app.services.matcher import strict_matcher
from app.services.price_calculator import price_calculator

router = APIRouter(prefix="/search", tags=["Search & Compare"])

@router.get("", response_model=SearchResponse)
async def search_and_compare(
    q: str = Query(..., min_length=1, description="Search term, e.g. نوتيلا 500 جرام"),
    district: Optional[str] = Query("سلطانة", description="District in Madinah"),
    sort_by: str = Query("cheapest_product", pattern="^(cheapest_product|cheapest_total)$"),
    db: Session = Depends(get_db)
):
    """
    Search and compare grocery prices across Al-Madinah Al-Munawwarah stores.
    Supports Arabic/English and strict size matching.
    """
    parsed = strict_matcher.parse_query(q)

    # Log the search
    log_entry = SearchLog(query=q, district_name=district)
    db.add(log_entry)
    db.commit()

    # 1. Fetch live items from all active store connectors
    raw_items = await connector_manager.search_all(q, district)

    # 2. Group raw items into distinct normalized products (by Brand + Sub-type + Size)
    grouped_products: Dict[str, Dict[str, Any]] = {}

    for item in raw_items:
        amount, unit, pack = strict_matcher.parse_size_and_unit(f"{item.title_ar} {item.raw_size_text or ''}")
        brand = item.brand_ar or parsed.brand or "عام"
        key = strict_matcher.generate_product_key(
            title_ar=item.title_ar,
            brand=brand,
            amount=amount,
            unit=unit,
            pack=pack,
            barcode=item.barcode
        )

        if key not in grouped_products:
            sub_cat, sub_cat_rank = strict_matcher.get_product_sub_category(item.title_ar)
            grouped_products[key] = {
                "name_ar": item.title_ar,
                "name_en": item.title_en,
                "brand_ar": brand,
                "brand_en": item.brand_en,
                "category": "بقالة",
                "sub_category": sub_cat,
                "sub_category_rank": sub_cat_rank,
                "normalized_size_amount": amount,
                "normalized_size_unit": unit,
                "pack_count": pack,
                "image_url": item.image_url,
                "barcode": item.barcode,
                "offers": []
            }

        # Calculate landed total cost
        connector = connector_manager.get_connector(item.store_code)
        fees_info = connector.get_fees_info(district) if connector else {}
        calc = price_calculator.calculate_landed_offer(item.price_halalas, fees_info)

        # Unit price per 100g or 100ml
        unit_price_sar = strict_matcher.calculate_unit_price_per_100g_or_ml(
            item.price_halalas, amount, unit
        )

        offer_dict = {
            "id": len(grouped_products[key]["offers"]) + 1,
            "store_code": item.store_code,
            "store_name_ar": item.store_name_ar,
            "store_logo": f"/assets/stores/{item.store_code}.png",
            "branch_name_ar": item.branch_name,
            "price_halalas": item.price_halalas,
            "price_sar": calc.price_sar,
            "original_price_sar": round(item.original_price_halalas / 100.0, 2) if item.original_price_halalas else None,
            "is_on_sale": bool(item.original_price_halalas and item.original_price_halalas > item.price_halalas),
            "is_in_stock": item.is_in_stock,
            "product_url": item.url,
            "deep_link": item.deep_link,
            "promo_conditions": item.promo_conditions,
            "last_verified_at": datetime.utcnow(),
            "delivery_fee_halalas": calc.delivery_fee_halalas,
            "delivery_fee_sar": calc.delivery_fee_sar,
            "service_fee_halalas": calc.service_fee_halalas,
            "total_landed_halalas": calc.total_landed_halalas,
            "total_landed_sar": calc.total_landed_sar,
            "total_status": calc.total_status,
            "total_status_text": calc.total_status_text,
            "is_cheapest_product": False,
            "is_cheapest_total": False,
            "unit_price_per_100g_sar": unit_price_sar
        }

        # Deduplicate store offers per product: keep best price for that store
        existing_offer_idx = next(
            (i for i, o in enumerate(grouped_products[key]["offers"]) if o["store_code"] == item.store_code),
            None
        )
        if existing_offer_idx is not None:
            if item.price_halalas < grouped_products[key]["offers"][existing_offer_idx]["price_halalas"]:
                offer_dict["id"] = grouped_products[key]["offers"][existing_offer_idx]["id"]
                grouped_products[key]["offers"][existing_offer_idx] = offer_dict
        else:
            grouped_products[key]["offers"].append(offer_dict)

    # 3. Synchronize to database cache
    # Rank offers inside each product
    matched_products_out: List[ProductOut] = []
    alternative_sizes_out: List[ProductOut] = []

    has_exact_target = (parsed.target_amount is not None)
    exact_size_matched = False

    dummy_id = 1
    for key, pdata in grouped_products.items():
        # Rank offers inside this product
        ranked_offers = price_calculator.rank_offers(pdata["offers"])

        # Sort offers based on requested mode
        if sort_by == "cheapest_total":
            ranked_offers.sort(
                key=lambda o: (
                    0 if o["total_status"] == "CONFIRMED" else 1,
                    o["total_landed_halalas"] if o["total_landed_halalas"] is not None else 9999999
                )
            )
        else:
            ranked_offers.sort(key=lambda o: o["price_halalas"])

        offers_out = [StoreOfferOut(**o) for o in ranked_offers]

        prod_out = ProductOut(
            id=dummy_id,
            gtin_barcode=pdata["barcode"],
            name_ar=pdata["name_ar"],
            name_en=pdata["name_en"],
            brand_ar=pdata["brand_ar"],
            brand_en=pdata["brand_en"],
            category=pdata["category"],
            sub_category=pdata.get("sub_category"),
            sub_category_rank=pdata.get("sub_category_rank", 10),
            normalized_size_amount=pdata["normalized_size_amount"],
            normalized_size_unit=pdata["normalized_size_unit"],
            pack_count=pdata["pack_count"],
            image_url=pdata["image_url"],
            offers=offers_out
        )
        dummy_id += 1

        # Check if this product strictly matches the user's requested size
        is_exact = strict_matcher.is_exact_match(
            parsed,
            pdata["name_ar"],
            f"{pdata['normalized_size_amount']} {pdata['normalized_size_unit']}"
        )

        if has_exact_target:
            if is_exact:
                exact_size_matched = True
                matched_products_out.append(prod_out)
            else:
                alternative_sizes_out.append(prod_out)
        else:
            # If user didn't specify size, all matching brand items are matched
            matched_products_out.append(prod_out)

    # Sort matched products logically:
    # 1. By sub-category priority (e.g. Fresh Milk before Evaporated Milk)
    # 2. By size descending (e.g. 2L before 1L before 160ml)
    # 3. By name
    matched_products_out.sort(
        key=lambda p: (
            p.sub_category_rank,
            -(p.normalized_size_amount or 0),
            p.name_ar
        )
    )

    # Collect distinct ordered sub-categories for UI filter tabs
    distinct_sub_cats: List[str] = []
    for p in matched_products_out:
        if p.sub_category and p.sub_category not in distinct_sub_cats:
            distinct_sub_cats.append(p.sub_category)

    # 4. Status message determination per strict prompt requirements
    if has_exact_target and not exact_size_matched:
        status_msg = f"لم نجد هذا الحجم ({parsed.raw_query}) في المصادر المفحوصة للمدينة المنورة. عرضنا لك الأحجام البديلة المتوفرة."
    elif matched_products_out:
        status_msg = f"تم العثور على {len(matched_products_out)} منتجات مطابقة في المدينة المنورة."
    else:
        status_msg = "لم نجد نتائج مطابقة لبحثك في المصادر المتصلة حاليًا."

    # Sort alternatives by size
    alternative_sizes_out.sort(key=lambda p: p.normalized_size_amount or 0)

    # Save to db for basket reference
    for p in (matched_products_out + alternative_sizes_out):
        existing_p = db.query(Product).filter(Product.name_ar == p.name_ar).first()
        if not existing_p:
            new_p = Product(
                gtin_barcode=p.gtin_barcode,
                name_ar=p.name_ar,
                name_en=p.name_en,
                brand_ar=p.brand_ar,
                brand_en=p.brand_en,
                category=p.category,
                normalized_size_amount=p.normalized_size_amount,
                normalized_size_unit=p.normalized_size_unit,
                pack_count=p.pack_count,
                image_url=p.image_url
            )
            db.add(new_p)
            db.commit()
            db.refresh(new_p)
            p.id = new_p.id

            # Save offers
            for o in p.offers:
                store_obj = db.query(Store).filter(Store.code == o.store_code).first()
                if not store_obj:
                    store_obj = Store(
                        code=o.store_code,
                        name_ar=o.store_name_ar,
                        name_en=o.store_code.title(),
                        status="connected"
                    )
                    db.add(store_obj)
                    db.commit()
                    db.refresh(store_obj)

                new_offer = StoreOffer(
                    store_id=store_obj.id,
                    product_id=new_p.id,
                    price_halalas=o.price_halalas,
                    is_in_stock=o.is_in_stock,
                    product_url=o.product_url,
                    deep_link=o.deep_link,
                    last_verified_at=o.last_verified_at
                )
                db.add(new_offer)
            db.commit()
        else:
            p.id = existing_p.id

    return SearchResponse(
        query=q,
        district_name=district,
        exact_size_matched=exact_size_matched or not has_exact_target,
        status_message=status_msg,
        disclaimer="الأرخص بين العروض المطابقة التي تم فحصها لموقعك",
        matched_products=matched_products_out,
        alternative_sizes=alternative_sizes_out,
        sub_categories=distinct_sub_cats,
        sources_summary=connector_manager.get_all_statuses()
    )
