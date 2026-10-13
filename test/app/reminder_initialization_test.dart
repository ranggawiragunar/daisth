import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/timezone/domain/models/device_timezone.dart';
import 'package:daisth/core/timezone/domain/repositories/timezone_repository.dart';
import 'package:daisth/features/reminders/domain/models/exact_alarm_status.dart';
import 'package:daisth/features/reminders/domain/models/reminder.dart';
import 'package:daisth/features/reminders/domain/models/reminder_permission_status.dart';
import 'package:daisth/features/reminders/domain/models/reminder_scheduling_mode.dart';
import 'package:daisth/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:daisth/core/time/domain/models/calendar_day.dart';
import 'package:daisth/features/routines/data/demo/routine_demo_data.dart';
import '../support/fake_routine_record_repository.dart';
import '../support/fake_routine_repository.dart';
import 'package:daisth/app/dependencies/app_dependencies.dart';
import '../support/test_persistence.dart';

void main() {
  test(
    'initializes timezone before notifications and forwards cold-start tap',
    () async {
      final order = <String>[];
      final timezone = _TimezoneRepository(order);
      final reminders = _ReminderRepository(order);
      final dependencies = AppDependencies(
        databaseService: TestPersistence.createDatabaseService(),
        timezoneRepository: timezone,
        reminderRepository: reminders,
        startTodayClock: false,
      );
      addTearDown(dependencies.dispose);
      String? openedPayload;

      await dependencies.initialize(
        onNotificationTap: (payload) => openedPayload = payload,
      );

      expect(order, ['timezone', 'notifications', 'launch-details']);
      expect(openedPayload, reminders.launchPayload);
    },
  );

  test(
    'historical record changes never reconcile OS reminders, current day still does',
    () async {
      final timezone = _TimezoneRepository([]);
      final reminders = _ReminderRepository([]);
      final records = FakeRoutineRecordRepository();
      final dependencies = AppDependencies(
        databaseService: TestPersistence.createDatabaseService(),
        timezoneRepository: timezone,
        reminderRepository: reminders,
        routineRepository: FakeRoutineRepository(),
        routineRecordRepository: records,
        startTodayClock: false,
      );
      addTearDown(records.close);
      addTearDown(dependencies.dispose);
      await dependencies.initialize();

      final today = CalendarDay.fromDateTime(DateTime.now());
      final yesterday = today.addDays(-1);
      await records.markCompleted(
        routine: RoutineDemoData.zuhur,
        day: yesterday,
        now: DateTime.now(),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(reminders.cancelCount, 0);
      expect(reminders.scheduleCount, 0);

      await records.markCompleted(
        routine: RoutineDemoData.zuhur,
        day: today,
        now: DateTime.now(),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(reminders.cancelCount, 2);
    },
  );
}

class _TimezoneRepository implements TimezoneRepository {
  _TimezoneRepository(this.order);
  final List<String> order;

  @override
  Future<DeviceTimezone> initialize() async {
    order.add('timezone');
    return const DeviceTimezone(ianaName: 'Asia/Jakarta');
  }

  @override
  Future<DeviceTimezone> getDeviceTimezone() async =>
      const DeviceTimezone(ianaName: 'Asia/Jakarta');
}

class _ReminderRepository implements ReminderRepository {
  _ReminderRepository(this.order);
  final List<String> order;
  final String launchPayload =
      '{"app":"daisth","v":1,"type":"routine","routineId":"zuhur"}';
  int scheduleCount = 0;
  int cancelCount = 0;

  @override
  Future<void> initialize({
    void Function(String? payload)? onNotificationTap,
  }) async {
    order.add('notifications');
  }

  @override
  Future<String?> getLaunchPayload() async {
    order.add('launch-details');
    return launchPayload;
  }

  @override
  Future<ReminderPermissionStatus> getPermissionStatus() async =>
      ReminderPermissionStatus.granted;
  @override
  Future<ReminderPermissionStatus> requestPermission() async =>
      ReminderPermissionStatus.granted;
  @override
  Future<ExactAlarmStatus> getExactAlarmStatus() async =>
      ExactAlarmStatus.unavailable;
  @override
  Future<ExactAlarmStatus> requestExactAlarmPermission() async =>
      ExactAlarmStatus.unavailable;
  @override
  Future<void> schedule(
    Reminder reminder, {
    required ReminderSchedulingMode mode,
  }) async {
    scheduleCount++;
  }

  @override
  Future<void> cancel(Reminder reminder) async {
    cancelCount++;
  }

  @override
  Future<void> cancelRemindersForDate(DateTime date) async {}
  @override
  Future<void> cancelAllDaisthReminders() async {}
  @override
  Future<List<Reminder>> getPendingReminders() async => const [];
  @override
  Future<bool> openNotificationSettings() async => true;
}
