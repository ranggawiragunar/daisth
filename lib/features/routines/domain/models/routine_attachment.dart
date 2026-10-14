class RoutineAttachment {
  const RoutineAttachment({
    required this.id,
    required this.routineId,
    required this.type,
    required this.localRelativePath,
    required this.originalFileName,
    required this.mimeType,
    required this.byteSize,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.width,
    this.height,
    this.contentSha256,
    this.storagePath,
    this.deletedAt,
  });

  static const maxAttachmentsPerRoutine = 8;
  static const maxBytes = 8 * 1024 * 1024;
  static const maxImageDimension = 2048;

  final String id;
  final String routineId;
  final String type;
  final String? localRelativePath;
  final String? originalFileName;
  final String mimeType;
  final int byteSize;
  final int? width;
  final int? height;
  final int sortOrder;
  final String? contentSha256;
  final String? storagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  RoutineAttachment copyWith({
    String? localRelativePath,
    bool clearLocalRelativePath = false,
    String? storagePath,
    int? sortOrder,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) => RoutineAttachment(
    id: id,
    routineId: routineId,
    type: type,
    localRelativePath: clearLocalRelativePath
        ? null
        : localRelativePath ?? this.localRelativePath,
    originalFileName: originalFileName,
    mimeType: mimeType,
    byteSize: byteSize,
    width: width,
    height: height,
    sortOrder: sortOrder ?? this.sortOrder,
    contentSha256: contentSha256,
    storagePath: storagePath ?? this.storagePath,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
  );
}
