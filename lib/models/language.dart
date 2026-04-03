// lib/models/language.dart

class Language {
  final String code;
  final String name;
  final String flag;
  final bool availableV1;

  const Language({
    required this.code,
    required this.name,
    required this.flag,
    this.availableV1 = true,
  });

  static const List<Language> supported = [
    Language(code: 'fr', name: 'Français',          flag: '🇫🇷'),
    Language(code: 'en', name: 'English',            flag: '🇬🇧'),
    Language(code: 'es', name: 'Español',            flag: '🇪🇸'),
    Language(code: 'de', name: 'Deutsch',            flag: '🇩🇪'),
    Language(code: 'pt', name: 'Português',          flag: '🇧🇷'),
    Language(code: 'ar', name: 'العربية',             flag: '🇸🇦'),
    Language(code: 'zh', name: '中文 (Mandarin)',     flag: '🇨🇳'),
    Language(code: 'ja', name: '日本語',              flag: '🇯🇵'),
    Language(code: 'sw', name: 'Swahili',            flag: '🇰🇪', availableV1: false),
    Language(code: 'dyu', name: 'Dioula / Bambara', flag: '🇨🇮', availableV1: false),
  ];
}