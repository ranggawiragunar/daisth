import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../routines/data/services/routine_attachment_file_service.dart';
import '../../../routines/data/services/routine_attachment_storage_service.dart';
import '../../../routines/domain/models/routine_attachment.dart';

import '../../domain/models/sync_entity.dart';
import '../../domain/repositories/cloud_data_repository.dart';
import '../mappers/sync_entity_firestore_mapper.dart';
import 'firestore_account_data_purger.dart';

class DaisthFirestoreService implements CloudDataRepository {
  DaisthFirestoreService({
    this._firestore,
    RoutineAttachmentStorageService? attachmentStorage,
    RoutineAttachmentFileService? attachmentFiles,
  }) : _attachmentStorage =
           attachmentStorage ?? RoutineAttachmentStorageService(),
       _attachmentFiles = attachmentFiles ?? RoutineAttachmentFileService();

  FirebaseFirestore? _firestore;
  final RoutineAttachmentStorageService _attachmentStorage;
  final RoutineAttachmentFileService _attachmentFiles;
  final _mapper = SyncEntityFirestoreMapper();
  bool _configured = false;

  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;

  void configureTransport() {
    if (_configured) return;
    firestore.settings = const Settings(persistenceEnabled: false);
    _configured = true;
  }

  @override
  Future<CloudDataset> fetchAccountDataset(String uid) async {
    configureTransport();
    final root = firestore.collection('users').doc(uid);
    await root.get(const GetOptions(source: Source.server));
    final entities = <SyncEntity>[];
    var invalid = 0;
    for (final type in SyncEntityType.values) {
      final snapshot = await root
          .collection(_mapper.collectionFor(type))
          .get(const GetOptions(source: Source.server));
      for (final document in snapshot.docs) {
        try {
          entities.add(
            _mapper.fromFirestore(
              type: type,
              documentId: document.id,
              data: document.data(),
            ),
          );
        } on SyncDocumentException catch (error) {
          if (error.failureCode == SyncFailureCode.unsupportedSchema) rethrow;
          invalid++;
        } on FormatException {
          invalid++;
        } catch (_) {
          invalid++;
        }
      }
    }
    return CloudDataset(entities: entities, invalidDocumentCount: invalid);
  }

  @override
  Future<void> writeEntities(String uid, List<SyncEntity> entities) async {
    configureTransport();
    final root = firestore.collection('users').doc(uid);
    final prepared = <SyncEntity>[];
    final deletions = <String>[];
    for (final entity in entities) {
      if (entity.type != SyncEntityType.routineAttachment) {
        prepared.add(entity);
        continue;
      }
      if (entity.isDeleted) {
        deletions.add(Uri.decodeComponent(entity.id));
        prepared.add(entity);
        continue;
      }
      final attachment = entity.payload as RoutineAttachment;
      final file = await _attachmentFiles.resolve(attachment.localRelativePath);
      if (file == null) {
        throw const FileSystemException('Attachment file is missing.');
      }
      final storagePath = await _attachmentStorage.uploadIfChanged(
        uid: uid,
        attachment: attachment,
        file: file,
      );
      prepared.add(
        SyncEntity(
          type: entity.type,
          id: entity.id,
          updatedAtUtc: entity.updatedAtUtc,
          sourceDeviceId: entity.sourceDeviceId,
          payload: attachment.copyWith(storagePath: storagePath),
        ),
      );
    }
    for (var offset = 0; offset < prepared.length; offset += 450) {
      final batch = firestore.batch();
      final group = prepared.skip(offset).take(450);
      for (final entity in group) {
        final ref = root
            .collection(_mapper.collectionFor(entity.type))
            .doc(entity.id);
        final data = _mapper.toFirestore(entity)
          ..['serverUpdatedAt'] = FieldValue.serverTimestamp();
        // Every entity map is a complete document. Replacing it also removes old
        // user content when this write is a metadata-only tombstone.
        batch.set(ref, data);
      }
      await batch.commit();
    }
    for (final attachmentId in deletions) {
      await _attachmentStorage.deleteAttachment(uid, attachmentId);
    }
  }

  @override
  Future<void> updateUserSyncMetadata(String uid, DateTime nowUtc) async {
    configureTransport();
    await firestore.collection('users').doc(uid).set({
      'dataSchemaVersion': 1,
      'lastSyncAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteAllUserCloudData(String uid) async {
    configureTransport();
    await _attachmentStorage.purgeUserAttachments(uid);
    await const FirestoreAccountDataPurger().purge(
      uid,
      _FirestorePurgeGateway(firestore),
    );
  }
}

class _FirestorePurgeGateway implements FirestorePurgeGateway {
  const _FirestorePurgeGateway(this.firestore);

  final FirebaseFirestore firestore;

  @override
  Future<List<String>> nextDocumentIds(
    String uid,
    String collection,
    int limit,
  ) async {
    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection(collection)
        .limit(limit)
        .get(const GetOptions(source: Source.server));
    return snapshot.docs.map((document) => document.id).toList(growable: false);
  }

  @override
  Future<void> deleteDocuments(
    String uid,
    String collection,
    List<String> documentIds,
  ) async {
    final batch = firestore.batch();
    final target = firestore
        .collection('users')
        .doc(uid)
        .collection(collection);
    for (final id in documentIds) {
      batch.delete(target.doc(id));
    }
    await batch.commit();
  }

  @override
  Future<void> deleteUserRoot(String uid) async {
    final root = firestore.collection('users').doc(uid);
    final snapshot = await root.get(const GetOptions(source: Source.server));
    if (snapshot.exists) await root.delete();
  }
}
