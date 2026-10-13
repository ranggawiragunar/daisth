import 'routine_origin.dart';
import 'routine_priority.dart';
import 'routine_schedule.dart';

class RoutineDefinition {
  const RoutineDefinition({
    required this.id,
    required this.origin,
    required this.title,
    required this.isEnabled,
    required this.isArchived,
    required this.schedule,
    required this.reminderEnabled,
    required this.priority,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.templateKey,
    this.description,
  });

  final String id;
  final RoutineOrigin origin;
  final String? templateKey;
  final String title;
  final String? description;
  final bool isEnabled;
  final bool isArchived;
  final RoutineSchedule schedule;
  final bool reminderEnabled;
  final RoutinePriority priority;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  RoutineDefinition copyWith({
    String? title,
    String? description,
    bool clearDescription = false,
    bool? isEnabled,
    bool? isArchived,
    RoutineSchedule? schedule,
    bool? reminderEnabled,
    RoutinePriority? priority,
    int? sortOrder,
    DateTime? updatedAt,
  }) => RoutineDefinition(
    id: id,
    origin: origin,
    templateKey: templateKey,
    title: title ?? this.title,
    description: clearDescription ? null : description ?? this.description,
    isEnabled: isEnabled ?? this.isEnabled,
    isArchived: isArchived ?? this.isArchived,
    schedule: schedule ?? this.schedule,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    priority: priority ?? this.priority,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
