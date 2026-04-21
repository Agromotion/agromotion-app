import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoFeedDisplay extends StatelessWidget {
  final RTCVideoRenderer renderer;
  final bool isFullScreen;
  const VideoFeedDisplay({
    super.key,
    required this.renderer,
    this.isFullScreen = false, // Por defeito false
  });

  @override
  Widget build(BuildContext context) {
    if (isFullScreen) {
      return RTCVideoView(
        renderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        double videoRatio =
            (renderer.videoWidth > 0 && renderer.videoHeight > 0)
            ? renderer.videoWidth / renderer.videoHeight
            : 16 / 9;

        return Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight,
            ),
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
                  renderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
