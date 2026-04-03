// lib/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/import_screen.dart';
import '../screens/language_picker_screen.dart';
import '../screens/processing_screen.dart';
import '../screens/player_screen.dart';
import '../screens/library_screen.dart';
import '../screens/settings_screen.dart';

class AppRoutes {
  static const String splash        = '/';
  static const String home          = '/home';
  static const String import        = '/import';
  static const String languagePicker = '/language-picker';
  static const String processing    = '/processing';
  static const String player        = '/player';
  static const String library       = '/library';
  static const String settings      = '/settings';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => HomeScreen(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: AppRoutes.library,
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.import,
      builder: (context, state) => const ImportScreen(),
    ),
    GoRoute(
      path: AppRoutes.languagePicker,
      builder: (context, state) {
        final videoId = state.extra as String? ?? '';
        return LanguagePickerScreen(videoId: videoId);
      },
    ),
    GoRoute(
      path: AppRoutes.processing,
      builder: (context, state) {
        final jobId = state.extra as String? ?? '';
        return ProcessingScreen(jobId: jobId);
      },
    ),
    GoRoute(
      path: AppRoutes.player,
      builder: (context, state) {
        final videoPath = state.extra as String? ?? '';
        return PlayerScreen(videoPath: videoPath);
      },
    ),
  ],
);