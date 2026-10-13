import '../models/routine_definition.dart';
import '../repositories/routine_repository.dart';

class EnsureDefaultRoutinesUseCase {
  const EnsureDefaultRoutinesUseCase({
    required this.repository,
    required this.templates,
  });
  final RoutineRepository repository;
  final List<RoutineDefinition> Function(DateTime now) templates;

  Future<void> call({DateTime? now}) async {
    final current = now ?? DateTime.now().toUtc();
    for (final template in templates(current)) {
      if (await repository.getRoutine(template.id) == null) {
        await repository.saveRoutine(template);
      }
    }
  }
}
