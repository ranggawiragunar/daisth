import 'history_day.dart';

class HistoryPage {
  const HistoryPage({
    required this.days,
    required this.earliestDay,
    required this.hasEarlier,
  });

  final List<HistoryDay> days;
  final String? earliestDay;
  final bool hasEarlier;
}
