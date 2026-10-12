import 'package:flutter_test/flutter_test.dart';
import 'package:istiqam/core/location/domain/models/geo_coordinate.dart';
import 'package:istiqam/core/location/domain/models/location_access_status.dart';
import 'package:istiqam/core/location/domain/repositories/location_repository.dart';
import 'package:istiqam/features/mosque/domain/models/mosque_place.dart';
import 'package:istiqam/features/mosque/domain/repositories/mosque_repository.dart';
import 'package:istiqam/features/mosque/domain/use_cases/find_nearby_mosques_use_case.dart';
import 'package:istiqam/features/mosque/presentation/view_models/mosque_finder_view_model.dart';

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
}

MosqueFinderViewModel _viewModel(_Location location) => MosqueFinderViewModel(
  findNearbyMosques: FindNearbyMosquesUseCase(
    locationRepository: location,
    mosqueRepository: _Mosques(),
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
  @override
  Future<List<MosquePlace>> findNearby({
    required GeoCoordinate origin,
    required int radiusMeters,
  }) async => const [];
}
