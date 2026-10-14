enum AppThemePreference { system, light, dark }

enum AppLanguagePreference { system, indonesian, english }

abstract final class AppLanguagePreferenceResolver {
  static String resolveCode(
    AppLanguagePreference preference,
    Iterable<String> systemLanguageCodes,
  ) => switch (preference) {
    AppLanguagePreference.indonesian => 'id',
    AppLanguagePreference.english => 'en',
    AppLanguagePreference.system => _resolveSystemCode(systemLanguageCodes),
  };

  static String _resolveSystemCode(Iterable<String> languageCodes) {
    final first = languageCodes.firstOrNull
        ?.toLowerCase()
        .split(RegExp('[-_]'))
        .first;
    if (first == 'id' || first == 'in') return 'id';
    if (first == 'en') return 'en';
    return 'en';
  }
}

class AppSettings {
  const AppSettings({
    this.themePreference = AppThemePreference.system,
    this.languagePreference = AppLanguagePreference.system,
    this.remindersEnabled = false,
    this.onboardingVersion,
    this.updatedAt,
  });

  final AppThemePreference themePreference;
  final AppLanguagePreference languagePreference;
  final bool remindersEnabled;
  final int? onboardingVersion;
  final DateTime? updatedAt;

  AppSettings copyWith({
    AppThemePreference? themePreference,
    AppLanguagePreference? languagePreference,
    bool? remindersEnabled,
    int? onboardingVersion,
    DateTime? updatedAt,
  }) => AppSettings(
    themePreference: themePreference ?? this.themePreference,
    languagePreference: languagePreference ?? this.languagePreference,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    onboardingVersion: onboardingVersion ?? this.onboardingVersion,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
