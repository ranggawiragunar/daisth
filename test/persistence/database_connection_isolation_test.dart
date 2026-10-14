import 'package:daisth/core/persistence/data/services/daisth_database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/test_persistence.dart';

void main() {
  test(
    'closing a notification connection leaves the foreground database usable',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final foreground = await persistence.database.open();

      for (var action = 0; action < 2; action++) {
        final background = DaisthDatabaseService.background(
          factory: databaseFactoryFfiNoIsolate,
          databasePath: persistence.databasePath,
        );
        try {
          final notificationDatabase = await background.open();
          expect(identical(notificationDatabase, foreground), isFalse);
          await notificationDatabase.update('app_settings', {
            'reminders_enabled': action,
          }, where: 'id = 1');
        } finally {
          await background.close();
        }
        expect(foreground.isOpen, isTrue);
        expect(
          (await foreground.query('app_settings')).single['reminders_enabled'],
          action,
        );
        await foreground.update('app_settings', {
          'theme_mode': 'dark',
        }, where: 'id = 1');
      }
    },
  );
}
