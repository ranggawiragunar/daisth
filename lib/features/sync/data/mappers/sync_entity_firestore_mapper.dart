import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../reflection/domain/models/daily_reflection.dart';
import '../../../reflection/domain/models/reflection_rhythm.dart';
import '../../../routines/domain/models/prayer_key.dart';
import '../../../routines/domain/models/routine_definition.dart';
import '../../../routines/domain/models/routine_origin.dart';
import '../../../routines/domain/models/routine_priority.dart';
import '../../../routines/domain/models/routine_record.dart';
import '../../../routines/domain/models/routine_schedule.dart';
import '../../../routines/domain/models/routine_status.dart';
import '../../../routines/domain/models/routine_step_definition.dart';
import '../../../routines/domain/models/routine_step_record.dart';
import '../../../routines/domain/models/routine_attachment.dart';
import '../../../routines/domain/models/routine_content.dart';
import '../../../../core/time/domain/models/calendar_day.dart';
import '../../domain/models/sync_entity.dart';
import 'firestore_document_ids.dart';

class SyncEntityFirestoreMapper {
  static const schemaVersion = 1;
  static const _mandatoryPrayerIds = {
    'subuh',
    'zuhur',
    'asar',
    'maghrib',
    'isya',
  };

  String collectionFor(SyncEntityType type) => switch (type) {
    SyncEntityType.routineDefinition => 'routineDefinitions',
    SyncEntityType.routineStepDefinition => 'routineStepDefinitions',
    SyncEntityType.routineRecord => 'routineRecords',
    SyncEntityType.routineStepRecord => 'routineStepRecords',
    SyncEntityType.dailyReflection => 'dailyReflections',
    SyncEntityType.routineContent => 'routineContents',
    SyncEntityType.routineAttachment => 'routineAttachments',
  };

  SyncEntity routineDefinition(RoutineDefinition value, String deviceId) =>
      SyncEntity(
        type: SyncEntityType.routineDefinition,
        id: FirestoreDocumentIds.routineDefinition(value.id),
        updatedAtUtc: value.updatedAt,
        sourceDeviceId: deviceId,
        payload: value,
      );

  SyncEntity routineStepDefinition(
    RoutineStepDefinition value,
    String deviceId,
  ) => SyncEntity(
    type: SyncEntityType.routineStepDefinition,
    id: FirestoreDocumentIds.routineStepDefinition(
      value.routineId,
      value.stepId,
    ),
    updatedAtUtc: value.updatedAt,
    sourceDeviceId: deviceId,
    payload: value,
  );

  SyncEntity routineRecord(RoutineRecord value, String deviceId) => SyncEntity(
    type: SyncEntityType.routineRecord,
    id: FirestoreDocumentIds.routineRecord(
      value.calendarDay.toDateKey(),
      value.routineId,
    ),
    updatedAtUtc: value.updatedAt,
    sourceDeviceId: deviceId,
    payload: value,
  );

  SyncEntity routineStepRecord(RoutineStepRecord value, String deviceId) =>
      SyncEntity(
        type: SyncEntityType.routineStepRecord,
        id: FirestoreDocumentIds.routineStepRecord(
          value.calendarDay.toDateKey(),
          value.routineId,
          value.stepId,
        ),
        updatedAtUtc: value.updatedAt,
        sourceDeviceId: deviceId,
        payload: value,
      );

  SyncEntity dailyReflection(DailyReflection value, String deviceId) =>
      SyncEntity(
        type: SyncEntityType.dailyReflection,
        id: FirestoreDocumentIds.dailyReflection(value.day.toDateKey()),
        updatedAtUtc: value.updatedAt,
        sourceDeviceId: deviceId,
        payload: value,
      );

  SyncEntity routineContent(RoutineContent value, String deviceId) =>
      SyncEntity(
        type: SyncEntityType.routineContent,
        id: Uri.encodeComponent(value.routineId),
        updatedAtUtc: value.updatedAt,
        sourceDeviceId: deviceId,
        payload: value,
      );

