/// Serviço para gerir a sinalização WebRTC via Firestore.
/// Inclui lógica para envio de ofertas e receção de respostas.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class SignalingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String robotId = String.fromEnvironment(
    'ROBOT_ID',
    defaultValue: 'robot_01',
  );

  /// Envia a oferta WebRTC para o Firestore
  Future<void> sendOffer(String sdp, String type) async {
    await _firestore.collection('robot').doc(robotId).set({
      'offer': {'sdp': sdp, 'type': type},
      'answer': null,
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }

  /// Escuta a resposta vinda do Robô
  Stream<DocumentSnapshot> getSignalingStream() {
    return _firestore.collection('robot').doc(robotId).snapshots();
  }
}
