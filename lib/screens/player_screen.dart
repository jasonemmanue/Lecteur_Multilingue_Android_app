// lib/screens/player_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../theme/app_colors.dart';

class PlayerScreen extends StatefulWidget {
  final String videoPath;
  const PlayerScreen({super.key, required this.videoPath});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _vpController;
  ChewieController? _chewieController;
  bool _isOriginalAudio = false; // false = audio traduit
  bool _showSubtitles   = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    // Activer la rotation pour le plein écran
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _initPlayer() async {
    final uri = Uri.tryParse(widget.videoPath);
    if (uri == null) return;

    _vpController = uri.isAbsolute && uri.scheme.startsWith('http')
        ? VideoPlayerController.networkUrl(uri)
        : VideoPlayerController.contentUri(uri);

    await _vpController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _vpController!,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.primary,
        handleColor: AppColors.primaryLight,
        backgroundColor: AppColors.border,
        bufferedColor: AppColors.bgSurface,
      ),
      placeholder: Container(color: AppColors.bgDark),
      errorBuilder: (_, msg) => Center(
        child: Text(msg,
            style: const TextStyle(color: AppColors.error)),
      ),
    );

    setState(() {});
  }

  @override
  void dispose() {
    // Remettre portrait uniquement en quittant
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _chewieController?.dispose();
    _vpController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('LinguaPlay'),
        actions: [
          // Bascule sous-titres
          IconButton(
            icon: Icon(
              _showSubtitles
                  ? Icons.subtitles_rounded
                  : Icons.subtitles_off_outlined,
              color: _showSubtitles ? AppColors.primary : Colors.white54,
            ),
            tooltip: 'Sous-titres',
            onPressed: () =>
                setState(() => _showSubtitles = !_showSubtitles),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Lecteur ──────────────────────────────────────────────────────
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _chewieController != null
                ? Chewie(controller: _chewieController!)
                : const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary)),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Bascule Audio Original / Traduit ───────────────────
                  const Text('Piste audio',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textMuted,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _AudioTrackButton(
                          label: 'Audio traduit',
                          icon: Icons.translate_rounded,
                          isActive: !_isOriginalAudio,
                          onTap: () =>
                              setState(() => _isOriginalAudio = false),
                        ),
                        _AudioTrackButton(
                          label: 'Audio original',
                          icon: Icons.record_voice_over_outlined,
                          isActive: _isOriginalAudio,
                          onTap: () =>
                              setState(() => _isOriginalAudio = true),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Infos sous-titres ─────────────────────────────────
                  if (_showSubtitles)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.subtitles_rounded,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Sous-titres traduits activés',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecond),
                            ),
                          ),
                          TextButton(
                            onPressed: () {/* TODO: export SRT */},
                            child: const Text('Exporter SRT',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioTrackButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _AudioTrackButton({
    required this.label, required this.icon,
    required this.isActive, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isActive
                      ? AppColors.primary
                      : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: isActive
                      ? AppColors.primaryLight
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}