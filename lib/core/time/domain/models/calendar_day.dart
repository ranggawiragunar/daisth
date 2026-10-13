class CalendarDay {
  const CalendarDay({
    required this.year,
    required this.month,
    required this.day,
  });

  factory CalendarDay.fromDateTime(DateTime dateTime) => CalendarDay(
    year: dateTime.year,
    month: dateTime.month,
    day: dateTime.day,
  );

  final int year;
  final int month;
  final int day;

  String toDateKey() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is CalendarDay &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);
}
