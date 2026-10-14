class RoutineContent {
  const RoutineContent({
    required this.routineId,
    required this.serializedDelta,
    required this.plainText,
    required this.formatVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  final String routineId;
  final String serializedDelta;
  final String plainText;
  final int formatVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasMeaningfulText => plainText.trim().isNotEmpty;
}
