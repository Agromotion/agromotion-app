import 'package:flutter/material.dart';

/// Um painel de diagnóstico para exibir estatísticas de streaming em tempo real.
///
/// Este widget foi desenhado para ser sobreposto a um feed de vídeo (como WebRTC),
/// utilizando um fundo semi-transparente para garantir a legibilidade sem
/// causar conflitos de renderização com vistas de plataforma nativas.
class StreamDebugPanel extends StatelessWidget {
  final Map<String, dynamic> stats;

  const StreamDebugPanel({super.key, required this.stats});

  // Extrai e formata com segurança os valores do mapa de estatísticas.
  String _getString(String key, {String defaultValue = "---"}) =>
      stats[key]?.toString() ?? defaultValue;

  String _getFps() => (stats['fps'] as num?)?.toInt().toString() ?? "0";

  String _getLatency() => _getString('latency', defaultValue: "0");

  String _getPacketLoss() =>
      ((stats['loss'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      // Fundo sólido semi-transparente para evitar conflitos com RTCVideoView.
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colorScheme, textTheme),
          Divider(color: colorScheme.onSurface.withOpacity(0.15), height: 20),
          IntrinsicWidth(
            child: Column(
              children: [
                _DebugLine(label: "RESOLUÇÃO", value: _getString('res')),
                _DebugLine(label: "FRAME RATE", value: "${_getFps()} FPS"),
                _DebugLine(label: "LATÊNCIA", value: "${_getLatency()} ms"),
                _DebugLine(
                  label: "PERDA PACOTES",
                  value: "${_getPacketLoss()}%",
                ),
                const SizedBox(height: 8),
                _DebugLine(label: "CPU ROBÔ", value: _getString('cpu')),
                _DebugLine(label: "TEMP. ROBÔ", value: _getString('temp')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.terminal_rounded, color: colorScheme.primary, size: 14),
        const SizedBox(width: 8),
        Text(
          "DIAGNÓSTICO TÉCNICO",
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.primary.withOpacity(0.8),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

/// Widget interno para renderizar uma linha de informação de debug.
class _DebugLine extends StatelessWidget {
  final String label;
  final String value;

  const _DebugLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 24),
          Text(
            value,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
