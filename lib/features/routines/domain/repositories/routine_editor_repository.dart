import '../models/routine_editor_save.dart';

abstract interface class RoutineEditorRepository {
  Future<void> save(RoutineEditorSave value);
}
