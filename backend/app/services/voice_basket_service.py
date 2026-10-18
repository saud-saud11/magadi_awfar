import re
import copy
from typing import List, Dict, Any, Optional, Tuple
from app.models.models import Product, StoreOffer
from app.services.matcher import strict_matcher
from app.schemas.schemas import VoiceBasketItemOut, VoiceParseResponse

# Default Category Configurations (Section 6: الافتراضات المنطقية)
DEFAULT_CATEGORY_CONFIGS = {
    "milk": {
        "default_size_amount": 1000.0,
        "default_size_unit": "ml",
        "default_variant": "كامل الدسم",
        "large_size_amount": 2000.0,
        "small_sample_amount": 200.0,
        "default_brand": "السعودية"
    },
    "cheese": {
        "default_size_amount": 216.0,  # 12 portions
        "default_size_unit": "g",
        "default_variant": "مربعات",
        "large_size_amount": 432.0,   # 24 portions
        "default_brand": "كيري"
    },
    "toast": {
        "default_size_amount": 600.0,
        "default_size_unit": "g",
        "default_variant": "أبيض فاخر",
        "default_brand": "لوزين"
    },
    "spread": {
        "default_size_amount": 400.0,
        "default_size_unit": "g",
        "default_variant": "بندق وكاكاو",
        "large_size_amount": 750.0,
        "default_brand": "نوتيلا"
    },
    "oil": {
        "default_size_amount": 1500.0,
        "default_size_unit": "ml",
        "large_size_amount": 2900.0,
        "default_brand": "عافية"
    },
    "rice": {
        "default_size_amount": 5000.0,
        "default_size_unit": "g",
        "large_size_amount": 10000.0,
        "default_brand": "الشعلان"
    },
    "sugar": {
        "default_size_amount": 5000.0,
        "default_size_unit": "g",
        "large_size_amount": 10000.0,
        "default_brand": "الأسرة"
    },
    "tea": {
        "default_size_amount": 100.0,
        "default_size_unit": "bags",
        "default_brand": "ليبتون"
    },
    "eggs": {
        "default_size_amount": 30.0,
        "default_size_unit": "pcs",
        "default_brand": "فقيه"
    },
    "juice": {
        "default_size_amount": 1000.0,
        "default_size_unit": "ml",
        "default_brand": "المراعي"
    }
}

