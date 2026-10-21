from pathlib import Path
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.database import engine, Base, SessionLocal
import asyncio
from app.api import districts, search, basket, alerts, admin, voice, pantry, push
from app.models.models import Store, District
from app.services.store_catalog_service import seed_staple_products_to_db
from app.services.price_monitor_service import price_monitor_service

# Initialize database schema
Base.metadata.create_all(bind=engine)
# Additive upgrade: old baselines are re-established from the first verified price.
from sqlalchemy import inspect, text
if 'baseline_version' not in {c['name'] for c in inspect(engine).get_columns('pantry_items')}:
    with engine.begin() as connection:
        connection.execute(text('ALTER TABLE pantry_items ADD COLUMN baseline_version INTEGER NOT NULL DEFAULT 0'))

app = FastAPI(
    title="مقاضي أوفر (Magadi Awfar) API",
    description="محرك مقارنة أسعار السوبرماركت والبقالة في المدينة المنورة - المملكة العربية السعودية",
    version="1.0.0"
)

# Enable CORS for Flutter mobile and web apps
app.add_middleware(
    CORSMiddleware,
    allow_origins=[s.strip() for s in settings.CORS_ORIGINS.split(",") if s.strip()],
    allow_credentials=False,
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
app.include_router(pantry.router, prefix=settings.API_V1_STR)
app.include_router(push.router, prefix=settings.API_V1_STR)

@app.on_event("startup")
async def on_startup():
    """Seed initial Madinah data, stores, and staple products on startup, and start background monitor."""
    # Start server price monitoring background task
    app.state.monitor_task = asyncio.create_task(price_monitor_service.start_background_loop())
    db = SessionLocal()
    try:
        # Seed stores
        from app.connectors.manager import connector_manager
        for source in connector_manager.get_all_statuses():
            store = db.query(Store).filter(Store.code == source['code']).first()
            if not store:
                store = Store(code=source['code'], name_ar=source['name_ar'], name_en=source['name_en'])
                db.add(store)
            store.status = source['status']
            store.base_delivery_fee_halalas = None
            store.free_delivery_threshold_halalas = None
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


@app.on_event("shutdown")
async def on_shutdown():
    price_monitor_service.stop_background_loop()
    task = getattr(app.state, 'monitor_task', None)
    if task:
        task.cancel()
        try: await task
        except asyncio.CancelledError: pass

@app.get(settings.API_V1_STR + '/sources')
def public_sources():
    from app.connectors.manager import connector_manager
    return {'sources': connector_manager.get_all_statuses()}
