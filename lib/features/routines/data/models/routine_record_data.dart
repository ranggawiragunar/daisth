class RoutineRecordData {
  const RoutineRecordData({
    required this.dateKey,
    required this.routineId,
    required this.status,
    required this.recordedAtUtc,
    required this.updatedAtUtc,
    this.completedAtUtc,
    this.notTodayReason,
  });

  final String dateKey;
  final String routineId;
  final String status;
  final String? completedAtUtc;
  final String recordedAtUtc;
  final String updatedAtUtc;
  final String? notTodayReason;

  factory RoutineRecordData.fromMap(Map<String, Object?> map) =>
      RoutineRecordData(
        dateKey: map['date_key']! as String,
        routineId: map['routine_id']! as String,
        status: map['status']! as String,
        completedAtUtc: map['completed_at_utc'] as String?,
        recordedAtUtc: map['recorded_at_utc']! as String,
        updatedAtUtc: map['updated_at_utc']! as String,
        notTodayReason: map['not_today_reason'] as String?,
      );

  Map<String, Object?> toMap() => {
    'date_key': dateKey,
    'routine_id': routineId,
    'status': status,
    'completed_at_utc': completedAtUtc,
    'recorded_at_utc': recordedAtUtc,
    'updated_at_utc': updatedAtUtc,
    'not_today_reason': notTodayReason,
  };
}
