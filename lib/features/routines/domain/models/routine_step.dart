import 'routine_requirement.dart';

class RoutineStep {
  const RoutineStep({
    required this.id,
    required this.title,
    required this.subtitle,
    this.requirement = RoutineRequirement.required,
    this.completed = false,
    this.badge,
    this.guidanceTitle,
    this.guidanceType,
    this.rakaatCount,
    this.sectionTitle,
    this.readerContentId,
  });

  final String id;
  final String title;
  final String subtitle;
  final RoutineRequirement requirement;
  final bool completed;
  final String? badge;
  final String? guidanceTitle;
  final String? guidanceType;
  final int? rakaatCount;
  final String? sectionTitle;
  final String? readerContentId;

  bool get isRequired => requirement == RoutineRequirement.required;
  bool get hasGuidance => guidanceTitle != null || readerContentId != null;

  RoutineStep copyWith({bool? completed}) => RoutineStep(
    id: id,
    title: title,
    subtitle: subtitle,
    requirement: requirement,
    completed: completed ?? this.completed,
    badge: badge,
    guidanceTitle: guidanceTitle,
    guidanceType: guidanceType,
    rakaatCount: rakaatCount,
    sectionTitle: sectionTitle,
    readerContentId: readerContentId,
  );
}
