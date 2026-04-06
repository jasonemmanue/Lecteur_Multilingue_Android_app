// lib/screens/player_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:path/path.dart' as p;
import '../theme/app_colors.dart';
import '../services/download_service.dart';
import '../providers/library_provider.dart';
import '../models/video_item.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String videoPath;
  const PlayerScreen({super.key, required this.videoPath});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  VideoPlayerController? _vpController;
  ChewieController?      _chewieController;
  bool _isOriginalAudio  = false;
  bool _showSubtitles    = true;
  bool _isSaving         = false;
  bool _isSaved          = false;
  String? _saveError;

  final _downloadService = DownloadService();

  @override
  void initState() {
    super.initState();
    _initPlayer();
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
      autoPlay:    true,
      looping:     false,
      allowFullScreen: true,
      materialProgressColors: ChewieProgressColors(
        playedColor:     AppColors.primary,
        handleColor:     AppColors.primaryLight,
        backgroundColor: AppColors.border,
        bufferedColor:   AppColors.bgSurface,
      ),
      placeholder:  Container(color: AppColors.bgDark),
      errorBuilder: (_, msg) => Center(
        child: Text(msg, style: const TextStyle(color: AppColors.error)),
      ),
    );

    setState(() {});
  }

  // ── Sauvegarde locale ──────────────────────────────────────────────────────

  Future<void> _saveToDevice() async {
    if (_isSaved || _isSaving) return;
    setState(() { _isSaving = true; _saveError = null; });

    try {
      // Copier dans Movies/LinguaPlay si pas déjà là
      final sourcePath = widget.videoPath;
      String finalPath = sourcePath;

      if (!sourcePath.contains('/Movies/LinguaPlay')) {
        final dir      = await _downloadService.getPublicVideoDirectory();
        final fileName = p.basename(sourcePath);
        finalPath = '${dir.path}/$fileName';
        await File(sourcePath).copy(finalPath);
      }

      // Ajouter à la bibliothèque Hive
      final videoId = p.basenameWithoutExtension(finalPath)
          .replaceAll('linguaplay_', '')
          .replaceAll('translated_', '');

      final already = ref.read(libraryProvider)
          .any((v) => v.localPath == finalPath);

      if (!already) {
        final item = VideoItem(
          id:         videoId,
          title:      p.basenameWithoutExtension(finalPath)
              .replaceAll('_', ' '),
          localPath:  finalPath,
          importedAt: DateTime.now(),
          translatedLanguages: const [],
        );
        await ref.read(libraryProvider.notifier).addVideo(item);
      }

      if (mounted) setState(() { _isSaved = true; _isSaving = false; });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Vidéo sauvegardée dans Movies/LinguaPlay',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.accent,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving  = false;
          _saveError = 'Erreur : $e';
        });
      }
    }
  }

  @override
  void dispose() {
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Bascule audio ─────────────────────────────────────
                  const Text('Piste audio',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textMuted,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color:        AppColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border:       Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _AudioTrackButton(
                          label:    'Audio traduit',
                          icon:     Icons.translate_rounded,
                          isActive: !_isOriginalAudio,
                          onTap: () =>
                              setState(() => _isOriginalAudio = false),
                        ),
                        _AudioTrackButton(
                          label:    'Audio original',
                          icon:     Icons.record_voice_over_outlined,
                          isActive: _isOriginalAudio,
                          onTap: () =>
                              setState(() => _isOriginalAudio = true),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Sous-titres ───────────────────────────────────────
                  if (_showSubtitles)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:        AppColors.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border:       Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.subtitles_rounded,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text('Sous-titres traduits activés',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecond)),
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

                  // ── Erreur sauvegarde ─────────────────────────────────
                  if (_saveError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:        AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.error.withOpacity(0.4)),
                      ),
                      child: Text(_saveError!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 13)),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Bouton Télécharger — fixe en bas ─────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: const BoxDecoration(
              color:  AppColors.bgCard,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: ElevatedButton.icon(
              onPressed: _isSaving || _isSaved ? null : _saveToDevice,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: _isSaved
                    ? AppColors.accent
                    : AppColors.primary,
                disabledBackgroundColor: _isSaved
                    ? AppColors.accent.withOpacity(0.7)
                    : AppColors.bgSurface,
              ),
              icon: _isSaving
                  ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : Icon(
                _isSaved
                    ? Icons.check_circle_rounded
                    : Icons.download_rounded,
                color: Colors.white,
              ),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _isSaving
                      ? 'Sauvegarde…'
                      : _isSaved
                      ? 'Sauvegardé ✓'
                      : 'Télécharger',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widget bouton piste audio ────────────────────────────────────────────────

class _AudioTrackButton extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final bool         isActive;
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
                  size:  16,
                  color: isActive ? AppColors.primary : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    color: isActive
                        ? AppColors.primaryLight
                        : AppColors.textMuted,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}