import 'package:agromotion/models/battery_state.dart';
import 'package:agromotion/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:agromotion/models/metric_data.dart';

/// Three live-status cards shown in a column:
///   1. Battery (percentage + voltage + current + charging state)
///   2. System (CPU + RAM + temperature)
///   3. GPS / robot status
class RealtimePanel extends StatelessWidget {
  const RealtimePanel({super.key, required this.snapshot});

  final TelemetrySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BatteryCard(snapshot: snapshot),
        const SizedBox(height: 10),
        _SystemCard(snapshot: snapshot),
        const SizedBox(height: 10),
        _GpsStatusCard(snapshot: snapshot),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Battery card
// ---------------------------------------------------------------------------

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
            trailing: snapshot.batteryIsCharging
                ? _StatusBadge(
                    label: 'A CARREGAR',
                    color: const Color(0xFFFDD835),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          // Percentage bar
          _PercentageBar(
            value: snapshot.batteryPercentage / 100,
            color: battery.color,
            label: '${snapshot.batteryPercentage}%',
            cs: cs,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatCell(
                label: 'TENSÃO',
                value: '${snapshot.batteryVoltage.toStringAsFixed(1)} V',
                color: cs.onSurface,
                cs: cs,
              ),
              _StatCell(
                label: 'CORRENTE',
                value: '${snapshot.batteryCurrent.toStringAsFixed(1)} A',
                color: cs.onSurface,
                cs: cs,
              ),
              _StatCell(
                label: 'POTÊNCIA',
                value:
                    '${(snapshot.batteryVoltage * snapshot.batteryCurrent).toStringAsFixed(1)} W',
                color: cs.onSurface,
                cs: cs,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// System card
// ---------------------------------------------------------------------------

class _SystemCard extends StatelessWidget {
  const _SystemCard({required this.snapshot});
  final TelemetrySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const cpuColor = Color(0xFF42A5F5);
    const ramColor = Color(0xFF66BB6A);
    final tempColor = snapshot.systemTemperature > 70
        ? const Color(0xFFEF5350)
        : snapshot.systemTemperature > 50
        ? const Color(0xFFFFA726)
        : const Color(0xFF26C6DA);

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
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GPS / Robot status card
// ---------------------------------------------------------------------------

class _GpsStatusCard extends StatelessWidget {
  const _GpsStatusCard({required this.snapshot});
  final TelemetrySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gpsColor = snapshot.gpsIsValid ? const Color(0xFF66BB6A) : cs.error;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.satellite_alt_rounded,
            iconColor: gpsColor,
            title: 'GPS & Estado',
            trailing: _StatusBadge(
              label: snapshot.gpsIsValid ? 'FIX OK' : 'SEM FIX',
              color: gpsColor,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatCell(
                label: 'LATITUDE',
                value: snapshot.gpsIsValid
                    ? snapshot.gpsLatitude.toStringAsFixed(5)
                    : '—',
                color: cs.onSurface,
                cs: cs,
              ),
              _StatCell(
                label: 'LONGITUDE',
                value: snapshot.gpsIsValid
                    ? snapshot.gpsLongitude.toStringAsFixed(5)
                    : '—',
                color: cs.onSurface,
                cs: cs,
              ),
              _StatCell(
                label: 'ALTITUDE',
                value: snapshot.gpsIsValid
                    ? '${snapshot.gpsAltitude.toStringAsFixed(0)} m'
                    : '—',
                color: cs.onSurface,
                cs: cs,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusPill(
                icon: snapshot.robotMoving
                    ? Icons.directions_run_rounded
                    : Icons.pause_circle_outline_rounded,
                label: snapshot.robotMoving ? 'Em movimento' : 'Parado',
                color: snapshot.robotMoving
                    ? const Color(0xFF66BB6A)
                    : cs.onSurface.withAlpha(80),
              ),
              const SizedBox(width: 10),
              _StatusPill(
                icon: Icons.videocam_rounded,
                label: '${snapshot.videoClientCount} cliente(s)',
                color: snapshot.videoClientCount > 0
                    ? const Color(0xFF42A5F5)
                    : cs.onSurface.withAlpha(80),
              ),
              if (snapshot.activeControllerEmail.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _StatusPill(
                    icon: Icons.gamepad_rounded,
                    label: snapshot.activeControllerEmail.split('@').first,
                    color: cs.primary,
                    overflow: true,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80), width: 1),
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
              fontSize: 10,
              fontWeight: FontWeight.w800,
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
  const _PercentageBar({
    required this.value,
    required this.color,
    required this.label,
    required this.cs,
  });

  final double value;
  final Color color;
  final String label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: cs.onSurface.withAlpha(20),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.displayValue,
    required this.color,
    required this.cs,
  });

  final String label;
  final double value;
  final String displayValue;
  final Color color;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withAlpha(120),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: cs.onSurface.withAlpha(15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          displayValue,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
    required this.cs,
  });

  final String label;
  final String value;
  final Color color;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: cs.onSurface.withAlpha(90),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
    this.overflow = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool overflow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: overflow ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          overflow
              ? Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
        ],
      ),
    );
  }
}
