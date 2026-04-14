import 'package:agromotion/config/app_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get robotId => AppConfig.robotId;

  /// Live telemetry stream — the whole robot document.
  Stream<DocumentSnapshot<Map<String, dynamic>>> getRealtimeStatus() {
    return _db.collection('robots').doc(robotId).snapshots();
  }

  /// Fetches historical telemetry between [start] and [end] and builds
  /// [FlSpot] lists for every tracked metric.
  Future<Map<String, dynamic>> getHistoryData(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final query = await _db
          .collection('robots')
          .doc(robotId)
          .collection('telemetry-history')
          .where('timestamp', isGreaterThanOrEqualTo: start)
          .where('timestamp', isLessThanOrEqualTo: end)
          .orderBy('timestamp')
          .get();

      final Map<String, List<FlSpot>> history = {
        'cpu': [],
        'ram': [],
        'temperature': [],
        'battery': [],
        'voltage': [],
        'current': [],
        'altitude': [],
      };

      double maxTemp = 0;
      double minTemp = double.infinity;
      double totalCpu = 0;
      double maxCpu = 0;
      int movingCount = 0;

      for (final doc in query.docs) {
        final d = doc.data();
        final ts = _toDate(d['timestamp']);
        if (ts == null) continue;

        final x = ts.difference(start).inMinutes / 60.0;

        final cpu = (d['system_cpu'] as num?)?.toDouble() ?? 0;
        final ram = (d['system_ram'] as num?)?.toDouble() ?? 0;
        final temp = (d['system_temperature'] as num?)?.toDouble() ?? 0;
        final bat = (d['battery_percentage'] as num?)?.toDouble() ?? 0;
        final volt = (d['battery_voltage'] as num?)?.toDouble() ?? 0;
        final curr = (d['battery_current'] as num?)?.toDouble() ?? 0;
        final alt = (d['gps_altitude'] as num?)?.toDouble() ?? 0;

        history['cpu']!.add(FlSpot(x, cpu));
        history['ram']!.add(FlSpot(x, ram));
        history['temperature']!.add(FlSpot(x, temp));
        history['battery']!.add(FlSpot(x, bat));
        history['voltage']!.add(FlSpot(x, volt));
        history['current']!.add(FlSpot(x, curr));
        history['altitude']!.add(FlSpot(x, alt));

        if (temp > maxTemp) maxTemp = temp;
        if (temp < minTemp) minTemp = temp;
        totalCpu += cpu;
        if (cpu > maxCpu) maxCpu = cpu;
        if (d['robot_moving'] == true) movingCount++;
      }

      final count = query.docs.length;
      return {
        'history': history,
        'maxTemp': maxTemp.toStringAsFixed(1),
        'minTemp': minTemp == double.infinity
            ? '0'
            : minTemp.toStringAsFixed(1),
        'avgCpu': count == 0 ? '0' : (totalCpu / count).toStringAsFixed(1),
        'maxCpu': maxCpu.toStringAsFixed(1),
        'docCount': count.toString(),
        'movingCount': movingCount.toString(),
        'movingPct': count == 0
            ? '0'
            : (movingCount / count * 100).toStringAsFixed(0),
      };
    } catch (e) {
      return {
        'history': <String, List<FlSpot>>{},
        'maxTemp': '0',
        'minTemp': '0',
        'avgCpu': '0',
        'maxCpu': '0',
        'docCount': '0',
        'movingCount': '0',
        'movingPct': '0',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getRawHistoryData(
    DateTime start,
    DateTime end,
  ) async {
    final query = await _db
        .collection('robots')
        .doc(robotId)
        .collection('telemetry-history')
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThanOrEqualTo: end)
        .orderBy('timestamp')
        .get();

    return query.docs.map((doc) => doc.data()).toList();
  }

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
