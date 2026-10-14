import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/persistence/data/schema/database_schema.dart';
import 'package:daisth/features/routines/data/repositories/routine_editor_repository_data.dart';
import 'package:daisth/features/routines/domain/models/routine_attachment.dart';
import 'package:daisth/features/routines/domain/models/routine_content.dart';
import 'package:daisth/features/routines/domain/models/routine_definition.dart';
import 'package:daisth/features/routines/domain/models/routine_origin.dart';
import 'package:daisth/features/routines/domain/models/routine_priority.dart';
import 'package:daisth/features/routines/domain/models/routine_schedule.dart';
import 'package:daisth/features/routines/domain/models/routine_editor_save.dart';

import '../support/test_persistence.dart';

void main() {
  test(
    'routine content, image metadata, and tombstone save atomically',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final database = await persistence.database.open();
      final now = DateTime.utc(2026, 10, 14, 5);
      final definition = RoutineDefinition(
        id: 'custom-reading',
        origin: RoutineOrigin.custom,
        title: 'Morning reading',
        description: null,
        isEnabled: true,
        isArchived: false,
        schedule: RoutineSchedule.fixed(8 * 60),
        reminderEnabled: true,
        priority: RoutinePriority.medium,
        sortOrder: 10,
        createdAt: now,
        updatedAt: now,
      );
      final content = RoutineContent(
        routineId: definition.id,
        serializedDelta: '[{"insert":"Read slowly\\n"}]',
        plainText: 'Read slowly',
        formatVersion: 1,
        createdAt: now,
        updatedAt: now,
      );
      final image = RoutineAttachment(
        id: 'photo-1',
        routineId: definition.id,
        type: 'image',
        localRelativePath: 'custom-reading/photo-1.jpg',
        originalFileName: 'reading.jpg',
        mimeType: 'image/jpeg',
        byteSize: 4200,
        width: 1200,
        height: 800,
        sortOrder: 0,
        contentSha256: 'abc123',
        createdAt: now,
        updatedAt: now,
      );
      final repository = RoutineEditorRepositoryData(
        database: persistence.database,
        onRoutineChanged: () {},
      );

      await repository.save(
        RoutineEditorSave(
          definition: definition,
          steps: const [],
          content: content,
          attachments: [image],
          removedAttachmentIds: const {},
          now: now,
        ),
      );

      expect(
        await database.query(DatabaseSchema.routineContents),
        hasLength(1),
      );
      expect(
        await database.query(DatabaseSchema.routineAttachments),
        hasLength(1),
      );
      expect(await database.query(DatabaseSchema.syncOutbox), isNotEmpty);

      await repository.save(
        RoutineEditorSave(
          definition: definition.copyWith(
            updatedAt: now.add(const Duration(minutes: 1)),
          ),
          steps: const [],
          content: null,
          attachments: const [],
          removedAttachmentIds: const {'photo-1'},
          now: now.add(const Duration(minutes: 1)),
        ),
      );
      expect(await database.query(DatabaseSchema.routineContents), isEmpty);
      final tombstone = (await database.query(
        DatabaseSchema.routineAttachments,
      )).single;
      expect(tombstone['deleted_at_utc'], isNotNull);
      expect(tombstone['local_relative_path'], isNull);
    },
  );
}
