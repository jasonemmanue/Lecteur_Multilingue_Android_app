// lib/screens/library_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../router/app_router.dart';
import '../models/video_item.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: brancher sur LibraryProvider avec Riverpod
    const List<VideoItem> videos = []; // remplacer par ref.watch(libraryProvider)

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('LinguaPlay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {/* TODO: recherche */},
          ),
        ],
      ),
      body: videos.isEmpty
          ? _EmptyState(onImport: () => context.push(AppRoutes.import))
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: videos.length,
        itemBuilder: (context, i) => _VideoCard(video: videos[i]),
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.video_library_outlined,
              color: AppColors.textMuted,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucune vidéo importée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
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
  final VideoItem video;
  const _VideoCard({required this.video});

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
              // Miniature
              Container(
                width: 80,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: video.thumbnailPath != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(video.thumbnailPath!, fit: BoxFit.cover),
                )
                    : const Icon(
                  Icons.play_circle_filled_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              // Infos
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
                    if (video.translatedLanguages.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: video.translatedLanguages
                            .map((l) => _LangBadge(langCode: l))
                            .toList(),
                      ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textMuted),
                color: AppColors.bgSurface,
                onSelected: (value) {
                  if (value == 'translate') {
                    context.push(AppRoutes.languagePicker,
                        extra: video.id);
                  }
                  // TODO: 'delete', 'share'
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'translate',
                    child: Text('Traduire'),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Text('Partager'),
                  ),
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