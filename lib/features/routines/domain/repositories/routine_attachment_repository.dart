import '../models/routine_attachment.dart';

abstract interface class RoutineAttachmentRepository {
  Future<List<RoutineAttachment>> listForRoutine(String routineId);
  Future<Set<String>> getAllLocalRelativePaths();
  Future<void> saveAll(List<RoutineAttachment> attachments);
  Future<void> applyRemote(RoutineAttachment attachment);
}
