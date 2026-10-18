from pathlib import Path
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.database import engine, Base, SessionLocal
from app.api import districts, search, basket, alerts, admin, voice
from app.models.models import Store, District
from app.services.store_catalog_service import seed_staple_products_to_db

# Initialize database schema
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="مقاضي أوفر (Magadi Awfar) API",
    description="محرك مقارنة أسعار السوبرماركت والبقالة في المدينة المنورة - المملكة العربية السعودية",
    version="1.0.0"
)

# Enable CORS for Flutter mobile and web apps
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(districts.router, prefix=settings.API_V1_STR)
app.include_router(search.router, prefix=settings.API_V1_STR)
app.include_router(basket.router, prefix=settings.API_V1_STR)
app.include_router(voice.router, prefix=settings.API_V1_STR)
app.include_router(alerts.router, prefix=settings.API_V1_STR)
app.include_router(admin.router, prefix=settings.API_V1_STR)

@app.on_event("startup")
def on_startup():
    """Seed initial Madinah data, stores, and staple products on startup if missing."""
    db = SessionLocal()
    try:
        # Seed stores
        initial_stores = [
            {"code": "danube", "name_ar": "الدانوب", "name_en": "Danube", "status": "connected", "delivery": 1500, "free": 15000},
            {"code": "panda", "name_ar": "بنده", "name_en": "Panda", "status": "connected", "delivery": 1200, "free": 10000},
            {"code": "othaim", "name_ar": "أسواق العثيم", "name_en": "Othaim Markets", "status": "connected", "delivery": 1000, "free": 12000},
            {"code": "tamimi", "name_ar": "أسواق التميمي", "name_en": "Tamimi Markets", "status": "connected", "delivery": 1500, "free": 15000},
            {"code": "noon_minutes", "name_ar": "نون منتس (فوري)", "name_en": "Noon Minutes", "status": "connected", "delivery": 500, "free": 5000},
            {"code": "amazon_sa", "name_ar": "أمازون السعودية (شحن للمدينة)", "name_en": "Amazon.sa", "status": "connected", "delivery": 1200, "free": 10000},
            {"code": "nahdi", "name_ar": "صيدلية النهدي", "name_en": "Nahdi Pharmacy", "status": "connected", "delivery": 1200, "free": 10000},
            {"code": "dawaa", "name_ar": "صيدلية الدواء", "name_en": "Al-Dawaa Pharmacy", "status": "connected", "delivery": 1000, "free": 10000},
            {"code": "carrefour", "name_ar": "كارفور السعودية", "name_en": "Carrefour KSA", "status": "requires_setup", "delivery": 1500, "free": 15000},
            {"code": "hungerstation", "name_ar": "هنقرستيشن", "name_en": "Hungerstation", "status": "requires_setup", "delivery": None, "free": None},
            {"code": "ninja", "name_ar": "تطبيق نينجا", "name_en": "Ninja App", "status": "requires_setup", "delivery": None, "free": None},
            {"code": "keeta", "name_ar": "كيتا (Keemart)", "name_en": "Keeta", "status": "requires_setup", "delivery": None, "free": None},
            {"code": "amazon_now", "name_ar": "Amazon Now", "name_en": "Amazon Now", "status": "unsupported", "delivery": None, "free": None},
        ]
        for s in initial_stores:
            exists = db.query(Store).filter(Store.code == s["code"]).first()
            if not exists:
                db.add(Store(
                    code=s["code"],
                    name_ar=s["name_ar"],
                    name_en=s["name_en"],
                    status=s["status"],
                    base_delivery_fee_halalas=s["delivery"],
                    free_delivery_threshold_halalas=s["free"],
                    logo_url=f"/assets/stores/{s['code']}.png"
                ))
        db.commit()

        # Seed staple catalog products & offers
        seed_staple_products_to_db(db)
    finally:
        db.close()


@app.get("/")
def root():
    return {
        "app": settings.APP_NAME,
        "city": settings.DEFAULT_CITY,
        "status": "online",
        "web_app_url": "/app/",
        "docs_url": "/docs"
    }

web_dir = Path(__file__).resolve().parent.parent.parent / "frontend" / "build" / "web"
if web_dir.exists():
    app.mount("/app", StaticFiles(directory=str(web_dir), html=True), name="web_app")

