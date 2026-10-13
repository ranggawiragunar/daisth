import '../../../../core/persistence/data/schema/database_schema.dart';
import '../../../../core/persistence/data/services/daisth_database_service.dart';

class AppSettingsSqliteService {
  const AppSettingsSqliteService(this.databaseService);

  final DaisthDatabaseService databaseService;

  Future<Map<String, Object?>?> getSettings() async {
    final db = await databaseService.open();
    final rows = await db.query(
      DatabaseSchema.appSettings,
      where: 'id = 1',
      limit: 1,
    );
    return rows.firstOrNull;
  }

  Future<void> saveSettings(Map<String, Object?> values) async {
    final db = await databaseService.open();
    final updated = await db.update(
      DatabaseSchema.appSettings,
      values,
      where: 'id = 1',
    );
    if (updated == 0) {
      await db.insert(DatabaseSchema.appSettings, {'id': 1, ...values});
    }
  }

  Future<int?> getOnboardingVersion() async {
    final row = await getSettings();
    return row?['onboarding_version'] as int?;
  }

  Future<void> setOnboardingVersion(int version) async {
    final db = await databaseService.open();
    await db.update(DatabaseSchema.appSettings, {
      'onboarding_version': version,
    }, where: 'id = 1');
  }
}