  SyncEntity routineAttachment(RoutineAttachment value, String deviceId) =>
      SyncEntity(
        type: SyncEntityType.routineAttachment,
        id: Uri.encodeComponent(value.id),
        updatedAtUtc: value.updatedAt,
        sourceDeviceId: deviceId,
        payload: value.deletedAt == null ? value : null,
        isDeleted: value.deletedAt != null,
        deletedAtUtc: value.deletedAt,
      );

  Map<String, Object?> toFirestore(SyncEntity entity) {
    final fields = entity.isDeleted
        ? <String, Object?>{}
        : switch (entity.type) {
            SyncEntityType.routineDefinition => _routineDefinitionToMap(
              _expect<RoutineDefinition>(entity.payload),
            ),
            SyncEntityType.routineStepDefinition => _routineStepDefinitionToMap(
              _expect<RoutineStepDefinition>(entity.payload),
            ),
            SyncEntityType.routineRecord => _routineRecordToMap(
              _expect<RoutineRecord>(entity.payload),
            ),
            SyncEntityType.routineStepRecord => _routineStepRecordToMap(
              _expect<RoutineStepRecord>(entity.payload),
            ),
            SyncEntityType.dailyReflection => _reflectionToMap(
              _expect<DailyReflection>(entity.payload),
            ),
            SyncEntityType.routineContent => _routineContentToMap(
              _expect<RoutineContent>(entity.payload),
            ),
            SyncEntityType.routineAttachment => _routineAttachmentToMap(
              _expect<RoutineAttachment>(entity.payload),
            ),
          };
    return {
      ...fields,
      'schemaVersion': schemaVersion,
      'updatedAtUtc': Timestamp.fromDate(entity.updatedAtUtc.toUtc()),
      'sourceDeviceId': entity.sourceDeviceId,
      'isDeleted': entity.isDeleted,
      'deletedAtUtc': entity.deletedAtUtc == null
          ? null
          : Timestamp.fromDate(entity.deletedAtUtc!.toUtc()),
    };
  }

