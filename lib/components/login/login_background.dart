import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';

class LoginBackground extends StatefulWidget {
  const LoginBackground({super.key});
  @override
  State<LoginBackground> createState() => _LoginBackgroundState();
}

class _LoginBackgroundState extends State<LoginBackground> {
  VideoPlayerController? _controller;
  int _currentVideoIndex = 0;
  bool _isChangingVideo = false;

  final List<String> _videoAssets = ['assets/login_videos/video5.MP4'];

  @override
  void initState() {
    super.initState();
    _initializeAndPlay(_currentVideoIndex);
  }

  Future<void> _initializeAndPlay(int index) async {
    final VideoPlayerController newController = VideoPlayerController.asset(
      _videoAssets[index],
    );

    try {
      await newController.initialize();
      await newController.setVolume(0.0);

      if (mounted) {
        final oldController = _controller;
        setState(() {
          _controller = newController;
          _isChangingVideo = false;
        });

        _controller!.play();
        _controller!.addListener(_videoListener);

        if (oldController != null) {
          await oldController.pause();
          await oldController.dispose();
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar vídeo: $e');
      _playNextVideo();
    }
  }

  void _videoListener() {
    if (_controller == null || _isChangingVideo) return;

    // Verifica se o vídeo chegou ao fim
    final bool isFinished =
        _controller!.value.position >=
        (_controller!.value.duration - const Duration(milliseconds: 500));

    if (isFinished && !_controller!.value.isLooping) {
      _isChangingVideo = true;
      _controller!.removeListener(_videoListener);
      _playNextVideo();
    }
  }

  void _playNextVideo() {
    _currentVideoIndex = (_currentVideoIndex + 1) % _videoAssets.length;
    _initializeAndPlay(_currentVideoIndex);
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Vídeo
        SizedBox.expand(
          child: _controller != null && _controller!.value.isInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                )
              : Container(color: isDark ? Colors.black : Colors.white),
        ),

        // Blur e Overlay
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14.0, sigmaY: 14.0),
              child: Container(
                color: isDark
                    ? Colors.black.withAlpha(40)
                    : Colors.white.withAlpha(20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