class VoiceBasketService:
    def __init__(self):
        # In-memory session tracking: session_id -> {basket, history, processed_request_ids, last_active_id}
        self.sessions: Dict[str, Dict[str, Any]] = {}

    def get_session(self, session_id: str) -> Dict[str, Any]:
        if session_id not in self.sessions:
            self.sessions[session_id] = {
                "basket": [],  # List of VoiceBasketItemOut dicts
                "history": [], # Stack of previous basket states for undo
                "processed_request_ids": set(),
                "last_active_item_id": None
            }
        return self.sessions[session_id]

    def undo_last_action(self, session_id: str) -> Tuple[bool, str, List[VoiceBasketItemOut]]:
        session = self.get_session(session_id)
        if not session["history"]:
            return False, "لا توجد عمليات سابقة للتراجع عنها", [VoiceBasketItemOut(**i) for i in session["basket"]]

        # Revert to last snapshot
        previous_basket = session["history"].pop()
        session["basket"] = previous_basket
        if session["basket"]:
            session["last_active_item_id"] = session["basket"][-1]["product_id"]
        else:
            session["last_active_item_id"] = None

        return True, "تم التراجع عن آخر تعديل بنجاح", [VoiceBasketItemOut(**i) for i in session["basket"]]

    def parse_and_execute(
        self,
        db_session,
        query: str,
        session_id: str = "default_session",
        request_id: Optional[str] = None,
        user_preferences: Optional[Dict[str, Any]] = None
    ) -> VoiceParseResponse:
        session = self.get_session(session_id)

        # 1. Idempotency Check: prevent duplicate additions if STT repeated request
        if request_id and request_id in session["processed_request_ids"]:
            current_out = [VoiceBasketItemOut(**i) for i in session["basket"]]
            return VoiceParseResponse(
                status="success",
                recognized_text=query,
                intent="duplicate_request_ignored",
                message_ar="تم تنفيذ هذا الطلب مسبقاً (تم منع الإضافة المكررة)",
                current_basket=current_out,
                can_undo=len(session["history"]) > 0,
                session_id=session_id
            )

        q_norm = strict_matcher.normalize_text(query).strip()

        # Handle empty query (e.g. initial fetch of session)
        if not q_norm:
            current_out = [VoiceBasketItemOut(**i) for i in session["basket"]]
            return VoiceParseResponse(
                status="success",
                recognized_text="",
                intent="fetch_session",
                message_ar="جاهز للاستماع لأمرك الصوتي",
                current_basket=current_out,
                can_undo=len(session["history"]) > 0,
                session_id=session_id
            )

        # 2. Check Undo Commands («رجّع آخر تعديل»، «تراجع»، «الغِ آخر عملية»)
        if any(w in q_norm for w in ["تراجع", "رجع اخر تعديل", "الغ اخر تعديل", "الغي اخر عملية", "رجع اخر شي"]):
            success, msg, basket_out = self.undo_last_action(session_id)
            if request_id:
                session["processed_request_ids"].add(request_id)
            return VoiceParseResponse(
                status="success" if success else "no_op",
                recognized_text=query,
                intent="undo",
                message_ar=msg,
                current_basket=basket_out,
                can_undo=len(session["history"]) > 0,
                session_id=session_id
            )

        # 3. Check Negation Commands («لا تضيف عصير»، «بدون عصير»، «ولا تحط عصير»)
        negation_match = re.search(r"(?:لا\s+تضيف|بدون|لا\s+تحط|ما\s+ابي|ما\s+ابغى)\s+([^\n\r,]+)", q_norm)
        if negation_match and ("ابي" not in q_norm or q_norm.startswith("لا") or "بدون" in q_norm):
            negated_term = negation_match.group(1).strip()
            # Ensure it is NOT added or if it is already in basket, do not duplicate/remove
            current_out = [VoiceBasketItemOut(**i) for i in session["basket"]]
            if request_id:
                session["processed_request_ids"].add(request_id)
            return VoiceParseResponse(
                status="success",
                recognized_text=query,
                intent="negation",
                message_ar=f"تم استبعاد «{negated_term}» ولم تتم إضافته إلى السلة بناءً على طلبك",
                current_basket=current_out,
                can_undo=len(session["history"]) > 0,
                session_id=session_id
            )

        # Snapshot state before modification for Undo
        session["history"].append(copy.deepcopy(session["basket"]))

        # 4. Check Contextual Conversational Adjustments
        # Case A: «لا خله كبير» or «خله كبير» (Size modification on last active item)
        if any(w in q_norm for w in ["خله كبير", "خله الحجم الكبير", "الحجم الكبير", "كبره", "لا خله كبير"]):
            return self._handle_modify_size(db_session, session, query, request_id, session_id, target_size="large")

        # Case B: «زيد واحدة» or «زيد حبة» (Increment quantity)
        if any(w in q_norm for w in ["زيد واحده", "زيد حبه", "زيد واحد", "زود حبه", "اضف حبه", "زيد 1"]):
            return self._handle_modify_quantity_delta(db_session, session, query, request_id, session_id, delta=1)

        # Case C: «خله اثنين» or «خلها حبتين» or «سوه اثنين» (Set absolute quantity)
        qty_match = re.search(r"(?:خله|خلها|خليه|خليهم|سوه|حط)\s+(\d+|اثنين|ثلاثه|اربعه|خمسه)", q_norm)
        if qty_match:
            qty_word = qty_match.group(1)
            target_qty = self._parse_arabic_number(qty_word)
            return self._handle_modify_quantity_absolute(db_session, session, query, request_id, session_id, target_qty=target_qty)

        # Case D: «شيل التوست» or «شيله» (Removal)
        if any(w in q_norm for w in ["شيل", "احذف", "امسح", "طلع"]):
            return self._handle_remove_item(session, query, q_norm, request_id, session_id)

        # 5. Compound / Multi-Item Addition
        # Example: «أبي حليب السعودية واثنين جبن كيري وخبز توست»
        return self._handle_add_items(db_session, session, query, q_norm, request_id, session_id, user_preferences)

    # -------------------------------------------------------------
    # Helper Handlers
    # -------------------------------------------------------------
    def _handle_modify_size(self, db_session, session, query, request_id, session_id, target_size="large") -> VoiceParseResponse:
        if not session["basket"]:
            return VoiceParseResponse(
                status="no_op",
                recognized_text=query,
                intent="change_size_or_type",
                message_ar="السلة فارغة حالياً، أضف منتجاً أولاً لتعديل حجمه",
                session_id=session_id
            )

        # Find target item (last active item or most recent)
        target_idx = len(session["basket"]) - 1
        last_item = session["basket"][target_idx]

        # Determine new size
        brand = last_item.get("brand_ar", "")
        name = last_item.get("name_ar", "")

        # Look up large variant in database or catalog
        category_key = self._detect_category_key(name)
        cfg = DEFAULT_CATEGORY_CONFIGS.get(category_key, {})
        new_size_amount = cfg.get("large_size_amount", 2000.0 if cfg.get("default_size_unit") == "ml" else 750.0)
        new_size_unit = cfg.get("default_size_unit", "ml")

        # Find matching large product in DB
        large_prod = (
            db_session.query(Product)
            .filter(
                Product.brand_ar == brand,
                Product.normalized_size_amount == new_size_amount
            )
            .first()
        )

        if not large_prod:
            # Fallback search by title
            large_prod = (
                db_session.query(Product)
                .filter(
                    Product.name_ar.like(f"%{brand}%"),
                    Product.normalized_size_amount == new_size_amount
                )
                .first()
            )

        if large_prod:
            session["basket"][target_idx]["product_id"] = large_prod.id
            session["basket"][target_idx]["name_ar"] = large_prod.name_ar
            session["basket"][target_idx]["size_amount"] = large_prod.normalized_size_amount
            session["basket"][target_idx]["size_unit"] = large_prod.normalized_size_unit
        else:
            # Update virtual record
            session["basket"][target_idx]["size_amount"] = new_size_amount
            session["basket"][target_idx]["size_unit"] = new_size_unit
            session["basket"][target_idx]["name_ar"] = session["basket"][target_idx]["name_ar"].replace("١ لتر", "٢ لتر").replace("1L", "2L")

        if request_id:
            session["processed_request_ids"].add(request_id)

        current_out = [VoiceBasketItemOut(**i) for i in session["basket"]]
        modified_out = [VoiceBasketItemOut(**session["basket"][target_idx])]

        return VoiceParseResponse(
            status="success",
            recognized_text=query,
            intent="change_size_or_type",
            message_ar=f"تم تعديل الحجم إلى الحجم الكبير ({new_size_amount} {new_size_unit}) لصنف «{session['basket'][target_idx]['name_ar']}» دون إضافة بند مكرر",
            items_modified=modified_out,
            current_basket=current_out,
            can_undo=True,
            session_id=session_id
        )

    def _handle_modify_quantity_delta(self, db_session, session, query, request_id, session_id, delta=1) -> VoiceParseResponse:
        if not session["basket"]:
            return VoiceParseResponse(
                status="no_op",
                recognized_text=query,
                intent="change_quantity",
                message_ar="السلة فارغة، أضف منتجاً أولاً لتعديل كميته",
                session_id=session_id
            )

        target_idx = len(session["basket"]) - 1
        session["basket"][target_idx]["quantity"] += delta

        if request_id:
            session["processed_request_ids"].add(request_id)

        current_out = [VoiceBasketItemOut(**i) for i in session["basket"]]
        modified_out = [VoiceBasketItemOut(**session["basket"][target_idx])]

        return VoiceParseResponse(
            status="success",
            recognized_text=query,
            intent="change_quantity",
            message_ar=f"تمت زيادة كمية «{session['basket'][target_idx]['name_ar']}» بواحد لتصبح {session['basket'][target_idx]['quantity']} حبات",
            items_modified=modified_out,
            current_basket=current_out,
            can_undo=True,
            session_id=session_id
        )

    def _handle_modify_quantity_absolute(self, db_session, session, query, request_id, session_id, target_qty=2) -> VoiceParseResponse:
        if not session["basket"]:
            return VoiceParseResponse(
                status="no_op",
                recognized_text=query,
                intent="change_quantity",
                message_ar="السلة فارغة، أضف منتجاً أولاً لتعديل كميته",
                session_id=session_id
            )

        target_idx = len(session["basket"]) - 1
        session["basket"][target_idx]["quantity"] = target_qty

        if request_id:
            session["processed_request_ids"].add(request_id)

        current_out = [VoiceBasketItemOut(**i) for i in session["basket"]]
        modified_out = [VoiceBasketItemOut(**session["basket"][target_idx])]

        return VoiceParseResponse(
            status="success",
            recognized_text=query,
            intent="change_quantity",
            message_ar=f"تم ضبط كمية «{session['basket'][target_idx]['name_ar']}» لتصبح {target_qty} حبات بالضبط",
            items_modified=modified_out,
            current_basket=current_out,
            can_undo=True,
            session_id=session_id
        )

    def _handle_remove_item(self, session, query, q_norm, request_id, session_id) -> VoiceParseResponse:
        if not session["basket"]:
            return VoiceParseResponse(
                status="no_op",
                recognized_text=query,
                intent="remove_item",
                message_ar="السلة فارغة بالفعل",
                session_id=session_id
            )

        # Check if user specified a name, e.g. «شيل التوست»
        target_name = None
        for item in session["basket"]:
            brand = (item.get("brand_ar") or "").lower()
            name = item["name_ar"].lower()
            if "توست" in q_norm and ("توست" in name or "لوزين" in name):
                target_name = item["name_ar"]
                break
            elif "كيري" in q_norm and "كيري" in name:
                target_name = item["name_ar"]
                break
            elif "حليب" in q_norm and "حليب" in name:
                target_name = item["name_ar"]
                break

        # If user just said «شيله» without name
        if not target_name:
            if len(session["basket"]) == 1:
                target_name = session["basket"][0]["name_ar"]
            else:
                # Ambiguous: multiple items in basket! Ask clarification question!
                options = [item["name_ar"] for item in session["basket"]]
                return VoiceParseResponse(
                    status="clarification_needed",
                    recognized_text=query,
                    intent="clarify",
                    message_ar="أي صنف تود حذفه من السلة؟",
                    clarification_question="توجد عدة أصناف في السلة، يرجى تحديد الصنف المراد حذفه:",
                    clarification_options=options,
                    current_basket=[VoiceBasketItemOut(**i) for i in session["basket"]],
                    can_undo=True,
                    session_id=session_id
                )

        # Remove the item
        session["basket"] = [i for i in session["basket"] if i["name_ar"] != target_name]
        if request_id:
            session["processed_request_ids"].add(request_id)

        current_out = [VoiceBasketItemOut(**i) for i in session["basket"]]
        return VoiceParseResponse(
            status="success",
            recognized_text=query,
            intent="remove_item",
            message_ar=f"تم حذف «{target_name}» من سلة المشتريات",
            items_removed=[target_name],
            current_basket=current_out,
            can_undo=True,
            session_id=session_id
        )

    def _handle_add_items(self, db_session, session, query, q_norm, request_id, session_id, user_preferences) -> VoiceParseResponse:
        # Split multiple items joined by 'و', 'واثنين', 'مع'
        chunks = self._split_compound_utterance(q_norm)
        added_items: List[VoiceBasketItemOut] = []

        for chunk in chunks:
            raw_chunk = chunk.strip()
            if not raw_chunk or len(raw_chunk) < 2:
                continue

            # Extract quantity (e.g. «حبتين حليب السعودية», «اثنين جبن كيري»)
            qty, item_phrase = self._extract_quantity_from_chunk(raw_chunk)

            # Extract size if explicitly mentioned (e.g. «لتر»، «نصف كيلو»، «٥٠٠ جرام»)
            amount, unit, pack = strict_matcher.parse_size_and_unit(item_phrase)

            # Check explicit constraints (خالي اللاكتوز، قليل الدسم، كامل الدسم)
            is_lactose_free = ("لاكتوز" in item_phrase)
            is_low_fat = ("قليل الدسم" in item_phrase or "خفيف" in item_phrase)
            is_full_fat = ("كامل الدسم" in item_phrase)

            # Detect category and defaults
            cat_key = self._detect_category_key(item_phrase)
            cfg = DEFAULT_CATEGORY_CONFIGS.get(cat_key, {})

            # Priority order: Explicit > Saved user preferences > Category defaults
            if amount is None:
                pref_size = (user_preferences or {}).get(f"{cat_key}_size")
                if pref_size:
                    amount, unit = pref_size.get("amount"), pref_size.get("unit")
                else:
                    amount = cfg.get("default_size_amount", 1.0)
                    unit = cfg.get("default_size_unit", "l")

            # Resolve to real database product
            product_record = self._resolve_db_product(
                db_session=db_session,
                phrase=item_phrase,
                cat_key=cat_key,
                target_amount=amount,
                target_unit=unit,
                is_lactose_free=is_lactose_free,
                is_low_fat=is_low_fat,
                is_full_fat=is_full_fat
            )

            if product_record:
                p_out = VoiceBasketItemOut(
                    product_id=product_record.id,
                    name_ar=product_record.name_ar,
                    brand_ar=product_record.brand_ar,
                    quantity=qty,
                    size_amount=product_record.normalized_size_amount or amount,
                    size_unit=product_record.normalized_size_unit or unit,
                    image_url=product_record.image_url,
                    notes="خالي اللاكتوز" if is_lactose_free else ("قليل الدسم" if is_low_fat else None)
                )
            else:
                # Logical fallback from catalog specs
                brand_name = cfg.get("default_brand", "عام")
                title = f"{item_phrase} {amount or ''} {unit or ''}".strip()
                p_out = VoiceBasketItemOut(
                    product_id=len(session["basket"]) + len(added_items) + 100,
                    name_ar=title,
                    brand_ar=brand_name,
                    quantity=qty,
                    size_amount=amount,
                    size_unit=unit,
                    image_url="https://d1c124wpoew66.cloudfront.net/spree/images/attachments/000/135/911/product/80176800-1.jpg",
                    notes="مطابقة افتراضية"
                )

            # Check if this item is already in session basket
            existing = next((i for i in session["basket"] if i["product_id"] == p_out.product_id), None)
            if existing:
                existing["quantity"] += qty
            else:
                session["basket"].append(p_out.model_dump())

            session["last_active_item_id"] = p_out.product_id
            added_items.append(p_out)

        if request_id:
            session["processed_request_ids"].add(request_id)

        current_out = [VoiceBasketItemOut(**i) for i in session["basket"]]

        if not added_items:
            # Revert the snapshot so history isn't polluted
            if session["history"]:
                session["history"].pop()
            return VoiceParseResponse(
                status="no_op",
                recognized_text=query,
                intent="unrecognized",
                message_ar="لم نتمكن من تحديد منتجات في هذا الطلب، يرجى التحديد بوضوح (مثال: حليب، جبن، خبز)",
                items_added=[],
                current_basket=current_out,
                can_undo=len(session["history"]) > 0,
                session_id=session_id
            )

        names_str = "، ".join([f"«{it.name_ar}» ({it.quantity} حبة)" for it in added_items])

        return VoiceParseResponse(
            status="success",
            recognized_text=query,
            intent="add_items",
            message_ar=f"تمت إضافة {names_str} إلى سلة المقارنة بنجاح",
            items_added=added_items,
            current_basket=current_out,
            can_undo=True,
            session_id=session_id
        )

    # -------------------------------------------------------------
    # Query Analysis & Database Resolution
    # -------------------------------------------------------------
    def _split_compound_utterance(self, q_norm: str) -> List[str]:
        # Remove common introductory words
        cleaned = re.sub(r"^(?:ابي|ابغى|اريد|اضف|حط|سجل|ضيف|محتاج)\s+", "", q_norm).strip()
        
        # Separate proclitic Arabic conjunction 'و' when followed by numbers or food keywords
        spaced = re.sub(
            r"\bو(?=اثنين|ثنتين|ثلاث|اربع|خمس|واحد|حبه|حبتين|علبه|علبتين|حليب|جبن|كيري|خبز|توست|نوتيلا|عصير|زيت|رز|شاي|سكر|بيض|لبن|زبادي)",
            "و ",
            cleaned
        )
        
        # Split on ' و ' or ' مع ' or commas
        chunks = re.split(r"(?:\s+و\s+|\s+مع\s+|\s*,\s*|\s*،\s*)", spaced)
        return [c.strip() for c in chunks if c.strip()]

    def _extract_quantity_from_chunk(self, chunk: str) -> Tuple[int, str]:
        # Check for dual form (حبتين، علبتين، كرتونين)
        if re.search(r"\b(حبتين|علبتين|عبوتين|قارورتين|قطعتين)\b", chunk):
            cleaned = re.sub(r"\b(حبتين|علبتين|عبوتين|قارورتين|قطعتين)\b", "", chunk).strip()
            return 2, cleaned

        # Check for numeric word (اثنين، ثنتين، 2)
        match_two = re.search(r"\b(اثنين|ثنتين|حبتين|2|٢)\b", chunk)
        if match_two:
            cleaned = re.sub(r"\b(اثنين|ثنتين|حبتين|2|٢)\b", "", chunk).strip()
            return 2, cleaned

        # Check for other numbers (ثلاثة، اربعة، 3، 4)
        num_match = re.search(r"\b(\d+|ثلاثه|ثلاث|اربعه|اربع|خمسه|خمس)\b", chunk)
        if num_match:
            word = num_match.group(1)
            qty = self._parse_arabic_number(word)
            cleaned = re.sub(r"\b" + re.escape(word) + r"\b", "", chunk).strip()
            return qty, cleaned

        # Default quantity: 1 unit (Section 6)
        return 1, chunk

    def _parse_arabic_number(self, word: str) -> int:
        mapping = {
            "واحد": 1, "واحده": 1, "1": 1, "١": 1,
            "اثنين": 2, "ثنتين": 2, "حبتين": 2, "2": 2, "٢": 2,
            "ثلاثه": 3, "ثلاث": 3, "3": 3, "٣": 3,
            "اربعه": 4, "اربع": 4, "4": 4, "٤": 4,
            "خمسه": 5, "خمس": 5, "5": 5, "٥": 5,
        }
        return mapping.get(word, 1)

    def _detect_category_key(self, text: str) -> str:
        t = text.lower()
        if "حليب" in t or "لبن" in t:
            return "milk"
        elif "كيري" in t or "جبن" in t or "جبنة" in t:
            return "cheese"
        elif "توست" in t or "خبز" in t or "لوزين" in t:
            return "toast"
        elif "نوتيلا" in t or "نوسيلا" in t or "شوكولاتة" in t:
            return "spread"
        elif "زيت" in t or "عافية" in t or "عافيه" in t:
            return "oil"
        elif "رز" in t or "أرز" in t or "شعلان" in t:
            return "rice"
        elif "سكر" in t or "الأسرة" in t:
            return "sugar"
        elif "شاي" in t or "ليبتون" in t:
            return "tea"
        elif "بيض" in t:
            return "eggs"
        elif "عصير" in t:
            return "juice"
        return "general"

    def _resolve_db_product(
        self,
        db_session,
        phrase: str,
        cat_key: str,
        target_amount: Optional[float],
        target_unit: Optional[str],
        is_lactose_free: bool = False,
        is_low_fat: bool = False,
        is_full_fat: bool = False
    ) -> Optional[Product]:
        q_norm = strict_matcher.normalize_text(phrase)
        query = db_session.query(Product)

        # 1. Filter by category or brand
        if "سعودي" in q_norm:
            query = query.filter(Product.brand_ar.like("%سعودي%"))
        elif "مراعي" in q_norm:
            query = query.filter(Product.brand_ar.like("%مراعي%"))
        elif "كيري" in q_norm:
            query = query.filter(Product.brand_ar.like("%كيري%"))
        elif "توست" in q_norm or "لوزين" in q_norm:
            query = query.filter(Product.name_ar.like("%توست%") | Product.brand_ar.like("%لوزين%"))
        elif "نوتيلا" in q_norm:
            query = query.filter(Product.brand_ar.like("%نوتيلا%"))
        elif "نوسيلا" in q_norm:
            query = query.filter(Product.brand_ar.like("%نوسيلا%"))
        elif cat_key == "milk":
            # If brand not specified, default to Saudia per config
            query = query.filter(Product.brand_ar.like("%سعودي%"))

        # 2. Strict Variant Filters (خالي اللاكتوز / قليل الدسم / كامل الدسم)
        if is_lactose_free:
            query = query.filter(Product.name_ar.like("%لاكتوز%"))
        elif is_low_fat:
            query = query.filter(Product.name_ar.like("%قليل الدسم%"))
        elif is_full_fat:
            query = query.filter(Product.name_ar.like("%كامل الدسم%"))
        elif cat_key == "milk":
            # Default milk variant is full fat per Section 6
            full_fat_check = query.filter(Product.name_ar.like("%كامل الدسم%"))
            if full_fat_check.first():
                query = full_fat_check

        # 3. Match Target Amount if specified
        if target_amount is not None:
            # Query with exact size
            exact_prod = query.filter(Product.normalized_size_amount == target_amount).first()
            if exact_prod:
                return exact_prod

        # 4. Return standard first matching product
        return query.first()

voice_basket_service = VoiceBasketService()
