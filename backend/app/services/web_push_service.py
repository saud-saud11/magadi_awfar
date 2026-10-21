import asyncio
import json
import logging
from urllib.parse import urlparse
from app.config import settings

logger = logging.getLogger('web_push')

class WebPushService:
    @property
    def configured(self):
        return bool(settings.VAPID_PUBLIC_KEY and settings.VAPID_PRIVATE_KEY and settings.VAPID_SUBJECT)

    @staticmethod
    def valid_endpoint(endpoint):
        try:
            parsed = urlparse(endpoint or '')
            host = parsed.hostname or ''
            port = parsed.port
        except ValueError: return False
        return (parsed.scheme == 'https' and port in (None, 443) and not parsed.username
                and not parsed.password and (host in ('fcm.googleapis.com', 'updates.push.services.mozilla.com', 'web.push.apple.com')
                    or host.endswith('.push.services.mozilla.com') or host.endswith('.notify.windows.com')))

    def format_notification_payload(self, title, body, product_id, store_code, store_name_ar,
                                    new_price_sar, old_price_sar=None, deep_link=None, image_url=None):
        return {'title': title, 'body': body, 'tag': f'price-{product_id}-{store_code}',
                'data': {'product_id': product_id, 'store_code': store_code, 'store_name_ar': store_name_ar,
                         'new_price_sar': new_price_sar, 'old_price_sar': old_price_sar,
                         'deep_link': settings.PUBLIC_APP_URL.rstrip('/') + '/?view=pantry'}}

    async def send_web_push(self, subscription, payload):
        if not self.configured or not self.valid_endpoint(subscription.get('endpoint')): return False
        if not subscription.get('p256dh_key') or not subscription.get('auth_key'): return False
        try:
            from pywebpush import webpush
            await asyncio.to_thread(webpush,
                subscription_info={'endpoint': subscription['endpoint'], 'keys': {
                    'p256dh': subscription['p256dh_key'], 'auth': subscription['auth_key']}},
                data=json.dumps(payload, ensure_ascii=False), vapid_private_key=settings.VAPID_PRIVATE_KEY,
                vapid_claims={'sub': settings.VAPID_SUBJECT}, ttl=3600, timeout=10)
            return True
        except Exception as error:
            # Do not log endpoint tokens or encryption keys.
            logger.warning('Web Push delivery failed (%s)', type(error).__name__)
            return False

web_push_service = WebPushService()
