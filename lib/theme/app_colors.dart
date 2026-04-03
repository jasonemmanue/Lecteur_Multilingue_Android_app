// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary      = Color(0xFF7C5CFC);
  static const Color primaryLight = Color(0xFFA98BFD);
  static const Color accent       = Color(0xFF34D399);
  static const Color warning      = Color(0xFFF59E0B);
  static const Color error        = Color(0xFFF87171);

  static const Color bgDark       = Color(0xFF0D0F14);
  static const Color bgCard       = Color(0xFF131720);
  static const Color bgSurface    = Color(0xFF1A1F2E);
  static const Color border       = Color(0xFF1E2635);

  static const Color textPrimary  = Color(0xFFE2E8F0);
  static const Color textSecond   = Color(0xFF94A3B8);
  static const Color textMuted    = Color(0xFF64748B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C5CFC), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF131720), Color(0xFF1A1F2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}