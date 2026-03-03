import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';

class JoystickOverlay extends StatefulWidget {
  final Function(double x, double y) onMoveLeft;
  final Function(double x, double y) onMoveRight;
  final bool transparent;
  final bool swapJoysticks;
  final bool isFullScreen;

  const JoystickOverlay({
    super.key,
    required this.onMoveLeft,
    required this.onMoveRight,
    this.transparent = false,
    this.swapJoysticks = false,
    this.isFullScreen = false,
  });

  @override
  State<JoystickOverlay> createState() => _JoystickOverlayState();
}

class _JoystickOverlayState extends State<JoystickOverlay> {
  double leftX = 0, leftY = 0;
  double rightX = 0, rightY = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Cores Otimizadas: Fundo muito mais subtil (0.05 a 0.15 de opacidade)
    final Color baseColor = colorScheme.onSurface.withAlpha(
      widget.isFullScreen ? 8 : 15,
    );
    final Color stickColor = colorScheme.primary.withAlpha(60);
    final Color arrowActiveColor = colorScheme.primary;
    final Color arrowInactiveColor = colorScheme.onSurface.withAlpha(10);

    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            width: constraints.maxWidth,
            padding: EdgeInsets.symmetric(
              // Eixo X: Joysticks mais perto do centro no modo FullScreen
              horizontal: widget.isFullScreen ? 140 : 20,
              vertical: 5,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildJoystick(
                  colorScheme,
                  baseColor,
                  stickColor,
                  arrowActiveColor,
                  arrowInactiveColor,
                  isRotation: widget.swapJoysticks,
                ),
                const Spacer(),
                _buildJoystick(
                  colorScheme,
                  baseColor,
                  stickColor,
                  arrowActiveColor,
                  arrowInactiveColor,
                  isRotation: !widget.swapJoysticks,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildJoystick(
    ColorScheme colorScheme,
    Color baseColor,
    Color stickColor,
    Color activeA,
    Color inactiveA, {
    required bool isRotation,
  }) {
    bool isLeftStick =
        (!widget.swapJoysticks && !isRotation) ||
        (widget.swapJoysticks && isRotation);
    double x = isLeftStick ? leftX : rightX;
    double y = isLeftStick ? leftY : rightY;

    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildArrow(
            Icons.arrow_left_rounded,
            Alignment.centerLeft,
            x < -0.3,
            activeA,
            inactiveA,
          ),
          _buildArrow(
            Icons.arrow_right_rounded,
            Alignment.centerRight,
            x > 0.3,
            activeA,
            inactiveA,
          ),
          if (!isRotation) ...[
            _buildArrow(
              Icons.arrow_drop_up_rounded,
              Alignment.topCenter,
              y < -0.3,
              activeA,
              inactiveA,
            ),
            _buildArrow(
              Icons.arrow_drop_down_rounded,
              Alignment.bottomCenter,
              y > 0.3,
              activeA,
              inactiveA,
            ),
          ],
          Joystick(
            mode: isRotation ? JoystickMode.horizontal : JoystickMode.all,
            listener: (details) {
              setState(() {
                if (isLeftStick) {
                  leftX = details.x;
                  leftY = details.y;
                  widget.onMoveLeft(details.x, details.y);
                } else {
                  rightX = details.x;
                  rightY = details.y;
                  widget.onMoveRight(details.x, details.y);
                }
              });
            },
            base: JoystickBase(
              decoration: JoystickBaseDecoration(
                color: baseColor,
                drawArrows: false,
              ),
            ),
            stick: JoystickStick(
              decoration: JoystickStickDecoration(color: stickColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrow(
    IconData icon,
    Alignment alignment,
    bool isActive,
    Color activeColor,
    Color inactiveColor,
  ) {
    return Align(
      alignment: alignment,
      child: Icon(
        icon,
        size: 30,
        color: isActive ? activeColor : inactiveColor,
      ),
    );
  }
}
