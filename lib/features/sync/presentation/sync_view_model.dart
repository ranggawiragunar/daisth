import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/models/sync_entity.dart';
import '../domain/sync_coordinator.dart';

class SyncViewModel extends ChangeNotifier {
  SyncViewModel(this.coordinator) {
    _subscription = coordinator.changes.stream.listen((_) => notifyListeners());
  }

  final SyncCoordinator coordinator;
  late final StreamSubscription<SyncState> _subscription;

  SyncState? get state => coordinator.state;
  SyncStatus get status => coordinator.status;
  Future<void> activate(String uid) => coordinator.activate(uid);
  Future<void> syncNow() => coordinator.syncNow();

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
