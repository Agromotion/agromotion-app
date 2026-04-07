import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

enum ChartType { line, bar, pie }

/// A single telemetry metric with its display config and historical data.
class MetricData {
  final String id;
  final String title;
  final String unit;
  final String value;
  final IconData icon;
  final Color color;
  final List<FlSpot> history;
  final ChartType chartType;

  const MetricData({
    required this.id,
    required this.title,
    required this.unit,
    required this.value,
    required this.icon,
    required this.color,
    required this.history,
    this.chartType = ChartType.line,
  });
}

/// A summary tile shown at the top of the statistics screen.
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

/// Snapshot of all realtime telemetry fields from Firestore.
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
    return TelemetrySnapshot(
      batteryPercentage: (m['battery_percentage'] as num?)?.toInt() ?? 0,
      batteryVoltage: (m['battery_voltage'] as num?)?.toDouble() ?? 0,
      batteryCurrent: (m['battery_current'] as num?)?.toDouble() ?? 0,
      batteryIsCharging: m['battery_is_charging'] ?? false,
      systemTemperature: (m['system_temperature'] as num?)?.toDouble() ?? 0,
      systemCpu: (m['system_cpu'] as num?)?.toInt() ?? 0,
      systemRam: (m['system_ram'] as num?)?.toInt() ?? 0,
      gpsIsValid: m['gps_is_valid'] ?? false,
      gpsLatitude: (m['gps_latitude'] as num?)?.toDouble() ?? 0,
      gpsLongitude: (m['gps_longitude'] as num?)?.toDouble() ?? 0,
      gpsAltitude: (m['gps_altitude'] as num?)?.toDouble() ?? 0,
      robotMoving: m['robot_moving'] ?? false,
      videoClientCount: (m['video_client_count'] as num?)?.toInt() ?? 0,
      activeControllerEmail: m['active_controller_email'] ?? '',
    );
  }
}
