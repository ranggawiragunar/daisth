import 'package:sqflite/sqflite.dart';

import '../../../../core/persistence/data/schema/database_schema.dart';
import '../../../../core/persistence/data/services/istiqam_database_service.dart';

class AppSettingsSqliteService {
  const AppSettingsSqliteService(this.databaseService);

  final IstiqamDatabaseService databaseService;

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
    await db.insert(DatabaseSchema.appSettings, {
      'id': 1,
      ...values,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
