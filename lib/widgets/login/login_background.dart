import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'dart:ui';

class LoginBackground extends StatefulWidget {
  const LoginBackground({super.key});

  @override
  State<LoginBackground> createState() => _LoginBackgroundState();
}

class _LoginBackgroundState extends State<LoginBackground> {
  // Tornamos as variáveis opcionais para evitar acesso antes da inicialização
  Player? _player;
  VideoController? _videoController;
  bool _isInitialized = false;

  final List<String> _videoUrls = [
    'https://res.cloudinary.com/dttvwjnxn/video/upload/f_auto,q_auto/v1769002678/video2_rvlrzi.mp4',
    'https://res.cloudinary.com/dttvwjnxn/video/upload/f_auto,q_auto/v1769002677/video3_hjka7u.mp4',
  ];

  @override
  void initState() {
    super.initState();
    _player = Player(
      configuration: const PlayerConfiguration(bufferSize: 32 * 1024 * 1024),
    );
    _videoController = VideoController(_player!);
    _setupPlayer();
  }

  Future<void> _setupPlayer() async {
    // Verificação de segurança inicial
    if (_player == null || !mounted) return;

    if (!kIsWeb) {
      final platform = _player!.platform;
      try {
        await (platform as dynamic)?.setProperty('cache', 'yes');
        await (platform as dynamic)?.setProperty(
          'demuxer-max-bytes',
          '50000000',
        );
        await (platform as dynamic)?.setProperty(
          'demuxer-readahead-secs',
          '30',
        );
      } catch (e) {
        debugPrint('Erro ao configurar propriedades do motor: $e');
      }
    }

    // Verificação após chamadas assíncronas
    if (!mounted) return;

    try {
      final playlist = Playlist(_videoUrls.map((url) => Media(url)).toList());

      await _player!.setVolume(0);
      await _player!.setPlaylistMode(PlaylistMode.loop);
      await _player!.open(playlist);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Erro ao iniciar playlist: $e');
    }
  }

  @override
  void dispose() {
    // Otimização: parar o player antes de destruir
    _player?.stop();
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Se ainda não inicializou, mostramos um fundo neutro para evitar flashes brancos
    if (!_isInitialized || _videoController == null) {
      return Container(color: isDark ? Colors.black : Colors.white);
    }

    return Stack(
      children: [
        SizedBox.expand(
          child: Video(
            controller: _videoController!,
            fit: BoxFit.cover,
            controls: NoVideoControls,
            fill: isDark ? Colors.black : Colors.white,
          ),
        ),
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
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
