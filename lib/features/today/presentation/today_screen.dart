import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/location/domain/models/location_access_status.dart';
import '../../../core/design_system/components/istiqam_surface.dart';
import '../../../core/design_system/tokens/istiqam_colors.dart';
import '../../../core/design_system/tokens/istiqam_spacing.dart';
import '../../prayer_times/presentation/prayer_schedule_session.dart';
import '../../prayer_times/presentation/prayer_time_presentation.dart';
import '../../routines/domain/repositories/routine_record_repository.dart';
import '../presentation/view_models/today_view_model.dart';
import 'widgets/daily_progress.dart';
import 'widgets/focus_routine_card.dart';
import 'widgets/routine_timeline.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({
    required this.prayerScheduleSession,
    required this.routineRecordRepository,
    this.startClock = true,
    this.bottomContentPadding = 0,
    this.onRoutineTap,
    super.key,
  });

  final PrayerScheduleSession prayerScheduleSession;
  final RoutineRecordRepository routineRecordRepository;
  final bool startClock;
  final double bottomContentPadding;
  final ValueChanged<String>? onRoutineTap;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  late final TodayViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TodayViewModel(
      prayerScheduleSession: widget.prayerScheduleSession,
      routineRecordRepository: widget.routineRecordRepository,
      startClock: widget.startClock,
    )..addListener(_onChanged);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_viewModel.initialize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_viewModel.onAppResumed());
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ambience = theme.brightness == Brightness.dark
        ? IstiqamColors.darkPrimary.withValues(alpha: 0.09)
        : IstiqamColors.primary200.withValues(alpha: 0.28);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        gradient: RadialGradient(
          center: const Alignment(0.9, -1.0),
          radius: 1.15,
          colors: [
            ambience,
            theme.scaffoldBackgroundColor.withValues(alpha: 0),
          ],
        ),
      ),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: IstiqamSpacing.contentMaxWidth,
            ),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    IstiqamSpacing.screenHorizontal,
                    IstiqamSpacing.lg,
                    IstiqamSpacing.screenHorizontal,
                    widget.bottomContentPadding,
                  ),
                  sliver: SliverList.list(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              "Assalamu'alaikum",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              PrayerTimePresentation.date(_viewModel.now),
                              maxLines: 1,
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: IstiqamSpacing.xl),
                      _focusContent(context),
                      if (_viewModel.usedLastKnownLocation) ...[
                        const SizedBox(height: IstiqamSpacing.md),
                        _LastKnownScheduleNotice(onRefresh: _viewModel.refresh),
                      ],
                      const SizedBox(height: IstiqamSpacing.xxl),
                      DailyProgress(
                        recordedCount: _viewModel.recordedStatuses.length,
                      ),
                      const SizedBox(height: IstiqamSpacing.section),
                      Text(
                        "Today's Routine",
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: IstiqamSpacing.lg),
                      RoutineTimeline(
                        schedule: widget.prayerScheduleSession.schedule,
                        period: _viewModel.currentPeriod,
                        recordedStatuses: _viewModel.recordedStatuses,
                        onRoutineTap: widget.onRoutineTap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _focusContent(BuildContext context) {
    final schedule = widget.prayerScheduleSession.schedule;
    final period = _viewModel.currentPeriod;
    if (schedule != null && period != null) {
      final prayer = period.focusPrayer;
      final routineId = PrayerTimePresentation.routineId(prayer);
      return FocusRoutineCard(
        title: 'Sholat ${PrayerTimePresentation.label(prayer)}',
        status: period.focusLabel,
        time: PrayerTimePresentation.time(schedule.timeFor(prayer)),
        onOpenRoutine: () => widget.onRoutineTap?.call(routineId),
      );
    }
    return _PrayerScheduleSetupCard(
      isLoading: _viewModel.isCheckingAccess || _viewModel.isLoading,
      accessStatus: _viewModel.accessStatus,
      hasLocationError: _viewModel.isLocationUnavailable,
      hasCalculationError: _viewModel.calculationError != null,
      onRequestLocation: _viewModel.requestLocation,
      onOpenAppSettings: _viewModel.openAppSettings,
      onOpenLocationSettings: _viewModel.openLocationSettings,
      onRefresh: _viewModel.refresh,
    );
  }
}

