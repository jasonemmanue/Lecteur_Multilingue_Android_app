// lib/services/api_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/translation_job.dart';
import '../models/language.dart';

class ApiService {
  static const String _baseUrl = 'https://votre-api.linguaplay.app'; // À remplacer

  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    // Intercepteur pour le JWT
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // TODO: injecter le token JWT depuis le secure storage
          // final token = await SecureStorageService.getToken();
          // options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  // ─── F01 : Upload vidéo ───────────────────────────────────────────────────

  Future<String> uploadVideo(File videoFile) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        videoFile.path,
        filename: videoFile.path.split('/').last,
      ),
    });

    final response = await _dio.post('/upload', data: formData);
    return response.data['video_id'] as String;
  }

  // ─── F03 : Lancer la traduction ───────────────────────────────────────────

  Future<String> startTranslation({
    required String videoId,
    required String targetLang,
  }) async {
    final response = await _dio.post('/translate', data: {
      'video_id': videoId,
      'target_lang': targetLang,
    });
    return response.data['job_id'] as String;
  }

  // ─── F05 : Polling du statut ──────────────────────────────────────────────

  Future<TranslationJob> getJobStatus(String jobId) async {
    final response = await _dio.get('/status/$jobId');
    return TranslationJob.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Télécharger la vidéo traduite ───────────────────────────────────────

  Future<void> downloadTranslatedVideo({
    required String jobId,
    required String savePath,
    void Function(int, int)? onProgress,
  }) async {
    await _dio.download(
      '/download/$jobId',
      savePath,
      onReceiveProgress: onProgress,
    );
  }

  // ─── Liste des langues disponibles ───────────────────────────────────────

  Future<List<Language>> getAvailableLanguages() async {
    // En V1 on retourne la liste statique, l'API confirmera en V2
    return Language.supported.where((l) => l.availableV1).toList();
  }

  // ─── Supprimer une vidéo ──────────────────────────────────────────────────

  Future<void> deleteVideo(String videoId) async {
    await _dio.delete('/video/$videoId');
  }
}