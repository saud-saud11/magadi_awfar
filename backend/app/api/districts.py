from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.models.models import District
from app.schemas.schemas import DistrictOut

router = APIRouter(prefix="/districts", tags=["Districts"])

# Verified Al-Madinah Al-Munawwarah districts
MADINAH_DISTRICTS = [
    {"name_ar": "سلطانة", "name_en": "Sultanah", "lat": 24.4851, "lng": 39.5962},
    {"name_ar": "قباء", "name_en": "Quba", "lat": 24.4398, "lng": 39.6174},
    {"name_ar": "العزيزية", "name_en": "Al Aziziyah", "lat": 24.4645, "lng": 39.5312},
    {"name_ar": "الخالدية", "name_en": "Al Khalidiyah", "lat": 24.4489, "lng": 39.6387},
    {"name_ar": "الرانوناء", "name_en": "Al Ranuna", "lat": 24.4121, "lng": 39.5991},
    {"name_ar": "العريض", "name_en": "Al Urayd", "lat": 24.4789, "lng": 39.6512},
    {"name_ar": "الدفاع", "name_en": "Al Difa'a", "lat": 24.4532, "lng": 39.5218},
    {"name_ar": "شظاة", "name_en": "Shazah", "lat": 24.4921, "lng": 39.6410},
    {"name_ar": "شوران", "name_en": "Shuran", "lat": 24.4082, "lng": 39.6351},
    {"name_ar": "العوالي", "name_en": "Al Awali", "lat": 24.4498, "lng": 39.6290},
    {"name_ar": "باقدو", "name_en": "Baqdo", "lat": 24.4612, "lng": 39.6580},
    {"name_ar": "الهجرة", "name_en": "Al Hijrah", "lat": 24.4312, "lng": 39.5890},
    {"name_ar": "المنطقة المركزية (الحرم)", "name_en": "Central Area (Haram)", "lat": 24.4672, "lng": 39.6108},
]

@router.get("", response_model=List[DistrictOut])
def get_madinah_districts(db: Session = Depends(get_db)):
    """Returns all districts in Al-Madinah Al-Munawwarah."""
    districts = db.query(District).all()
    if not districts:
        # Seed initial Madinah districts if database is fresh
        for d in MADINAH_DISTRICTS:
            new_d = District(
                name_ar=d["name_ar"],
                name_en=d["name_en"],
                city="المدينة المنورة",
                latitude=d["lat"],
                longitude=d["lng"]
            )
            db.add(new_d)
        db.commit()
        districts = db.query(District).all()
    return districts
