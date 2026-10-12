import 'package:flutter/foundation.dart';

import '../../../../core/location/domain/models/location_access_status.dart';
import '../../domain/models/mosque_search_failure.dart';
import '../../domain/models/nearby_mosque_result.dart';
import '../../domain/use_cases/find_nearby_mosques_use_case.dart';

enum MosqueFinderState {
  checking,
  permissionExplanation,
  denied,
  deniedForever,
  serviceDisabled,
  loading,
  results,
  empty,
  locationUnavailable,
  networkError,
  serviceBusy,
}

class MosqueFinderViewModel extends ChangeNotifier {
  MosqueFinderViewModel({required this.findNearbyMosques});

  final FindNearbyMosquesUseCase findNearbyMosques;

  MosqueFinderState state = MosqueFinderState.checking;
  NearbyMosqueResult? result;
  bool _initialized = false;
  bool _operationInProgress = false;

  bool get isBusy => _operationInProgress;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _checkAccess(showExplanationForDenied: true);
  }

  Future<void> requestLocation() async {
    await _checkAccess(
      showExplanationForDenied: false,
      requestPermission: true,
    );
  }

  Future<void> refresh() async {
    await _checkAccess(showExplanationForDenied: false, forceRefresh: true);
  }

  Future<void> onAppResumed() async {
    if (!_initialized || _operationInProgress) return;
    await _checkAccess(showExplanationForDenied: false);
  }

  Future<void> openAppSettings() async {
    await findNearbyMosques.openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await findNearbyMosques.openLocationSettings();
  }

  Future<void> _checkAccess({
    required bool showExplanationForDenied,
    bool requestPermission = false,
    bool forceRefresh = false,
  }) async {
    if (_operationInProgress) return;
    _operationInProgress = true;
    if (state != MosqueFinderState.results &&
        state != MosqueFinderState.empty) {
      state = MosqueFinderState.checking;
    }
    notifyListeners();
    try {
      await _handleAccess(
        requestPermission
            ? await findNearbyMosques.requestLocationAccess()
            : await findNearbyMosques.checkLocationAccess(),
        showExplanationForDenied: showExplanationForDenied,
        forceRefresh: forceRefresh,
      );
    } catch (_) {
      state = MosqueFinderState.denied;
    } finally {
      _operationInProgress = false;
      notifyListeners();
    }
  }

  Future<void> _handleAccess(
    LocationAccessStatus access, {
    bool showExplanationForDenied = false,
    bool forceRefresh = false,
  }) async {
    switch (access) {
      case LocationAccessStatus.granted:
        await _loadResults(forceRefresh: forceRefresh);
      case LocationAccessStatus.denied:
        state = showExplanationForDenied
            ? MosqueFinderState.permissionExplanation
            : MosqueFinderState.denied;
        notifyListeners();
      case LocationAccessStatus.deniedForever:
        state = MosqueFinderState.deniedForever;
        notifyListeners();
      case LocationAccessStatus.serviceDisabled:
        state = MosqueFinderState.serviceDisabled;
        notifyListeners();
    }
  }

  Future<void> _loadResults({bool forceRefresh = false}) async {
    state = MosqueFinderState.loading;
    notifyListeners();
    try {
      result = await findNearbyMosques(forceRefresh: forceRefresh);
      state = result!.places.isEmpty
          ? MosqueFinderState.empty
          : MosqueFinderState.results;
    } on LocationUnavailableFailure {
      state = MosqueFinderState.locationUnavailable;
    } on MosqueSearchFailure catch (failure) {
      state = failure.type == MosqueSearchFailureType.serviceBusy
          ? MosqueFinderState.serviceBusy
          : MosqueFinderState.networkError;
    } catch (_) {
      state = MosqueFinderState.networkError;
    }
    notifyListeners();
  }
}
