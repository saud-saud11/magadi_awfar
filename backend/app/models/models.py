from datetime import datetime
from sqlalchemy import (
    Column, Integer, String, Float, Boolean, DateTime, ForeignKey, Text
)
from sqlalchemy.orm import relationship
from app.database import Base

class District(Base):
    __tablename__ = "districts"

    id = Column(Integer, primary_key=True, index=True)
    name_ar = Column(String(100), nullable=False, index=True)
    name_en = Column(String(100), nullable=True)
    city = Column(String(100), default="المدينة المنورة", nullable=False)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)

    branches = relationship("StoreBranch", back_populates="district")

class Store(Base):
    __tablename__ = "stores"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String(50), unique=True, nullable=False, index=True)
    name_ar = Column(String(100), nullable=False)
    name_en = Column(String(100), nullable=False)
    status = Column(String(50), default="requires_setup", nullable=False)
    # Statuses: connected, requires_setup, under_investigation, paused, unsupported
    status_reason = Column(String(255), nullable=True)
    logo_url = Column(String(255), nullable=True)
    is_enabled = Column(Boolean, default=True)
    
    # Financial fees in Halalas (1 SAR = 100 Halalas). NULL if unknown
    base_delivery_fee_halalas = Column(Integer, nullable=True)
    free_delivery_threshold_halalas = Column(Integer, nullable=True)
    min_order_halalas = Column(Integer, nullable=True)
    service_fee_halalas = Column(Integer, nullable=True)
    
    update_interval_minutes = Column(Integer, default=60)
    last_sync_at = Column(DateTime, nullable=True)
    last_error = Column(Text, nullable=True)

    branches = relationship("StoreBranch", back_populates="store")
    offers = relationship("StoreOffer", back_populates="store")

class StoreBranch(Base):
    __tablename__ = "store_branches"

    id = Column(Integer, primary_key=True, index=True)
    store_id = Column(Integer, ForeignKey("stores.id"), nullable=False)
    branch_name_ar = Column(String(150), nullable=False)
    branch_name_en = Column(String(150), nullable=True)
    district_id = Column(Integer, ForeignKey("districts.id"), nullable=True)
    coverage_districts = Column(Text, nullable=True)  # JSON list of covered district IDs/names
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    is_active = Column(Boolean, default=True)

    store = relationship("Store", back_populates="branches")
    district = relationship("District", back_populates="branches")
    offers = relationship("StoreOffer", back_populates="branch")

