import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/time/domain/models/calendar_day.dart';
import 'package:daisth/features/reminders/data/mappers/routine_reminder_state_mapper.dart';
import 'package:daisth/features/reminders/data/repositories/routine_reminder_state_repository_data.dart';
import 'package:daisth/features/reminders/data/services/routine_reminder_state_sqlite_service.dart';
import 'package:daisth/features/reminders/domain/models/exact_alarm_status.dart';
import 'package:daisth/features/reminders/domain/models/reminder.dart';
import 'package:daisth/features/reminders/domain/models/reminder_action.dart';
import 'package:daisth/features/reminders/domain/models/reminder_payload.dart';
import 'package:daisth/features/reminders/domain/models/reminder_permission_status.dart';
import 'package:daisth/features/reminders/domain/models/reminder_scheduling_mode.dart';
import 'package:daisth/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:daisth/features/reminders/domain/use_cases/handle_reminder_action_use_case.dart';
import 'package:daisth/features/routines/data/repositories/routine_record_repository_data.dart';
import 'package:daisth/features/routines/data/demo/routine_demo_data.dart';
import 'package:daisth/features/routines/domain/models/routine_status.dart';
import 'package:daisth/features/routines/domain/use_cases/mark_routine_complete_use_case.dart';
import 'package:daisth/features/routines/domain/use_cases/resolve_routine_status_use_case.dart';
import '../support/test_persistence.dart';

void main() {
  test(
    'Done is idempotent and completes required Sholat Malam steps',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final reminders = _Reminders();
      final states = RoutineReminderStateRepositoryData(
        service: RoutineReminderStateSqliteService(persistence.database),
        mapper: RoutineReminderStateMapper(),
      );
      final handler = _handler(persistence.routineRecords, states, reminders);
      final payload = _payload('sholat-malam');
      await handler(
        action: ReminderAction.done,
        payload: payload,
        actionAt: DateTime.utc(2026, 10, 13, 10),
      );
      final completedAt = (await persistence.routineRecords.getRoutineRecord(
        payloadDay,
        'sholat-malam',
      ))!.completedAt;
      await handler(
        action: ReminderAction.done,
        payload: payload,
        actionAt: DateTime.utc(2026, 10, 13, 11),
      );
      expect(
        (await persistence.routineRecords.getRoutineRecord(
          payloadDay,
          'sholat-malam',
        ))!.status,
        RoutineStatus.completed,
      );
      expect(
        (await persistence.routineRecords.getStepRecords(
          payloadDay,
          'sholat-malam',
        )).where((r) => r.isCompleted),
        hasLength(4),
      );
      expect(
        (await persistence.routineRecords.getRoutineRecord(
          payloadDay,
          'sholat-malam',
        ))!.completedAt,
        completedAt,
      );
      expect(
        reminders.cancelled.map((r) => r.id),
        containsAll([
          'sholat-malam-follow-up-2026-10-13',
          'sholat-malam-snooze-2026-10-13',
        ]),
      );
    },
  );

  test(
    'simple prayer Done persists required progress and leaves optional dhikr clear',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final states = RoutineReminderStateRepositoryData(
        service: RoutineReminderStateSqliteService(persistence.database),
        mapper: RoutineReminderStateMapper(),
      );
      final handler = _handler(
        persistence.routineRecords,
        states,
        _Reminders(),
      );
      await handler(
        action: ReminderAction.done,
        payload: _payload('zuhur'),
        actionAt: DateTime.utc(2026, 10, 13, 10),
      );
      expect(
        (await persistence.routineRecords.getRoutineRecord(
          payloadDay,
          'zuhur',
        ))!.status,
        RoutineStatus.completed,
      );
      final steps = await persistence.routineRecords.getStepRecords(
        payloadDay,
        'zuhur',
      );
      expect(
        steps.singleWhere((step) => step.stepId == 'zuhur').isCompleted,
        isTrue,
      );
      expect(
        steps
            .singleWhere((step) => step.stepId == 'post-prayer-dhikr')
            .isCompleted,
        isFalse,
      );
    },
  );

  test('Dhuha Done leaves optional extra rakaat untouched', () async {
    final persistence = await TestPersistence.create();
    addTearDown(persistence.dispose);
    final states = RoutineReminderStateRepositoryData(
      service: RoutineReminderStateSqliteService(persistence.database),
      mapper: RoutineReminderStateMapper(),
    );
    final handler = _handler(persistence.routineRecords, states, _Reminders());
    await handler(
      action: ReminderAction.done,
      payload: _payload('dhuha'),
      actionAt: DateTime.utc(2026, 10, 13, 10),
    );
    final steps = await persistence.routineRecords.getStepRecords(
      payloadDay,
      'dhuha',
    );
    expect(
      steps.singleWhere((step) => step.stepId == 'dhuha-minimum').isCompleted,
      isTrue,
    );
    expect(
      steps.singleWhere((step) => step.stepId == 'dhuha-extra').isCompleted,
      isFalse,
    );
  });

  test(
    'Penutup Hari Done completes six readings and leaves Wudu untouched',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final states = RoutineReminderStateRepositoryData(
        service: RoutineReminderStateSqliteService(persistence.database),
        mapper: RoutineReminderStateMapper(),
      );
      final handler = _handler(
        persistence.routineRecords,
        states,
        _Reminders(),
      );
      await handler(
        action: ReminderAction.done,
        payload: _payload('penutup-hari'),
        actionAt: DateTime.utc(2026, 10, 13, 10),
      );

      final record = await persistence.routineRecords.getRoutineRecord(
        payloadDay,
        'penutup-hari',
      );
      final steps = await persistence.routineRecords.getStepRecords(
        payloadDay,
        'penutup-hari',
      );
      expect(record!.status, RoutineStatus.completed);
      expect(steps.where((step) => step.isCompleted), hasLength(6));
      expect(
        steps.singleWhere((step) => step.stepId == 'wudu').isCompleted,
        isFalse,
      );
    },
  );

  test(
    'Snooze schedules one ten minute reminder and suppresses follow-up',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final reminders = _Reminders();
      final states = RoutineReminderStateRepositoryData(
        service: RoutineReminderStateSqliteService(persistence.database),
        mapper: RoutineReminderStateMapper(),
      );
      final handler = _handler(persistence.routineRecords, states, reminders);
      final now = DateTime.utc(2026, 10, 13, 10);
      await handler(
        action: ReminderAction.snooze,
        payload: _payload('zuhur'),
        actionAt: now,
      );
      await handler(
        action: ReminderAction.snooze,
        payload: _payload('zuhur'),
        actionAt: now.add(const Duration(minutes: 2)),
      );
      final state = await states.getState(payloadDay, 'zuhur');
      expect(state!.snoozedUntil, now.add(const Duration(minutes: 12)));
      expect(state.followUpSuppressed, isTrue);
      expect(reminders.scheduled, hasLength(1));
      expect(reminders.scheduled.single.type, ReminderType.snooze);
      expect(reminders.scheduled.single.id, 'zuhur-snooze-2026-10-13');
      expect(
        reminders.cancelled.map((r) => r.id),
        contains('zuhur-follow-up-2026-10-13'),
      );
      await handler(
        action: ReminderAction.done,
        payload: _payload('zuhur'),
        actionAt: now.add(const Duration(minutes: 3)),
      );
      expect(reminders.scheduled, isEmpty);
    },
  );
}

