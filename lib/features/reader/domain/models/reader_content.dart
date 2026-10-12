import 'reader_section.dart';

class ReaderContent {
  ReaderContent({
    required this.id,
    required this.title,
    required this.context,
    required List<ReaderSection> sections,
    required this.sourceLabel,
    this.subtitle,
  }) : sections = List.unmodifiable(sections);

  final String id;
  final String title;
  final String context;
  final String? subtitle;
  final List<ReaderSection> sections;
  final String sourceLabel;
}