class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    gtin_barcode = Column(String(50), index=True, nullable=True)
    name_ar = Column(String(255), nullable=False, index=True)
    name_en = Column(String(255), nullable=True)
    brand_ar = Column(String(100), nullable=True, index=True)
    brand_en = Column(String(100), nullable=True)
    category = Column(String(100), default="بقالة", nullable=False)
    
    # Normalized measurement
    normalized_size_amount = Column(Float, nullable=True)
    normalized_size_unit = Column(String(20), nullable=True)  # g, kg, ml, l, pcs
    pack_count = Column(Integer, default=1, nullable=False)  # 1 for single, 2 for 2-pack bundle, etc.
    
    image_url = Column(String(500), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    offers = relationship("StoreOffer", back_populates="product")
    alerts = relationship("PriceAlert", back_populates="product")
    pantry_items = relationship("PantryItem", back_populates="product")

class StoreOffer(Base):
    __tablename__ = "store_offers"

    id = Column(Integer, primary_key=True, index=True)
    store_id = Column(Integer, ForeignKey("stores.id"), nullable=False)
    branch_id = Column(Integer, ForeignKey("store_branches.id"), nullable=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    
    # Financials in Halalas (strictly integer)
    price_halalas = Column(Integer, nullable=False)
    original_price_halalas = Column(Integer, nullable=True)
    
    is_on_sale = Column(Boolean, default=False)
    is_in_stock = Column(Boolean, default=True)
    stock_quantity = Column(Integer, nullable=True)
    
    product_url = Column(String(500), nullable=False)
    deep_link = Column(String(500), nullable=True)
    promo_conditions = Column(String(255), nullable=True)
    
    last_verified_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    raw_data_json = Column(Text, nullable=True)

    store = relationship("Store", back_populates="offers")
    branch = relationship("StoreBranch", back_populates="offers")
    product = relationship("Product", back_populates="offers")

class PriceAlert(Base):
    __tablename__ = "price_alerts"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    district_id = Column(Integer, ForeignKey("districts.id"), nullable=True)
    target_price_halalas = Column(Integer, nullable=False)
    device_id = Column(String(100), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    product = relationship("Product", back_populates="alerts")

class SearchLog(Base):
    __tablename__ = "search_logs"

    id = Column(Integer, primary_key=True, index=True)
    query = Column(String(255), nullable=False)
    district_name = Column(String(100), nullable=True)
    matched_products_count = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

class PantryItem(Base):
    __tablename__ = "pantry_items"

    id = Column(Integer, primary_key=True, index=True)
    device_uuid = Column(String(100), nullable=False, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    district_id = Column(Integer, ForeignKey("districts.id"), nullable=True)
    
    # Usual home replenishment quantity
    usual_quantity = Column(Integer, default=1, nullable=False)
    
    baseline_version = Column(Integer, default=0, nullable=False)

    # Baseline price (first valid reading when item is added; never considered a drop)
    baseline_price_halalas = Column(Integer, nullable=False)
    baseline_store_code = Column(String(50), nullable=False)
    
    # Custom alert settings
    target_price_halalas = Column(Integer, nullable=True)
    target_discount_percent = Column(Float, nullable=True)  # e.g. 10.0 for 10%
    specific_store_codes = Column(Text, nullable=True)  # JSON list of store codes, or NULL for all
    is_alert_enabled = Column(Boolean, default=True, nullable=False)
    track_landed_total = Column(Boolean, default=False, nullable=False)
    
    # Latest checked snapshot
    last_lowest_price_halalas = Column(Integer, nullable=False)
    last_lowest_store_code = Column(String(50), nullable=False)
    last_checked_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    product = relationship("Product", back_populates="pantry_items")
    district = relationship("District")
    notifications = relationship("NotificationLog", back_populates="pantry_item", cascade="all, delete-orphan")

class PushSubscription(Base):
    __tablename__ = "push_subscriptions"

    id = Column(Integer, primary_key=True, index=True)
    device_uuid = Column(String(100), unique=True, nullable=False, index=True)
    platform = Column(String(20), default="web", nullable=False)  # web, ios, android
    
    # Web Push credentials
    endpoint = Column(Text, nullable=True)
    p256dh_key = Column(Text, nullable=True)
    auth_key = Column(Text, nullable=True)
    
    # FCM / APNs token for native apps
    fcm_token = Column(Text, nullable=True)
    
    # Alert Preferences
    enable_quiet_hours = Column(Boolean, default=True, nullable=False)
    quiet_hours_start = Column(String(10), default="23:00", nullable=False)  # 24h format
    quiet_hours_end = Column(String(10), default="07:00", nullable=False)
    daily_digest_enabled = Column(Boolean, default=False, nullable=False)
    
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class NotificationLog(Base):
    __tablename__ = "notification_logs"

    id = Column(Integer, primary_key=True, index=True)
    device_uuid = Column(String(100), nullable=False, index=True)
    pantry_item_id = Column(Integer, ForeignKey("pantry_items.id"), nullable=False)
    
    # Idempotency key: prevents duplicate notifications on repeated checks / retries
    idempotency_key = Column(String(255), unique=True, nullable=False, index=True)
    
    # Event type: store_drop, competitor_cheaper, promo_offer
    event_type = Column(String(50), nullable=False)
    title = Column(String(255), nullable=False)
    body = Column(Text, nullable=False)
    
    store_code = Column(String(50), nullable=False)
    store_name_ar = Column(String(100), nullable=False)
    old_price_halalas = Column(Integer, nullable=True)
    new_price_halalas = Column(Integer, nullable=False)
    
    deep_link = Column(String(500), nullable=True)
    is_sent = Column(Boolean, default=False, nullable=False)
    sent_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    pantry_item = relationship("PantryItem", back_populates="notifications")

