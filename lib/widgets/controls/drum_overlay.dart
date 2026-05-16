import 'dart:async';
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
  double _currentValue = 0.0;

  late AnimationController _rotationController;

  // 🔥 NOVO: estado contínuo otimizado
  Timer? _loop;
  double _lastSent = 999;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _startLoop();
  }

  void _startLoop() {
    _loop?.cancel();

    // 🔥 30ms é sweet spot WebRTC mobile/raspberry
    _loop = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!mounted) return;

      final v = _currentValue;

      // deadzone
      if (v.abs() < 0.02) return;

      // evita spam idêntico
      if ((v - _lastSent).abs() < 0.01) return;

      _lastSent = v;
      widget.onChanged(v);
    });
  }

  void _stopLoop() {
    _loop?.cancel();
    _loop = null;
  }

  @override
  void dispose() {
    _stopLoop();
    _rotationController.dispose();
    super.dispose();
  }

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

    double speedFactor = (1.1 - _currentValue.abs()).clamp(0.2, 1.5);

    _rotationController.duration = Duration(
      milliseconds: (speedFactor * 1000).toInt(),
    );

    if (!_rotationController.isAnimating) {
      _rotationController.repeat();
    }

    return RotationTransition(
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
          _buildDynamicIcon(colorScheme.primary),

          const SizedBox(height: 12),

          SizedBox(
            height: widget.isFullScreen ? 160 : 130,
            child: RotatedBox(
              quarterTurns: 3,
              child: Slider(
                value: _currentValue,
                min: -1.0,
                max: 1.0,
                onChanged: (val) {
                  setState(() => _currentValue = val);

                  final fixed = double.parse(val.toStringAsFixed(2));
                  widget.onChanged(fixed);

                  if (_currentValue.abs() < 0.05) {
                    _stopLoop();
                  } else {
                    if (_loop == null) _startLoop();
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: () {
              setState(() => _currentValue = 0.0);
              widget.onChanged(0.0);
              _stopLoop();
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