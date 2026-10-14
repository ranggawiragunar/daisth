import '../../domain/models/routine_attachment.dart';

class RoutineAttachmentMapper {
  const RoutineAttachmentMapper();

  RoutineAttachment fromMap(Map<String, Object?> row) => RoutineAttachment(
    id: row['id'] as String,
    routineId: row['routine_id'] as String,
    type: row['type'] as String,
    localRelativePath: row['local_relative_path'] as String?,
    originalFileName: row['original_file_name'] as String?,
    mimeType: row['mime_type'] as String,
    byteSize: row['byte_size'] as int,
    width: row['width'] as int?,
    height: row['height'] as int?,
    sortOrder: row['sort_order'] as int,
    contentSha256: row['content_sha256'] as String?,
    storagePath: row['storage_path'] as String?,
    createdAt: DateTime.parse(row['created_at_utc'] as String).toUtc(),
    updatedAt: DateTime.parse(row['updated_at_utc'] as String).toUtc(),
    deletedAt: (row['deleted_at_utc'] as String?) == null
        ? null
        : DateTime.parse(row['deleted_at_utc'] as String).toUtc(),
  );

  Map<String, Object?> toMap(RoutineAttachment value) => {
    'id': value.id,
    'routine_id': value.routineId,
    'type': value.type,
    'local_relative_path': value.localRelativePath,
    'original_file_name': value.originalFileName,
    'mime_type': value.mimeType,
    'byte_size': value.byteSize,
    'width': value.width,
    'height': value.height,
    'sort_order': value.sortOrder,
    'content_sha256': value.contentSha256,
    'storage_path': value.storagePath,
    'created_at_utc': value.createdAt.toUtc().toIso8601String(),
    'updated_at_utc': value.updatedAt.toUtc().toIso8601String(),
    'deleted_at_utc': value.deletedAt?.toUtc().toIso8601String(),
  };
}
