importScripts('https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js');

firebase.initializeApp({
    apiKey: "AIzaSyDpLwQQpMlyMEyEZFi2YC-xKiQvA_TuX4E",
    authDomain: "barter-30a05.firebaseapp.com",
    projectId: "barter-30a05",
    storageBucket: "barter-30a05.firebasestorage.app",
    messagingSenderId: "460987873980",
    appId: "1:460987873980:web:fee9bfc0ed48109183aeb9",
    measurementId: "G-EDQKVSF7KQ"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);

    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/favicon.png'
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});
