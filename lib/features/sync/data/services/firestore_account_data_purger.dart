const daisthAccountCollections = [
  'routineDefinitions',
  'routineStepDefinitions',
  'routineRecords',
  'routineStepRecords',
  'dailyReflections',
  'routineContents',
  'routineAttachments',
];

abstract interface class FirestorePurgeGateway {
  Future<List<String>> nextDocumentIds(
    String uid,
    String collection,
    int limit,
  );
  Future<void> deleteDocuments(
    String uid,
    String collection,
    List<String> documentIds,
  );
  Future<void> deleteUserRoot(String uid);
}

class FirestoreAccountDataPurger {
  const FirestoreAccountDataPurger({this.batchSize = 400});

  final int batchSize;

  Future<void> purge(String uid, FirestorePurgeGateway gateway) async {
    for (final collection in daisthAccountCollections) {
      while (true) {
        final ids = await gateway.nextDocumentIds(uid, collection, batchSize);
        if (ids.isEmpty) break;
        await gateway.deleteDocuments(uid, collection, ids);
      }
    }
    await gateway.deleteUserRoot(uid);
  }
}
