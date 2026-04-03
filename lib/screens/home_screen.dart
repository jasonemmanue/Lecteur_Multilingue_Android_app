// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../router/app_router.dart';

class HomeScreen extends StatelessWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith(AppRoutes.library)) return 0;
    if (loc.startsWith(AppRoutes.settings)) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.import),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Importer',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.bgCard,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.video_library_outlined,
              activeIcon: Icons.video_library_rounded,
              label: 'Bibliothèque',
              isActive: _selectedIndex(context) == 0,
              onTap: () => context.go(AppRoutes.library),
            ),
            const SizedBox(width: 60), // espace FAB
            _NavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings_rounded,
              label: 'Paramètres',
              isActive: _selectedIndex(context) == 1,
              onTap: () => context.go(AppRoutes.settings),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}