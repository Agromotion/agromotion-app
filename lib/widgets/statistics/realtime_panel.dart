import 'package:agromotion/models/battery_state.dart';
import 'package:agromotion/widgets/glass_container.dart';
import 'package:agromotion/widgets/statistics/shortcut_icon.dart';
import 'package:flutter/material.dart';
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

// --- Battery Card ---
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
                ? const _StatusBadge(
                    label: 'A CARREGAR',
                    color: Color(0xFFFDD835),
                  )
                : null,
          ),
          const SizedBox(height: 16),
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
                cs: cs,
              ),
              _StatCell(
                label: 'CORRENTE',
                value: '${snapshot.batteryCurrent.toStringAsFixed(1)} A',
                cs: cs,
              ),
              _StatCell(
                label: 'POTÊNCIA',
                value:
                    '${(snapshot.batteryVoltage * snapshot.batteryCurrent).toStringAsFixed(1)} W',
                cs: cs,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- System Card ---
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
        ],
      ),
    );
  }
}

// --- GPS Card (Atualizado com atalho para Mapa) ---
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
          Row(
            children: [
              _CardHeader(
                icon: Icons.satellite_alt_rounded,
                iconColor: gpsColor,
                title: 'Localização',
              ),
              const Spacer(),
              // BOTÃO DINÂMICO DE MAPA
              MapShortcutButton(gpsColor: gpsColor),
            ],
          ),
          const SizedBox(height: 14),
          // Envolvemos os dados num FittedBox para não quebrar em ecrãs pequenos
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              children: [
                _StatCell(
                  label: 'LATITUDE',
                  value: snapshot.gpsIsValid
                      ? snapshot.gpsLatitude.toStringAsFixed(5)
                      : '—',
                  cs: cs,
                ),
                const SizedBox(width: 20),
                _StatCell(
                  label: 'LONGITUDE',
                  value: snapshot.gpsIsValid
                      ? snapshot.gpsLongitude.toStringAsFixed(5)
                      : '—',
                  cs: cs,
                ),
                const SizedBox(width: 20),
                _StatCell(
                  label: 'ALTITUDE',
                  value: snapshot.gpsIsValid
                      ? '${snapshot.gpsAltitude.toStringAsFixed(0)}m'
                      : '—',
                  cs: cs,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 12),
          // Pills de estado com Wrap para responsividade
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusPill(
                icon: snapshot.robotMoving
                    ? Icons.directions_run_rounded
                    : Icons.pause_circle_outline_rounded,
                label: snapshot.robotMoving ? 'Em movimento' : 'Parado',
                color: snapshot.robotMoving
                    ? const Color(0xFF66BB6A)
                    : cs.onSurface.withOpacity(0.5),
              ),
              _StatusPill(
                icon: Icons.videocam_rounded,
                label: '${snapshot.videoClientCount} visualizadores',
                color: snapshot.videoClientCount > 0
                    ? const Color(0xFF42A5F5)
                    : cs.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Widgets de Apoio (Helper Widgets) ---

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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
  const _StatusBadge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;
  const _StatCell({required this.label, required this.value, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: cs.onSurface.withOpacity(0.4),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
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
