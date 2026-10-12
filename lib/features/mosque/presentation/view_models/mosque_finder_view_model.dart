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
  bool _requestInProgress = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _checkAccess(showExplanationForDenied: true);
  }

  Future<void> requestLocation() async {
    if (_requestInProgress) return;
    _requestInProgress = true;
    state = MosqueFinderState.checking;
    notifyListeners();
    try {
      await _handleAccess(await findNearbyMosques.requestLocationAccess());
    } catch (_) {
      state = MosqueFinderState.denied;
      notifyListeners();
    } finally {
      _requestInProgress = false;
    }
  }

  Future<void> refresh() async {
    await _checkAccess(showExplanationForDenied: false);
  }

  Future<void> onAppResumed() async {
    if (!_initialized || _requestInProgress) return;
    await _checkAccess(showExplanationForDenied: false);
  }

  Future<void> openAppSettings() async {
    await findNearbyMosques.openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await findNearbyMosques.openLocationSettings();
  }

  Future<void> _checkAccess({required bool showExplanationForDenied}) async {
    try {
      await _handleAccess(
        await findNearbyMosques.checkLocationAccess(),
        showExplanationForDenied: showExplanationForDenied,
      );
    } catch (_) {
      state = MosqueFinderState.denied;
      notifyListeners();
    }
  }

  Future<void> _handleAccess(
    LocationAccessStatus access, {
    bool showExplanationForDenied = false,
  }) async {
    switch (access) {
      case LocationAccessStatus.granted:
        await _loadResults();
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

  Future<void> _loadResults() async {
    state = MosqueFinderState.loading;
    notifyListeners();
    try {
      result = await findNearbyMosques();
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
