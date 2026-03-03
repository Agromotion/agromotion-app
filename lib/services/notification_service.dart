import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _email = FirebaseAuth.instance.currentUser?.email;

  // Real-time stream of notifications for the logged-in user
  Stream<QuerySnapshot> streamNotifications() {
    if (_email == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(_email)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> markAsRead(String docId) async {
    await _db
        .collection('users')
        .doc(_email)
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});
  }

  Future<void> deleteNotification(String docId) async {
    await _db
        .collection('users')
        .doc(_email)
        .collection('notifications')
        .doc(docId)
        .delete();
  }

  Future<void> markAllAsRead() async {
    final docs = await _db
        .collection('users')
        .doc(_email)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    for (var doc in docs.docs) {
      doc.reference.update({'isRead': true});
    }
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
      String topic = "robot_01";
      await messaging.subscribeToTopic(topic);
    }
  }
}
