// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    // ✅ v21 : paramètre nommé 'settings:'
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    const channel = AndroidNotificationChannel(
      'linguaplay_translations',
      'Traductions LinguaPlay',
      description: 'Notifications de fin de traduction vidéo',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  static Future<void> notifyTranslationDone({
    required String videoTitle,
    required String targetLanguage,
    int notificationId = 0,
  }) async {
    // ✅ v21 : paramètre nommé 'id:'
    await _plugin.show(
      id: notificationId,
      title: '✅ Traduction terminée',
      body: '"$videoTitle" est disponible en $targetLanguage',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'linguaplay_translations',
          'Traductions LinguaPlay',
          channelDescription: 'Notifications de fin de traduction vidéo',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  static Future<void> notifyTranslationError({
    required String videoTitle,
    String? errorMessage,
    int notificationId = 1,
  }) async {
    await _plugin.show(
      id: notificationId,
      title: '❌ Traduction échouée',
      body: '"$videoTitle" — ${errorMessage ?? 'Une erreur est survenue'}',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'linguaplay_translations',
          'Traductions LinguaPlay',
          channelDescription: 'Notifications de fin de traduction vidéo',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  static void _onNotificationTap(NotificationResponse response) {}
}