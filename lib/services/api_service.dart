// lib/services/api_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/translation_job.dart';
import '../models/language.dart';
import '../services/secure_storage_service.dart';
import '../config/app_config.dart';

// ─── Exceptions ───────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final String message;
  final int?   statusCode;
  final String? detail;

  const ApiException(this.message, {this.statusCode, this.detail});

  @override
  String toString() => 'ApiException($statusCode): $message';

  String get userMessage {
    switch (statusCode) {
      case 401: return 'Session expirée. Veuillez vous reconnecter.';
      case 404: return 'Ressource introuvable.';
      case 413: return 'Fichier trop volumineux (max ${AppConfig.maxFileSizeMb} MB).';
      case 415: return 'Format de fichier non supporté.';
      case 422: return detail ?? 'Données invalides.';
      case 429: return 'Trop de traductions lancées. Réessayez dans une heure.';
      case 503: return 'Service temporairement indisponible.';
      default:  return message;
    }
  }
}

class NetworkException extends ApiException {
  const NetworkException()
      : super('Impossible de joindre le serveur. Vérifiez votre connexion.');
}

// ─── Service API ──────────────────────────────────────────────────────────────

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl:        AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers:        {'Content-Type': 'application/json'},
    ));

    // Intercepteur JWT — optionnel (mode invité si pas de token)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await SecureStorageService.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            // Si pas de token → requête sans auth (serveur accepte si route publique)
          } catch (_) {
            // Secure storage indisponible → on continue sans token
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  // ─── Helper erreurs ───────────────────────────────────────────────────────

  ApiException _handleError(Object e) {
    if (e is ApiException) return e;
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown ||
          e.type == DioExceptionType.connectionTimeout) {
        return const NetworkException();
      }
      final code   = e.response?.statusCode;
      final detail = e.response?.data is Map
          ? e.response?.data['detail']?.toString()
          : null;
      final msg    = e.response?.data is Map
          ? (e.response?.data['error']?.toString() ?? 'Erreur serveur')
          : (e.message ?? 'Erreur réseau');
      return ApiException(msg, statusCode: code, detail: detail);
    }
    return ApiException(e.toString());
  }

  // ─── Health check ─────────────────────────────────────────────────────────

  Future<bool> isApiReachable() async {
    try {
      final response = await _dio.get(
        '/health',
        options: Options(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── F01 : Upload vidéo ───────────────────────────────────────────────────

  Future<String> uploadVideo(
      File videoFile, {
        void Function(int received, int total)? onProgress,
      }) async {
    // Mode hors-ligne : simuler un video_id
    if (AppConfig.offlineMode) {
      await Future.delayed(const Duration(seconds: 2));
      return 'demo-video-${DateTime.now().millisecondsSinceEpoch}';
    }

    try {
      final sizeBytes = await videoFile.length();
      if (sizeBytes / (1024 * 1024) > AppConfig.maxFileSizeMb) {
        throw ApiException('Fichier trop volumineux', statusCode: 413);
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          videoFile.path,
          filename: videoFile.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/upload',
        data: formData,
        options: Options(
          contentType:  'multipart/form-data',
          sendTimeout:  AppConfig.uploadTimeout,
        ),
        onSendProgress: onProgress,
      );
      return response.data['video_id'] as String;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─── F01 : Import depuis URL ──────────────────────────────────────────────

  Future<String> importFromUrl(String url) async {
    if (AppConfig.offlineMode) {
      await Future.delayed(const Duration(seconds: 1));
      return 'demo-video-url-${DateTime.now().millisecondsSinceEpoch}';
    }
    try {
      final response = await _dio.post('/upload/url', data: {'url': url});
      return response.data['video_id'] as String;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─── F02 : Langues disponibles ────────────────────────────────────────────

  Future<List<Language>> getAvailableLanguages() async {
    // Toujours retourner la liste statique en mode invité ou hors-ligne
    if (AppConfig.offlineMode) return Language.supported;
    try {
      final response = await _dio.get('/languages');
      final list = response.data['languages'] as List<dynamic>;
      return list.map((l) => Language(
        code:        l['code'] as String,
        name:        l['name'] as String,
        flag:        l['flag'] as String,
        availableV1: l['available_v1'] as bool? ?? true,
      )).toList();
    } catch (_) {
      // Fallback sur liste statique si API indisponible
      return Language.supported;
    }
  }

  // ─── F03 : Lancer la traduction ───────────────────────────────────────────

  Future<String> startTranslation({
    required String videoId,
    required String targetLang,
  }) async {
    if (AppConfig.offlineMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return 'demo-job-${DateTime.now().millisecondsSinceEpoch}';
    }
    try {
      final response = await _dio.post('/translate', data: {
        'video_id':    videoId,
        'target_lang': targetLang,
      });
      return response.data['job_id'] as String;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─── F05 : Polling du statut ──────────────────────────────────────────────

  Future<TranslationJob> getJobStatus(String jobId) async {
    if (AppConfig.offlineMode) {
      // Simuler une progression pour le test
      await Future.delayed(const Duration(milliseconds: 300));
      return TranslationJob(
        jobId:       jobId,
        videoId:     'demo',
        targetLanguage: 'fr',
        status:      JobStatus.processing,
        progress:    45,
        currentStep: 'translation',
      );
    }
    try {
      final response = await _dio.get('/status/$jobId');
      return TranslationJob.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Télécharger la vidéo traduite ───────────────────────────────────────

  Future<String> downloadTranslatedVideo({
    required String jobId,
    required String savePath,
    void Function(int received, int total)? onProgress,
  }) async {
    if (AppConfig.offlineMode) return savePath;
    try {
      await _dio.download(
        '/download/$jobId',
        savePath,
        onReceiveProgress: onProgress,
        options: Options(receiveTimeout: AppConfig.receiveTimeout),
      );
      return savePath;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Supprimer une vidéo ──────────────────────────────────────────────────

  Future<void> deleteVideo(String videoId) async {
    if (AppConfig.offlineMode) return;
    try {
      await _dio.delete('/video/$videoId');
    } catch (e) {
      throw _handleError(e);
    }
  }
}