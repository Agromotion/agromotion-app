import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoFeedDisplay extends StatefulWidget {
  final RTCVideoRenderer renderer;
  final bool isFullScreen;

  const VideoFeedDisplay({
    super.key,
    required this.renderer,
    this.isFullScreen = false,
  });

  @override
  State<VideoFeedDisplay> createState() => _VideoFeedDisplayState();
}

class _VideoFeedDisplayState extends State<VideoFeedDisplay> {
  @override
  void initState() {
    super.initState();
    // Quando o renderer obtém dimensões reais, reconstrói o widget
    // para o AspectRatio usar o ratio correto em vez do fallback 16/9
    widget.renderer.onResize = () {
      if (mounted) setState(() {});
    };
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFullScreen) {
      return RTCVideoView(
        widget.renderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      );
    }

    // Na Web, o <video> HTML precisa de dimensões reais no primeiro render.
    // Qualquer container intermédio com constraints derivadas de videoWidth/Height=0
    // impede a stream de inicializar. Usamos SizedBox.expand para garantir
    // que o <video> recebe o espaço total disponível imediatamente.
    if (kIsWeb) {
      return SizedBox.expand(
        child: RTCVideoView(
          widget.renderer,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasRealDimensions =
            widget.renderer.videoWidth > 0 && widget.renderer.videoHeight > 0;

        final videoRatio = hasRealDimensions
            ? widget.renderer.videoWidth / widget.renderer.videoHeight
            : 16 / 9;

        return Center(
          child: AspectRatio(
            aspectRatio: videoRatio,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.outline.withAlpha(50)),
              ),
              child: RTCVideoView(
                widget.renderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
              ),
            ),
          ),
        );
      },
    );
  }
}
