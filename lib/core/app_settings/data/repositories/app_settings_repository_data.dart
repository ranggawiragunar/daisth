import '../../domain/models/app_settings.dart';
import '../../domain/repositories/app_settings_repository.dart';
import '../services/app_settings_sqlite_service.dart';

class AppSettingsRepositoryData implements AppSettingsRepository {
  const AppSettingsRepositoryData({required this.service});

  final AppSettingsSqliteService service;

  @override
  Future<AppSettings> getSettings() async {
    final row = await service.getSettings();
    if (row == null) return const AppSettings();
    return AppSettings(
      themePreference: _parseTheme(row['theme_mode'] as String?),
      remindersEnabled: row['reminders_enabled'] == 1,
      updatedAt:
          DateTime.tryParse(row['updated_at_utc'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  @override
  Future<void> saveSettings(AppSettings settings) => service.saveSettings({
    'theme_mode': settings.themePreference.name,
    'reminders_enabled': settings.remindersEnabled ? 1 : 0,
    'updated_at_utc':
        settings.updatedAt?.toUtc().toIso8601String() ??
        DateTime.now().toUtc().toIso8601String(),
  });

  AppThemePreference _parseTheme(String? value) => switch (value) {
    'light' => AppThemePreference.light,
    'dark' => AppThemePreference.dark,
    _ => AppThemePreference.system,
  };
}
