import '../models/routine_definition.dart';
import '../models/routine_origin.dart';
import '../repositories/routine_repository.dart';

class ResetDefaultRoutineUseCase {
  const ResetDefaultRoutineUseCase({
    required this.repository,
    required this.templates,
  });
  final RoutineRepository repository;
  final List<RoutineDefinition> Function(DateTime now) templates;

  Future<void> call(String id, {DateTime? now}) async {
    final current = await repository.getRoutine(id);
    if (current == null || current.origin != RoutineOrigin.defaultRoutine) {
      throw StateError('Only a default routine can be reset.');
    }
    final template = templates(
      now ?? DateTime.now().toUtc(),
    ).firstWhere((item) => item.id == id);
    final updatedAt = now ?? DateTime.now().toUtc();
    await repository.saveRoutine(
      RoutineDefinition(
        id: current.id,
        origin: current.origin,
        templateKey: current.templateKey,
        title: template.title,
        description: template.description,
        isEnabled: template.isEnabled,
        isArchived: false,
        schedule: template.schedule,
        reminderEnabled: template.reminderEnabled,
        priority: template.priority,
        sortOrder: template.sortOrder,
        createdAt: current.createdAt,
        updatedAt: updatedAt,
      ),
    );
  }
}
