// lib/screens/language_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../models/language.dart';
import '../services/api_service.dart';
import '../router/app_router.dart';

class LanguagePickerScreen extends StatefulWidget {
  final String videoId;
  const LanguagePickerScreen({super.key, required this.videoId});

  @override
  State<LanguagePickerScreen> createState() => _LanguagePickerScreenState();
}

class _LanguagePickerScreenState extends State<LanguagePickerScreen> {
  String? _selectedCode;
  bool _isStarting = false;
  final _api = ApiService();

  Future<void> _startTranslation() async {
    if (_selectedCode == null) return;
    setState(() => _isStarting = true);
    try {
      final jobId = await _api.startTranslation(
        videoId: widget.videoId,
        targetLang: _selectedCode!,
      );
      if (mounted) {
        context.pushReplacement(AppRoutes.processing, extra: jobId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v1Langs  = Language.supported.where((l) => l.availableV1).toList();
    final v2Langs  = Language.supported.where((l) => !l.availableV1).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Langue cible')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Choisissez la langue de traduction',
                  style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'La voix sera clonée dans la langue sélectionnée',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecond),
                ),
                const SizedBox(height: 24),

                // Langues V1
                const _SectionTitle(title: 'Disponibles maintenant'),
                const SizedBox(height: 10),
                ...v1Langs.map((lang) => _LanguageTile(
                  language: lang,
                  isSelected: _selectedCode == lang.code,
                  onTap: () => setState(() => _selectedCode = lang.code),
                )),

                const SizedBox(height: 20),
                // Langues V2
                const _SectionTitle(title: 'Prochainement (V2)'),
                const SizedBox(height: 10),
                ...v2Langs.map((lang) => _LanguageTile(
                  language: lang,
                  isSelected: false,
                  disabled: true,
                  onTap: () {},
                )),
              ],
            ),
          ),

          // Bouton Lancer
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: const BoxDecoration(
              color: AppColors.bgCard,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: ElevatedButton(
              onPressed: _selectedCode != null && !_isStarting
                  ? _startTranslation
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                disabledBackgroundColor: AppColors.bgSurface,
              ),
              child: _isStarting
                  ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Text('Lancer la traduction'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600,
      color: AppColors.textMuted, letterSpacing: 0.8,
    ),
  );
}

class _LanguageTile extends StatelessWidget {
  final Language language;
  final bool isSelected;
  final bool disabled;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.language, required this.isSelected,
    this.disabled = false, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.15)
                : AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(language.flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  language.name,
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppColors.primaryLight
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (disabled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text('V2',
                      style: TextStyle(fontSize: 10,
                          color: AppColors.textMuted)),
                )
              else if (isSelected)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}