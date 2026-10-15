import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../core/design_system/tokens/daisth_radius.dart';
import '../../../../core/maps/daisth_map_config.dart';
import '../../../../core/localization/daisth_localizations.dart';
import '../../domain/models/mosque_place.dart';
import '../../domain/models/nearby_mosque_result.dart';
import 'mosque_map_coordinate_mapper.dart';
import 'mosque_map_marker.dart';

typedef MosqueMapRendererBuilder =
    Widget Function(BuildContext context, MosqueMapRenderRequest request);

class MosqueMapRenderRequest {
  const MosqueMapRenderRequest({
    required this.result,
    required this.selectedPlaceId,
    required this.onStyleLoaded,
    required this.onStyleFailure,
    required this.onMarkerTapped,
  });

  final NearbyMosqueResult result;
  final String? selectedPlaceId;
  final VoidCallback onStyleLoaded;
  final VoidCallback onStyleFailure;
  final ValueChanged<String> onMarkerTapped;
}

class MosqueMapPanel extends StatefulWidget {
  const MosqueMapPanel({
    required this.result,
    required this.selectedPlaceId,
    required this.onPlaceSelected,
    this.rendererBuilder,
    this.styleLoadTimeout = DaisthMapConfig.styleLoadTimeout,
    super.key,
  });

  final NearbyMosqueResult result;
  final String? selectedPlaceId;
  final ValueChanged<String> onPlaceSelected;
  final MosqueMapRendererBuilder? rendererBuilder;
  final Duration styleLoadTimeout;

  @override
  State<MosqueMapPanel> createState() => _MosqueMapPanelState();
}

enum _MapStatus { loading, ready, failed }

