// lib/providers/library_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/video_item.dart';
import '../services/storage_service.dart';

final libraryProvider =
StateNotifierProvider<LibraryNotifier, List<VideoItem>>((ref) {
  return LibraryNotifier();
});

class LibraryNotifier extends StateNotifier<List<VideoItem>> {
  final _storage = StorageService();

  LibraryNotifier() : super([]) {
    _load();
  }

  void _load() {
    state = _storage.getAllVideos();
  }

  Future<void> addVideo(VideoItem video) async {
    await _storage.saveVideo(video);
    _load();
  }

  Future<void> removeVideo(String videoId) async {
    await _storage.deleteVideo(videoId);
    _load();
  }

  Future<void> addTranslation(String videoId, String langCode) async {
    final video = state.firstWhere((v) => v.id == videoId);
    final updated = [...video.translatedLanguages, langCode];
    await _storage.updateTranslatedLanguages(videoId, updated);
    _load();
  }

  Future<void> refresh() async {
    _load();
  }
}