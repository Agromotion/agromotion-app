importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

// Estas chaves são as mesmas que usaste no Firebase.initializeApp da tua App
firebase.initializeApp({
apiKey: 'AIzaSyAmh8Zp3I2hKBIArpq1dbQEn1M8lKUBnVY',
    appId: '1:447251651704:web:fb4e8cd36cbbf39648218d',
    messagingSenderId: '447251651704',
    projectId: 'agromotion-8a7f8',
    authDomain: 'agromotion-8a7f8.firebaseapp.com',
    databaseURL: 'https://agromotion-8a7f8-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'agromotion-8a7f8.firebasestorage.app',
    measurementId: 'G-ZZEW4M1P0Q',
});


const messaging = firebase.messaging();

// Lógica para mostrar a notificação quando a app está em background
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Mensagem em background recebida: ', payload);

  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png' // Garante que este ícone existe na tua pasta web/icons
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});