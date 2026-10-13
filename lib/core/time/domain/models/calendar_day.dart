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

  factory CalendarDay.parseDateKey(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) throw FormatException('Invalid calendar date.', value);
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      throw FormatException('Invalid calendar date.', value);
    }
    return CalendarDay(year: year, month: month, day: day);
  }

  final int year;
  final int month;
  final int day;

  String toDateKey() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  DateTime toDateTime() => DateTime(year, month, day);

  CalendarDay addDays(int count) =>
      CalendarDay.fromDateTime(toDateTime().add(Duration(days: count)));

  int compareTo(CalendarDay other) => toDateKey().compareTo(other.toDateKey());

  @override
  bool operator ==(Object other) =>
      other is CalendarDay &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);
}
