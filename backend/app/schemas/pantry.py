from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime

class PantryItemCreate(BaseModel):
    device_uuid: str = Field(..., description="Unique client device identifier")
    product_id: int
    district_name: Optional[str] = "سلطانة"
    usual_quantity: int = Field(1, ge=1, le=100)
    target_price_sar: Optional[float] = Field(None, gt=0, le=100000)
    target_discount_percent: Optional[float] = Field(None, gt=0, le=100)
    specific_store_codes: Optional[List[str]] = None
    is_alert_enabled: bool = True
    track_landed_total: bool = False

class PantryItemUpdate(BaseModel):
    usual_quantity: Optional[int] = Field(None, ge=1, le=100)
    target_price_sar: Optional[float] = Field(None, gt=0, le=100000)
    target_discount_percent: Optional[float] = Field(None, gt=0, le=100)
    specific_store_codes: Optional[List[str]] = None
    is_alert_enabled: Optional[bool] = None
    track_landed_total: Optional[bool] = None

class PantryItemOut(BaseModel):
    server_synced: bool = True
    has_verified_price: bool = False
    id: int
    device_uuid: str
    product_id: int
    product_name_ar: str
    product_name_en: Optional[str] = None
    brand_ar: Optional[str] = None
    image_url: Optional[str] = None
    normalized_size_amount: Optional[float] = None
    normalized_size_unit: Optional[str] = None
    pack_count: int = 1
    pack_label_ar: Optional[str] = None
    usual_quantity: int
    
    # Financials
    baseline_price_sar: float
    baseline_store_code: str
    current_lowest_price_sar: float
    current_lowest_store_code: str
    current_lowest_store_name_ar: str
    savings_amount_sar: float
    savings_percent: float
    is_price_dropped: bool
    is_on_sale: bool
    
    # Settings
    target_price_sar: Optional[float] = Field(None, gt=0, le=100000)
    target_discount_percent: Optional[float] = Field(None, gt=0, le=100)
    specific_store_codes: Optional[List[str]] = None
    is_alert_enabled: bool
    track_landed_total: bool
    
    last_checked_at: datetime
    created_at: datetime

    class Config:
        from_attributes = True

class PantrySummaryOut(BaseModel):
    device_uuid: str
    items_count: int
    active_alerts_count: int
    total_estimated_monthly_sar: float
    total_potential_savings_sar: float
    monitoring_status: str
    items: List[PantryItemOut]

class PushSubscriptionCreate(BaseModel):
    device_uuid: str
    platform: str = "web"  # web, ios, android
    endpoint: Optional[str] = None
    p256dh_key: Optional[str] = None
    auth_key: Optional[str] = None
    fcm_token: Optional[str] = None
    enable_quiet_hours: bool = True
    quiet_hours_start: str = Field("23:00", pattern=r"^(?:[01][0-9]|2[0-3]):[0-5][0-9]$")
    quiet_hours_end: str = Field("07:00", pattern=r"^(?:[01][0-9]|2[0-3]):[0-5][0-9]$")
    daily_digest_enabled: bool = False

class AlertPreferencesUpdate(BaseModel):
    enable_quiet_hours: Optional[bool] = None
    quiet_hours_start: Optional[str] = Field(None, pattern=r"^(?:[01][0-9]|2[0-3]):[0-5][0-9]$")
    quiet_hours_end: Optional[str] = Field(None, pattern=r"^(?:[01][0-9]|2[0-3]):[0-5][0-9]$")
    daily_digest_enabled: Optional[bool] = None

class NotificationLogOut(BaseModel):
    id: int
    device_uuid: str
    pantry_item_id: int
    event_type: str
    title: str
    body: str
    store_code: str
    store_name_ar: str
    old_price_sar: Optional[float] = None
    new_price_sar: float
    savings_sar: Optional[float] = None
    deep_link: Optional[str] = None
    sent_at: datetime

    class Config:
        from_attributes = True
