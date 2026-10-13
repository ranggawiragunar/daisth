import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/routine_definition.dart';
import '../../domain/repositories/routine_repository.dart';

class RoutineManagementViewModel extends ChangeNotifier {
  RoutineManagementViewModel(this.repository) {
    _subscription = repository.changes.listen((_) => unawaited(refresh()));
  }

  final RoutineRepository repository;
  late final StreamSubscription<void> _subscription;
  List<RoutineDefinition> routines = const [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> initialize() => refresh();

  Future<void> refresh() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      routines = await repository.getAllManagedRoutines();
    } catch (_) {
      errorMessage = 'Rutinitas belum dapat dimuat.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
