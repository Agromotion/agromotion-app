import 'package:agromotion/services/auth_service.dart';
import 'package:agromotion/services/notification_service.dart';
import 'package:agromotion/utils/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  /// Stream em tempo real (equivalente ao onValue)
  Stream<QuerySnapshot<Map<String, dynamic>>> getSchedulesStream() {
    return _firestore.collection('schedules').orderBy('time').snapshots();
  }

  Future<void> saveSchedule(
    Map<String, dynamic> scheduleData, {
    String? id,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = id == null
        ? _firestore.collection('schedules').doc()
        : _firestore.collection('schedules').doc(id);

    await docRef.set({
      'time': scheduleData['time'],
      'days': scheduleData['days'],
      'active': scheduleData['active'],
      'createdByUid': AuthService().currentUser?.uid ?? 'Desconhecido',
      'createdByEmail': AuthService().currentUser?.email ?? 'Desconhecido',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Opcional: Notificar também na criação/edição
    await _notifyAll(
      'Horário Atualizado',
      'O horário das ${scheduleData['time']} foi modificado.',
    );
  }

  Future<void> deleteSchedule(String id) async {
    await _firestore.collection('schedules').doc(id).delete();
  }

  Future<void> toggleStatus(String id, bool status, String time) async {
    await _firestore.collection('schedules').doc(id).update({'active': status});

    final acao = status ? "ATIVADO" : "DESATIVADO";
    final userEmail = _auth.currentUser?.email ?? "alguém";

    await _notifyAll(
      'Agromotion: Horário Alterado',
      'O horário das $time foi $acao por $userEmail.',
    );
  }

  /// Busca todos os tokens (Firestore) e envia notificações
  Future<void> _notifyAll(String title, String body) async {
    try {
      final snapshot = await _firestore.collection('user_tokens').get();

      for (final doc in snapshot.docs) {
        final token = doc.data()['token'];
        if (token != null) {
          await _notificationService.sendDirectNotification(
            title: title,
            body: body,
            token: token.toString(),
          );
        }
      }
    } catch (e, stack) {
      AppLogger.error("Erro ao buscar tokens para notificação: ", e, stack);
    }
  }
}
