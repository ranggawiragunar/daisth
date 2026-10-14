import 'package:flutter/material.dart';

import '../../../../core/design_system/components/daisth_notice.dart';
import '../../../../core/design_system/components/daisth_notice_controller.dart';
import '../../../../core/design_system/components/daisth_surface.dart';
import '../../../../core/design_system/tokens/daisth_spacing.dart';
import '../../../../core/design_system/tokens/daisth_radius.dart';
import '../../../../core/maps/services/map_navigation_service.dart';
import '../../../../core/localization/daisth_terminology.dart';
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
      title: 'Tidak dapat membuka navigasi',
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
      title: 'Tidak dapat membuka informasi OpenStreetMap',
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
              'Tentang Data Peta',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Informasi lokasi Masjid dan Mushola diambil dari OpenStreetMap, '
              'peta kolaboratif yang dibuat dan diperbarui oleh komunitas. '
              'Datanya tersedia di bawah lisensi Open Database License (ODbL).',
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
                icon: const Icon(Icons.open_in_new_rounded),
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
            tooltip: 'Informasi peta',
            onPressed: _showMapInformation,
            icon: const Icon(Icons.info_outline_rounded),
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
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Muat ulang pencarian'),
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
      MosqueFinderState.checking => const _LoadingState(
        key: ValueKey('checking'),
        message: 'Memeriksa akses lokasi…',
      ),
      MosqueFinderState.permissionExplanation => _PermissionState(
        key: const ValueKey('permission-explanation'),
        title: 'Temukan tempat sholat di dekatmu',
        message:
            'Lokasi digunakan saat kamu membuka pencarian ini dan tidak disimpan dalam riwayat ibadah.',
        action: 'Gunakan lokasi saya',
        onPressed: _model.requestLocation,
      ),
      MosqueFinderState.denied => _PermissionState(
        key: const ValueKey('denied'),
        title: 'Lokasi diperlukan untuk mencari tempat terdekat',
        message:
            'Izinkan akses lokasi saat menggunakan aplikasi untuk mencari Masjid dan Mushola.',
        action: 'Coba lagi',
        onPressed: _model.requestLocation,
      ),
      MosqueFinderState.deniedForever => _PermissionState(
        key: const ValueKey('denied-forever'),
        title: 'Izin lokasi dinonaktifkan',
        message: 'Aktifkan izin lokasi Daisth melalui pengaturan perangkat.',
        action: 'Buka Pengaturan',
        onPressed: _model.openAppSettings,
      ),
      MosqueFinderState.serviceDisabled => _PermissionState(
        key: const ValueKey('service-disabled'),
        title: 'Layanan lokasi tidak aktif',
        message:
            'Aktifkan layanan lokasi perangkat untuk mencari tempat terdekat.',
        action: 'Buka Pengaturan Lokasi',
        onPressed: _model.openLocationSettings,
      ),
      MosqueFinderState.loading =>
        _model.result == null
            ? const _LoadingState(
                key: ValueKey('loading'),
                message: 'Mencari Masjid & Mushola di sekitar…',
              )
            : _model.result!.places.isEmpty
            ? _RetryState(
                key: const ValueKey('empty'),
                title:
                    'Belum menemukan Masjid atau Mushola di sekitar lokasi ini.',
                message: 'Pencarian mencakup area hingga 5 km.',
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
        title: 'Lokasi belum tersedia',
        message: 'Periksa layanan lokasi lalu coba lagi.',
        onRetry: _model.refresh,
      ),
      MosqueFinderState.networkError => _RetryState(
        key: const ValueKey('network-error'),
        title: 'Pencarian tempat sholat belum bisa dimuat',
        message: 'Layanan data sedang tidak tersedia. Coba lagi.',
        onRetry: _model.refresh,
      ),
      MosqueFinderState.serviceBusy => _RetryState(
        key: const ValueKey('service-busy'),
        title: 'Layanan pencarian sedang sibuk',
        message: 'Layanan data sedang sibuk. Coba lagi.',
        onRetry: _model.refresh,
      ),
      MosqueFinderState.empty => _RetryState(
        key: const ValueKey('empty'),
        title: 'Belum menemukan Masjid atau Mushola di sekitar lokasi ini.',
        message: 'Pencarian mencakup area hingga 5 km.',
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
            Image.asset(
              'assets/empty_states/no_location_2048.png',
              width: 148,
              height: 148,
              fit: BoxFit.contain,
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
            Icon(
              Icons.location_searching_rounded,
              size: 42,
              color: Theme.of(context).colorScheme.primary,
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
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
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
          'Terdekat',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DaisthSpacing.sm),
        _NearestMosqueCard(place: places.first, onNavigate: onNavigate),
        if (places.length > 1) ...[
          const SizedBox(height: DaisthSpacing.xl),
          Text('Tempat lainnya', style: theme.textTheme.titleSmall),
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
          'Pencarian hingga ${_formatDistance(result.searchedRadiusMeters)}',
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
            isRefreshing ? Icons.sync_rounded : Icons.history_rounded,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: DaisthSpacing.sm),
          Expanded(
            child: Text(
              isRefreshing
                  ? 'Menampilkan hasil terakhir sambil memperbarui.'
                  : 'Menampilkan hasil terakhir. Data terbaru belum tersedia.',
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
          Icons.info_outline_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: 18,
        ),
        const SizedBox(width: DaisthSpacing.sm),
        const Expanded(
          child: Text('Menggunakan lokasi terakhir yang tersedia.'),
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
              Icon(Icons.mosque_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: DaisthSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: DaisthSpacing.xxs),
                    Text(
                      '${_typeLabel(place.type)} · ${_formatDistance(place.distanceMeters)}',
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
              icon: const Icon(Icons.directions_walk_rounded),
              label: const Text('Navigate'),
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
          _typeLabel(place.type),
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
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

String _typeLabel(MosquePlaceType type) => switch (type) {
  MosquePlaceType.mosque => 'Masjid',
  MosquePlaceType.musalla => 'Mushola',
  MosquePlaceType.unknown => 'Tempat sholat',
};

String _formatDistance(num meters) => meters < 1000
    ? '${meters.round()} m'
    : '${(meters / 1000).toStringAsFixed(1)} km';
