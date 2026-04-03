// lib/services/download_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  final Dio _dio = Dio();

  /// Télécharge la vidéo traduite et retourne le chemin local du fichier
  Future<String> downloadTranslatedVideo({
    required String downloadUrl,
    required String jobId,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final dir = await _getVideoDirectory();
    final filePath = '${dir.path}/translated_$jobId.mp4';

    await _dio.download(
      downloadUrl,
      filePath,
      cancelToken: cancelToken,
      onReceiveProgress: onProgress,
      options: Options(
        receiveTimeout: const Duration(minutes: 10),
      ),
    );

    return filePath;
  }

  /// Supprime une vidéo locale
  Future<void> deleteLocalVideo(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Retourne la taille du cache vidéo en octets
  Future<int> getCacheSize() async {
    final dir = await _getVideoDirectory();
    int total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  /// Vide le cache des vidéos téléchargées
  Future<void> clearCache() async {
    final dir = await _getVideoDirectory();
    await for (final entity in dir.list()) {
      await entity.delete(recursive: true);
    }
  }

  /// Formate la taille en MB lisible
  static String formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<Directory> _getVideoDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${appDir.path}/videos');
    if (!await videoDir.exists()) await videoDir.create(recursive: true);
    return videoDir;
  }
}