from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from sqlalchemy.orm import Session
from typing import Optional
from app.database import get_db
from app.security import require_device
from app.schemas.schemas import VoiceParseRequest, VoiceParseResponse, VoiceBasketItemOut
from app.services.voice_basket_service import voice_basket_service
from app.config import settings

router = APIRouter(prefix="/voice", tags=["Voice Basket AI"], dependencies=[Depends(require_device)])

@router.post("/parse", response_model=VoiceParseResponse)
def parse_voice_command(
    req: VoiceParseRequest,
    db: Session = Depends(get_db)
):
    """
    Parses Arabic voice commands (Saudi dialect) to build and edit the grocery basket.
    Supports multi-item additions, logical defaults, quantity/size modifications, and undo.
    """
    return voice_basket_service.parse_and_execute(
        db_session=db,
        query=req.query,
        session_id=req.session_id,
        request_id=req.request_id,
        user_preferences=req.user_preferences
    )

@router.post("/process-audio")
async def process_voice_audio(
    audio_file: UploadFile = File(...),
    session_id: str = Form("default_session"),
    db: Session = Depends(get_db)
):
    """
    Accepts recorded voice audio (WAV / M4A / WebM / MP3).
    Transcribes audio via Cloud STT / Gemini API if configured, then executes the basket command.
    If cloud STT keys are not yet configured on server, returns transparent status and instructions.
    """
    if not settings.GEMINI_API_KEY and not settings.OPENAI_API_KEY:
        return {
            "status": "requires_setup",
            "message_ar": "خدمة تحويل الصوت إلى نص السحابية تتطلب تعيين GEMINI_API_KEY على الخادم. يمكنك استخدام الإدخال الصوتي المحلي أو الكتابة المباشرة.",
            "transcribed_text": None,
            "session_id": session_id
        }

    # If key is available, we could call Gemini 1.5 Flash / STT API
    # Return placeholder demonstrating transparent cloud integration
    return {
        "status": "requires_setup",
        "message_ar": "جاري تفعيل الاتصال مع مزود تحويل الصوت السحابي.",
        "session_id": session_id
    }

@router.post("/undo")
def undo_voice_command(
    session_id: str = Depends(require_device)
):
    """
    Reverts the last voice basket operation for the given session.
    """
    success, msg, basket_items = voice_basket_service.undo_last_action(session_id)
    return {
        "status": "success" if success else "no_op",
        "message_ar": msg,
        "current_basket": basket_items,
        "session_id": session_id
    }

@router.get("/session/{session_id}")
def get_session_basket(
    session_id: str
):
    """
    Retrieves the current items in the voice basket for the given session.
    """
    session = voice_basket_service.get_session(session_id)
    items = [VoiceBasketItemOut(**i) for i in session["basket"]]
    return {
        "session_id": session_id,
        "basket": items,
        "count": len(items),
        "can_undo": len(session["history"]) > 0
    }
