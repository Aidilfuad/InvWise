class LanguageOption {
  final String id;
  final String label;

  const LanguageOption({
    required this.id,
    required this.label,
  });
}

class LanguageMockData {
  const LanguageMockData._();

  static const String currentLanguageId = 'en_my';
  static const String currentLanguageLabel = 'English (Malaysia)';
  static const String currentLanguageStatus = 'Active';

  static const List<LanguageOption> options = [
    LanguageOption(id: 'en_my', label: 'English (Malaysia)'),
    LanguageOption(id: 'ms', label: 'Bahasa Melayu'),
    LanguageOption(id: 'zh', label: '中文 (Chinese)'),
    LanguageOption(id: 'ja', label: 'Japanese'),
  ];
}