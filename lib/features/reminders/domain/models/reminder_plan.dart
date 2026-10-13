import '../../../../core/timezone/domain/models/device_timezone.dart';
import 'reminder.dart';

class ReminderPlan {
  ReminderPlan({
    required this.date,
    required this.timezone,
    required List<Reminder> reminders,
  }) : reminders = List.unmodifiable(reminders);

  final DateTime date;
  final DeviceTimezone timezone;
  final List<Reminder> reminders;
}
