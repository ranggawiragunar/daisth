import 'reminder_priority.dart';

enum ReminderType { primary, followUp, snooze }

class Reminder {
  const Reminder({
    required this.id,
    required this.routineId,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.priority,
    this.type = ReminderType.primary,
    this.dateKey,
    this.timezoneIdentifier = 'UTC',
    this.actionable = true,
  });

  final String id;
  final String routineId;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final ReminderPriority priority;
  final ReminderType type;
  final String? dateKey;
  final String timezoneIdentifier;
  final bool actionable;
}
