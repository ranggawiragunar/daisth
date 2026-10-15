import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../core/design_system/assets/daisth_assets.dart';
import '../../../../core/design_system/components/daisth_feature_visual.dart';
import '../../../../core/design_system/components/daisth_notice.dart';
import '../../../../core/design_system/components/daisth_notice_controller.dart';
import '../../../../core/design_system/components/daisth_surface.dart';
import '../../../../core/design_system/tokens/daisth_spacing.dart';
import '../../../../core/design_system/tokens/daisth_radius.dart';
import '../../../../core/maps/services/map_navigation_service.dart';
import '../../../../core/localization/daisth_terminology.dart';
import '../../../../core/localization/daisth_localizations.dart';
import '../../domain/models/mosque_place.dart';
import '../../domain/models/mosque_place_type.dart';
import '../../domain/models/nearby_mosque_result.dart';
import '../view_models/mosque_finder_view_model.dart';

class MosqueFinderScreen extends StatefulWidget {
  const MosqueFinderScreen({
    required this.routineId,
    required this.viewModel,
    required this.navigationService,
    required this.noticeController,
    super.key,
  });

  final String routineId;
  final MosqueFinderViewModel viewModel;
  final MapNavigationService navigationService;
  final DaisthNoticeController noticeController;

  @override
  State<MosqueFinderScreen> createState() => _MosqueFinderScreenState();
}

