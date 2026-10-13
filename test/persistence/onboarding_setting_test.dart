import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/app_settings/data/repositories/app_settings_repository_data.dart';
import 'package:daisth/core/app_settings/data/services/app_settings_sqlite_service.dart';

import '../support/test_persistence.dart';

void main() {
  test(
    'fresh onboarding setting persists across repository recreation',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);

      expect(await persistence.appSettings.getOnboardingVersion(), isNull);
      await persistence.appSettings.setOnboardingVersion(1);
      expect(await persistence.appSettings.getOnboardingVersion(), 1);

      final reopened = TestPersistence.createDatabaseServiceAt(
        persistence.databasePath,
      );
      addTearDown(reopened.close);
      final repository = AppSettingsRepositoryData(
        service: AppSettingsSqliteService(reopened),
      );
      expect(await repository.getOnboardingVersion(), 1);
    },
  );
}
