import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/features/sync/data/services/firestore_account_data_purger.dart';

void main() {
  test('purges every known collection in bounded batches then root', () async {
    final gateway = _FakePurgeGateway();
    gateway.documents['routineRecords'] = List.generate(
      905,
      (index) => 'record-$index',
    );
    gateway.documents['dailyReflections'] = ['reflection-1'];

    await const FirestoreAccountDataPurger().purge('user-1', gateway);

    expect(gateway.documents.values.every((items) => items.isEmpty), isTrue);
    expect(gateway.batchSizes, [400, 400, 105, 1]);
    expect(gateway.rootDeleted, isTrue);
    expect(gateway.visitedCollections, daisthAccountCollections);

    await const FirestoreAccountDataPurger().purge('user-1', gateway);
    expect(gateway.rootDeleteCount, 2);
  });
}

class _FakePurgeGateway implements FirestorePurgeGateway {
  final documents = {
    for (final name in daisthAccountCollections) name: <String>[],
  };
  final batchSizes = <int>[];
  final visitedCollections = <String>[];
  bool rootDeleted = false;
  int rootDeleteCount = 0;

  @override
  Future<List<String>> nextDocumentIds(
    String uid,
    String collection,
    int limit,
  ) async {
    if (!visitedCollections.contains(collection)) {
      visitedCollections.add(collection);
    }
    return documents[collection]!.take(limit).toList();
  }

  @override
  Future<void> deleteDocuments(
    String uid,
    String collection,
    List<String> documentIds,
  ) async {
    batchSizes.add(documentIds.length);
    documents[collection]!.removeWhere(documentIds.toSet().contains);
  }

  @override
  Future<void> deleteUserRoot(String uid) async {
    rootDeleted = true;
    rootDeleteCount++;
  }
}
