class DhikrItem {
  const DhikrItem({
    required this.id,
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.targetCount,
  }) : assert(targetCount > 0);

  final String id;
  final String title;
  final String arabic;
  final String transliteration;
  final int targetCount;
}