  SyncEntity fromFirestore({
    required SyncEntityType type,
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    if (_integer(data['schemaVersion']) != schemaVersion) {
      throw const SyncDocumentException(
        SyncFailureCode.unsupportedSchema,
        'Unsupported cloud schema version.',
      );
    }
    final updatedAt = _timestamp(data['updatedAtUtc']);
    final sourceDeviceId = _requiredString(data['sourceDeviceId']);
    final isDeleted = _requiredBool(data['isDeleted']);
    final deletedAt = _optionalTimestamp(data['deletedAtUtc']);
    if (isDeleted && deletedAt == null) {
      throw const SyncDocumentException(
        SyncFailureCode.invalidRemoteDocument,
        'Tombstone has no deletion timestamp.',
      );
    }
    final payload = isDeleted
        ? null
        : switch (type) {
            SyncEntityType.routineDefinition => _routineDefinitionFromMap(
              documentId,
              data,
            ),
            SyncEntityType.routineStepDefinition =>
              _routineStepDefinitionFromMap(documentId, data),
            SyncEntityType.routineRecord => _routineRecordFromMap(
              documentId,
              data,
            ),
            SyncEntityType.routineStepRecord => _routineStepRecordFromMap(
              documentId,
              data,
            ),
            SyncEntityType.dailyReflection => _reflectionFromMap(
              documentId,
              data,
            ),
            SyncEntityType.routineContent => _routineContentFromMap(
              documentId,
              data,
            ),
            SyncEntityType.routineAttachment => _routineAttachmentFromMap(
              documentId,
              data,
            ),
          };
    _validateTombstoneId(type, documentId);
    return SyncEntity(
      type: type,
      id: documentId,
      updatedAtUtc: updatedAt,
      sourceDeviceId: sourceDeviceId,
      payload: payload,
      isDeleted: isDeleted,
      deletedAtUtc: deletedAt,
    );
  }

  Map<String, Object?> _routineDefinitionToMap(RoutineDefinition value) => {
    'id': value.id,
    'origin': value.origin.storageValue,
    'templateKey': value.templateKey,
    'title': value.title,
    'description': value.description,
    'isEnabled': value.isEnabled,
    'isArchived': value.isArchived,
    'scheduleKind': value.schedule.kind,
    'fixedTimeMinutes': value.schedule.minutesAfterMidnight,
    'prayerKey': value.schedule.prayerKey?.storageValue,
    'reminderEnabled': value.reminderEnabled,
    'priority': value.priority.storageValue,
    'sortOrder': value.sortOrder,
    'createdAtUtc': Timestamp.fromDate(value.createdAt.toUtc()),
  };

  RoutineDefinition _routineDefinitionFromMap(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final id = _requiredString(data['id']);
    if (FirestoreDocumentIds.routineDefinition(id) != documentId) {
      throw const SyncDocumentException(
        SyncFailureCode.invalidRemoteDocument,
        'Routine document identity mismatch.',
      );
    }
    final origin = RoutineOrigin.fromStorage(_requiredString(data['origin']));
    final scheduleKind = _requiredString(data['scheduleKind']);
    final RoutineSchedule schedule;
    if (scheduleKind == 'fixed') {
      schedule = RoutineSchedule.fixed(
        _requiredInteger(data['fixedTimeMinutes']),
      );
      if (data['prayerKey'] != null) throw const FormatException();
    } else if (scheduleKind == 'prayer') {
      final prayerKey = PrayerKey.fromStorage(
        _requiredString(data['prayerKey']),
      );
      if (prayerKey == null || data['fixedTimeMinutes'] != null) {
        throw const FormatException();
      }
      schedule = RoutineSchedule.prayer(prayerKey);
    } else {
      throw const FormatException();
    }
    if (origin == null) throw const FormatException();
    final templateKey = _optionalString(data['templateKey']);
    if ((origin == RoutineOrigin.defaultRoutine && templateKey == null) ||
        (origin == RoutineOrigin.custom && templateKey != null)) {
      throw const FormatException();
    }
    final priority = RoutinePriority.fromStorage(
      _requiredString(data['priority']),
    );
    if (priority == null) throw const FormatException();
    return RoutineDefinition(
      id: id,
      origin: origin,
      templateKey: templateKey,
      title: _requiredString(data['title']),
      description: _optionalString(data['description']),
      isEnabled: _requiredBool(data['isEnabled']),
      isArchived: _requiredBool(data['isArchived']),
      schedule: schedule,
      reminderEnabled: _requiredBool(data['reminderEnabled']),
      priority: priority,
      sortOrder: _requiredInteger(data['sortOrder']),
      createdAt: _timestamp(data['createdAtUtc']),
      updatedAt: _timestamp(data['updatedAtUtc']),
    );
  }

  Map<String, Object?> _routineStepDefinitionToMap(
    RoutineStepDefinition value,
  ) => {
    'routineId': value.routineId,
    'stepId': value.stepId,
    'title': value.title,
    'isRequired': value.isRequired,
    'isArchived': value.isArchived,
    'sortOrder': value.sortOrder,
    'createdAtUtc': Timestamp.fromDate(value.createdAt.toUtc()),
  };

  RoutineStepDefinition _routineStepDefinitionFromMap(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final routineId = _requiredString(data['routineId']);
    final stepId = _requiredString(data['stepId']);
    if (FirestoreDocumentIds.routineStepDefinition(routineId, stepId) !=
        documentId) {
      throw const FormatException();
    }
    return RoutineStepDefinition(
      routineId: routineId,
      stepId: stepId,
      title: _requiredString(data['title']),
      isRequired: _requiredBool(data['isRequired']),
      isArchived: _requiredBool(data['isArchived']),
      sortOrder: _requiredInteger(data['sortOrder']),
      createdAt: _timestamp(data['createdAtUtc']),
      updatedAt: _timestamp(data['updatedAtUtc']),
    );
  }

  Map<String, Object?> _routineRecordToMap(RoutineRecord value) => {
    'dateKey': value.calendarDay.toDateKey(),
    'routineId': value.routineId,
    'status': value.status.name,
    'completedAtUtc': _timestampValue(value.completedAt),
    'recordedAtUtc': Timestamp.fromDate(value.recordedAt.toUtc()),
    'notTodayReason': value.notTodayReason,
  };

  RoutineRecord _routineRecordFromMap(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final dateKey = _requiredString(data['dateKey']);
    final routineId = _requiredString(data['routineId']);
    _validateDay(dateKey);
    if (FirestoreDocumentIds.routineRecord(dateKey, routineId) != documentId) {
      throw const FormatException();
    }
    final status = switch (_requiredString(data['status'])) {
      'partial' => RoutineStatus.partial,
      'completed' => RoutineStatus.completed,
      'notToday' => RoutineStatus.notToday,
      _ => throw const FormatException(),
    };
    if (status == RoutineStatus.notToday &&
        _mandatoryPrayerIds.contains(routineId)) {
      throw const FormatException();
    }
    return RoutineRecord(
      calendarDay: CalendarDay.parseDateKey(dateKey),
      routineId: routineId,
      status: status,
      completedAt: _optionalTimestamp(data['completedAtUtc']),
      recordedAt: _timestamp(data['recordedAtUtc']),
      updatedAt: _timestamp(data['updatedAtUtc']),
      notTodayReason: _optionalString(data['notTodayReason']),
    );
  }

  Map<String, Object?> _routineStepRecordToMap(RoutineStepRecord value) => {
    'dateKey': value.calendarDay.toDateKey(),
    'routineId': value.routineId,
    'stepId': value.stepId,
    'isCompleted': value.isCompleted,
    'completedAtUtc': _timestampValue(value.completedAt),
    'recordedAtUtc': Timestamp.fromDate(value.recordedAt.toUtc()),
  };

  RoutineStepRecord _routineStepRecordFromMap(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final dateKey = _requiredString(data['dateKey']);
    final routineId = _requiredString(data['routineId']);
    final stepId = _requiredString(data['stepId']);
    _validateDay(dateKey);
    if (FirestoreDocumentIds.routineStepRecord(dateKey, routineId, stepId) !=
        documentId) {
      throw const FormatException();
    }
    return RoutineStepRecord(
      calendarDay: CalendarDay.parseDateKey(dateKey),
      routineId: routineId,
      stepId: stepId,
      isCompleted: _requiredBool(data['isCompleted']),
      completedAt: _optionalTimestamp(data['completedAtUtc']),
      recordedAt: _timestamp(data['recordedAtUtc']),
      updatedAt: _timestamp(data['updatedAtUtc']),
    );
  }

  Map<String, Object?> _reflectionToMap(DailyReflection value) => {
    'dateKey': value.day.toDateKey(),
    'rhythm': value.rhythm.name,
    'note': value.note,
    'recordedAtUtc': Timestamp.fromDate(value.recordedAt.toUtc()),
  };

  DailyReflection _reflectionFromMap(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final dateKey = _requiredString(data['dateKey']);
    _validateDay(dateKey);
    if (FirestoreDocumentIds.dailyReflection(dateKey) != documentId) {
      throw const FormatException();
    }
    final rhythm = switch (_requiredString(data['rhythm'])) {
      'steady' => ReflectionRhythm.steady,
      'mixed' => ReflectionRhythm.mixed,
      'heavy' => ReflectionRhythm.heavy,
      _ => throw const FormatException(),
    };
    return DailyReflection(
      day: CalendarDay.parseDateKey(dateKey),
      rhythm: rhythm,
      note: _optionalString(data['note']),
      recordedAt: _timestamp(data['recordedAtUtc']),
      updatedAt: _timestamp(data['updatedAtUtc']),
    );
  }

  Map<String, Object?> _routineContentToMap(RoutineContent value) => {
    'routineId': value.routineId,
    'deltaJson': value.serializedDelta,
    'plainText': value.plainText,
    'formatVersion': value.formatVersion,
    'createdAtUtc': Timestamp.fromDate(value.createdAt.toUtc()),
  };

  RoutineContent _routineContentFromMap(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final routineId = _requiredString(data['routineId']);
    if (Uri.encodeComponent(routineId) != documentId ||
        _requiredInteger(data['formatVersion']) != 1) {
      throw const FormatException();
    }
    final serialized = _requiredString(data['deltaJson']);
    if (utf8.encode(serialized).length > 700 * 1024) {
      throw const FormatException();
    }
    final plainText = _requiredString(data['plainText']);
    if (plainText.length > 50000) throw const FormatException();
    return RoutineContent(
      routineId: routineId,
      serializedDelta: serialized,
      plainText: plainText,
      formatVersion: 1,
      createdAt: _timestamp(data['createdAtUtc']),
      updatedAt: _timestamp(data['updatedAtUtc']),
    );
  }

  Map<String, Object?> _routineAttachmentToMap(RoutineAttachment value) => {
    'id': value.id,
    'routineId': value.routineId,
    'type': value.type,
    'storagePath': value.storagePath,
    'mimeType': value.mimeType,
    'byteSize': value.byteSize,
    'width': value.width,
    'height': value.height,
    'sortOrder': value.sortOrder,
    'contentSha256': value.contentSha256,
    'createdAtUtc': Timestamp.fromDate(value.createdAt.toUtc()),
  };

  RoutineAttachment _routineAttachmentFromMap(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final id = _requiredString(data['id']);
    final routineId = _requiredString(data['routineId']);
    if (Uri.encodeComponent(id) != documentId ||
        _requiredString(data['type']) != 'image') {
      throw const FormatException();
    }
    final mime = _requiredString(data['mimeType']);
    if (mime != 'image/jpeg' && mime != 'image/png') {
      throw const FormatException();
    }
    final byteSize = _requiredInteger(data['byteSize']);
    if (byteSize <= 0 || byteSize > RoutineAttachment.maxBytes) {
      throw const FormatException();
    }
    final storagePath = _requiredString(data['storagePath']);
    if (!storagePath.contains('/routine-attachments/$id/')) {
      throw const FormatException();
    }
    return RoutineAttachment(
      id: id,
      routineId: routineId,
      type: 'image',
      localRelativePath: null,
      originalFileName: null,
      mimeType: mime,
      byteSize: byteSize,
      width: _integer(data['width']),
      height: _integer(data['height']),
      sortOrder: _requiredInteger(data['sortOrder']),
      contentSha256: _optionalString(data['contentSha256']),
      storagePath: storagePath,
      createdAt: _timestamp(data['createdAtUtc']),
      updatedAt: _timestamp(data['updatedAtUtc']),
    );
  }

  void _validateTombstoneId(SyncEntityType type, String id) {
    switch (type) {
      case SyncEntityType.routineDefinition:
        if (Uri.decodeComponent(id).isEmpty) throw const FormatException();
      case SyncEntityType.routineStepDefinition:
        FirestoreDocumentIds.splitPair(id);
      case SyncEntityType.routineRecord || SyncEntityType.dailyReflection:
        final pair = type == SyncEntityType.routineRecord
            ? FirestoreDocumentIds.splitPair(id)
            : (id, '');
        _validateDay(pair.$1);
      case SyncEntityType.routineStepRecord:
        final triple = FirestoreDocumentIds.splitTriple(id);
        _validateDay(triple.$1);
      case SyncEntityType.routineContent || SyncEntityType.routineAttachment:
        if (Uri.decodeComponent(id).isEmpty) throw const FormatException();
    }
  }

  void _validateDay(String value) {
    CalendarDay.parseDateKey(value);
  }

  T _expect<T>(Object? value) {
    if (value is T) return value;
    throw StateError('Unexpected sync payload for $T.');
  }

  String _requiredString(Object? value) {
    if (value is String && value.isNotEmpty) return value;
    throw const FormatException();
  }

  String? _optionalString(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    throw const FormatException();
  }

  int _requiredInteger(Object? value) {
    if (value is int) return value;
    throw const FormatException();
  }

  int? _integer(Object? value) => value is int ? value : null;

  bool _requiredBool(Object? value) {
    if (value is bool) return value;
    throw const FormatException();
  }

  DateTime _timestamp(Object? value) {
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    throw const FormatException();
  }

  DateTime? _optionalTimestamp(Object? value) =>
      value == null ? null : _timestamp(value);

  Object? _timestampValue(DateTime? value) =>
      value == null ? null : Timestamp.fromDate(value.toUtc());
}

class SyncDocumentException implements Exception {
  const SyncDocumentException(this.failureCode, this.message);

  final SyncFailureCode failureCode;
  final String message;
}
