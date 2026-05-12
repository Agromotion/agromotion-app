import 'package:flutter/material.dart';
import 'package:agromotion/widgets/glass_container.dart';

class DrumOverlay extends StatefulWidget {
  final Function(double value) onChanged;
  final bool isFullScreen;

  const DrumOverlay({
    super.key,
    required this.onChanged,
    this.isFullScreen = false,
  });

  @override
  State<DrumOverlay> createState() => _DrumOverlayState();
}

class _DrumOverlayState extends State<DrumOverlay>
    with SingleTickerProviderStateMixin {
  double _currentValue = 0.0; // -1.0 a 1.0
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    // Inicializa o controlador de rotação
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  /// Constrói o ícone dinâmico que roda e muda de forma consoante o estado
  Widget _buildDynamicIcon(Color primaryColor) {
    final bool isStopped = _currentValue.abs() < 0.05;

    if (isStopped) {
      _rotationController.stop();
      return Icon(
        Icons.pause_circle_outline_rounded,
        color: widget.isFullScreen
            ? Colors.white38
            : primaryColor.withAlpha(120),
        size: 26,
      );
    }

    // Ajusta a velocidade da animação: quanto maior o valor, mais rápido roda
    // Valor 1.0 -> 300ms de rotação | Valor 0.1 -> 1500ms de rotação
    double speedFactor = (1.1 - _currentValue.abs()).clamp(0.2, 1.5);
    _rotationController.duration = Duration(
      milliseconds: (speedFactor * 1000).toInt(),
    );

    if (!_rotationController.isAnimating) {
      _rotationController.repeat();
    }

    return RotationTransition(
      // Se o valor for negativo, usamos ReverseAnimation para rodar no sentido oposto
      turns: _currentValue > 0
          ? _rotationController
          : ReverseAnimation(_rotationController),
      child: Icon(
        _currentValue > 0
            ? Icons.rotate_right_rounded
            : Icons.rotate_left_rounded,
        color: widget.isFullScreen ? Colors.white : primaryColor,
        size: 26,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isActive = _currentValue.abs() > 0.05;

    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      borderRadius: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Feedback Visual Superior
          _buildDynamicIcon(colorScheme.primary),

          const SizedBox(height: 12),

          // Slider Vertical
          SizedBox(
            height: widget.isFullScreen ? 160 : 130,
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                    pressedElevation: 4,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 20,
                  ),
                  activeTrackColor: colorScheme.primary,
                  inactiveTrackColor: widget.isFullScreen
                      ? Colors.white10
                      : colorScheme.onSurface.withAlpha(20),
                  thumbColor: isActive
                      ? colorScheme.primary
                      : Colors.grey.shade400,
                ),
                child: Slider(
                  value: _currentValue,
                  min: -1.0,
                  max: 1.0,
                  onChanged: (val) {
                    setState(() => _currentValue = val);
                    // Arredonda para 2 casas decimais para poupar largura de banda no WebRTC
                    widget.onChanged(double.parse(val.toStringAsFixed(2)));
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Botão Reset (Emergency Stop Visual)
          GestureDetector(
            onTap: () {
              if (_currentValue != 0.0) {
                setState(() => _currentValue = 0.0);
                widget.onChanged(0.0);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? Colors.redAccent.withAlpha(200)
                    : Colors.grey.withAlpha(50),
              ),
              child: const Icon(
                Icons.stop_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