class _MosqueFinderScreenState extends State<MosqueFinderScreen>
    with WidgetsBindingObserver {
  MosqueFinderViewModel get _model => widget.viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _model.addListener(_onChanged);
    _model.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _model.removeListener(_onChanged);
    _model.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _model.onAppResumed();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openDirections(MosquePlace place) async {
    var opened = false;
    try {
      opened = await widget.navigationService.openWalkingDirections(place);
    } catch (_) {
      opened = false;
    }
    if (!mounted || opened) return;
    widget.noticeController.show(
      context,
      type: DaisthNoticeType.error,
      title: DaisthLocalizations.text(
        context,
        id: 'Tidak dapat membuka navigasi',
        en: 'Could not open navigation',
      ),
    );
  }

  Future<void> _openAttribution() async {
    var opened = false;
    try {
      opened = await widget.navigationService.openOpenStreetMapCopyright();
    } catch (_) {
      opened = false;
    }
    if (!mounted || opened) return;
    widget.noticeController.show(
      context,
      type: DaisthNoticeType.info,
      title: DaisthLocalizations.text(
        context,
        id: 'Tidak dapat membuka informasi OpenStreetMap',
        en: 'Could not open OpenStreetMap information',
      ),
    );
  }

  void _showMapInformation() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              DaisthLocalizations.text(
                context,
                id: 'Tentang Data Peta',
                en: 'About map data',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              DaisthLocalizations.text(
                context,
                id: 'Informasi lokasi Masjid dan Mushola diambil dari OpenStreetMap, peta kolaboratif yang dibuat dan diperbarui oleh komunitas. Datanya tersedia di bawah lisensi Open Database License (ODbL).',
                en: 'Location information for Masjid and Mushola comes from OpenStreetMap, a collaborative map created and maintained by its community. Data is available under the Open Database License (ODbL).',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _openAttribution();
                },
                icon: const Icon(PhosphorIconsRegular.arrowSquareOut),
                label: const Text('OpenStreetMap'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final places = _model.result?.places ?? const <MosquePlace>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          DaisthTerminology.nearbyPrayerPlacesTitle(
            Localizations.localeOf(context),
          ),
          style: theme.textTheme.titleMedium,
        ),
        actions: [
          IconButton(
            tooltip: DaisthLocalizations.text(
              context,
              id: 'Informasi peta',
              en: 'Map information',
            ),
            onPressed: _showMapInformation,
            icon: const Icon(PhosphorIconsRegular.info),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          _model.state == MosqueFinderState.results && !_model.isBusy
          ? SizedBox(
              width: MediaQuery.sizeOf(context).width - 40,
              height: 48,
              child: FilledButton.icon(
                key: const ValueKey('mosque-refresh-button'),
                onPressed: _model.refresh,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size.fromHeight(48),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.onPrimary.withValues(
                        alpha: 0.18,
                      ),
                    ),
                  ),
                ),
                icon: const Icon(PhosphorIconsRegular.arrowClockwise, size: 18),
                label: Text(
                  DaisthLocalizations.text(
                    context,
                    id: 'Muat ulang pencarian',
                    en: 'Refresh search',
                  ),
                ),
              ),
            )
          : null,
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _buildState(theme, places),
        ),
      ),
    );
  }

  Widget _buildState(ThemeData theme, List<MosquePlace> places) {
    return switch (_model.state) {
      MosqueFinderState.checking => _LoadingState(
        key: ValueKey('checking'),
        message: DaisthLocalizations.text(
          context,
          id: 'Memeriksa akses lokasi…',
          en: 'Checking location access…',
        ),
      ),
      MosqueFinderState.permissionExplanation => _PermissionState(
        key: const ValueKey('permission-explanation'),
        title: DaisthLocalizations.text(
          context,
          id: 'Temukan tempat sholat di dekatmu',
          en: 'Find a place to pray nearby',
        ),
        message: DaisthLocalizations.text(
          context,
          id: 'Lokasi digunakan saat kamu membuka pencarian ini dan tidak disimpan dalam riwayat ibadah.',
          en: 'Your location is used while this search is open and is not saved in your worship history.',
        ),
        action: DaisthLocalizations.text(
          context,
          id: 'Gunakan lokasi saya',
          en: 'Use my location',
        ),
        onPressed: _model.requestLocation,
      ),
      MosqueFinderState.denied => _PermissionState(
        key: const ValueKey('denied'),
        title: DaisthLocalizations.text(
          context,
          id: 'Lokasi diperlukan untuk mencari tempat terdekat',
          en: 'Location is needed to find nearby places',
        ),
        message: DaisthLocalizations.text(
          context,
          id: 'Izinkan akses lokasi saat menggunakan aplikasi untuk mencari Masjid dan Mushola.',
          en: 'Allow location access while using the app to find nearby Masjid and Mushola.',
        ),
        action: DaisthLocalizations.text(
          context,
          id: 'Coba lagi',
          en: 'Try again',
        ),
        onPressed: _model.requestLocation,
      ),
      MosqueFinderState.deniedForever => _PermissionState(
        key: const ValueKey('denied-forever'),
        title: DaisthLocalizations.text(
          context,
          id: 'Izin lokasi dinonaktifkan',
          en: 'Location permission is off',
        ),
        message: DaisthLocalizations.text(
          context,
          id: 'Aktifkan izin lokasi Daisth melalui pengaturan perangkat.',
          en: 'Enable Daisth location access in your device settings.',
        ),
        action: DaisthLocalizations.text(
          context,
          id: 'Buka Pengaturan',
          en: 'Open Settings',
        ),
        onPressed: _model.openAppSettings,
      ),
      MosqueFinderState.serviceDisabled => _PermissionState(
        key: const ValueKey('service-disabled'),
        title: DaisthLocalizations.text(
          context,
          id: 'Layanan lokasi tidak aktif',
          en: 'Location services are off',
        ),
        message: DaisthLocalizations.text(
          context,
          id: 'Aktifkan layanan lokasi perangkat untuk mencari tempat terdekat.',
          en: 'Turn on device location services to find nearby places.',
        ),
        action: DaisthLocalizations.text(
          context,
          id: 'Buka Pengaturan Lokasi',
          en: 'Open Location Settings',
        ),
        onPressed: _model.openLocationSettings,
      ),
      MosqueFinderState.loading =>
        _model.result == null
            ? _LoadingState(
                key: ValueKey('loading'),
                message: DaisthLocalizations.text(
                  context,
                  id: 'Mencari Masjid & Mushola di sekitar…',
                  en: 'Searching for nearby Masjid & Mushola…',
                ),
              )
            : _model.result!.places.isEmpty
            ? _RetryState(
                key: const ValueKey('empty'),
                title: DaisthLocalizations.text(
                  context,
                  id: 'Belum menemukan Masjid atau Mushola di sekitar lokasi ini.',
                  en: 'No Masjid or Mushola found near this location.',
                ),
                message: DaisthLocalizations.text(
                  context,
                  id: 'Pencarian mencakup area hingga 5 km.',
                  en: 'Search covers an area up to 5 km.',
                ),
                onRetry: _model.refresh,
              )
            : _ResultsState(
                key: const ValueKey('results'),
                result: _model.result!,
                isRefreshing: true,
                onNavigate: _openDirections,
              ),
      MosqueFinderState.locationUnavailable => _RetryState(
        key: const ValueKey('location-unavailable'),
        title: DaisthLocalizations.text(
          context,
          id: 'Lokasi belum tersedia',
          en: 'Location is unavailable',
        ),
        message: DaisthLocalizations.text(
          context,
          id: 'Periksa layanan lokasi lalu coba lagi.',
          en: 'Check location services and try again.',
        ),
        onRetry: _model.refresh,
      ),
      MosqueFinderState.networkError => _RetryState(
        key: const ValueKey('network-error'),
        title: DaisthLocalizations.text(
          context,
          id: 'Pencarian tempat sholat belum bisa dimuat',
          en: 'Nearby search could not load',
        ),
        message: DaisthLocalizations.text(
          context,
          id: 'Layanan data sedang tidak tersedia. Coba lagi.',
          en: 'The data service is unavailable. Try again.',
        ),
        onRetry: _model.refresh,
      ),
      MosqueFinderState.serviceBusy => _RetryState(
        key: const ValueKey('service-busy'),
        title: DaisthLocalizations.text(
          context,
          id: 'Layanan pencarian sedang sibuk',
          en: 'Search service is busy',
        ),
        message: DaisthLocalizations.text(
          context,
          id: 'Layanan data sedang sibuk. Coba lagi.',
          en: 'The data service is busy. Try again.',
        ),
        onRetry: _model.refresh,
      ),
      MosqueFinderState.empty => _RetryState(
        key: const ValueKey('empty'),
        title: DaisthLocalizations.text(
          context,
          id: 'Belum menemukan Masjid atau Mushola di sekitar lokasi ini.',
          en: 'No Masjid or Mushola found near this location.',
        ),
        message: DaisthLocalizations.text(
          context,
          id: 'Pencarian mencakup area hingga 5 km.',
          en: 'Search covers an area up to 5 km.',
        ),
        onRetry: _model.refresh,
      ),
      MosqueFinderState.results => _ResultsState(
        key: const ValueKey('results'),
        result: _model.result!,
        onNavigate: _openDirections,
      ),
    };
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(DaisthSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: DaisthSpacing.lg),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _PermissionState extends StatelessWidget {
  const _PermissionState({
    required this.title,
    required this.message,
    required this.action,
    required this.onPressed,
    super.key,
  });

  final String title;
  final String message;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        DaisthSpacing.xl,
        DaisthSpacing.xl,
        DaisthSpacing.xl,
        104,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DaisthFeatureVisual(
              asset: DaisthAssets.noLocation,
              width: 148,
              height: 148,
            ),
            const SizedBox(height: DaisthSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: DaisthSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DaisthSpacing.xl),
            FilledButton(onPressed: onPressed, child: Text(action)),
          ],
        ),
      ),
    ),
  );
}

