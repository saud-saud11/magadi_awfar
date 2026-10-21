import re
import secrets
from fastapi import Header, HTTPException, Request
from app.config import settings


async def require_device(request: Request, authorization: str = Header(default='')) -> str:
    """Guest possession credential. Never accept public IDs as authentication."""
    token = authorization.removeprefix('Bearer ')
    if not authorization.startswith('Bearer ') or not re.fullmatch(r'[a-f0-9]{64}', token):
        raise HTTPException(401, 'يلزم تحديث التطبيق لإنشاء جلسة خاصة بهذا الجهاز')
    identifiers = [request.query_params.get('device_uuid'), request.query_params.get('session_id'), request.path_params.get('session_id'), request.path_params.get('device_id')]
    if request.headers.get('content-type', '').startswith('application/json'):
        try:
            data = await request.json()
            if isinstance(data, dict): identifiers += [data.get('device_uuid'), data.get('session_id'), data.get('device_id')]
        except ValueError:
            pass
    if any(value and not secrets.compare_digest(str(value), token) for value in identifiers):
        raise HTTPException(403, 'الجلسة لا تخص هذا الجهاز')
    return token


def require_admin(authorization: str = Header(default='')):
    expected = settings.ADMIN_TOKEN
    if not expected:
        raise HTTPException(503, 'لوحة الإدارة غير مهيأة')
    if not secrets.compare_digest(authorization, f'Bearer {expected}'):
        raise HTTPException(403, 'صلاحية المشرف مطلوبة')
