class ReaderSection {
  const ReaderSection({
    this.heading,
    this.headingEn,
    this.arabic,
    this.transliteration,
    this.translation,
    this.translationEn,
    this.sourceLabel,
    this.sourceLabelEn,
    this.note,
    this.noteEn,
    this.showFieldLabels = false,
  });

  final String? heading;
  final String? headingEn;
  final String? arabic;
  final String? transliteration;
  final String? translation;
  final String? translationEn;
  final String? sourceLabel;
  final String? sourceLabelEn;
  final String? note;
  final String? noteEn;
  final bool showFieldLabels;

  String? headingFor(String languageCode) =>
      languageCode.toLowerCase() == 'en' ? headingEn ?? heading : heading;

  String? translationFor(String languageCode) =>
      languageCode.toLowerCase() == 'en'
      ? translationEn ?? translation
      : translation;

  String? sourceLabelFor(String languageCode) =>
      languageCode.toLowerCase() == 'en'
      ? sourceLabelEn ?? sourceLabel
      : sourceLabel;

  String? noteFor(String languageCode) =>
      languageCode.toLowerCase() == 'en' ? noteEn ?? note : note;
}
