// lib/screens/import_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import '../theme/app_colors.dart';
import '../router/app_router.dart';
import '../services/api_service.dart';
import '../services/download_service.dart';
import '../providers/library_provider.dart';
import '../models/video_item.dart';
import '../config/app_config.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final _urlController = TextEditingController();
  bool    _isUploading    = false;
  int     _uploadProgress = 0;
  String? _uploadError;

  final _api             = ApiService();
  final _downloadService = DownloadService();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  // ── Sélection galerie ─────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    final result = await FilePicker.platform.pickFiles(
      type:          FileType.video,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;

    await _uploadAndNavigate(File(path));
  }

  Future<void> _uploadAndNavigate(File file) async {
    setState(() {
      _isUploading    = true;
      _uploadError    = null;
      _uploadProgress = 0;
    });

    try {
      final videoId = await _api.uploadVideo(
        file,
        onProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() =>
            _uploadProgress = (received / total * 100).round());
          }
        },
      );
      if (mounted) {
        context.pushReplacement(AppRoutes.languagePicker, extra: videoId);
      }
    } on NetworkException catch (_) {
      setState(() => _uploadError =
      'Impossible de joindre le serveur.\n'
          'Vérifiez que l\'API est lancée et que l\'URL est correcte :\n'
          '${AppConfig.baseUrl}');
    } on ApiException catch (e) {
      setState(() => _uploadError = e.userMessage);
    } catch (e) {
      setState(() => _uploadError = 'Erreur inattendue : $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ── Import URL ────────────────────────────────────────────────────────────

  Future<void> _importFromUrl(String url) async {
    if (url.trim().isEmpty) return;
    Navigator.pop(context);

    setState(() { _isUploading = true; _uploadError = null; });

    try {
      final videoId = await _api.importFromUrl(url.trim());
      if (mounted) {
        context.pushReplacement(AppRoutes.languagePicker, extra: videoId);
      }
    } on NetworkException catch (_) {
      setState(() => _uploadError =
      'Serveur inaccessible. Vérifiez votre réseau et l\'URL API : '
          '${AppConfig.baseUrl}');
    } on ApiException catch (e) {
      setState(() => _uploadError = e.userMessage);
    } catch (e) {
      setState(() => _uploadError = 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ── Supprimer une vidéo de l'historique ──────────────────────────────────

  Future<void> _deleteVideo(VideoItem video) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Supprimer ?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Supprimer "${video.title}" de l\'historique ?',
          style: const TextStyle(color: AppColors.textSecond, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _downloadService.deleteLocalVideo(video.localPath);
      await ref.read(libraryProvider.notifier).removeVideo(video.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final videos = ref.watch(libraryProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('LinguaPlay')),
      body: _isUploading
          ? _UploadingIndicator(progress: _uploadProgress)
          : Column(
        children: [
          // ── Historique des vidéos traduites ───────────────────────
          Expanded(
            child: videos.isEmpty
                ? _EmptyHistory()
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: videos.length,
              itemBuilder: (context, i) => _HistoryCard(
                video:    videos[i],
                onTap: () => context.push(
                  AppRoutes.player,
                  extra: videos[i].localPath,
                ),
                onDelete: () => _deleteVideo(videos[i]),
              ),
            ),
          ),

          // ── Erreur ────────────────────────────────────────────────
          if (_uploadError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_uploadError!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 13)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 16, color: AppColors.textMuted),
                      padding:     EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          setState(() => _uploadError = null),
                    ),
                  ],
                ),
              ),
            ),

          // ── Bouton Importer — fixe en bas ─────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            decoration: const BoxDecoration(
              color:  AppColors.bgCard,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon:  const Icon(Icons.add_rounded),
                    label: const Text('Importer une vidéo'),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                  ),
                ),
                const SizedBox(width: 10),
                // Bouton URL
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color:        AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(14),
                    border:       Border.all(color: AppColors.border),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.link_rounded,
                        color: AppColors.accent),
                    tooltip:   'Importer depuis une URL',
                    onPressed: () => _showUrlDialog(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUrlDialog(BuildContext context) {
    _urlController.clear();
    showModalBottomSheet(
      context:            context,
      backgroundColor:    AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Coller un lien vidéo',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller:  _urlController,
              autofocus:   true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText:  'https://youtube.com/watch?v=...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled:    true,
                fillColor: AppColors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                prefixIcon: const Icon(Icons.link_rounded,
                    color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _importFromUrl(_urlController.text),
              child: const Text('Importer'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets internes ─────────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color:        AppColors.bgSurface,
              borderRadius: BorderRadius.circular(20),
              border:       Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.video_library_outlined,
                color: AppColors.textMuted, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('Aucune vidéo traduite',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text(
            'Importez une vidéo et lancez une traduction\npour la retrouver ici',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecond),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final VideoItem    video;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.video,
    required this.onTap,
    required this.onDelete,
  });

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';

  @override
  Widget build(BuildContext context) {
    final fileExists = File(video.localPath).existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap:        fileExists ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Miniature / icône
              Container(
                width: 64, height: 48,
                decoration: BoxDecoration(
                  color:        AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border:       Border.all(color: AppColors.border),
                ),
                child: Icon(
                  fileExists
                      ? Icons.play_circle_filled_rounded
                      : Icons.broken_image_outlined,
                  color: fileExists
                      ? AppColors.primary
                      : AppColors.textMuted,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.basenameWithoutExtension(video.localPath)
                          .replaceAll('_', ' '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w600,
                        color: fileExists
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(video.importedAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                    if (video.translatedLanguages.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: video.translatedLanguages
                            .map((l) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(l.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.w600)),
                        ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              Column(
                children: [
                  if (fileExists)
                    IconButton(
                      icon: const Icon(Icons.play_arrow_rounded,
                          color: AppColors.primary),
                      onPressed: onTap,
                      tooltip: 'Lire',
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Supprimer',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadingIndicator extends StatelessWidget {
  final int progress;
  const _UploadingIndicator({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100, height: 100,
                  child: CircularProgressIndicator(
                    value:           progress > 0 ? progress / 100 : null,
                    strokeWidth:     6,
                    color:           AppColors.primary,
                    backgroundColor: AppColors.border,
                  ),
                ),
                if (progress > 0)
                  Text('$progress%',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Upload en cours…',
                style: TextStyle(
                    color: AppColors.textSecond, fontSize: 16,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text('Ne fermez pas l\'application',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}