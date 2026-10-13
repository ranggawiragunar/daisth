import '../models/app_settings.dart';

abstract interface class AppSettingsRepository {
  Future<AppSettings> getSettings();

  Future<void> saveSettings(AppSettings settings);

  Future<int?> getOnboardingVersion();

  Future<void> setOnboardingVersion(int version);
}
