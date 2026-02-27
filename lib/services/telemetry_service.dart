import 'package:agromotion/config/app_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelemetryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get robotId => AppConfig.robotId;

  /// Streams the latest telemetry document from Firestore
  Stream<Map<String, dynamic>> getTelemetryStream() {
    return _firestore
        .collection('robots')
        .doc(robotId)
        .snapshots()
        .map((snap) => snap.data() ?? {});
  }
}
