// lib/providers/queue_provider.dart
// Gère la file d'attente de traductions simultanées.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/translation_job.dart';
import '../config/app_config.dart';

// ─── État de la file ──────────────────────────────────────────────────────────

class QueueState {
  final List<QueueEntry> entries;

  const QueueState({this.entries = const []});

  int get activeCount => entries.where((e) =>
  e.job.status == JobStatus.processing ||
      e.job.status == JobStatus.pending
  ).length;

  bool get isFull => activeCount >= AppConfig.maxQueueSize;

  QueueState copyWith({List<QueueEntry>? entries}) =>
      QueueState(entries: entries ?? this.entries);
}

class QueueEntry {
  final String    videoId;
  final String    videoTitle;
  final String    targetLanguage;
  final TranslationJob job;

  const QueueEntry({
    required this.videoId,
    required this.videoTitle,
    required this.targetLanguage,
    required this.job,
  });

  QueueEntry copyWith({TranslationJob? job}) => QueueEntry(
    videoId:        videoId,
    videoTitle:     videoTitle,
    targetLanguage: targetLanguage,
    job:            job ?? this.job,
  );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class QueueNotifier extends StateNotifier<QueueState> {
  QueueNotifier() : super(const QueueState());

  /// Ajoute un job à la file d'attente.
  void enqueue({
    required String videoId,
    required String videoTitle,
    required String targetLanguage,
    required TranslationJob job,
  }) {
    if (state.isFull) return;

    final entry = QueueEntry(
      videoId:        videoId,
      videoTitle:     videoTitle,
      targetLanguage: targetLanguage,
      job:            job,
    );

    state = state.copyWith(entries: [...state.entries, entry]);
  }

  /// Met à jour le statut d'un job dans la file.
  void updateJob(String jobId, TranslationJob updatedJob) {
    final updated = state.entries.map((e) {
      return e.job.jobId == jobId ? e.copyWith(job: updatedJob) : e;
    }).toList();
    state = state.copyWith(entries: updated);
  }

  /// Retire un job terminé ou en erreur de la file.
  void dequeue(String jobId) {
    final filtered = state.entries
        .where((e) => e.job.jobId != jobId)
        .toList();
    state = state.copyWith(entries: filtered);
  }

  /// Retourne l'entrée correspondant à un jobId.
  QueueEntry? findByJobId(String jobId) {
    try {
      return state.entries.firstWhere((e) => e.job.jobId == jobId);
    } catch (_) {
      return null;
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final queueProvider = StateNotifierProvider<QueueNotifier, QueueState>((ref) {
  return QueueNotifier();
});