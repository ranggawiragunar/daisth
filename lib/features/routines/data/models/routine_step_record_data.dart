class RoutineStepRecordData {
  const RoutineStepRecordData({
    required this.dateKey,
    required this.routineId,
    required this.stepId,
    required this.isCompleted,
    required this.recordedAtUtc,
    required this.updatedAtUtc,
    this.completedAtUtc,
  });

  final String dateKey;
  final String routineId;
  final String stepId;
  final bool isCompleted;
  final String? completedAtUtc;
  final String recordedAtUtc;
  final String updatedAtUtc;

  factory RoutineStepRecordData.fromMap(Map<String, Object?> map) =>
      RoutineStepRecordData(
        dateKey: map['date_key']! as String,
        routineId: map['routine_id']! as String,
        stepId: map['step_id']! as String,
        isCompleted: map['is_completed'] == 1,
        completedAtUtc: map['completed_at_utc'] as String?,
        recordedAtUtc: map['recorded_at_utc']! as String,
        updatedAtUtc: map['updated_at_utc']! as String,
      );

  Map<String, Object?> toMap() => {
    'date_key': dateKey,
    'routine_id': routineId,
    'step_id': stepId,
    'is_completed': isCompleted ? 1 : 0,
    'completed_at_utc': completedAtUtc,
    'recorded_at_utc': recordedAtUtc,
    'updated_at_utc': updatedAtUtc,
  };
}