class _MosqueMapPanelState extends State<MosqueMapPanel> {
  Timer? _styleTimer;
  _MapStatus _status = _MapStatus.loading;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _startStyleTimer();
  }

  @override
  void dispose() {
    _styleTimer?.cancel();
    super.dispose();
  }

  void _startStyleTimer() {
    _styleTimer?.cancel();
    _styleTimer = Timer(widget.styleLoadTimeout, _setFailed);
  }

  void _setReady() {
    if (!mounted || _status == _MapStatus.ready) return;
    _styleTimer?.cancel();
    setState(() => _status = _MapStatus.ready);
  }

  void _setFailed() {
    if (!mounted || _status == _MapStatus.failed) return;
    _styleTimer?.cancel();
    setState(() => _status = _MapStatus.failed);
  }

  void _retry() {
    setState(() {
      _attempt++;
      _status = _MapStatus.loading;
    });
    _startStyleTimer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final request = MosqueMapRenderRequest(
      result: widget.result,
      selectedPlaceId: widget.selectedPlaceId,
      onStyleLoaded: _setReady,
      onStyleFailure: _setFailed,
      onMarkerTapped: widget.onPlaceSelected,
    );
    final renderer =
        widget.rendererBuilder?.call(context, request) ??
        _MapLibreMosqueRenderer(
          key: ValueKey('map-attempt-$_attempt'),
          request: request,
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(DaisthRadius.large),
      child: SizedBox(
        height: 236,
        child: ColoredBox(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_status != _MapStatus.failed) renderer,
              if (_status == _MapStatus.loading)
                const Center(
                  child: SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                ),
              if (_status == _MapStatus.failed)
                _MapFailureState(onRetry: _retry),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapFailureState extends StatelessWidget {
  const _MapFailureState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                DaisthLocalizations.text(
                  context,
                  id: 'Peta belum bisa dimuat',
                  en: 'Map could not be loaded',
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                DaisthLocalizations.text(
                  context,
                  id: 'Daftar tempat tetap tersedia. Coba muat peta lagi.',
                  en: 'The place list is still available. Try loading the map again.',
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(
                  DaisthLocalizations.text(
                    context,
                    id: 'Coba lagi',
                    en: 'Retry map',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapLibreMosqueRenderer extends StatefulWidget {
  const _MapLibreMosqueRenderer({required this.request, super.key});

  final MosqueMapRenderRequest request;

  @override
  State<_MapLibreMosqueRenderer> createState() =>
      _MapLibreMosqueRendererState();
}

class _MapLibreMosqueRendererState extends State<_MapLibreMosqueRenderer> {
  MapLibreMapController? _controller;
  bool _styleReady = false;
  bool _syncInProgress = false;
  int _markerRevision = 0;
  Brightness? _lastBrightness;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    if (_lastBrightness != null &&
        _lastBrightness != brightness &&
        _styleReady) {
      _styleReady = false;
      _markerRevision++;
    }
    _lastBrightness = brightness;
  }

  @override
  void didUpdateWidget(covariant _MapLibreMosqueRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_styleReady &&
        (oldWidget.request.result != widget.request.result ||
            oldWidget.request.selectedPlaceId !=
                widget.request.selectedPlaceId)) {
      _markerRevision++;
      _syncMarkers();
    }
  }

  @override
  void dispose() {
    _detachController(_controller);
    _controller = null;
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _detachController(_controller);
    _controller = controller;
    _styleReady = false;
    _markerRevision++;
    controller.onCircleTapped.add(_onCircleTapped);
  }

  void _detachController(MapLibreMapController? controller) {
    controller?.onCircleTapped.remove(_onCircleTapped);
  }

  void _onCircleTapped(Circle circle) {
    final markerId = circle.data?['markerId'];
    if (markerId is! String || markerId == MosqueMapMarker.currentLocationId) {
      return;
    }
    final place = _placeById(markerId);
    if (place == null) return;
    final controller = _controller;
    if (controller != null && !controller.isDisposed) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          MosqueMapCoordinateMapper.toMapLibre(place.coordinate),
          DaisthMapConfig.selectedPlaceZoom,
        ),
        duration: const Duration(milliseconds: 350),
      );
    }
    widget.request.onMarkerTapped(place.id);
  }

  MosquePlace? _placeById(String id) {
    for (final place in widget.request.result.places) {
      if (place.id == id) return place;
    }
    return null;
  }

  Future<void> _onStyleLoaded() async {
    _styleReady = true;
    _markerRevision++;
    await _syncMarkers();
  }

  Future<void> _syncMarkers() async {
    final controller = _controller;
    if (!_styleReady ||
        controller == null ||
        controller.isDisposed ||
        _syncInProgress) {
      return;
    }
    _syncInProgress = true;
    final initialRevision = _markerRevision;
    try {
      while (mounted &&
          _styleReady &&
          identical(controller, _controller) &&
          !controller.isDisposed) {
        final revision = _markerRevision;
        await controller.clearCircles();
        if (!mounted ||
            !identical(controller, _controller) ||
            controller.isDisposed ||
            revision != _markerRevision) {
          continue;
        }
        final markers = MosqueMapMarker.fromResult(widget.request.result);
        final scheme = Theme.of(context).colorScheme;
        final options = markers
            .map((marker) {
              final selected = marker.id == widget.request.selectedPlaceId;
              final color = switch (marker.kind) {
                MosqueMapMarkerKind.currentLocation => scheme.primary,
                MosqueMapMarkerKind.mosque => scheme.secondary,
                MosqueMapMarkerKind.mushola => scheme.tertiary,
                MosqueMapMarkerKind.other => scheme.onSurfaceVariant,
              };
              return CircleOptions(
                geometry: MosqueMapCoordinateMapper.toMapLibre(
                  marker.coordinate,
                ),
                circleRadius: marker.isCurrentLocation
                    ? 7
                    : selected
                    ? 10
                    : 8,
                circleColor: _toMapColor(color),
                circleOpacity: marker.isCurrentLocation ? 0.92 : 0.98,
                circleStrokeColor: _toMapColor(scheme.surface),
                circleStrokeWidth: marker.isCurrentLocation ? 3 : 2,
              );
            })
            .toList(growable: false);
        final data = markers
            .map(
              (marker) => <String, dynamic>{
                'markerId': marker.id,
                'kind': marker.kind.name,
              },
            )
            .toList(growable: false);
        await controller.addCircles(options, data);
        if (!mounted ||
            !identical(controller, _controller) ||
            controller.isDisposed) {
          return;
        }
        if (revision != _markerRevision) continue;
        widget.request.onStyleLoaded();
        return;
      }
    } catch (_) {
      if (mounted && identical(controller, _controller)) {
        widget.request.onStyleFailure();
      }
    } finally {
      _syncInProgress = false;
      if (mounted &&
          _styleReady &&
          (_markerRevision != initialRevision ||
              !identical(controller, _controller))) {
        unawaited(_syncMarkers());
      }
    }
  }

  String _toMapColor(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MapLibreMap(
      initialCameraPosition: CameraPosition(
        target: MosqueMapCoordinateMapper.toMapLibre(
          widget.request.result.origin,
        ),
        zoom: DaisthMapConfig.initialZoom,
      ),
      styleString: DaisthMapConfig.styleUrlFor(isDark: isDark),
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: _onStyleLoaded,
      myLocationEnabled: false,
      compassEnabled: false,
      attributionButtonPosition: AttributionButtonPosition.bottomRight,
      attributionButtonMargins: const Point<num>(12, 12),
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
    );
  }
}
