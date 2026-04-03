// lib/models/video_item.dart
import 'package:hive/hive.dart';

part 'video_item.g.dart';

@HiveType(typeId: 0)
class VideoItem extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String title;
  @HiveField(2) final String localPath;
  @HiveField(3) final String? thumbnailPath;
  @HiveField(4) final int? durationMs;
  @HiveField(5) final DateTime importedAt;
  @HiveField(6) final String? sourceLanguage;
  @HiveField(7) final List<String> translatedLanguages;

  VideoItem({
    required this.id,
    required this.title,
    required this.localPath,
    this.thumbnailPath,
    this.durationMs,
    required this.importedAt,
    this.sourceLanguage,
    this.translatedLanguages = const [],
  });

  Duration? get duration =>
      durationMs != null ? Duration(milliseconds: durationMs!) : null;

  VideoItem copyWith({
    String? id,
    String? title,
    String? localPath,
    String? thumbnailPath,
    int? durationMs,
    DateTime? importedAt,
    String? sourceLanguage,
    List<String>? translatedLanguages,
  }) {
    return VideoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      localPath: localPath ?? this.localPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      durationMs: durationMs ?? this.durationMs,
      importedAt: importedAt ?? this.importedAt,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      translatedLanguages: translatedLanguages ?? this.translatedLanguages,
    );
  }
}