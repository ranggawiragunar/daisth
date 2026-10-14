import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/design_system/components/daisth_notice_controller.dart';
import 'package:daisth/core/design_system/theme/daisth_theme.dart';
import 'package:daisth/core/location/domain/models/geo_coordinate.dart';
import 'package:daisth/core/location/domain/models/location_access_status.dart';
import 'package:daisth/core/location/domain/repositories/location_repository.dart';
import 'package:daisth/core/maps/services/map_navigation_service.dart';
import 'package:daisth/features/mosque/domain/models/mosque_place.dart';
import 'package:daisth/features/mosque/domain/models/cached_mosque_places.dart';
import 'package:daisth/features/mosque/domain/models/mosque_place_type.dart';
import 'package:daisth/features/mosque/domain/models/mosque_search_failure.dart';
import 'package:daisth/features/mosque/domain/repositories/mosque_repository.dart';
import 'package:daisth/features/mosque/domain/use_cases/find_nearby_mosques_use_case.dart';
import 'package:daisth/features/mosque/presentation/screens/mosque_finder_screen.dart';
import 'package:daisth/features/mosque/presentation/view_models/mosque_finder_view_model.dart';

void main() {
  testWidgets('renders sorted result and refresh control in dark mode', (
    tester,
  ) async {
    final harness = _Harness(
      access: LocationAccessStatus.granted,
      currentError: StateError('no fresh fix'),
      lastKnown: true,
      places: [_place('Masjid Al Ikhlas', 120)],
    );
    await tester.pumpWidget(harness.app(theme: DaisthTheme.dark));
    await tester.pumpAndSettle();

    expect(find.text('Masjid Al Ikhlas'), findsOneWidget);
    expect(find.textContaining('120 m'), findsOneWidget);
    expect(
      find.text('Menggunakan lokasi terakhir yang tersedia.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Informasi peta'), findsOneWidget);
    expect(find.text('Muat ulang pencarian'), findsOneWidget);
    expect(find.text('OpenStreetMap'), findsNothing);
    final screenSize = tester.getSize(find.byType(Scaffold));
    final refreshButton = tester.getRect(
      find.byKey(const ValueKey('mosque-refresh-button')),
    );
    expect(refreshButton.center.dx, closeTo(screenSize.width / 2, 1));
    expect(refreshButton.width, closeTo(screenSize.width - 40, 1));
    expect(refreshButton.height, closeTo(48, 0.1));
    expect(refreshButton.center.dy, greaterThan(screenSize.height / 2));
    expect(refreshButton.bottom, lessThan(screenSize.height - 8));
    expect(find.textContaining('contributors'), findsNothing);
    expect(find.byKey(const ValueKey('navigation-today')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    harness.dispose();
  });

  testWidgets('OpenStreetMap attribution opens the copyright page', (
    tester,
  ) async {
    Uri? openedUri;
    final harness = _Harness(
      access: LocationAccessStatus.granted,
      places: [_place('Masjid Al Ikhlas', 120)],
      launcher: (uri) async {
        openedUri = uri;
        return true;
      },
    );
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Informasi peta'));
    await tester.pumpAndSettle();

    expect(find.text('Tentang Data Peta'), findsOneWidget);
    expect(find.textContaining('OpenStreetMap'), findsWidgets);
    expect(find.textContaining('Open Database License'), findsOneWidget);
    expect(find.textContaining('contributors'), findsNothing);

    await tester.tap(find.text('OpenStreetMap'));
    await tester.pumpAndSettle();

    expect(openedUri, Uri.https('www.openstreetmap.org', '/copyright'));
    expect(find.text('Tentang Data Peta'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    harness.dispose();
  });

  testWidgets('shows loading and then an empty result state', (tester) async {
    final locationFix = Completer<GeoCoordinate>();
    final harness = _Harness(
      access: LocationAccessStatus.granted,
      currentFuture: locationFix.future,
    );
    await tester.pumpWidget(harness.app());
    await tester.pump();
    expect(find.text('Mencari Masjid & Mushola di sekitar…'), findsOneWidget);

    locationFix.complete(const GeoCoordinate(latitude: -6.2, longitude: 106.8));
    await tester.pumpAndSettle();
    expect(
      find.text('Belum menemukan Masjid atau Mushola di sekitar lokasi ini.'),
      findsOneWidget,
    );
    expect(find.text('Coba lagi'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    harness.dispose();
  });

  testWidgets('keeps current results visible while refresh is running', (
    tester,
  ) async {
    final harness = _Harness(
      access: LocationAccessStatus.granted,
      places: [_place('Masjid Al Ikhlas', 120)],
    );
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    expect(find.text('Masjid Al Ikhlas'), findsOneWidget);

    final pending = Completer<List<MosquePlace>>();
    harness.mosqueRepository.pendingResponse = pending;
    await tester.tap(find.byKey(const ValueKey('mosque-refresh-button')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Masjid Al Ikhlas'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    pending.complete([_place('Masjid Baru', 80)]);
    await tester.pumpAndSettle();
    expect(find.text('Masjid Baru'), findsOneWidget);
    expect(find.text('Masjid Al Ikhlas'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    harness.dispose();
  });

  testWidgets('shows stale cached results and a compact fallback notice', (
    tester,
  ) async {
    final pending = Completer<List<MosquePlace>>();
    final cachedPlace = _place('Masjid tersimpan', 120);
    final harness = _Harness(
      access: LocationAccessStatus.granted,
      cached: CachedMosquePlaces(places: [cachedPlace], isFresh: false),
      pendingResponse: pending,
    );
    await tester.pumpWidget(harness.app());
    await tester.pump();
    await tester.pump();

    expect(find.text('Masjid tersimpan'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      find.text('Menampilkan hasil terakhir sambil memperbarui.'),
      findsOneWidget,
    );

    pending.complete(const []);
    await tester.pumpAndSettle();
    expect(find.text('Masjid tersimpan'), findsOneWidget);
    expect(
      find.text('Menampilkan hasil terakhir. Data terbaru belum tersedia.'),
      findsOneWidget,
    );
    expect(
      find.text('Belum menemukan Masjid atau Mushola di sekitar lokasi ini.'),
      findsNothing,
    );
    expect(
      find.text('Pencarian tempat sholat belum bisa dimuat'),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    harness.dispose();
  });

  testWidgets('shows retryable provider error', (tester) async {
    final harness = _Harness(
      access: LocationAccessStatus.granted,
      repositoryError: const MosqueSearchFailure(
        MosqueSearchFailureType.unavailable,
      ),
    );
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    expect(
      find.text('Pencarian tempat sholat belum bisa dimuat'),
      findsOneWidget,
    );
    expect(
      find.text('Layanan data sedang tidak tersedia. Coba lagi.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    harness.dispose();
  });

  testWidgets(
    'renders persistent denial, denied forever, and service disabled states',
    (tester) async {
      for (final entry in [
        (
          LocationAccessStatus.denied,
          'Lokasi diperlukan untuk mencari tempat terdekat',
        ),
        (LocationAccessStatus.deniedForever, 'Izin lokasi dinonaktifkan'),
        (LocationAccessStatus.serviceDisabled, 'Layanan lokasi tidak aktif'),
      ]) {
        final harness = _Harness(access: entry.$1);
        await tester.pumpWidget(harness.app());
        await tester.pumpAndSettle();
        if (entry.$1 == LocationAccessStatus.denied) {
          expect(find.text('Temukan tempat sholat di dekatmu'), findsOneWidget);
          await harness.viewModel.requestLocation();
          await tester.pumpAndSettle();
        }
        expect(find.text(entry.$2), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        harness.dispose();
      }
    },
  );
}

MosquePlace _place(String name, double distance) => MosquePlace(
  id: name,
  name: name,
  coordinate: const GeoCoordinate(latitude: -6.2, longitude: 106.8),
  distanceMeters: distance,
  type: MosquePlaceType.mosque,
);

class _Harness {
  _Harness({
    required this.access,
    this.currentError,
    this.currentFuture,
    this.lastKnown = false,
    this.places = const [],
    this.repositoryError,
    this.launcher,
    this.cached,
    this.pendingResponse,
  }) : noticeController = DaisthNoticeController() {
    mosqueRepository = _FakeMosques(
      places: places,
      error: repositoryError,
      cached: cached,
    )..pendingResponse = pendingResponse;
    viewModel = MosqueFinderViewModel(
      findNearbyMosques: FindNearbyMosquesUseCase(
        locationRepository: _FakeLocation(
          access: access,
          currentError: currentError,
          currentFuture: currentFuture,
          lastKnown: lastKnown
              ? const GeoCoordinate(latitude: -6.21, longitude: 106.81)
              : null,
        ),
        mosqueRepository: mosqueRepository,
      ),
    );
  }

  final LocationAccessStatus access;
  final Object? currentError;
  final Future<GeoCoordinate>? currentFuture;
  final bool lastKnown;
  final List<MosquePlace> places;
  final Object? repositoryError;
  final ExternalUriLauncher? launcher;
  final CachedMosquePlaces? cached;
  final Completer<List<MosquePlace>>? pendingResponse;
  final DaisthNoticeController noticeController;
  late final _FakeMosques mosqueRepository;
  late final MosqueFinderViewModel viewModel;

  Widget app({ThemeData? theme}) => MaterialApp(
    theme: theme ?? DaisthTheme.light,
    home: DaisthNoticeScope(
      controller: noticeController,
      child: MosqueFinderScreen(
        routineId: 'zuhur',
        viewModel: viewModel,
        navigationService: MapNavigationService(
          launcher: launcher ?? (_) async => true,
        ),
        noticeController: noticeController,
      ),
    ),
  );

  void dispose() => noticeController.dispose();
}

class _FakeLocation implements LocationRepository {
  _FakeLocation({
    required this.access,
    this.currentError,
    this.currentFuture,
    this.lastKnown,
  });

  final LocationAccessStatus access;
  final Object? currentError;
  final Future<GeoCoordinate>? currentFuture;
  final GeoCoordinate? lastKnown;

  @override
  Future<LocationAccessStatus> checkAccess() async => access;
  @override
  Future<LocationAccessStatus> requestAccess() async => access;
  @override
  Future<GeoCoordinate> getCurrentLocation() async {
    if (currentError != null) throw currentError!;
    return currentFuture ??
        const GeoCoordinate(latitude: -6.2, longitude: 106.8);
  }

  @override
  Future<GeoCoordinate?> getLastKnownLocation() async => lastKnown;
  @override
  Future<bool> openAppSettings() async => true;
  @override
  Future<bool> openLocationSettings() async => true;
}

class _FakeMosques implements MosqueRepository {
  _FakeMosques({required this.places, this.error, this.cached});

  final List<MosquePlace> places;
  final Object? error;
  final CachedMosquePlaces? cached;
  Completer<List<MosquePlace>>? pendingResponse;
  CachedMosquePlaces? _storedCache;

  @override
  Future<CachedMosquePlaces?> getCachedNearby({
    required GeoCoordinate origin,
    required int radiusMeters,
  }) async => cached ?? _storedCache;

  @override
  Future<List<MosquePlace>> findNearby({
    required GeoCoordinate origin,
    required int radiusMeters,
    bool bypassCache = false,
  }) async {
    if (error != null) throw error!;
    final results = pendingResponse != null
        ? await pendingResponse!.future
        : places;
    if (results.isNotEmpty) {
      _storedCache = CachedMosquePlaces(places: results, isFresh: true);
    }
    return results;
  }
}
