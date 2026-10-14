import 'dart:convert';

import '../models/routine_attachment.dart';
import '../models/routine_content.dart';
import '../models/routine_definition.dart';
import '../models/routine_origin.dart';
import '../models/routine_step_definition.dart';
import '../repositories/routine_editor_repository.dart';
import '../repositories/routine_record_repository.dart';
import '../repositories/routine_repository.dart';
import '../models/routine_editor_save.dart';
import 'save_custom_routine_use_case.dart';

class SaveRoutineEditorUseCase {
  const SaveRoutineEditorUseCase({
    required this.editorRepository,
    required this.routines,
    required this.records,
  });

  static const maxPlainTextCharacters = 50000;
  static const maxDeltaBytes = 700 * 1024;

  final RoutineEditorRepository editorRepository;
  final RoutineRepository routines;
  final RoutineRecordRepository records;

  Future<void> call({
    required RoutineDefinition definition,
    required List<RoutineStepDefinition>? steps,
    required RoutineContent? content,
    required List<RoutineAttachment> attachments,
    required Set<String> removedAttachmentIds,
    required DateTime now,
  }) async {
    final existing = await routines.getRoutine(definition.id);
    final normalizedTitle = definition.title.trim();
    if (definition.origin == RoutineOrigin.custom && normalizedTitle.isEmpty) {
      throw const RoutineDefinitionValidationException(
        'Masukkan nama rutinitas.',
      );
    }
    if (definition.origin == RoutineOrigin.custom &&
        normalizedTitle.length > 50) {
      throw const RoutineDefinitionValidationException(
        'Nama rutinitas maksimal 50 karakter.',
      );
    }
    if (existing != null && existing.origin != definition.origin) {
      throw const RoutineDefinitionValidationException(
        'Rutinitas ini tidak dapat diganti.',
      );
    }
    if (steps != null && steps.any((step) => step.title.trim().isEmpty)) {
      throw const RoutineDefinitionValidationException(
        'Isi atau hapus item checklist yang kosong.',
      );
    }
    if (steps != null &&
        steps.isNotEmpty &&
        !steps.any((step) => step.isRequired)) {
      throw const RoutineDefinitionValidationException(
        'Pilih setidaknya satu langkah wajib.',
      );
    }
    if (attachments.length > RoutineAttachment.maxAttachmentsPerRoutine) {
      throw const RoutineDefinitionValidationException(
        'Terlalu banyak gambar untuk satu rutinitas.',
      );
    }
    if (attachments.any((item) => item.byteSize > RoutineAttachment.maxBytes)) {
      throw const RoutineDefinitionValidationException(
        'Salah satu gambar melebihi ukuran yang didukung.',
      );
    }
    if (content != null &&
        (content.plainText.length > maxPlainTextCharacters ||
            utf8.encode(content.serializedDelta).length > maxDeltaBytes)) {
      throw const RoutineDefinitionValidationException(
        'Catatan terlalu panjang untuk disimpan.',
      );
    }

    final updated = definition.copyWith(
      title: definition.origin == RoutineOrigin.custom
          ? normalizedTitle
          : definition.title,
      updatedAt: now.toUtc(),
    );
    await editorRepository.save(
      RoutineEditorSave(
        definition: updated,
        steps: steps,
        content: content,
        attachments: attachments,
        removedAttachmentIds: removedAttachmentIds,
        now: now.toUtc(),
      ),
    );
    if (updated.origin == RoutineOrigin.custom && steps != null) {
      await SaveCustomRoutineUseCase(
        routines: routines,
        records: records,
      ).recalculateTodayAfterDefinitionChange(updated, steps, now);
    }
  }
}
