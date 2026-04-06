// lib/screens/language_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/app_colors.dart';
import '../models/language.dart';
import '../services/api_service.dart';
import '../router/app_router.dart';
import '../config/app_config.dart';

// ─── Provider langues (chargées depuis l'API) ─────────────────────────────────

final languagesProvider = FutureProvider<List<Language>>((ref) async {
  return ApiService().getAvailableLanguages();
});

class LanguagePickerScreen extends ConsumerStatefulWidget {
  final String videoId;
  const LanguagePickerScreen({super.key, required this.videoId});

  @override
  ConsumerState<LanguagePickerScreen> createState() =>
      _LanguagePickerScreenState();
}

class _LanguagePickerScreenState extends ConsumerState<LanguagePickerScreen> {
  String? _selectedCode;
  bool    _isStarting = false;
  String? _error;

  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadDefaultLanguage();
  }

  // ── Mémorisation de la préférence linguistique ────────────────────────────

  Future<void> _loadDefaultLanguage() async {
    final box  = await Hive.openBox('preferences');
    final code = box.get(AppConfig.keyDefaultLanguage) as String?;
    if (code != null && mounted) {
      setState(() => _selectedCode = code);
    }
  }

  Future<void> _saveDefaultLanguage(String code) async {
    final box = await Hive.openBox('preferences');
    await box.put(AppConfig.keyDefaultLanguage, code);
  }

  // ── Lancement de la traduction ────────────────────────────────────────────

  Future<void> _startTranslation() async {
    if (_selectedCode == null) return;
    setState(() { _isStarting = true; _error = null; });

    // Mémoriser la langue choisie
    await _saveDefaultLanguage(_selectedCode!);

    try {
      final jobId = await _api.startTranslation(
        videoId:    widget.videoId,
        targetLang: _selectedCode!,
      );
      if (mounted) {
        context.pushReplacement(
          AppRoutes.processing,
          extra: {'jobId': jobId, 'targetLang': _selectedCode},
        );
      }
    } on ApiException catch (e) {
      setState(() => _error = e.userMessage);
    } catch (e) {
      setState(() => _error = 'Erreur inattendue : $e');
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languagesAsync = ref.watch(languagesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Langue cible')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: languagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, __) => _LanguageListFallback(
                selectedCode: _selectedCode,
                onSelect: (code) => setState(() => _selectedCode = code),
              ),
              data: (languages) => _LanguageList(
                languages:    languages,
                selectedCode: _selectedCode,
                onSelect: (code) => setState(() => _selectedCode = code),
              ),
            ),
          ),

          // ── Erreur ───────────────────────────────────────────────────────
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Text(_error!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 13)),
              ),
            ),

          // ── Bouton Lancer ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: const BoxDecoration(
              color:  AppColors.bgCard,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: ElevatedButton(
              onPressed: _selectedCode != null && !_isStarting
                  ? _startTranslation
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize:            const Size.fromHeight(52),
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

// ─── Liste des langues ────────────────────────────────────────────────────────

class _LanguageList extends StatelessWidget {
  final List<Language> languages;
  final String?        selectedCode;
  final ValueChanged<String> onSelect;

  const _LanguageList({
    required this.languages,
    required this.selectedCode,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final v1Langs = languages.where((l) => l.availableV1).toList();
    final v2Langs = languages.where((l) => !l.availableV1).toList();

    return ListView(
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

        const _SectionTitle(title: 'Disponibles maintenant'),
        const SizedBox(height: 10),
        ...v1Langs.map((lang) => _LanguageTile(
          language:   lang,
          isSelected: selectedCode == lang.code,
          onTap: () => onSelect(lang.code),
        )),

        if (v2Langs.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionTitle(title: 'Prochainement (V2)'),
          const SizedBox(height: 10),
          ...v2Langs.map((lang) => _LanguageTile(
            language:   lang,
            isSelected: false,
            disabled:   true,
            onTap:      () {},
          )),
        ],
      ],
    );
  }
}

/// Fallback si l'API est indisponible : liste statique
class _LanguageListFallback extends StatelessWidget {
  final String?          selectedCode;
  final ValueChanged<String> onSelect;

  const _LanguageListFallback({
    required this.selectedCode,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return _LanguageList(
      languages:    Language.supported,
      selectedCode: selectedCode,
      onSelect:     onSelect,
    );
  }
}

// ─── Widgets internes ─────────────────────────────────────────────────────────

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
  final Language  language;
  final bool      isSelected;
  final bool      disabled;
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
          margin:   const EdgeInsets.only(bottom: 10),
          padding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              Text(language.flag,
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  language.name,
                  style: TextStyle(
                    fontSize:   16,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppColors.primaryLight
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (disabled)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text('V2',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textMuted)),
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