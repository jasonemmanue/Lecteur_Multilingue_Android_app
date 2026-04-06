// lib/services/download_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadService {
  final Dio _dio = Dio();

  Future<String> downloadTranslatedVideo({
    required String downloadUrl,
    required String jobId,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final dir      = await getPublicVideoDirectory();
    final filePath = '${dir.path}/linguaplay_$jobId.mp4';

    await _dio.download(
      downloadUrl,
      filePath,
      cancelToken:       cancelToken,
      onReceiveProgress: onProgress,
      options: Options(receiveTimeout: const Duration(minutes: 10)),
    );

    return filePath;
  }

  /// Dossier public visible dans le gestionnaire de fichiers
  Future<Directory> getPublicVideoDirectory() async {
    if (Platform.isAndroid) {
      final sdkInt = await _getAndroidSdkInt();
      if (sdkInt < 29) {
        final status = await Permission.storage.request();
        if (!status.isGranted) return _getFallbackDirectory();
      }
      const path = '/storage/emulated/0/Movies/LinguaPlay';
      final dir  = Directory(path);
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    }
    return _getFallbackDirectory();
  }

  Future<Directory> _getFallbackDirectory() async {
    final appDir   = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${appDir.path}/videos');
    if (!await videoDir.exists()) await videoDir.create(recursive: true);
    return videoDir;
  }

  Future<int> _getAndroidSdkInt() async {
    try {
      final result = await Process.run('getprop', ['ro.build.version.sdk']);
      return int.tryParse(result.stdout.toString().trim()) ?? 29;
    } catch (_) {
      return 29;
    }
  }

  Future<void> deleteLocalVideo(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) await file.delete();
  }

  Future<int> getCacheSize() async {
    final dir   = await getPublicVideoDirectory();
    int   total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  Future<void> clearCache() async {
    final dir = await getPublicVideoDirectory();
    await for (final entity in dir.list()) {
      await entity.delete(recursive: true);
    }
  }

  static String formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}