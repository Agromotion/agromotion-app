import 'package:agromotion/services/notification_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScheduleService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('schedules');
  final DatabaseReference _tokensRef = FirebaseDatabase.instance.ref(
    'user_tokens',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  Stream<DatabaseEvent> getSchedulesStream() => _dbRef.onValue;

  Future<void> saveSchedule(
    Map<String, dynamic> scheduleData, {
    String? id,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = id == null ? _dbRef.push() : _dbRef.child(id);
    await ref.set({
      'time': scheduleData['time'],
      'days': scheduleData['days'],
      'active': scheduleData['active'],
      'createdByUid': user.uid,
      'createdByEmail': user.email,
      'createdAt': ServerValue.timestamp,
    });

    // Opcional: Notificar também na criação/edição
    _notifyAll(
      'Horário Atualizado',
      'O horário das ${scheduleData['time']} foi modificado.',
    );
  }

  Future<void> deleteSchedule(String id) async {
    await _dbRef.child(id).remove();
  }

  Future<void> toggleStatus(String id, bool status, String time) async {
    await _dbRef.child(id).update({'active': status});

    final acao = status ? "ATIVADO" : "DESATIVADO";
    final userEmail = _auth.currentUser?.email ?? "alguém";

    // Chama a função auxiliar para notificar todos os dispositivos
    await _notifyAll(
      'AgroMotion: Horário Alterado',
      'O horário das $time foi $acao por $userEmail.',
    );
  }

  /// Função auxiliar para buscar todos os tokens e enviar notificações individuais
  Future<void> _notifyAll(String title, String body) async {
    try {
      final snapshot = await _tokensRef.get();
      if (snapshot.exists) {
        final tokensMap = snapshot.value as Map<dynamic, dynamic>;

        // Itera sobre todos os tokens guardados
        for (var token in tokensMap.values) {
          await _notificationService.sendDirectNotification(
            title: title,
            body: body,
            token: token.toString(),
          );
        }
      }
    } catch (e) {
      print("Erro ao buscar tokens para notificação: $e");
    }
  }
}
