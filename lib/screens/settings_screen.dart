// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoDownload = false;
  bool _keepOriginalAudio = true;
  bool _showSubtitlesByDefault = true;
  String _defaultLanguage = 'fr';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Section Traduction ──────────────────────────────────────────
          _SectionHeader(title: 'Traduction'),
          const SizedBox(height: 10),

          _SettingsCard(
            children: [
              _DropdownTile(
                icon: Icons.language_rounded,
                title: 'Langue par défaut',
                subtitle: 'Langue cible pour les nouvelles traductions',
                value: _defaultLanguage,
                items: const {
                  'fr': '🇫🇷  Français',
                  'en': '🇬🇧  English',
                  'es': '🇪🇸  Español',
                  'de': '🇩🇪  Deutsch',
                  'pt': '🇧🇷  Português',
                  'ar': '🇸🇦  العربية',
                  'zh': '🇨🇳  中文',
                  'ja': '🇯🇵  日本語',
                },
                onChanged: (v) => setState(() => _defaultLanguage = v!),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Section Lecture ─────────────────────────────────────────────
          _SectionHeader(title: 'Lecture'),
          const SizedBox(height: 10),

          _SettingsCard(
            children: [
              _SwitchTile(
                icon: Icons.subtitles_rounded,
                title: 'Sous-titres par défaut',
                subtitle: 'Afficher les sous-titres à l\'ouverture d\'une vidéo',
                value: _showSubtitlesByDefault,
                onChanged: (v) => setState(() => _showSubtitlesByDefault = v),
              ),
              _Divider(),
              _SwitchTile(
                icon: Icons.record_voice_over_outlined,
                title: 'Conserver l\'audio original',
                subtitle: 'Garder la piste originale accessible',
                value: _keepOriginalAudio,
                onChanged: (v) => setState(() => _keepOriginalAudio = v),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Section Stockage ────────────────────────────────────────────
          _SectionHeader(title: 'Stockage'),
          const SizedBox(height: 10),

          _SettingsCard(
            children: [
              _SwitchTile(
                icon: Icons.download_rounded,
                title: 'Téléchargement auto',
                subtitle: 'Télécharger la vidéo traduite dès que prête',
                value: _autoDownload,
                onChanged: (v) => setState(() => _autoDownload = v),
              ),
              _Divider(),
              _ActionTile(
                icon: Icons.delete_sweep_outlined,
                iconColor: AppColors.error,
                title: 'Vider le cache',
                subtitle: 'Supprimer les fichiers temporaires',
                onTap: () => _showConfirmDialog(
                  context,
                  title: 'Vider le cache ?',
                  message: 'Les fichiers temporaires seront supprimés. Vos vidéos enregistrées ne seront pas affectées.',
                  onConfirm: () {/* TODO: clear cache */},
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Section À propos ────────────────────────────────────────────
          _SectionHeader(title: 'À propos'),
          const SizedBox(height: 10),

          _SettingsCard(
            children: [
              _InfoTile(
                icon: Icons.info_outline_rounded,
                title: 'Version',
                value: '1.0.0',
              ),
              _Divider(),
              _ActionTile(
                icon: Icons.description_outlined,
                title: 'Conditions d\'utilisation',
                onTap: () {/* TODO: open URL */},
              ),
              _Divider(),
              _ActionTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Politique de confidentialité',
                onTap: () {/* TODO: open URL */},
              ),
              _Divider(),
              _ActionTile(
                icon: Icons.bug_report_outlined,
                title: 'Signaler un problème',
                onTap: () {/* TODO: open mailto */},
              ),
            ],
          ),

          const SizedBox(height: 40),

          // ── Bouton Déconnexion ──────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () => _showConfirmDialog(
              context,
              title: 'Se déconnecter ?',
              message: 'Vous serez redirigé vers l\'écran de connexion.',
              onConfirm: () {/* TODO: logout */},
            ),
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: const Text(
              'Se déconnecter',
              style: TextStyle(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.error, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showConfirmDialog(
      BuildContext context, {
        required String title,
        required String message,
        required VoidCallback onConfirm,
      }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(title,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(message,
            style: const TextStyle(color: AppColors.textSecond, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets internes ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1, thickness: 1,
      color: AppColors.border,
      indent: 52,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecond)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.textSecond, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecond)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textMuted, size: 14),
          ],
        ),
      ),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecond)),
              ],
            ),
          ),
          DropdownButton<String>(
            value: value,
            dropdownColor: AppColors.bgSurface,
            underline: const SizedBox(),
            icon: const Icon(Icons.expand_more_rounded,
                color: AppColors.textMuted, size: 20),
            style: const TextStyle(
                color: AppColors.primaryLight,
                fontFamily: 'Sora',
                fontSize: 14,
                fontWeight: FontWeight.w600),
            items: items.entries
                .map((e) => DropdownMenuItem(
              value: e.key,
              child: Text(e.value),
            ))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecond, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}