/**
 * GuardUp — Firebase Cloud Messaging Service Worker
 *
 * Implements standard background notification handling, immediate activation,
 * and robust cache invalidation strategies.
 */

// 1. Prevent stale worker caching: force immediate activation & takeover
self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    Promise.all([
      self.clients.claim(),
      // Remove any stale caches if present
      caches.keys().then((keys) => {
        return Promise.all(
          keys
            .filter((key) => key.startsWith('fcm-cache-'))
            .map((key) => caches.delete(key))
        );
      }).catch(() => { }),
    ])
  );
});

// 2. Import standard Firebase SDK scripts
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

// 3. Initialize Firebase in the Service Worker
const firebaseConfig = {
  apiKey: "AIzaSyANQsvTrssM3tBdW2CesKv0q3TGpHyvmgk",
  authDomain: "guardup-991fd.firebaseapp.com",
  projectId: "guardup-991fd",
  storageBucket: "guardup-991fd.firebasestorage.app",
  messagingSenderId: "263066511816",
  appId: "1:263066511816:web:e97a776222497bfaa3f8fd",
  measurementId: "G-PVMFGXRL0P"
};

if (!firebase.apps.length) {
  firebase.initializeApp(firebaseConfig);
}

const messaging = firebase.messaging();

// 4. Handle incoming background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message:', payload);

  const notificationTitle =
    payload.notification?.title ||
    payload.data?.title ||
    'GuardUp Admin';

  const notificationOptions = {
    body: payload.notification?.body || payload.data?.body || '',
    icon: payload.notification?.icon || payload.data?.icon || '/icons/icon-192.png',
    badge: '/favicon.png',
    tag: payload.data?.tag || payload.data?.id || 'guardup-alert',
    data: payload.data || {},
    requireInteraction: false,
    vibrate: [200, 100, 200]
  };

  return self.registration.showNotification(
    notificationTitle,
    notificationOptions
  );
});

// 5. Handle notification click & routing
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const clickAction =
    event.notification.data?.click_action ||
    event.notification.data?.url ||
    '/';

  event.waitUntil(
    clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        // If a tab is already open, focus it and forward payload
        for (const client of clientList) {
          if ('focus' in client) {
            client.focus();
            client.postMessage({
              type: 'NOTIFICATION_CLICKED',
              data: event.notification.data,
            });
            return;
          }
        }
        // If no tab is open, open a new window
        if (clients.openWindow) {
          return clients.openWindow(clickAction);
        }
      })
  );
});