final payloadDay = CalendarDay(year: 2026, month: 10, day: 13);
ReminderPayload _payload(String id) => ReminderPayload(
  routineId: id,
  dateKey: '2026-10-13',
  kind: ReminderType.primary,
  title: RoutineDemoData.byId(id)!.title,
  timezoneIdentifier: 'Asia/Jakarta',
);
HandleReminderActionUseCase _handler(
  RoutineRecordRepositoryData routine,
  RoutineReminderStateRepositoryData states,
  _Reminders reminders,
) => HandleReminderActionUseCase(
  routineRepository: routine,
  reminderStateRepository: states,
  reminderRepository: reminders,
  markRoutineComplete: MarkRoutineCompleteUseCase(
    repository: routine,
    resolveStatus: const ResolveRoutineStatusUseCase(),
  ),
);

class _Reminders implements ReminderRepository {
  final scheduled = <Reminder>[];
  final cancelled = <Reminder>[];
  @override
  Future<void> initialize({
    void Function(String? payload)? onNotificationTap,
  }) async {}
  @override
  Future<String?> getLaunchPayload() async => null;
  @override
  Future<ReminderPermissionStatus> getPermissionStatus() async =>
      ReminderPermissionStatus.granted;
  @override
  Future<ReminderPermissionStatus> requestPermission() async =>
      ReminderPermissionStatus.granted;
  @override
  Future<ExactAlarmStatus> getExactAlarmStatus() async =>
      ExactAlarmStatus.enabled;
  @override
  Future<ExactAlarmStatus> requestExactAlarmPermission() async =>
      ExactAlarmStatus.enabled;
  @override
  Future<void> schedule(
    Reminder reminder, {
    required ReminderSchedulingMode mode,
  }) async {
    scheduled.removeWhere((r) => r.id == reminder.id);
    scheduled.add(reminder);
  }

  @override
  Future<void> cancel(Reminder reminder) async {
    cancelled.add(reminder);
    scheduled.removeWhere((r) => r.id == reminder.id);
  }

  @override
  Future<void> cancelRemindersForDate(DateTime date) async {}
  @override
  Future<void> cancelAllDaisthReminders() async {}
  @override
  Future<List<Reminder>> getPendingReminders() async => scheduled;
  @override
  Future<bool> openNotificationSettings() async => true;
}
