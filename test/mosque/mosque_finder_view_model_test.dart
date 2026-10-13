import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/location/domain/models/geo_coordinate.dart';
import 'package:daisth/core/location/domain/models/location_access_status.dart';
import 'package:daisth/core/location/domain/repositories/location_repository.dart';
import 'package:daisth/features/mosque/domain/models/mosque_place.dart';
import 'package:daisth/features/mosque/domain/models/mosque_place_type.dart';
import 'package:daisth/features/mosque/domain/models/cached_mosque_places.dart';
import 'package:daisth/features/mosque/domain/models/mosque_search_failure.dart';
import 'package:daisth/features/mosque/domain/repositories/mosque_repository.dart';
import 'package:daisth/features/mosque/domain/use_cases/find_nearby_mosques_use_case.dart';
import 'package:daisth/features/mosque/presentation/view_models/mosque_finder_view_model.dart';

void main() {
  test(
    'shows rationale before requesting initially denied permission',
    () async {
      final location = _Location(LocationAccessStatus.denied);
      final viewModel = _viewModel(location);
      addTearDown(viewModel.dispose);

      await viewModel.initialize();
      expect(viewModel.state, MosqueFinderState.permissionExplanation);
      expect(location.requestCount, 0);

      await viewModel.requestLocation();
      expect(location.requestCount, 1);
      expect(viewModel.state, MosqueFinderState.denied);
    },
  );

  test(
    'keeps denied forever and disabled location as distinct states',
    () async {
      final permanentlyDenied = _viewModel(
        _Location(LocationAccessStatus.deniedForever),
      );
      await permanentlyDenied.initialize();
      expect(permanentlyDenied.state, MosqueFinderState.deniedForever);
      permanentlyDenied.dispose();

      final disabled = _viewModel(
        _Location(LocationAccessStatus.serviceDisabled),
      );
      await disabled.initialize();
      expect(disabled.state, MosqueFinderState.serviceDisabled);
      disabled.dispose();
    },
  );

  test(
    'keeps successful empty search distinct from provider failure',
    () async {
      final emptyMosques = _Mosques();
      final empty = _viewModel(
        _Location(LocationAccessStatus.granted),
        emptyMosques,
      );
      await empty.initialize();
      expect(empty.state, MosqueFinderState.empty);
      empty.dispose();

      final failed = _viewModel(
        _Location(LocationAccessStatus.granted),
        _Mosques(
          error: const MosqueSearchFailure(MosqueSearchFailureType.unavailable),
        ),
      );
      await failed.initialize();
      expect(failed.state, MosqueFinderState.networkError);
      failed.dispose();
    },
  );

  test('ignores repeated refresh while a provider request is active', () async {
    final mosque = _Mosques();
    final viewModel = _viewModel(
      _Location(LocationAccessStatus.granted),
      mosque,
    );
    await viewModel.initialize();
    expect(mosque.radiusRequests, [5000]);

    final pending = Completer<List<MosquePlace>>();
    mosque.pendingResponse = pending;
    final refresh = viewModel.refresh();
    await Future<void>.delayed(Duration.zero);
    await viewModel.refresh();
    await viewModel.refresh();

    expect(viewModel.isBusy, isTrue);
    expect(mosque.radiusRequests, [5000, 5000]);
    expect(mosque.bypassCacheCalls, [false, true]);

    pending.complete(const []);
    await refresh;
    expect(viewModel.isBusy, isFalse);
    viewModel.dispose();
  });

  test(
    'keeps same-area cached results visible during an empty refresh',
    () async {
      final cachedPlace = MosquePlace(
        id: 'cached',
        name: 'Cached mosque',
        coordinate: const GeoCoordinate(latitude: 0, longitude: 0),
        distanceMeters: 100,
        type: MosquePlaceType.mosque,
      );
      final mosque = _Mosques(
        cached: CachedMosquePlaces(places: [cachedPlace], isFresh: false),
      );
      final pending = Completer<List<MosquePlace>>();
      mosque.pendingResponse = pending;
      final viewModel = _viewModel(
        _Location(LocationAccessStatus.granted),
        mosque,
      );
      addTearDown(viewModel.dispose);

      final loading = viewModel.initialize();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.state, MosqueFinderState.loading);
      expect(viewModel.result?.places.single.id, 'cached');
      expect(viewModel.result?.isUsingCachedResults, isTrue);

      pending.complete(const []);
      await loading;

      expect(viewModel.state, MosqueFinderState.results);
      expect(viewModel.result?.places.single.id, 'cached');
      expect(viewModel.result?.isUsingCachedResults, isTrue);
    },
  );
}

MosqueFinderViewModel _viewModel(_Location location, [_Mosques? mosque]) =>
    MosqueFinderViewModel(
      findNearbyMosques: FindNearbyMosquesUseCase(
        locationRepository: location,
        mosqueRepository: mosque ?? _Mosques(),
      ),
    );

class _Location implements LocationRepository {
  _Location(this.status);

  final LocationAccessStatus status;
  int requestCount = 0;

  @override
  Future<LocationAccessStatus> checkAccess() async => status;
  @override
  Future<LocationAccessStatus> requestAccess() async {
    requestCount++;
    return status;
  }

  @override
  Future<GeoCoordinate> getCurrentLocation() async =>
      const GeoCoordinate(latitude: 0, longitude: 0);
  @override
  Future<GeoCoordinate?> getLastKnownLocation() async => null;
  @override
  Future<bool> openAppSettings() async => true;
  @override
  Future<bool> openLocationSettings() async => true;
}

class _Mosques implements MosqueRepository {
  _Mosques({this.error, this.cached});

  final Object? error;
  final CachedMosquePlaces? cached;
  final radiusRequests = <int>[];
  final bypassCacheCalls = <bool>[];
  Completer<List<MosquePlace>>? pendingResponse;

  @override
  Future<CachedMosquePlaces?> getCachedNearby({
    required GeoCoordinate origin,
    required int radiusMeters,
  }) async => cached;

  @override
  Future<List<MosquePlace>> findNearby({
    required GeoCoordinate origin,
    required int radiusMeters,
    bool bypassCache = false,
  }) async {
    radiusRequests.add(radiusMeters);
    bypassCacheCalls.add(bypassCache);
    if (error != null) throw error!;
    if (pendingResponse != null) return pendingResponse!.future;
    return const [];
  }
}
