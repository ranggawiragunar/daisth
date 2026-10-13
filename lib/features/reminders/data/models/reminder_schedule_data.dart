class ReminderScheduleData {
  const ReminderScheduleData({
    required this.notificationId,
    required this.identity,
    required this.routineId,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.channelId,
    required this.payload,
    this.actionable = true,
  });

  final int notificationId;
  final String identity;
  final String routineId;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final String channelId;
  final String payload;
  final bool actionable;
}
