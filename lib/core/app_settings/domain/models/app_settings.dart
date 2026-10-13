enum AppThemePreference { system, light, dark }

class AppSettings {
  const AppSettings({
    this.themePreference = AppThemePreference.system,
    this.remindersEnabled = false,
    this.updatedAt,
  });

  final AppThemePreference themePreference;
  final bool remindersEnabled;
  final DateTime? updatedAt;

  AppSettings copyWith({
    AppThemePreference? themePreference,
    bool? remindersEnabled,
    DateTime? updatedAt,
  }) => AppSettings(
    themePreference: themePreference ?? this.themePreference,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
