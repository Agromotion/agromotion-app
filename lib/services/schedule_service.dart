import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScheduleService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('schedules');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obter todos os horários em tempo real
  Stream<DatabaseEvent> getSchedulesStream() {
    return _dbRef.onValue;
  }

  // Adicionar ou Atualizar horário
  Future<void> saveSchedule(Map<String, dynamic> scheduleData, {String? id}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Se não tiver ID, gera um novo (Push)
    final ref = id == null ? _dbRef.push() : _dbRef.child(id);

    await ref.set({
      'time': scheduleData['time'],
      'days': scheduleData['days'],
      'active': scheduleData['active'],
      'createdByUid': user.uid,
      'createdByEmail': user.email,
      'createdAt': ServerValue.timestamp,
    });
  }

  // Remover horário
  Future<void> deleteSchedule(String id) async {
    await _dbRef.child(id).remove();
  }

  // Alternar estado Ativo/Inativo rapidamente
  Future<void> toggleStatus(String id, bool status) async {
    await _dbRef.child(id).update({'active': status});
  }
}