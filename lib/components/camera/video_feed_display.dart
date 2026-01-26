import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoFeedDisplay extends StatelessWidget {
  final RTCVideoRenderer renderer;

  const VideoFeedDisplay({super.key, required this.renderer});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    double aspectRatio = (renderer.videoWidth > 0 && renderer.videoHeight > 0)
        ? renderer.videoWidth / renderer.videoHeight
        : 16 / 9;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outline.withAlpha(50)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: RTCVideoView(
            renderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
          ),
        ),
      ),
    );
  }
}
