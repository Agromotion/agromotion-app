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

    // Em fullscreen: cores fixas brancas com opacidade — visíveis sobre qualquer vídeo.
    // Em portrait: usa o colorScheme normal do tema.
    final Color baseColor = widget.isFullScreen
        ? Colors.white.withAlpha(25) // anel exterior subtil mas visível
        : colorScheme.onSurface.withAlpha(15);

    final Color stickColor = widget.isFullScreen
        ? Colors.white.withAlpha(90) // stick claramente visível
        : colorScheme.primary.withAlpha(60);

    final Color arrowActiveColor = widget.isFullScreen
        ? Colors
              .white // seta ativa: branco puro
        : colorScheme.primary;

    final Color arrowInactiveColor = widget.isFullScreen
        ? Colors.white.withAlpha(40) // seta inativa: branco muito suave
        : colorScheme.onSurface.withAlpha(10);

    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            width: constraints.maxWidth,
            padding: EdgeInsets.symmetric(
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
                  isLeftPosition: true,
                ),
                const Spacer(),
                _buildJoystick(
                  colorScheme,
                  baseColor,
                  stickColor,
                  arrowActiveColor,
                  arrowInactiveColor,
                  isLeftPosition: false,
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
    required bool isLeftPosition,
  }) {
    bool isVerticalMode = isLeftPosition
        ? !widget.swapJoysticks
        : widget.swapJoysticks;

    double x = isLeftPosition ? leftX : rightX;
    double y = isLeftPosition ? leftY : rightY;

    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo de fundo em fullscreen para garantir contraste mínimo
          // mesmo que o vídeo seja totalmente branco ou claro.
          if (widget.isFullScreen)
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withAlpha(50),
              ),
            ),

          if (isVerticalMode) ...[
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
          if (!isVerticalMode) ...[
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
          ],

          Joystick(
            mode: isVerticalMode
                ? JoystickMode.vertical
                : JoystickMode.horizontal,
            listener: (details) {
              setState(() {
                if (isLeftPosition) {
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
        size: 35,
        color: isActive ? activeColor : inactiveColor,
      ),
    );
  }
}
