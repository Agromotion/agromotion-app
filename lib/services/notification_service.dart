import 'package:agromotion/config/app_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _email = FirebaseAuth.instance.currentUser?.email;

  // Atalho para a referência da coleção
  CollectionReference get _notifRef =>
      _db.collection('users').doc(_email).collection('notifications');

  Stream<QuerySnapshot> streamNotifications() {
    if (_email == null) return const Stream.empty();
    return _notifRef.orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> markAsRead(String docId, {bool status = true}) async {
    await _notifRef.doc(docId).update({'isRead': status});
  }

  Future<void> deleteNotification(String docId) async {
    await _notifRef.doc(docId).delete();
  }

  Future<void> markAllAsRead() async {
    final unread = await _notifRef.where('isRead', isEqualTo: false).get();
    final batch = _db.batch();
    for (var doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> clearAllNotifications() async {
    final allDocs = await _notifRef.get();
    final batch = _db.batch();
    for (var doc in allDocs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. Request Permission (iOS/Android 13+)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String topic = AppConfig.robotId;
      await messaging.subscribeToTopic(topic);
    }
  }
}
