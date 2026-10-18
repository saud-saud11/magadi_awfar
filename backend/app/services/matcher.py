import re
from typing import Optional, Tuple, Dict, Any, List
from dataclasses import dataclass

@dataclass
class ParsedQuery:
    raw_query: str
    cleaned_query: str
    brand: Optional[str]
    target_amount: Optional[float]
    target_unit: Optional[str]  # normalized to 'g', 'ml', 'pcs'
    pack_count: int = 1

class StrictMatcher:
    def __init__(self):
        # Arabic numeral conversion
        self.arabic_digits = str.maketrans("٠١٢٣٤٥٦٧٨٩", "0123456789")

    def normalize_text(self, text: str) -> str:
        if not text:
            return ""
        text = text.translate(self.arabic_digits)
        # Remove Arabic diacritics (tashkeel)
        text = re.sub(r'[\u064B-\u0652]', '', text)
        # Normalize alef and hamza
        text = re.sub(r'[إأآا]', 'ا', text)
        # Normalize teh marbuta and heh
        text = re.sub(r'ة', 'ه', text)
        # Normalize ya and alef maqsura
        text = re.sub(r'[يى]', 'ي', text)
        text = re.sub(r'\s+', ' ', text).strip().lower()
        return text

    def parse_size_and_unit(self, text: str) -> Tuple[Optional[float], Optional[str], int]:
        """Extracts normalized amount (in grams or ml) and pack count."""
        normalized = self.normalize_text(text)
        
        # Check pack count (e.g. "2 حبه", "2x", "عبوتين", "عرض حبتين")
        pack_count = 1
        pack_match = re.search(r'(?:عرض\s*)?(\d+)\s*(?:عبوات|عبوه|حبه|حبات|قطع|قطعه|x|×)', normalized)
        if pack_match:
            try:
                pack_count = int(pack_match.group(1))
            except ValueError:
                pass
        elif "عبوتين" in normalized or "حبتين" in normalized:
            pack_count = 2

        # Check special textual fractions
        if "نصف كيلو" in normalized or "نص كيلو" in normalized or "نصف كجم" in normalized:
            return 500.0, "g", pack_count
        if "ربع كيلو" in normalized or "ربع كجم" in normalized:
            return 250.0, "g", pack_count
        if "كيلو ونصف" in normalized or "كيلو ونص" in normalized:
            return 1500.0, "g", pack_count

        # Regular regex for numbers + units
        # e.g., 500g, 500 جرام, 500 غرام, 500 جم, 1 كجم, 1كغم, 1.5 l, 1 لتر
        unit_match = re.search(
            r'(\d+(?:\.\d+)?)\s*(كيلو|كغم|كجم|كغ|جرام|غرام|جم|لتر|مل|kg|gm|ml|g|l)(?![a-zA-Z\u0600-\u06FF])',
            normalized
        )
        if unit_match:
            amount = float(unit_match.group(1))
            unit_str = unit_match.group(2)

            # Normalize to base units: 'g' for mass, 'ml' for liquid volume
            if unit_str in ['كجم', 'كغم', 'كيلو', 'كغ', 'kg']:
                return amount * 1000.0, 'g', pack_count
            elif unit_str in ['جرام', 'غرام', 'جم', 'g', 'gm']:
                return amount, 'g', pack_count
            elif unit_str in ['لتر', 'l']:
                return amount * 1000.0, 'ml', pack_count
            elif unit_str in ['مل', 'ml']:
                return amount, 'ml', pack_count

        return None, None, pack_count

    def parse_query(self, query: str) -> ParsedQuery:
        cleaned = self.normalize_text(query)
        amount, unit, pack_count = self.parse_size_and_unit(cleaned)
        
        # Detect brand if obvious
        brand = None
        if "نوتيلا" in cleaned or "nutella" in cleaned:
            brand = "نوتيلا"
        elif "المراعي" in cleaned or "almarai" in cleaned:
            brand = "المراعي"
        elif "نادك" in cleaned or "nadec" in cleaned:
            brand = "نادك"

        return ParsedQuery(
            raw_query=query,
            cleaned_query=cleaned,
            brand=brand,
            target_amount=amount,
            target_unit=unit,
            pack_count=pack_count
        )

    def is_exact_match(
        self,
        query: ParsedQuery,
        product_title: str,
        raw_size: Optional[str] = None
    ) -> bool:
        """Strict matching. Does NOT confuse 500g with 400g or 750g."""
        item_text = f"{product_title} {raw_size or ''}"
        p_amount, p_unit, p_pack = self.parse_size_and_unit(item_text)

        # If user did not specify size, anything matching brand/name passes
        if query.target_amount is None:
            return True

        # If item has no discernable size but query had one, cannot confirm exact match
        if p_amount is None:
            return False

        # Units must match (e.g. grams vs grams)
        if query.target_unit != p_unit:
            return False

        # Pack count must strictly match (don't mix 1-pack with 2-pack bundle!)
        if query.pack_count != p_pack:
            return False

        # Exact weight check with tight tolerance (within 2% to account for minor rounding)
        diff = abs(query.target_amount - p_amount)
        if diff <= (query.target_amount * 0.02):
            return True

        return False

    def calculate_unit_price_per_100g_or_ml(
        self,
        price_halalas: int,
        amount: Optional[float],
        unit: Optional[str]
    ) -> Optional[float]:
        """Calculates price per 100g or 100ml in SAR for comparison across sizes."""
        if not amount or amount <= 0 or not unit:
            return None
        
        # price in SAR
        price_sar = price_halalas / 100.0
        # price per 100 units
        unit_price = (price_sar / amount) * 100.0
        return round(unit_price, 2)

    def generate_product_key(
        self,
        title_ar: str,
        brand: str,
        amount: Optional[float],
        unit: Optional[str],
        pack: int = 1,
        barcode: Optional[str] = None
    ) -> str:
        """
        Generates a robust unique grouping key for identical grocery products
        across multiple stores without merging distinct sub-types
        (e.g., full-fat vs low-fat milk, laban vs milk, nutella spread vs nutella b-ready).
        """
        norm = self.normalize_text(title_ar)
        words = set(norm.split())

        types = []

        # Dairy categories
        if 'لبن' in words:
            types.append('laban')
        elif any(w in words for w in ['زبادي', 'روب', 'يوغرت']):
            types.append('yoghurt')
        elif 'حليب' in words:
            types.append('milk')
        elif 'جبن' in words or 'جبنه' in words:
            types.append('cheese')
        elif 'قشطه' in words or 'قشطة' in words:
            types.append('cream')

        # Fat / Type modifiers
        if any(p in norm for p in ['قليل الدسم', 'منخفض الدسم', 'لايت', 'light']):
            types.append('lowfat')
        elif any(p in norm for p in ['خالي الدسم', 'منزوع الدسم', 'بدون دسم', 'skimmed']):
            types.append('skimmed')
        elif any(p in norm for p in ['كامل الدسم', 'full fat', 'full cream']):
            types.append('fullfat')
        elif any(p in norm for p in ['طويل الاجل', 'طويل الأجل', 'uht']):
            types.append('uht')
        elif any(p in norm for p in ['بودره', 'مجفف', 'powder']):
            types.append('powder')
        elif any(p in norm for p in ['مبخر', 'evaporated']):
            types.append('evaporated')

        # Confectionery / Spread modifiers
        if any(p in norm for p in ['بي ريدي', 'b-ready', 'b ready']):
            types.append('bready')
        elif any(p in norm for p in ['اند جو', '& go', 'and go']):
            types.append('andgo')
        elif any(p in norm for p in ['بسكويت', 'بسكوت', 'biscuits']):
            types.append('biscuits')
        elif any(p in norm for p in ['قابله للدهن', 'قابلة للدهن', 'كريمه', 'كريمة', 'سبريد', 'spread']):
            types.append('spread')

        # Rice
        if any(p in norm for p in ['مزه', 'مزة', 'سيلا', 'sella']):
            types.append('sella')
        if any(p in norm for p in ['بسمتي', 'basmati']):
            types.append('basmati')
        if any(p in norm for p in ['مصري', 'egyptian', 'صنوايت', 'calrose']):
            types.append('calrose')

        # Oil types (avoiding substring collisions)
        if any(w in words for w in ['ذره', 'ذرة', 'corn']):
            types.append('corn')
        elif any(w in words for w in ['شمس', 'دوار', 'sunflower']):
            types.append('sunflower')
        elif any(w in words for w in ['زيتون', 'olive']):
            types.append('olive')
        elif any(w in words for w in ['قلي', 'نخيل', 'frying']):
            types.append('frying')

        # Flavors
        for flv in ['مانجو', 'فراوله', 'فراولة', 'شوكولاته', 'شوكولاتة', 'موز', 'فانيلا', 'فانيليا']:
            if flv in norm:
                types.append(f'flavor_{flv}')
                break

        # Infant Formula Stages (only for infant/baby milk)
        is_baby = any(w in norm for w in ['اطفال', 'أطفال', 'رضع', 'سيميلاك', 'نان', 'similac', 'nan', 'ابتاميل', 'بليميل', 'بيبيلاك'])
        if is_baby:
            if any(p in norm for p in [' 1 ', ' ١ ', 'رقم 1', 'مرحله 1', 'مرحلة 1', 'أوبتي برو 1', 'اوبتي برو 1', 'جولد 1']):
                types.append('stage1')
            elif any(p in norm for p in [' 2 ', ' ٢ ', 'رقم 2', 'مرحله 2', 'مرحلة 2', 'أوبتي برو 2', 'اوبتي برو 2', 'جولد 2']):
                types.append('stage2')
            elif any(p in norm for p in [' 3 ', ' ٣ ', 'رقم 3', 'مرحله 3', 'مرحلة 3', 'أوبتي برو 3', 'اوبتي برو 3', 'جولد 3']):
                types.append('stage3')

        type_sig = '_'.join(types) if types else 'general'
        return f"{brand}_{type_sig}_{amount}_{unit}_{pack}"

    def get_product_sub_category(self, title_ar: str) -> Tuple[str, int]:
        """
        Classifies product into human-friendly sub-categories with priority rank for clean display.
        Returns: (sub_category_name_ar, priority_rank)
        """
        norm = self.normalize_text(title_ar)
        words = set(norm.split())

        # 1. Milk and Dairy Sub-types
        if any(flv in norm for flv in ['مانجو', 'فراوله', 'فراولة', 'شوكولاته', 'شوكولاتة', 'موز', 'فانيلا', 'فانيليا']) and any(w in norm for w in ['حليب', 'لبن']):
            return ('حليب بالنكهات', 3)
        if 'مبخر' in norm or 'مكثف' in norm:
            return ('حليب مبخر ومكثف', 4)
        if any(p in norm for p in ['بودره', 'مجفف', 'بودرة']):
            return ('حليب مجفف وبودرة', 5)
        if 'لبن' in words or any(w in words for w in ['زبادي', 'روب']):
            return ('ألبان وزبادي طازجة', 6)
        if any(w in words for w in ['جبن', 'جبنه', 'قشطه', 'قشطة', 'كاسات']):
            return ('أجبان وقشطة', 7)
        if any(p in norm for p in ['طويل الاجل', 'طويل الأجل', 'uht']):
            return ('حليب طويل الأجل', 2)
        if 'حليب' in words or 'طازج' in words:
            return ('حليب طازج', 1)

        # 2. Chocolate Spread / Nutella Sub-types
        if any(p in norm for p in ['بي ريدي', 'b-ready', 'b ready']):
            return ('ويفر نوتيلا بي-ريدي', 2)
        if any(p in norm for p in ['اند جو', '& go', 'and go']):
            return ('نوتيلا آند جو', 3)
        if any(p in norm for p in ['بسكويت', 'بسكوت', 'biscuits']):
            return ('بسكويت نوتيلا', 4)
        if 'نوتيلا' in norm or 'نوسيلا' in norm or 'شوكولاته' in norm or 'شوكولاتة' in norm:
            return ('شوكولاتة قابلة للدهن', 1)

        # 3. Rice Sub-types
        if 'ارز' in words or 'أرز' in words:
            if 'مزه' in norm or 'سيلا' in norm:
                return ('أرز مزة بسمتي', 1)
            elif 'بسمتي' in norm or 'عنبر' in norm:
                return ('أرز بسمتي أبيض', 2)
            elif 'مصري' in norm or 'صنوايت' in norm:
                return ('أرز مصري', 3)
            return ('أرز وحبوب', 1)

        # 4. Oil Sub-types
        if 'زيت' in words:
            if 'ذره' in norm or 'ذرة' in norm:
                return ('زيت ذرة نقي', 1)
            elif 'شمس' in norm or 'دوار' in norm:
                return ('زيت دوار الشمس', 2)
            elif 'زيتون' in norm:
                return ('زيت زيتون', 3)
            elif 'قلي' in norm:
                return ('زيت للقلي والطبخ', 4)
            return ('زيوت طعام', 1)

        # 5. Sugar & Staples
        if 'سكر' in words:
            return ('سكر ومحليات', 1)
        if 'شاي' in words:
            if 'كيس' in norm or 'اكياس' in norm or 'أكياس' in norm:
                return ('شاي أكياس', 1)
            return ('شاي فرط وأوراق', 2)
        if 'بيض' in words:
            return ('بيض طازج', 1)
        if 'تونه' in words or 'تونة' in words:
            return ('تونة ومعلبات', 1)

        # 6. Infant Nutrition / Pharmacies
        if any(w in norm for w in ['سيميلاك', 'نان', 'اطفال', 'أطفال', 'رضع']):
            if '1' in norm or '١' in norm:
                return ('حليب أطفال - مرحلة 1', 1)
            elif '2' in norm or '٢' in norm:
                return ('حليب أطفال - مرحلة 2', 2)
            elif '3' in norm or '٣' in norm:
                return ('حليب أطفال - مرحلة 3', 3)
            return ('تغذية ورعاية الأطفال', 1)

        return ('عروض مطابقة', 10)

strict_matcher = StrictMatcher()
