import '../models/sync_entity.dart';

class CloudDataset {
  const CloudDataset({required this.entities, this.invalidDocumentCount = 0});

  final List<SyncEntity> entities;
  final int invalidDocumentCount;
}

abstract interface class CloudDataRepository {
  Future<CloudDataset> fetchAccountDataset(String uid);
  Future<void> writeEntities(String uid, List<SyncEntity> entities);
  Future<void> updateUserSyncMetadata(String uid, DateTime nowUtc);
  Future<void> deleteAllUserCloudData(String uid);
}