class _RetryState extends StatelessWidget {
  const _RetryState({
    required this.title,
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(DaisthSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DaisthFeatureVisual(
              asset: DaisthAssets.genericError,
              height: 104,
            ),
            const SizedBox(height: DaisthSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: DaisthSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: DaisthSpacing.lg),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(PhosphorIconsRegular.arrowClockwise),
              label: Text(
                DaisthLocalizations.text(
                  context,
                  id: 'Coba lagi',
                  en: 'Try again',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ResultsState extends StatelessWidget {
  const _ResultsState({
    required this.result,
    required this.onNavigate,
    this.isRefreshing = false,
    super.key,
  });

  final NearbyMosqueResult result;
  final ValueChanged<MosquePlace> onNavigate;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final places = result.places;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DaisthSpacing.screenHorizontal,
        DaisthSpacing.md,
        DaisthSpacing.screenHorizontal,
        104,
      ),
      children: [
        const Align(
          alignment: Alignment.centerRight,
          child: DaisthFeatureVisual(
            asset: DaisthAssets.mosqueFinderHeader,
            height: 64,
          ),
        ),
        if (isRefreshing) ...[
          LinearProgressIndicator(
            minHeight: 2,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          ),
          const SizedBox(height: DaisthSpacing.sm),
        ],
        if (result.isUsingCachedResults) ...[
          _CachedResultsNotice(isRefreshing: isRefreshing),
          const SizedBox(height: DaisthSpacing.md),
        ],
        if (result.usedLastKnownLocation) ...[
          const _LastKnownNotice(),
          const SizedBox(height: DaisthSpacing.md),
        ],
        Text(
          DaisthLocalizations.text(context, id: 'Terdekat', en: 'Nearest'),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DaisthSpacing.sm),
        _NearestMosqueCard(place: places.first, onNavigate: onNavigate),
        if (places.length > 1) ...[
          const SizedBox(height: DaisthSpacing.xl),
          Text(
            DaisthLocalizations.text(
              context,
              id: 'Tempat lainnya',
              en: 'More places',
            ),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: DaisthSpacing.sm),
          DaisthSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 1; index < places.length; index++) ...[
                  _MosqueResultTile(
                    place: places[index],
                    onTap: () => onNavigate(places[index]),
                  ),
                  if (index < places.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: DaisthSpacing.md),
        Text(
          DaisthLocalizations.text(
            context,
            id: 'Pencarian hingga ${_formatDistance(result.searchedRadiusMeters)}',
            en: 'Search radius up to ${_formatDistance(result.searchedRadiusMeters)}',
          ),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CachedResultsNotice extends StatelessWidget {
  const _CachedResultsNotice({required this.isRefreshing});

  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DaisthSpacing.md,
        vertical: DaisthSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.55,
        ),
        borderRadius: BorderRadius.circular(DaisthRadius.medium),
      ),
      child: Row(
        children: [
          Icon(
            isRefreshing
                ? PhosphorIconsRegular.arrowsClockwise
                : PhosphorIconsRegular.clockCounterClockwise,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: DaisthSpacing.sm),
          Expanded(
            child: Text(
              isRefreshing
                  ? DaisthLocalizations.text(
                      context,
                      id: 'Menampilkan hasil terakhir sambil memperbarui.',
                      en: 'Showing previous results while refreshing.',
                    )
                  : DaisthLocalizations.text(
                      context,
                      id: 'Menampilkan hasil terakhir. Data terbaru belum tersedia.',
                      en: 'Showing previous results. New data is not available yet.',
                    ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LastKnownNotice extends StatelessWidget {
  const _LastKnownNotice();

  @override
  Widget build(BuildContext context) => DaisthSurface(
    style: DaisthSurfaceStyle.softPrimary,
    padding: const EdgeInsets.symmetric(
      horizontal: DaisthSpacing.md,
      vertical: DaisthSpacing.sm,
    ),
    child: Row(
      children: [
        Icon(
          PhosphorIconsRegular.info,
          color: Theme.of(context).colorScheme.primary,
          size: 18,
        ),
        const SizedBox(width: DaisthSpacing.sm),
        Expanded(
          child: Text(
            DaisthLocalizations.text(
              context,
              id: 'Menggunakan lokasi terakhir yang tersedia.',
              en: 'Using the last available location.',
            ),
          ),
        ),
      ],
    ),
  );
}

class _NearestMosqueCard extends StatelessWidget {
  const _NearestMosqueCard({required this.place, required this.onNavigate});

  final MosquePlace place;
  final ValueChanged<MosquePlace> onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DaisthSurface(
      style: DaisthSurfaceStyle.warm,
      padding: const EdgeInsets.all(DaisthSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                PhosphorIconsRegular.mosque,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: DaisthSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: DaisthSpacing.xxs),
                    Text(
                      '${_typeLabel(context, place.type)} · ${_formatDistance(place.distanceMeters)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (place.shortAddress != null) ...[
                      const SizedBox(height: DaisthSpacing.xs),
                      Text(
                        place.shortAddress!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DaisthSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => onNavigate(place),
              icon: const Icon(PhosphorIconsRegular.personSimpleWalk),
              label: Text(
                DaisthLocalizations.text(
                  context,
                  id: 'Navigasi',
                  en: 'Navigate',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MosqueResultTile extends StatelessWidget {
  const _MosqueResultTile({required this.place, required this.onTap});

  final MosquePlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      title: Text(place.name, style: theme.textTheme.bodyLarge),
      subtitle: Text(
        [
          _typeLabel(context, place.type),
          if (place.shortAddress != null) place.shortAddress!,
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDistance(place.distanceMeters),
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(width: 6),
          const Icon(PhosphorIconsRegular.caretRight),
        ],
      ),
    );
  }
}

String _typeLabel(BuildContext context, MosquePlaceType type) => switch (type) {
  MosquePlaceType.mosque => 'Masjid',
  MosquePlaceType.musalla => 'Mushola',
  MosquePlaceType.unknown => DaisthLocalizations.text(
    context,
    id: 'Tempat sholat',
    en: 'Prayer place',
  ),
};

String _formatDistance(num meters) => meters < 1000
    ? '${meters.round()} m'
    : '${(meters / 1000).toStringAsFixed(1)} km';
