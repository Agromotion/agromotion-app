import 'package:agromotion/config/app_config.dart';
import 'package:agromotion/utils/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> setupPushNotifications() async {
    try {
      // 1. Pedir permissões ao utilizador (Obrigatório no iOS, e no Android 13+)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.info("Permissão de notificações concedida.");

        // Inicializa o motor de notificações nativas do Sistema Operativo (OS)
        await _initLocalNotifications();

        // Subscrever ao tópico para receber as mensagens do robô (Python)
        // O Firebase Cloud Messaging na Web NÃO suporta subscrição de tópicos!
        if (!kIsWeb) {
          final cleanId = AppConfig.robotId.replaceAll(
            RegExp(r'[^a-zA-Z0-9-_]'),
            '_',
          );
          await _fcm.subscribeToTopic('robot_$cleanId');
          AppLogger.info("Subscrito no tópico de notificações: robot_$cleanId");
        } else {
          AppLogger.warning("Web não suporta subscrição a tópicos. Ignorado.");
        }

        // 2. Obter o token do dispositivo e guardar na BD
        String? token = await _fcm.getToken();
        if (token != null) {
          await _saveTokenToFirestore(token);
        }

        // 3. Atualizar token automaticamente se a Google o renovar
        _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

        // 4. Capturar notificações quando a App está aberta (Foreground)
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          AppLogger.info(
            "Notificação Foreground recebida: ${message.notification?.title}",
          );
          _showNativeNotification(message);
        });
      } else {
        AppLogger.warning("Permissão de notificações negada pelo utilizador.");
      }
    } catch (e) {
      AppLogger.error("Erro ao inicializar notificações", e);
    }
  }

  Future<void> _initLocalNotifications() async {
    // O plugin gere a Web automaticamente. Só precisamos de passar a diretoria do ícone do Android.
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    // Passou a exigir o parâmetro nomeado 'settings'
    await _localNotifications.initialize(settings: initSettings);

    if (!kIsWeb) {
      // No Android 8+, é obrigatório criar um "Canal" com prioridade máxima para a notificação saltar no ecrã (Heads-up)
      const channel = AndroidNotificationChannel(
        'agromotion_alerts',
        'Alertas Agromotion',
        description: 'Notificações importantes do sistema.',
        importance: Importance.max,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  void _showNativeNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Aciona a API nativa de notificações (Status bar no Android / Canto inferior direito no Windows)
    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'agromotion_alerts',
          'Alertas Agromotion',
          channelDescription: 'Notificações importantes do sistema.',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    try {
      // Salva o token diretamente no documento principal do utilizador
      await _db.collection('users').doc(user.email!.toLowerCase()).set({
        'tokens': FieldValue.arrayUnion([
          token,
        ]), // arrayUnion previne duplicados e permite múltiplos devices
        'updatedAt': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : 'mobile',
      }, SetOptions(merge: true));

      AppLogger.info("Token FCM guardado com sucesso no Firestore.");
    } catch (e) {
      AppLogger.error("Erro ao guardar token FCM", e);
    }
  }

  Future<void> removeToken() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _db.collection('users').doc(user.email!.toLowerCase()).update({
          'tokens': FieldValue.arrayRemove([token]),
        });
        AppLogger.info("Token FCM removido (Logout).");
      }
    } catch (e) {
      AppLogger.error("Erro ao remover token FCM", e);
    }
  }

  // ─────────────────────────────────────────
  // Firebase Firestore - Gestão do Ecrã de Notificações
  // ─────────────────────────────────────────

  Stream<QuerySnapshot> streamNotifications() {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      return const Stream<QuerySnapshot>.empty();
    }

    return _db
        .collection('users')
        .doc(user.email!.toLowerCase())
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> markAsRead(String id, {required bool status}) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    await _db
        .collection('users')
        .doc(user.email!.toLowerCase())
        .collection('notifications')
        .doc(id)
        .update({'isRead': status});
  }

  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    final snap = await _db
        .collection('users')
        .doc(user.email!.toLowerCase())
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (var doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String id) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    await _db
        .collection('users')
        .doc(user.email!.toLowerCase())
        .collection('notifications')
        .doc(id)
        .delete();
  }

  Future<void> clearAllNotifications() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    final snap = await _db
        .collection('users')
        .doc(user.email!.toLowerCase())
        .collection('notifications')
        .get();

    final batch = _db.batch();
    for (var doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
