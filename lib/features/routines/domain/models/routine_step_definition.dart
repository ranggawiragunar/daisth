class RoutineStepDefinition {
  const RoutineStepDefinition({
    required this.routineId,
    required this.stepId,
    required this.title,
    required this.isRequired,
    required this.isArchived,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String routineId;
  final String stepId;
  final String title;
  final bool isRequired;
  final bool isArchived;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  RoutineStepDefinition copyWith({
    String? title,
    bool? isRequired,
    bool? isArchived,
    int? sortOrder,
    DateTime? updatedAt,
  }) => RoutineStepDefinition(
    routineId: routineId,
    stepId: stepId,
    title: title ?? this.title,
    isRequired: isRequired ?? this.isRequired,
    isArchived: isArchived ?? this.isArchived,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