class _PrayerScheduleSetupCard extends StatelessWidget {
  const _PrayerScheduleSetupCard({
    required this.isLoading,
    required this.accessStatus,
    required this.hasLocationError,
    required this.hasCalculationError,
    required this.onRequestLocation,
    required this.onOpenAppSettings,
    required this.onOpenLocationSettings,
    required this.onRefresh,
  });

  final bool isLoading;
  final LocationAccessStatus? accessStatus;
  final bool hasLocationError;
  final bool hasCalculationError;
  final VoidCallback onRequestLocation;
  final VoidCallback onOpenAppSettings;
  final VoidCallback onOpenLocationSettings;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = isLoading
        ? 'Memuat jadwal sholat'
        : hasLocationError || hasCalculationError
        ? 'Jadwal belum dapat dimuat'
        : accessStatus == LocationAccessStatus.deniedForever
        ? 'Izin lokasi dinonaktifkan'
        : accessStatus == LocationAccessStatus.serviceDisabled
        ? 'Layanan lokasi tidak aktif'
        : 'Aktifkan jadwal sholat';
    final message = isLoading
        ? 'Menghitung waktu sholat di lokasimu.'
        : hasLocationError || hasCalculationError
        ? 'Periksa akses dan layanan lokasi, lalu coba lagi.'
        : accessStatus == LocationAccessStatus.deniedForever
        ? 'Aktifkan izin lokasi Istiqam melalui pengaturan perangkat.'
        : accessStatus == LocationAccessStatus.serviceDisabled
        ? 'Aktifkan layanan lokasi perangkat untuk menghitung waktu sholat.'
        : 'Istiqam menggunakan lokasi saat aplikasi dibuka untuk menghitung waktu sholat di daerahmu.';
    final actionLabel = switch (accessStatus) {
      LocationAccessStatus.deniedForever => 'Buka Pengaturan',
      LocationAccessStatus.serviceDisabled => 'Buka Pengaturan Lokasi',
      LocationAccessStatus.denied => 'Gunakan lokasi saya',
      LocationAccessStatus.granted => 'Coba lagi',
      null => 'Gunakan lokasi saya',
    };
    final onPressed = switch (accessStatus) {
      LocationAccessStatus.deniedForever => onOpenAppSettings,
      LocationAccessStatus.serviceDisabled => onOpenLocationSettings,
      LocationAccessStatus.denied => onRequestLocation,
      LocationAccessStatus.granted => onRefresh,
      null => onRequestLocation,
    };

    return IstiqamSurface(
      style: IstiqamSurfaceStyle.softPrimary,
      padding: const EdgeInsets.all(IstiqamSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isLoading)
                SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                )
              else
                Icon(
                  Icons.location_on_outlined,
                  color: theme.colorScheme.primary,
                ),
              const SizedBox(width: IstiqamSpacing.sm),
              Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
            ],
          ),
          const SizedBox(height: IstiqamSpacing.sm),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!isLoading) ...[
            const SizedBox(height: IstiqamSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onPressed,
                child: Text(actionLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LastKnownScheduleNotice extends StatelessWidget {
  const _LastKnownScheduleNotice({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => IstiqamSurface(
    padding: const EdgeInsets.symmetric(
      horizontal: IstiqamSpacing.md,
      vertical: IstiqamSpacing.sm,
    ),
    child: Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: IstiqamSpacing.sm),
        const Expanded(child: Text('Menggunakan lokasi terakhir.')),
        TextButton(onPressed: onRefresh, child: const Text('Refresh')),
      ],
    ),
  );
}
