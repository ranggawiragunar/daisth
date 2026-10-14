import 'dart:ui' show DartPluginRegistrant, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/persistence/data/services/daisth_database_service.dart';
import '../../../../core/timezone/data/repositories/timezone_repository_data.dart';
import '../../../../core/timezone/data/services/timezone_flutter_service.dart';
import '../../../routines/data/mappers/routine_record_mapper.dart';
import '../../../routines/data/catalog/default_routine_template_catalog.dart';
import '../../../routines/data/mappers/routine_definition_mapper.dart';
import '../../../routines/data/repositories/routine_record_repository_data.dart';
import '../../../routines/data/repositories/routine_repository_data.dart';
import '../../../routines/data/resolvers/routine_resolver.dart';
import '../../../routines/data/services/routine_record_sqlite_service.dart';
import '../../../routines/data/services/routine_sqlite_service.dart';
import '../../../routines/domain/use_cases/mark_routine_complete_use_case.dart';
import '../../../routines/domain/use_cases/resolve_routine_status_use_case.dart';
import '../../../routines/domain/use_cases/ensure_default_routines_use_case.dart';
import '../mappers/reminder_mapper.dart';
import '../repositories/reminder_repository_data.dart';
import '../repositories/routine_reminder_state_repository_data.dart';
import '../mappers/routine_reminder_state_mapper.dart';
import '../services/reminder_local_notifications_service.dart';
import '../services/routine_reminder_state_sqlite_service.dart';
import '../../domain/models/reminder_action.dart';
import '../../domain/models/reminder_payload.dart';
import '../../domain/use_cases/handle_reminder_action_use_case.dart';

@pragma('vm:entry-point')
void daisthBackgroundNotificationResponse(NotificationResponse response) async {
  try {
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();
    final action = ReminderActionIds.parse(response.actionId);
    final payload = ReminderPayload.tryParse(response.payload);
    if (action == null || payload == null || action == ReminderAction.open) {
      return;
    }
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(payload.timezoneIdentifier));
    final db = DaisthDatabaseService.background();
    final routineRepo = RoutineRecordRepositoryData(
      service: RoutineRecordSqliteService(db),
      mapper: RoutineRecordMapper(),
    );
    final definitions = RoutineRepositoryData(
      service: RoutineSqliteService(db),
      mapper: RoutineDefinitionMapper(),
    );
    await EnsureDefaultRoutinesUseCase(
      repository: definitions,
      templates: DefaultRoutineTemplateCatalog.definitions,
    )();
    final resolver = RoutineResolver(definitions);
    final stateRepo = RoutineReminderStateRepositoryData(
      service: RoutineReminderStateSqliteService(db),
      mapper: RoutineReminderStateMapper(),
    );
    final notificationService = ReminderLocalNotificationsService(
      languageCode: PlatformDispatcher.instance.locale.languageCode,
    );
    final reminderRepo = ReminderRepositoryData(
      service: notificationService,
      mapper: ReminderMapper(),
    );
    await TimezoneRepositoryData(
      service: TimezoneFlutterService(),
    ).initialize();
    await reminderRepo.initialize();
    final useCase = HandleReminderActionUseCase(
      routineRepository: routineRepo,
      reminderStateRepository: stateRepo,
      reminderRepository: reminderRepo,
      markRoutineComplete: MarkRoutineCompleteUseCase(
        repository: routineRepo,
        resolveStatus: const ResolveRoutineStatusUseCase(),
      ),
      resolveRoutine: (id) async => (await resolver.resolve(id))?.routine,
    );
    await useCase(action: action, payload: payload);
    await db.close();
    await routineRepo.closeChanges();
    await definitions.closeChanges();
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Daisth reminder action failed: $error\n$stackTrace');
    }
  }
}
