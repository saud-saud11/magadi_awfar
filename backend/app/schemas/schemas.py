from datetime import datetime
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field, ConfigDict

class DistrictBase(BaseModel):
    name_ar: str
    name_en: Optional[str] = None
    city: str = "المدينة المنورة"
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class DistrictOut(DistrictBase):
    id: int

    model_config = ConfigDict(from_attributes=True)

class StoreBase(BaseModel):
    code: str
    name_ar: str
    name_en: str
    status: str
    status_reason: Optional[str] = None
    logo_url: Optional[str] = None
    is_enabled: bool = True
    base_delivery_fee_halalas: Optional[int] = None
    free_delivery_threshold_halalas: Optional[int] = None
    min_order_halalas: Optional[int] = None
    service_fee_halalas: Optional[int] = None
    update_interval_minutes: int = 60

class StoreOut(StoreBase):
    id: int
    last_sync_at: Optional[datetime] = None
    last_error: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

class StoreOfferOut(BaseModel):
    price_verified: bool = False
    stock_known: bool = False
    source_url: Optional[str] = None
    id: int
    store_code: str
    store_name_ar: str
    store_logo: Optional[str] = None
    branch_name_ar: Optional[str] = None
    price_halalas: int
    price_sar: float
    original_price_sar: Optional[float] = None
    is_on_sale: bool = False
    is_in_stock: bool = True
    product_url: str
    deep_link: Optional[str] = None
    promo_conditions: Optional[str] = None
    last_verified_at: datetime
    
    # Landed Cost
    delivery_fee_halalas: Optional[int] = None
    delivery_fee_sar: Optional[float] = None
    service_fee_halalas: Optional[int] = None
    total_landed_halalas: Optional[int] = None
    total_landed_sar: Optional[float] = None
    total_status: str  # "CONFIRMED" or "REQUIRES_STORE_CONFIRMATION"
    total_status_text: str  # "مؤكد" أو "الإجمالي يُؤكد لدى المتجر"
    
    is_cheapest_product: bool = False
    is_cheapest_total: bool = False
    unit_price_per_100g_sar: Optional[float] = None

class ProductOut(BaseModel):
    id: int
    gtin_barcode: Optional[str] = None
    name_ar: str
    name_en: Optional[str] = None
    brand_ar: Optional[str] = None
    brand_en: Optional[str] = None
    category: str
    sub_category: Optional[str] = None
    sub_category_rank: int = 10
    normalized_size_amount: Optional[float] = None
    normalized_size_unit: Optional[str] = None
    pack_count: int = 1
    pack_type: Optional[str] = "single"
    pack_label_ar: Optional[str] = "بالحبّة"
    image_url: Optional[str] = None
    offers: List[StoreOfferOut] = []

class SearchResponse(BaseModel):
    query: str
    district_name: Optional[str] = None
    exact_size_matched: bool
    status_message: str
    disclaimer: str = "الأرخص بين العروض المطابقة التي تم فحصها لموقعك"
    matched_products: List[ProductOut] = []
    alternative_sizes: List[ProductOut] = []
    sub_categories: List[str] = []
    sources_summary: List[Dict[str, Any]] = []

class BasketItemInput(BaseModel):
    product_id: int
    quantity: int = Field(1, ge=1, le=100)

class BasketCompareRequest(BaseModel):
    district_name: Optional[str] = "سلطانة"
    items: List[BasketItemInput]

class StoreBasketResult(BaseModel):
    branch_id: Optional[int] = None
    store_code: str
    store_name_ar: str
    store_logo: Optional[str] = None
    is_complete: bool
    available_items_count: int
    total_items_count: int
    missing_items: List[str] = []
    subtotal_halalas: int
    subtotal_sar: float
    delivery_fee_halalas: Optional[int] = None
    delivery_fee_sar: Optional[float] = None
    total_halalas: Optional[int] = None
    total_sar: Optional[float] = None
    total_status_text: str
    is_cheapest_complete_basket: bool = False

class BasketCompareResponse(BaseModel):
    district_name: Optional[str]
    stores: List[StoreBasketResult]
    split_basket_suggestion: Optional[Dict[str, Any]] = None

class PriceAlertCreate(BaseModel):
    product_id: int
    district_name: Optional[str] = "سلطانة"
    target_price_sar: float
    device_id: str

class PriceAlertOut(BaseModel):
    id: int
    product_id: int
    target_price_halalas: int
    target_price_sar: float
    is_active: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class AdminStoreUpdate(BaseModel):
    is_enabled: Optional[bool] = None
    update_interval_minutes: Optional[int] = None
    base_delivery_fee_halalas: Optional[int] = None

# ==========================================
# Voice Basket Schemas
# ==========================================
class VoiceParseRequest(BaseModel):
    query: str
    session_id: str = Field(..., pattern=r"^[a-f0-9]{64}$")
    request_id: Optional[str] = None
    current_basket: Optional[List[Dict[str, Any]]] = None
    user_preferences: Optional[Dict[str, Any]] = None

class VoiceBasketItemOut(BaseModel):
    pack_count: int = 1
    product_id: int
    name_ar: str
    brand_ar: Optional[str] = None
    quantity: int = 1
    size_amount: Optional[float] = None
    size_unit: Optional[str] = None
    unit_price_sar: Optional[float] = None
    image_url: Optional[str] = None
    notes: Optional[str] = None

class VoiceParseResponse(BaseModel):
    status: str  # "success", "clarification_needed", "no_op", "error"
    recognized_text: str
    intent: str
    message_ar: str
    items_added: List[VoiceBasketItemOut] = []
    items_modified: List[VoiceBasketItemOut] = []
    items_removed: List[str] = []
    current_basket: List[VoiceBasketItemOut] = []
    clarification_question: Optional[str] = None
    clarification_options: List[str] = []
    can_undo: bool = False
    session_id: str

