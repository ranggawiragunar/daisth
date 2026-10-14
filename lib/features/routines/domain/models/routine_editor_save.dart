import 'routine_attachment.dart';
import 'routine_content.dart';
import 'routine_definition.dart';
import 'routine_step_definition.dart';

class RoutineEditorSave {
  const RoutineEditorSave({
    required this.definition,
    required this.attachments,
    required this.removedAttachmentIds,
    required this.now,
    this.steps,
    this.content,
  });

  final RoutineDefinition definition;
  final List<RoutineStepDefinition>? steps;
  final RoutineContent? content;
  final List<RoutineAttachment> attachments;
  final Set<String> removedAttachmentIds;
  final DateTime now;
}
