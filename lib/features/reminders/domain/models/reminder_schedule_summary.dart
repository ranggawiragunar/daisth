import 'exact_alarm_status.dart';
import 'reminder_plan.dart';

class ReminderScheduleSummary {
  const ReminderScheduleSummary({
    required this.plan,
    required this.scheduledCount,
    required this.exactAlarmStatus,
  });

  final ReminderPlan plan;
  final int scheduledCount;
  final ExactAlarmStatus exactAlarmStatus;
}
