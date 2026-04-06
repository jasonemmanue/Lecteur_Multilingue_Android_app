// lib/config/app_config.dart
class AppConfig {
  AppConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  // ── Mode hors-ligne (test UI sans API) ──────────────────────────────────────
  static const bool offlineMode = bool.fromEnvironment(
    'OFFLINE_MODE',
    defaultValue: false,
  );

  // ── Timeouts ────────────────────────────────────────────────────────────────
  static const Duration connectTimeout  = Duration(seconds: 30);
  static const Duration receiveTimeout  = Duration(minutes: 10);
  static const Duration uploadTimeout   = Duration(minutes: 5);

  // ── Polling ─────────────────────────────────────────────────────────────────
  static const Duration pollingInterval   = Duration(seconds: 4);
  static const int      maxPollingRetries = 3;

  // ── Upload ──────────────────────────────────────────────────────────────────
  static const int maxFileSizeMb = 500;
  static const List<String> allowedExtensions = [
    'mp4', 'mkv', 'avi', 'mov', 'webm'
  ];

  // ── File d'attente ──────────────────────────────────────────────────────────
  static const int maxQueueSize = 5;

  // ── Clés Hive ────────────────────────────────────────────────────────────────
  static const String keyDefaultLanguage = 'pref_default_language';
  static const String keyJwtToken        = 'jwt_token';
  static const String keyUserId          = 'user_id';
  static const String keyGuestMode       = 'guest_mode';
}