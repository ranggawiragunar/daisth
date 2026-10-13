class ReminderReschedulePolicy {
  const ReminderReschedulePolicy();

  bool shouldReschedule({
    required DateTime? scheduledDate,
    required String? scheduledTimezone,
    required DateTime currentDate,
    required String currentTimezone,
  }) =>
      scheduledDate == null ||
      !_sameDate(scheduledDate, currentDate) ||
      scheduledTimezone != currentTimezone;

  bool _sameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
