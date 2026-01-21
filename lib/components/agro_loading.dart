import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Widget reutilizável para exibir um indicador de loading usando apenas Assets locais
class AgroLoading extends StatelessWidget {
  final double size;
  final String animationSource;
  final bool repeat;

  final AnimationController? controller;

  const AgroLoading({
    super.key,
    this.size = 92.0,
    this.animationSource = 'assets/loading_indicator.json',
    this.repeat = true,
    this.controller,
  });

  /// Construtor para tamanho pequeno (46px)
  const AgroLoading.small({
    super.key,
    this.animationSource = 'assets/loading_indicator.json',
    this.repeat = true,
    this.controller,
  }) : size = 46.0;

  /// Construtor para tamanho médio (92px)
  const AgroLoading.medium({
    super.key,
    this.animationSource = 'assets/loading_indicator.json',
    this.repeat = true,
    this.controller,
  }) : size = 92.0;

  /// Construtor para tamanho grande (138px)
  const AgroLoading.large({
    super.key,
    this.animationSource = 'assets/loading_indicator.json',
    this.repeat = true,
    this.controller,
  }) : size = 138.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        animationSource,
        renderCache: RenderCache.drawingCommands,
        addRepaintBoundary: true,
        width: size,
        height: size,
        fit: BoxFit.contain,
        repeat: repeat,
        animate: true,
        controller: controller,
        frameRate: FrameRate(30),
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Erro ao carregar Lottie do asset: $error');
          return _buildFallback();
        },
      ),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: SizedBox(
        width: size * 0.7,
        height: size * 0.7,
        child: CircularProgressIndicator(
          strokeWidth: size / 23,
          color: const Color(0xFF2CB67D),
        ),
      ),
    );
  }
}

/// Widget para exibir loading centralizado na tela
class FullScreenLoading extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final String? message;

  const FullScreenLoading({
    super.key,
    this.size = 92.0,
    this.backgroundColor,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.black.withAlpha(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AgroLoading(size: size),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget para exibir loading em overlay
class LoadingOverlay {
  static OverlayEntry? _overlayEntry;

  static void show(
    BuildContext context, {
    double size = 92.0,
    String? message,
  }) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => FullScreenLoading(size: size, message: message),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Remove o loading overlay
  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
