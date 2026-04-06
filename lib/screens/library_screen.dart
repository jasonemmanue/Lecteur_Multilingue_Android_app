// lib/screens/library_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../router/app_router.dart';
import '../models/video_item.dart';
import '../providers/library_provider.dart';
import '../providers/queue_provider.dart';
import '../services/api_service.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videos = ref.watch(libraryProvider);
    final queue  = ref.watch(queueProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('LinguaPlay'),
        actions: [
          if (videos.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => showSearch(
                context: context,
                delegate: _VideoSearchDelegate(videos),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (queue.entries.isNotEmpty)
            _QueueBanner(entries: queue.entries),
          Expanded(
            child: videos.isEmpty
                ? _EmptyState(
                onImport: () => context.push(AppRoutes.import))
                : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async =>
                  ref.read(libraryProvider.notifier).refresh(),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: videos.length,
                itemBuilder: (context, i) => _VideoCard(
                  video: videos[i],
                  onDelete: () => _confirmDelete(context, ref, videos[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, VideoItem video,
      ) async {
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
          'Supprimer "${video.title}" et tous ses fichiers ?',
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
      try {
        await ApiService().deleteVideo(video.id);
      } catch (_) {}
      ref.read(libraryProvider.notifier).removeVideo(video.id);
    }
  }
}

// ─── Bannière file d'attente ──────────────────────────────────────────────────

class _QueueBanner extends StatelessWidget {
  final List<QueueEntry> entries;
  const _QueueBanner({required this.entries});

  @override
  Widget build(BuildContext context) {
    final active = entries.where((e) =>
    e.job.status.name == 'processing' ||
        e.job.status.name == 'pending').toList();
    if (active.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${active.length} traduction${active.length > 1 ? 's' : ''} en cours…',
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${active.first.job.progress}%',
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── État vide ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onImport;
  const _EmptyState({required this.onImport});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.video_library_outlined,
                color: AppColors.textMuted, size: 36),
          ),
          const SizedBox(height: 20),
          const Text('Aucune vidéo importée',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'Importez une vidéo depuis votre galerie\nou via une URL pour commencer',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecond),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: onImport,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Importer une vidéo'),
          ),
        ],
      ),
    );
  }
}

// ─── Carte vidéo ──────────────────────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  final VideoItem    video;
  final VoidCallback onDelete;

  const _VideoCard({required this.video, required this.onDelete});

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutes.player, extra: video.localPath),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 88, height: 60,
                  child: _VideoThumbnail(
                    thumbnailPath: video.thumbnailPath,
                    duration:      video.duration,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(video.importedAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                    if (video.translatedLanguages.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: video.translatedLanguages
                            .map((l) => _LangBadge(langCode: l))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textMuted),
                color: AppColors.bgSurface,
                onSelected: (value) {
                  if (value == 'translate') {
                    context.push(AppRoutes.languagePicker, extra: video.id);
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'translate', child: Text('Traduire')),
                  PopupMenuItem(value: 'share',     child: Text('Partager')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Supprimer',
                        style: TextStyle(color: AppColors.error)),
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

// ─── Miniature vidéo ──────────────────────────────────────────────────────────

class _VideoThumbnail extends StatelessWidget {
  final String?   thumbnailPath;
  final Duration? duration;

  const _VideoThumbnail({this.thumbnailPath, this.duration});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (thumbnailPath != null && File(thumbnailPath!).existsSync())
          Image.file(File(thumbnailPath!), fit: BoxFit.cover)
        else
          Container(
            color: AppColors.bgSurface,
            child: const Icon(Icons.play_circle_filled_rounded,
                color: AppColors.primary, size: 32),
          ),
        if (duration != null)
          Positioned(
            bottom: 4, right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${duration!.inMinutes}:'
                    '${(duration!.inSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Badge langue ─────────────────────────────────────────────────────────────

class _LangBadge extends StatelessWidget {
  final String langCode;
  const _LangBadge({required this.langCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Text(
        langCode.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryLight,
        ),
      ),
    );
  }
}

// ─── Recherche ────────────────────────────────────────────────────────────────

class _VideoSearchDelegate extends SearchDelegate<VideoItem?> {
  final List<VideoItem> videos;
  _VideoSearchDelegate(this.videos);

  @override
  String get searchFieldLabel => 'Rechercher une vidéo…';

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  // ✅ Un seul buildLeading, avec la bonne signature
  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    final filtered = videos
        .where((v) => v.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text('Aucun résultat',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (_, i) => _VideoCard(
        video: filtered[i],
        onDelete: () {},
      ),
    );
  }

  // ✅ Signature correcte pour Flutter SearchDelegate
  @override
  void close(BuildContext context, VideoItem? result) {
    super.close(context, result);
  }
}