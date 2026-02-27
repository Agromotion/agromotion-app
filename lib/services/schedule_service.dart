/// Serviço para gerir os horários de operação.
/// Inclui lógica para criação, edição, remoção e notificação de alterações.
library;

import 'package:agromotion/config/app_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ID do robô definido como constante ou vindo de um config
  String get _robotId => AppConfig.robotId;

  // Helper para obter a referência da sub-coleção de agendamentos do robô
  CollectionReference<Map<String, dynamic>> get _schedulesRef =>
      _firestore.collection('robots').doc(_robotId).collection('schedules');

  /// Stream em tempo real dos agendamentos do robô
  Stream<QuerySnapshot<Map<String, dynamic>>> getSchedulesStream() {
    return _schedulesRef.orderBy('time').snapshots();
  }

  Future<void> saveSchedule(
    Map<String, dynamic> scheduleData, {
    String? id,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = id == null ? _schedulesRef.doc() : _schedulesRef.doc(id);

    await docRef.set({
      'time': scheduleData['time'],
      'days': scheduleData['days'],
      'active': scheduleData['active'],
      'createdByUid': user.uid,
      'createdByEmail': user.email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSchedule(String id) async {
    await _schedulesRef.doc(id).delete();
  }

  Future<void> toggleStatus(String id, bool status) async {
    await _schedulesRef.doc(id).update({'active': status});
  }
}
