// Service Worker for Magadi Awfar Web Push Notifications
self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('push', (event) => {
  let data = {};
  if (event.data) {
    try {
      data = event.data.json();
    } catch (e) {
      data = { title: 'تنبيه مقاضي أوفر', body: event.data.text() };
    }
  }

  const title = data.title || 'مقاضي أوفر — متابعة الأسعار';
  const options = {
    body: data.body || 'هناك تحديث جديد على أسعار مقاضي البيت!',
    icon: data.icon || 'icons/Icon-192.png',
    badge: 'icons/Icon-192.png',
    dir: 'rtl',
    lang: 'ar',
    vibrate: [200, 100, 200],
    data: data.data || {},
    actions: [
      { action: 'open_pantry', title: 'عرض مقاضي البيت' },
      { action: 'open_store', title: 'فتح المتجر' }
    ]
  };

  event.waitUntil(
    self.registration.showNotification(title, options)
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const action = event.action;
  const nData = event.notification.data || {};

  event.waitUntil(
    (async () => {
      if (action === 'open_store' && nData.store_url) {
        if (self.clients.openWindow) {
          return self.clients.openWindow(nData.store_url);
        }
      }

      // Default: focus or open app at pantry screen
      const allClients = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
      for (const client of allClients) {
        if ('focus' in client) {
          client.focus();
          client.postMessage({ type: 'NAVIGATE_TO_PANTRY', data: nData });
          return;
        }
      }

      if (self.clients.openWindow) {
        const targetUrl = nData.deep_link || '/magadi_awfar/#/pantry';
        return self.clients.openWindow(targetUrl);
      }
    })()
  );
});
