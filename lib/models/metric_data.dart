import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MetricData {
  final String id;
  final String title;
  final String unit;
  final String value;
  final IconData icon;
  final Color color;
  final List<FlSpot> history;

  const MetricData({
    required this.id,
    required this.title,
    required this.unit,
    required this.value,
    required this.icon,
    required this.color,
    required this.history,
  });
}

class SummaryTileData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const SummaryTileData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class TelemetrySnapshot {
  final int batteryPercentage;
  final double batteryVoltage;
  final double batteryCurrent;
  final bool batteryIsCharging;
  final double systemTemperature;
  final int systemCpu;
  final int systemRam;
  final bool gpsIsValid;
  final double gpsLatitude;
  final double gpsLongitude;
  final double gpsAltitude;
  final bool robotMoving;
  final int videoClientCount;
  final String activeControllerEmail;

  const TelemetrySnapshot({
    this.batteryPercentage = 0,
    this.batteryVoltage = 0,
    this.batteryCurrent = 0,
    this.batteryIsCharging = false,
    this.systemTemperature = 0,
    this.systemCpu = 0,
    this.systemRam = 0,
    this.gpsIsValid = false,
    this.gpsLatitude = 0,
    this.gpsLongitude = 0,
    this.gpsAltitude = 0,
    this.robotMoving = false,
    this.videoClientCount = 0,
    this.activeControllerEmail = '',
  });

  factory TelemetrySnapshot.fromMap(Map<String, dynamic> m) {
    // Extrai o mapa de telemetria
    final data = m.containsKey('telemetry')
        ? m['telemetry'] as Map<String, dynamic>
        : m;

    // Extrai o mapa de controle
    final controlData = m['control'] as Map<String, dynamic>? ?? {};

    // Agora busca o viewer_queue dentro de controlData
    final viewerQueue = controlData['viewer_queue'];
    final viewerCount = viewerQueue is List ? viewerQueue.length : 0;

    return TelemetrySnapshot(
      batteryPercentage: _toInt(data['battery_percentage']),
      batteryVoltage: _toDouble(data['battery_voltage']),
      batteryCurrent: _toDouble(data['battery_current']),
      batteryIsCharging: data['battery_is_charging'] ?? false,
      systemTemperature: _toDouble(data['system_temperature']),
      systemCpu: _toInt(data['system_cpu']),
      systemRam: _toInt(data['system_ram']),
      gpsIsValid: data['gps_is_valid'] ?? false,
      gpsLatitude: _toDouble(data['gps_latitude']),
      gpsLongitude: _toDouble(data['gps_longitude']),
      gpsAltitude: _toDouble(data['gps_altitude']),
      robotMoving: data['robot_moving'] ?? false,
      videoClientCount: viewerCount,
      activeControllerEmail: controlData['active_controller_email'] ?? '',
    );
  }

  static double _toDouble(dynamic val) {
    if (val is num) return val.toDouble();
    return 0.0;
  }

  static int _toInt(dynamic val) {
    if (val is num) return val.toInt();
    return 0;
  }
}
