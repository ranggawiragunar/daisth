enum AppThemePreference { system, light, dark }

class AppSettings {
  const AppSettings({
    this.themePreference = AppThemePreference.system,
    this.remindersEnabled = false,
    this.onboardingVersion,
    this.updatedAt,
  });

  final AppThemePreference themePreference;
  final bool remindersEnabled;
  final int? onboardingVersion;
  final DateTime? updatedAt;

  AppSettings copyWith({
    AppThemePreference? themePreference,
    bool? remindersEnabled,
    int? onboardingVersion,
    DateTime? updatedAt,
  }) => AppSettings(
    themePreference: themePreference ?? this.themePreference,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    onboardingVersion: onboardingVersion ?? this.onboardingVersion,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
