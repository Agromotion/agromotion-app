import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:agromotion/theme/app_theme.dart';

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
    final customColors = Theme.of(context).extension<AppColorsExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final int opacity = widget.transparent ? 40 : 80;

    // Adjust side padding: In Normal Mode (Portrait), we hug the edges (10).
    // In FullScreen (Landscape), we pull them in slightly (60) for ergonomics.
    final double sidePadding = widget.isFullScreen ? 60 : 20;

    return SizedBox(
      height: 150, // Fixed height to contain the 130px joysticks
      width: double.infinity,
      child: Stack(
        children: [
          // Left Side Joystick
          Positioned(
            left: sidePadding,
            top: 0,
            child: _buildJoystick(
              customColors,
              colorScheme,
              opacity,
              isRotation: widget.swapJoysticks,
              isLeftInstance: true,
            ),
          ),
          // Right Side Joystick
          Positioned(
            right: sidePadding,
            top: 0,
            child: _buildJoystick(
              customColors,
              colorScheme,
              opacity,
              isRotation: !widget.swapJoysticks,
              isLeftInstance: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoystick(
    AppColorsExtension customColors,
    ColorScheme colorScheme,
    int opacity, {
    required bool isRotation,
    required bool isLeftInstance,
  }) {
    double x = isLeftInstance ? leftX : rightX;
    double y = isLeftInstance ? leftY : rightY;

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
            colorScheme,
            opacity,
          ),
          _buildArrow(
            Icons.arrow_right_rounded,
            Alignment.centerRight,
            x > 0.3,
            colorScheme,
            opacity,
          ),

          if (!isRotation) ...[
            _buildArrow(
              Icons.arrow_drop_up_rounded,
              Alignment.topCenter,
              y < -0.3,
              colorScheme,
              opacity,
            ),
            _buildArrow(
              Icons.arrow_drop_down_rounded,
              Alignment.bottomCenter,
              y > 0.3,
              colorScheme,
              opacity,
            ),
          ],

          Joystick(
            mode: isRotation ? JoystickMode.horizontal : JoystickMode.all,
            listener: (details) {
              setState(() {
                if (isLeftInstance) {
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
                color: customColors.glassGradient.colors.first.withAlpha(
                  opacity,
                ),
                drawArrows: false,
                drawInnerCircle: true,
              ),
            ),
            stick: JoystickStick(
              decoration: JoystickStickDecoration(
                color: customColors.glassGradient.colors.first.withAlpha(
                  opacity + 40,
                ),
              ),
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
    ColorScheme colorScheme,
    int baseOpacity,
  ) {
    return Align(
      alignment: alignment,
      child: Icon(
        icon,
        size: 30,
        color: isActive
            ? colorScheme.primary
            : Colors.white.withAlpha(baseOpacity),
      ),
    );
  }
}
