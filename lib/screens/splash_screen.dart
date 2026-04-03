// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../router/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );

    _ctrl.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go(AppRoutes.home);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 32,
                        spreadRadius: 4,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.play_circle_outline_rounded,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'LinguaPlay',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lecteur vidéo multilingue',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecond,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}