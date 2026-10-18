from typing import List, Dict, Any, Optional
from app.models.models import Product, StoreOffer, Store
from app.connectors.manager import connector_manager
from app.schemas.schemas import StoreBasketResult, BasketCompareResponse

class BasketService:
    def compare_basket(
        self,
        db_session,
        items: List[Dict[str, int]],  # [{"product_id": 1, "quantity": 2}, ...]
        district_name: str = "سلطانة"
    ) -> BasketCompareResponse:
        
        # Load all products requested
        product_ids = [item["product_id"] for item in items]
        products = db_session.query(Product).filter(Product.id.in_(product_ids)).all()
        product_map = {p.id: p for p in products}

        # Load stores
        stores = db_session.query(Store).filter(Store.is_enabled == True).all()

        store_results: List[StoreBasketResult] = []

        for st in stores:
            connector = connector_manager.get_connector(st.code)
            fees = connector.get_fees_info(district_name) if connector else {}
            base_delivery = fees.get("base_delivery_fee_halalas", st.base_delivery_fee_halalas)
            free_thresh = fees.get("free_delivery_threshold_halalas", st.free_delivery_threshold_halalas)

            subtotal_halalas = 0
            available_count = 0
            missing_items: List[str] = []

            for item in items:
                p_id = item["product_id"]
                qty = item["quantity"]
                prod = product_map.get(p_id)
                if not prod:
                    continue

                # Find valid in-stock offer for this product in this store
                offer = (
                    db_session.query(StoreOffer)
                    .filter(
                        StoreOffer.store_id == st.id,
                        StoreOffer.product_id == p_id,
                        StoreOffer.is_in_stock == True
                    )
                    .order_by(StoreOffer.price_halalas.asc())
                    .first()
                )

                if offer:
                    available_count += 1
                    subtotal_halalas += (offer.price_halalas * qty)
                else:
                    missing_items.append(prod.name_ar)

            is_complete = (len(missing_items) == 0 and len(items) > 0)
            
            # Delivery fee calculation
            if base_delivery is None:
                delivery_fee_halalas = None
                delivery_fee_sar = None
                total_halalas = None
                total_sar = None
                total_status_text = "الإجمالي يُؤكد لدى المتجر (رسوم التوصيل غير محددة)"
            else:
                effective_delivery = base_delivery
                if free_thresh and subtotal_halalas >= free_thresh:
                    effective_delivery = 0
                delivery_fee_halalas = effective_delivery
                delivery_fee_sar = round(effective_delivery / 100.0, 2)
                total_halalas = subtotal_halalas + effective_delivery
                total_sar = round(total_halalas / 100.0, 2)
                total_status_text = "مؤكد شامل التوصيل"

            store_results.append(StoreBasketResult(
                store_code=st.code,
                store_name_ar=st.name_ar,
                store_logo=st.logo_url,
                is_complete=is_complete,
                available_items_count=available_count,
                total_items_count=len(items),
                missing_items=missing_items,
                subtotal_halalas=subtotal_halalas,
                subtotal_sar=round(subtotal_halalas / 100.0, 2),
                delivery_fee_halalas=delivery_fee_halalas,
                delivery_fee_sar=delivery_fee_sar,
                total_halalas=total_halalas,
                total_sar=total_sar,
                total_status_text=total_status_text,
                is_cheapest_complete_basket=False
            ))

        # Mark the cheapest complete basket
        complete_baskets = [
            b for b in store_results
            if b.is_complete and b.total_halalas is not None
        ]

        if complete_baskets:
            min_basket = min(complete_baskets, key=lambda b: b.total_halalas)
            min_basket.is_cheapest_complete_basket = True

        # Sort: complete baskets first (by total price), then incomplete baskets
        store_results.sort(
            key=lambda b: (
                0 if b.is_complete else 1,
                b.total_halalas if b.total_halalas is not None else 9999999
            )
        )

        # Split basket suggestion: test if buying each item from its absolute cheapest store beats single store
        split_suggestion = self._analyze_split_basket(db_session, items, store_results, district_name)

        return BasketCompareResponse(
            district_name=district_name,
            stores=store_results,
            split_basket_suggestion=split_suggestion
        )

    def _analyze_split_basket(
        self,
        db_session,
        items: List[Dict[str, int]],
        single_store_results: List[StoreBasketResult],
        district_name: str
    ) -> Optional[Dict[str, Any]]:
        # Calculate item-level best prices
        store_items_grouped: Dict[str, List[Dict[str, Any]]] = {}
        total_items_halalas = 0

        for item in items:
            p_id = item["product_id"]
            qty = item["quantity"]
            
            # Find cheapest offer across all stores
            best_offer = (
                db_session.query(StoreOffer, Store)
                .join(Store, Store.id == StoreOffer.store_id)
                .filter(
                    StoreOffer.product_id == p_id,
                    StoreOffer.is_in_stock == True,
                    Store.is_enabled == True
                )
                .order_by(StoreOffer.price_halalas.asc())
                .first()
            )

            if best_offer:
                offer, store = best_offer
                if store.code not in store_items_grouped:
                    store_items_grouped[store.code] = []
                store_items_grouped[store.code].append({
                    "product_id": p_id,
                    "quantity": qty,
                    "price_halalas": offer.price_halalas
                })
                total_items_halalas += (offer.price_halalas * qty)

        # Check total delivery fees for split stores
        split_delivery_total = 0
        all_fees_known = True

        for s_code, s_items in store_items_grouped.items():
            connector = connector_manager.get_connector(s_code)
            fees = connector.get_fees_info(district_name) if connector else {}
            base_delivery = fees.get("base_delivery_fee_halalas")
            if base_delivery is None:
                all_fees_known = False
                break
            
            store_subtotal = sum(i["price_halalas"] * i["quantity"] for i in s_items)
            free_thresh = fees.get("free_delivery_threshold_halalas")
            if free_thresh and store_subtotal >= free_thresh:
                effective_delivery = 0
            else:
                effective_delivery = base_delivery
            split_delivery_total += effective_delivery

        if not all_fees_known or len(store_items_grouped) <= 1:
            return None

        split_total_halalas = total_items_halalas + split_delivery_total

        # Compare with best single complete basket
        complete_singles = [b for b in single_store_results if b.is_complete and b.total_halalas]
        if not complete_singles:
            return None

        best_single = min(complete_singles, key=lambda b: b.total_halalas)
        savings_halalas = best_single.total_halalas - split_total_halalas

        if savings_halalas > 0:
            return {
                "stores_count": len(store_items_grouped),
                "store_codes": list(store_items_grouped.keys()),
                "split_total_sar": round(split_total_halalas / 100.0, 2),
                "combined_delivery_fees_sar": round(split_delivery_total / 100.0, 2),
                "net_savings_sar": round(savings_halalas / 100.0, 2),
                "recommendation_text": f"تقسيم السلة بين {len(store_items_grouped)} متاجر يوفر لك {round(savings_halalas / 100.0, 2)} ر.س بعد احتساب رسوم التوصيل المنفصلة لكل متجر."
            }

        return None

basket_service = BasketService()
