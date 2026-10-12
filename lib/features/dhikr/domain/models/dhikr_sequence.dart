import 'dhikr_item.dart';

class DhikrSequence {
  DhikrSequence({
    required this.id,
    required this.title,
    required this.context,
    required List<DhikrItem> items,
    required this.sourceLabel,
  }) : assert(items.isNotEmpty),
       items = List.unmodifiable(items);

  final String id;
  final String title;
  final String context;
  final List<DhikrItem> items;
  final String sourceLabel;
}
