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
    tag: data.tag || 'magadi-price-update',
    actions: [{ action: 'open_pantry', title: 'عرض مقاضي البيت' }]
  };

  event.waitUntil(
    self.registration.showNotification(title, options)
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil((async () => {
    const target = new URL(self.registration.scope);
    target.searchParams.set('view', 'pantry');
    const clients = await self.clients.matchAll({type: 'window', includeUncontrolled: true});
    for (const client of clients) {
      if (client.url.startsWith(self.registration.scope) && 'navigate' in client) {
        const navigated = await client.navigate(target.href);
        if (navigated) return navigated.focus();
      }
    }
    return self.clients.openWindow(target.href);
  })());
});
