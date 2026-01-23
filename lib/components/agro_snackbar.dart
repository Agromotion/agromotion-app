import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AgroSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
  }) {
    _OverlayManager.show(context, message, isError);
  }
}

class _OverlayManager {
  static OverlayEntry? _currentEntry;

  static void show(BuildContext context, String message, bool isError) {
    _currentEntry?.remove();

    final overlay = Overlay.of(context);
    _currentEntry = OverlayEntry(
      builder: (context) => _GlassSnackbarWidget(
        message: message,
        isError: isError,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );

    overlay.insert(_currentEntry!);
  }
}

class _GlassSnackbarWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _GlassSnackbarWidget({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_GlassSnackbarWidget> createState() => _GlassSnackbarWidgetState();
}

class _GlassSnackbarWidgetState extends State<_GlassSnackbarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  double _dragOffset = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 220),
    );

    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _scale = Tween<double>(begin: 0.96, end: 1).animate(curve);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(curve);

    _controller.forward();
    HapticFeedback.selectionClick();
    _setAutoDismiss();
  }

  void _setAutoDismiss() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted && !_isDragging) {
      _dismiss();
    }
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy < 0) return;

    setState(() {
      _isDragging = true;
      _dragOffset += details.delta.dy;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    const threshold = 60.0;

    if (_dragOffset > threshold) {
      _dismiss();
    } else {
      setState(() {
        _dragOffset = 0;
        _isDragging = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isError
        ? Colors.red.withAlpha(20)
        : Colors.white.withAlpha(10);

    final borderColor = widget.isError
        ? Colors.redAccent.withAlpha(50)
        : Colors.white.withAlpha(20);

    final dragProgress = (_dragOffset / 120).clamp(0.0, 1.0);

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 32, left: 24, right: 24),
          child: RepaintBoundary(
            child: GestureDetector(
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final effectiveOpacity = (_opacity.value * (1 - dragProgress))
                      .clamp(0.0, 1.0);

                  return Opacity(opacity: effectiveOpacity, child: child);
                },
                child: SlideTransition(
                  position: _slide,
                  child: Transform.translate(
                    offset: Offset(0, _dragOffset),
                    child: ScaleTransition(
                      scale: _scale,
                      child: Material(
                        color: Colors.transparent,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: borderColor,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.isError
                                        ? Icons.warning_amber_rounded
                                        : Icons.check_circle_outline_rounded,
                                    color: widget.isError
                                        ? Colors.redAccent
                                        : Colors.greenAccent,
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      widget.message,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
