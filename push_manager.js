// Web Push & PWA Helper for Magadi Awfar
(function() {
  function urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4);
    const base64 = (base64String + padding)
      .replace(/-/g, '+')
      .replace(/_/g, '/');
    const rawData = window.atob(base64);
    const outputArray = new Uint8Array(rawData.length);
    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i);
    }
    return outputArray;
  }

  window.magadiIsPushSupported = function() {
    return ('serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window);
  };

  window.magadiIsIos = function() {
    return /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
  };

  window.magadiIsStandalone = function() {
    return (window.navigator.standalone === true) || 
           (window.matchMedia && window.matchMedia('(display-mode: standalone)').matches);
  };

  window.magadiGetPermissionState = function() {
    if (!('Notification' in window)) return 'unsupported';
    return Notification.permission; // 'granted', 'denied', or 'default'
  };

  window.magadiRegisterAndSubscribe = async function(vapidPublicKey) {
    if (!window.magadiIsPushSupported()) {
      return JSON.stringify({ success: false, error: 'Push not supported' });
    }

    try {
      // Request permission in the user gesture before waiting for a service worker.
      const permission = await Notification.requestPermission();
      if (permission !== 'granted') {
        return JSON.stringify({ success: false, error: 'Permission ' + permission });
      }

      const reg = await navigator.serviceWorker.register(new URL('sw_push.js', document.baseURI));
      await navigator.serviceWorker.ready;
      const subscribeOptions = {
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(vapidPublicKey)
      };

      let subscription = await reg.pushManager.getSubscription();
      if (subscription && subscription.options.applicationServerKey) {
        const oldKey = new Uint8Array(subscription.options.applicationServerKey);
        const newKey = subscribeOptions.applicationServerKey;
        if (oldKey.length !== newKey.length || oldKey.some((v, i) => v !== newKey[i])) {
          await subscription.unsubscribe();
          subscription = null;
        }
      }
      if (!subscription) {
        subscription = await reg.pushManager.subscribe(subscribeOptions);
      }

      const subJson = subscription.toJSON();
      return JSON.stringify({
        success: true,
        endpoint: subJson.endpoint,
        p256dh: subJson.keys ? subJson.keys.p256dh : null,
        auth: subJson.keys ? subJson.keys.auth : null
      });
    } catch (err) {
      console.error('Error subscribing to push:', err);
      return JSON.stringify({ success: false, error: err.toString() });
    }
  };
})();
