import 'package:agromotion/config/app_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get robotId => AppConfig.robotId;

  Stream<DocumentSnapshot<Map<String, dynamic>>> getRealtimeStatus() {
    return _db.collection('robots').doc(robotId).snapshots();
  }

  /// Stream que emite sempre que há alterações no histórico dentro do intervalo.
  Stream<Map<String, dynamic>> streamHistoryData(DateTime start, DateTime end) {
    final String startStr = start.toIso8601String();
    final String endStr = end.toIso8601String();

    return _db
        .collection('robots')
        .doc(robotId)
        .collection('telemetry_history')
        .where('timestamp', isGreaterThanOrEqualTo: startStr)
        .where('timestamp', isLessThanOrEqualTo: endStr)
        .orderBy('timestamp')
        .snapshots()
        .map((query) {
          final Map<String, List<FlSpot>> history = {
            'cpu': [],
            'ram': [],
            'temperature': [],
            'battery': [],
            'voltage': [],
            'current': [],
            'altitude': [],
          };

          double maxTemp = -999.0;
          double minTemp = 999.0;
          double totalCpu = 0;
          double maxCpu = 0;
          int movingCount = 0;

          for (final doc in query.docs) {
            final d = doc.data();
            final ts = _toDate(d['timestamp']);
            if (ts == null) continue;

            final double x =
                ts.difference(start).inMilliseconds / (1000 * 60 * 60);

            final cpu = _toDouble(d['system_cpu']);
            final ram = _toDouble(d['system_ram']);
            final temp = _toDouble(d['system_temperature']);
            final bat = _toDouble(d['battery_percentage']);
            final volt = _toDouble(d['battery_voltage']);
            final curr = _toDouble(d['battery_current']);
            final alt = _toDouble(d['gps_altitude']);

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
            'maxTemp': count == 0 ? '0' : maxTemp.toStringAsFixed(1),
            'minTemp': (count == 0 || minTemp == 999.0)
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
        });
  }

  Future<List<Map<String, dynamic>>> getRawHistoryData(
    DateTime start,
    DateTime end,
  ) async {
    final query = await _db
        .collection('robots')
        .doc(robotId)
        .collection('telemetry_history')
        .where('timestamp', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('timestamp', isLessThanOrEqualTo: end.toIso8601String())
        .orderBy('timestamp')
        .get();

    return query.docs.map((doc) => doc.data()).toList();
  }

  double _toDouble(dynamic val) {
    if (val is num) return val.toDouble();
    return 0.0;
  }

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
