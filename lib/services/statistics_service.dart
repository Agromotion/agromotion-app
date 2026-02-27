import 'package:agromotion/config/app_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get robotId => AppConfig.robotId;

  Future<Map<String, dynamic>> getHistoryData(
    DateTime start,
    DateTime end,
  ) async {
    // Query telemetry_history sub-collection
    final query = await _db
        .collection('robots')
        .doc(robotId)
        .collection('telemetry_history')
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThanOrEqualTo: end)
        .orderBy('timestamp', descending: false)
        .get();

    List<FlSpot> batterySpots = [];
    double totalDistance = 0.0;
    double maxTemp = 0.0;
    double avgCpu = 0.0;

    final docs = query.docs;

    for (int i = 0; i < docs.length; i++) {
      final data = docs[i].data();
      final timestamp = (data['timestamp'] as Timestamp).toDate();

      // Calculate X axis as hours from start
      double xValue = timestamp.difference(start).inMinutes / 60.0;

      // 1. Battery Data
      double battery = (data['battery_percentage'] ?? 0).toDouble();
      batterySpots.add(FlSpot(xValue, battery));

      // 2. Temperature & CPU (for Activity Tiles)
      double temp = (data['system_temperature'] ?? 0).toDouble();
      if (temp > maxTemp) maxTemp = temp;

      avgCpu += (data['system_cpu'] ?? 0).toDouble();
    }

    if (docs.isNotEmpty) avgCpu /= docs.length;

    return {
      'batteryData': batterySpots,
      'maxTemp': maxTemp.toStringAsFixed(1),
      'avgCpu': avgCpu.toStringAsFixed(1),
      'docCount': docs.length,
      // Note: Distance calculation would require lat/lon delta logic here
    };
  }
}
