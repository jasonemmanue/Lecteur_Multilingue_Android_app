// lib/services/storage_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/video_item.dart';

class StorageService {
  static const String _videosBoxName = 'videos';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(VideoItemAdapter());
    await Hive.openBox<VideoItem>(_videosBoxName);
  }

  static Box<VideoItem> get _box => Hive.box<VideoItem>(_videosBoxName);

  // ── CRUD vidéos ────────────────────────────────────────────────────────────

  Future<void> saveVideo(VideoItem video) async {
    await _box.put(video.id, video);
  }

  Future<void> deleteVideo(String videoId) async {
    await _box.delete(videoId);
  }

  Future<VideoItem?> getVideo(String videoId) async {
    return _box.get(videoId);
  }

  List<VideoItem> getAllVideos() {
    final videos = _box.values.toList();
    videos.sort((a, b) => b.importedAt.compareTo(a.importedAt));
    return videos;
  }

  Future<void> updateTranslatedLanguages(
      String videoId,
      List<String> languages,
      ) async {
    final video = _box.get(videoId);
    if (video == null) return;
    await _box.put(videoId, video.copyWith(translatedLanguages: languages));
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}