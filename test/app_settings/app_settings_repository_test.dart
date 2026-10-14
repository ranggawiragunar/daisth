import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/app_settings/domain/models/app_settings.dart';
import 'package:daisth/core/persistence/data/schema/database_schema.dart';
import 'package:daisth/core/app_settings/data/repositories/app_settings_repository_data.dart';
import 'package:daisth/core/app_settings/data/services/app_settings_sqlite_service.dart';

import '../support/test_persistence.dart';

void main() {
  test('stores device-local settings across repository recreation', () async {
    final persistence = await TestPersistence.create();
    addTearDown(persistence.dispose);

    final defaults = await persistence.appSettings.getSettings();
    expect(defaults.themePreference, AppThemePreference.system);
    expect(defaults.languagePreference, AppLanguagePreference.system);
    expect(defaults.remindersEnabled, isFalse);

    final updatedAt = DateTime.utc(2026, 10, 13, 4, 30);
    await persistence.appSettings.saveSettings(
      AppSettings(
        themePreference: AppThemePreference.dark,
        languagePreference: AppLanguagePreference.indonesian,
        remindersEnabled: true,
        updatedAt: updatedAt,
      ),
    );
    expect(
      await (await persistence.database.open()).query(
        DatabaseSchema.syncOutbox,
      ),
      isEmpty,
      reason: 'Appearance and reminder preferences remain device-local.',
    );
    final restored = await persistence.appSettings.getSettings();
    expect(restored.themePreference, AppThemePreference.dark);
    expect(restored.languagePreference, AppLanguagePreference.indonesian);
    expect(restored.remindersEnabled, isTrue);
    expect(restored.updatedAt, updatedAt);

    await persistence.database.close();
    final restartedDatabase = TestPersistence.createDatabaseServiceAt(
      persistence.databasePath,
    );
    addTearDown(restartedDatabase.close);
    final restartedRepository = AppSettingsRepositoryData(
      service: AppSettingsSqliteService(restartedDatabase),
    );
    final afterRestart = await restartedRepository.getSettings();
    expect(afterRestart.themePreference, AppThemePreference.dark);
    expect(afterRestart.languagePreference, AppLanguagePreference.indonesian);
    expect(afterRestart.remindersEnabled, isTrue);

    await restartedRepository.saveSettings(
      afterRestart.copyWith(languagePreference: AppLanguagePreference.english),
    );
    expect(
      (await (await restartedDatabase.open()).query(
        DatabaseSchema.appSettings,
      )).single['language_mode'],
      'en',
    );
    await restartedRepository.saveSettings(
      afterRestart.copyWith(languagePreference: AppLanguagePreference.system),
    );
    expect(
      (await (await restartedDatabase.open()).query(
        DatabaseSchema.appSettings,
      )).single['language_mode'],
      'system',
    );
    expect(
      await (await restartedDatabase.open()).query(DatabaseSchema.syncOutbox),
      isEmpty,
      reason: 'Device-local language changes must never create sync writes.',
    );
  });
}
