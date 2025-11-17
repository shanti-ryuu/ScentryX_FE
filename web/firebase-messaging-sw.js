/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyA1BCv0rMRV7kGdy9EcSg1r37W0LLP90nQ',
  authDomain: 'scentryx-13554.firebaseapp.com',
  projectId: 'scentryx-13554',
  storageBucket: 'scentryx-13554.firebasestorage.app',
  messagingSenderId: '1000647218784',
  appId: '1:1000647218784:web:4e244df5e66ad8d1fa9505',
});

self.addEventListener('push', function (event) {
  if (!event.data) {
    return;
  }

  const payload = event.data.json();
  const title = payload.notification?.title ?? 'ScentryX Alert';
  const body = payload.notification?.body ?? 'Gas sensor update';

  event.waitUntil(
    self.registration.showNotification(title, {
      body,
      icon: '/icons/Icon-192.png',
      data: payload?.data ?? {},
    }),
  );
});
