import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:agromotion/models/battery_state.dart';
import 'package:agromotion/widgets/glass_container.dart';
import 'package:agromotion/widgets/statistics/mapshortcut_icon.dart';
import 'package:agromotion/models/metric_data.dart';

class RealtimePanel extends StatelessWidget {
  const RealtimePanel({super.key, required this.snapshot});
  final TelemetrySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BatteryCard(snapshot: snapshot),
        const SizedBox(height: 12),
        _SystemCard(snapshot: snapshot),
        const SizedBox(height: 12),
        _GpsStatusCard(snapshot: snapshot),
      ],
    );
  }
}

// ---------------- BATTERY ----------------

class _BatteryCard extends StatelessWidget {
  const _BatteryCard({required this.snapshot});
  final TelemetrySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final battery = BatteryState.from(
      level: snapshot.batteryPercentage,
      isCharging: snapshot.batteryIsCharging,
    );

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: battery.icon,
            iconColor: battery.color,
            title: 'Bateria',
            trailing: _StatusBadge(
              label: '${snapshot.batteryVoltage.toStringAsFixed(2)} V',
              color: snapshot.batteryIsCharging
                  ? const Color(0xFFFDD835)
                  : battery.color,
              icon: Icons.power,
            ),
          ),
          const SizedBox(height: 16),
          _PercentageBar(
            value: snapshot.batteryPercentage / 100,
            color: battery.color,
            label: '${snapshot.batteryPercentage}%',
            cs: cs,
          ),
        ],
      ),
    );
  }
}

// ---------------- SYSTEM ----------------

class _SystemCard extends StatelessWidget {
  const _SystemCard({required this.snapshot});
  final TelemetrySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    const cpuColor = Color(0xFF42A5F5);
    const ramColor = Color(0xFF66BB6A);

    final tempColor = snapshot.systemTemperature > 70
        ? Colors.redAccent
        : snapshot.systemTemperature > 50
            ? Colors.orangeAccent
            : Colors.cyan;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.developer_board_rounded,
            iconColor: cpuColor,
            title: 'Sistema',
            trailing: _StatusBadge(
              label: '${snapshot.systemTemperature.toStringAsFixed(1)}°C',
              color: tempColor,
              icon: Icons.thermostat_rounded,
            ),
          ),
          const SizedBox(height: 16),
          _BarRow(
            label: 'CPU',
            value: snapshot.systemCpu / 100,
            displayValue: '${snapshot.systemCpu}%',
            color: cpuColor,
            cs: cs,
          ),
          const SizedBox(height: 10),
          _BarRow(
            label: 'RAM',
            value: snapshot.systemRam / 100,
            displayValue: '${snapshot.systemRam}%',
            color: ramColor,
            cs: cs,
          ),
          const SizedBox(height: 10),
          _StatusPill(
            icon: Icons.videocam_rounded,
            label: '${snapshot.videoClientCount} visualizadores',
            color: snapshot.videoClientCount > 0
                ? const Color(0xFF42A5F5)
                : cs.onSurface.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}

// ---------------- GPS (COM CACHE) ----------------

class _GpsStatusCard extends StatefulWidget {
  const _GpsStatusCard({required this.snapshot});
  final TelemetrySnapshot snapshot;

  @override
  State<_GpsStatusCard> createState() => _GpsStatusCardState();
}

class _GpsStatusCardState extends State<_GpsStatusCard> {
  String? _address;
  double? _lastLat;
  double? _lastLon;
  bool _loading = false;

  static const double _threshold = 0.0001; // ~11m

  @override
  void didUpdateWidget(covariant _GpsStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeUpdateAddress();
  }

  @override
  void initState() {
    super.initState();
    _maybeUpdateAddress();
  }

  bool _hasMoved(double lat, double lon) {
    if (_lastLat == null || _lastLon == null) return true;
    return (lat - _lastLat!).abs() > _threshold ||
        (lon - _lastLon!).abs() > _threshold;
  }

  Future<void> _maybeUpdateAddress() async {
    final lat = widget.snapshot.gpsLatitude;
    final lon = widget.snapshot.gpsLongitude;

    if (!widget.snapshot.gpsIsValid) return;

    if (!_hasMoved(lat, lon)) return;

    setState(() {
      _loading = true;
    });

    final url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1';

    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'agromotion-app'},
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        _address = data['display_name'];
        _lastLat = lat;
        _lastLon = lon;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final cs = Theme.of(context).colorScheme;

    final gpsColor =
        snapshot.gpsIsValid ? const Color(0xFF66BB6A) : cs.error;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CardHeader(
                icon: Icons.satellite_alt_rounded,
                iconColor: gpsColor,
                title: 'Localização',
              ),
              const Spacer(),
              MapShortcutButton(gpsColor: gpsColor),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 12),

          if (snapshot.gpsIsValid)
            Text(
              _loading
                  ? 'A obter morada...'
                  : _address ?? 'Sem dados',
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusPill(
                icon: Icons.my_location,
                label:
                    'Lat: ${snapshot.gpsLatitude.toStringAsFixed(5)}',
                color: gpsColor,
              ),
              _StatusPill(
                icon: Icons.my_location,
                label:
                    'Lon: ${snapshot.gpsLongitude.toStringAsFixed(5)}',
                color: gpsColor,
              ),
              _StatusPill(
                icon: Icons.height,
                label:
                    '${snapshot.gpsAltitude.toStringAsFixed(1)} m',
                color: gpsColor,
              ),
              _StatusPill(
                icon: snapshot.robotMoving
                    ? Icons.directions_run_rounded
                    : Icons.pause_circle_outline_rounded,
                label:
                    snapshot.robotMoving ? 'Em movimento' : 'Parado',
                color: snapshot.robotMoving
                    ? const Color(0xFF66BB6A)
                    : cs.onSurface.withAlpha(50),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------- HELPERS ----------------

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;

  const _CardHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Text(
          title,
          style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _StatusBadge({
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PercentageBar extends StatelessWidget {
  final double value;
  final Color color;
  final String label;
  final ColorScheme cs;

  const _PercentageBar({
    required this.value,
    required this.color,
    required this.label,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final double value;
  final String displayValue;
  final Color color;
  final ColorScheme cs;

  const _BarRow({
    required this.label,
    required this.value,
    required this.displayValue,
    required this.color,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 35,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: cs.onSurface.withOpacity(0.5),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 4,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          displayValue,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}