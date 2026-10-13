import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/timezone/domain/models/device_timezone.dart';
import 'package:daisth/core/timezone/domain/repositories/timezone_repository.dart';
import 'package:daisth/features/reminders/domain/models/exact_alarm_status.dart';
import 'package:daisth/features/reminders/domain/models/reminder.dart';
import 'package:daisth/features/reminders/domain/models/reminder_permission_status.dart';
import 'package:daisth/features/reminders/domain/models/reminder_scheduling_mode.dart';
import 'package:daisth/features/reminders/domain/repositories/reminder_repository.dart';
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
  }) async {}
  @override
  Future<void> cancel(Reminder reminder) async {}
  @override
  Future<void> cancelRemindersForDate(DateTime date) async {}
  @override
  Future<void> cancelAllDaisthReminders() async {}
  @override
  Future<List<Reminder>> getPendingReminders() async => const [];
  @override
  Future<bool> openNotificationSettings() async => true;
}
