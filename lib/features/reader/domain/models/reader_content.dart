import 'reader_section.dart';

class ReaderContent {
  ReaderContent({
    required this.id,
    required this.title,
    required this.context,
    required List<ReaderSection> sections,
    this.titleEn,
    this.contextEn,
    this.sourceLabel,
    this.sourceLabelEn,
    this.subtitle,
  }) : sections = List.unmodifiable(sections);

  final String id;
  final String title;
  final String? titleEn;
  final String context;
  final String? contextEn;
  final String? subtitle;
  final List<ReaderSection> sections;
  final String? sourceLabel;
  final String? sourceLabelEn;

  String titleFor(String languageCode) =>
      languageCode.toLowerCase() == 'en' ? titleEn ?? title : title;

  String contextFor(String languageCode) =>
      languageCode.toLowerCase() == 'en' ? contextEn ?? context : context;

  String? sourceLabelFor(String languageCode) =>
      languageCode.toLowerCase() == 'en'
      ? sourceLabelEn ?? sourceLabel
      : sourceLabel;
}
