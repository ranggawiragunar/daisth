import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/location/domain/models/location_access_status.dart';
import '../../../core/design_system/components/daisth_surface.dart';
import '../../../core/design_system/tokens/daisth_colors.dart';
import '../../../core/design_system/tokens/daisth_spacing.dart';
import '../../prayer_times/presentation/prayer_schedule_session.dart';
import '../../prayer_times/presentation/prayer_time_presentation.dart';
import '../../routines/domain/repositories/routine_record_repository.dart';
import '../../routines/domain/repositories/routine_repository.dart';
import '../../routines/domain/models/routine_origin.dart';
import '../../routines/domain/models/routine_schedule.dart';
import '../../routines/domain/models/routine_definition.dart';
import '../../routines/domain/models/routine_status.dart' as routine_domain;
import '../../reflection/domain/repositories/reflection_repository.dart';
import '../../reflection/presentation/widgets/reflection_today_card.dart';
import '../presentation/view_models/today_view_model.dart';
import 'widgets/daily_progress.dart';
import 'widgets/focus_routine_card.dart';
import 'widgets/routine_timeline.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({
    required this.prayerScheduleSession,
    required this.routineRecordRepository,
    this.routineRepository,
    this.reflectionRepository,
    this.ensureRoutinesReady,
    this.startClock = true,
    this.bottomContentPadding = 0,
    this.onRoutineTap,
    this.onReflectionTap,
    super.key,
  });

  final PrayerScheduleSession prayerScheduleSession;
  final RoutineRecordRepository routineRecordRepository;
  final RoutineRepository? routineRepository;
  final ReflectionRepository? reflectionRepository;
  final Future<void> Function()? ensureRoutinesReady;
  final bool startClock;
  final double bottomContentPadding;
  final ValueChanged<String>? onRoutineTap;
  final VoidCallback? onReflectionTap;

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
      routineRepository: widget.routineRepository,
      ensureRoutinesReady: widget.ensureRoutinesReady,
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
        ? DaisthColors.darkPrimary.withValues(alpha: 0.09)
        : DaisthColors.primary200.withValues(alpha: 0.28);

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
              maxWidth: DaisthSpacing.contentMaxWidth,
            ),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    DaisthSpacing.screenHorizontal,
                    DaisthSpacing.lg,
                    DaisthSpacing.screenHorizontal,
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
                      const SizedBox(height: DaisthSpacing.xl),
                      _focusContent(context),
                      if (_viewModel.usedLastKnownLocation) ...[
                        const SizedBox(height: DaisthSpacing.md),
                        _LastKnownScheduleNotice(onRefresh: _viewModel.refresh),
                      ],
                      const SizedBox(height: DaisthSpacing.xxl),
                      DailyProgress(
                        recordedCount: _viewModel.recordedStatuses.entries
                            .where((entry) => entry.key != 'penutup-hari')
                            .length,
                        total: _viewModel.routines.isEmpty
                            ? DailyProgress.defaultTotal
                            : _viewModel.routines
                                  .where(
                                    (routine) => routine.id != 'penutup-hari',
                                  )
                                  .length,
                      ),
                      if (widget.reflectionRepository != null &&
                          widget.onReflectionTap != null) ...[
                        const SizedBox(height: DaisthSpacing.lg),
                        ReflectionTodayCard(
                          repository: widget.reflectionRepository!,
                          onOpen: widget.onReflectionTap!,
                        ),
                      ],
                      const SizedBox(height: DaisthSpacing.section),
                      Text(
                        "Today's Routine",
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: DaisthSpacing.lg),
                      RoutineTimeline(
                        schedule: widget.prayerScheduleSession.schedule,
                        period: _viewModel.currentPeriod,
                        recordedStatuses: _viewModel.recordedStatuses,
                        definitions: widget.routineRepository == null
                            ? null
                            : _viewModel.routines,
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
      final customFocus = _nearbyCustomRoutine();
      if (customFocus != null) {
        final minutes = customFocus.schedule.minutesAfterMidnight!;
        final time =
            '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
        return FocusRoutineCard(
          eyebrow: 'ROUTINE FOCUS',
          title: customFocus.title,
          status: 'Scheduled for $time',
          time: time,
          onOpenRoutine: () => widget.onRoutineTap?.call(customFocus.id),
        );
      }
      final prayer = period.focusPrayer;
      final routineId = PrayerTimePresentation.routineId(prayer);
      return FocusRoutineCard(
        title: PrayerTimePresentation.label(
          prayer,
          Localizations.localeOf(context),
        ),
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

  RoutineDefinition? _nearbyCustomRoutine() {
    final currentMinute = _viewModel.now.hour * 60 + _viewModel.now.minute;
    RoutineDefinition? closest;
    var closestDistance = 31;
    for (final routine in _viewModel.routines) {
      if ((routine.origin != RoutineOrigin.custom &&
              routine.id != 'penutup-hari') ||
          _viewModel.recordedStatuses[routine.id] ==
              routine_domain.RoutineStatus.completed ||
          _viewModel.recordedStatuses[routine.id] ==
              routine_domain.RoutineStatus.notToday ||
          routine.schedule is! FixedRoutineSchedule) {
        continue;
      }
      final scheduledMinute = routine.schedule.minutesAfterMidnight!;
      final rawDistance = scheduledMinute - currentMinute;
      final distance = [
        rawDistance,
        rawDistance + 1440,
        rawDistance - 1440,
      ].reduce((a, b) => a.abs() <= b.abs() ? a : b).abs();
      if (distance <= 30 && distance < closestDistance) {
        closest = routine;
        closestDistance = distance;
      }
    }
    return closest;
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
        ? 'Aktifkan izin lokasi Daisth melalui pengaturan perangkat.'
        : accessStatus == LocationAccessStatus.serviceDisabled
        ? 'Aktifkan layanan lokasi perangkat untuk menghitung waktu sholat.'
        : 'Daisth menggunakan lokasi saat aplikasi dibuka untuk menghitung waktu sholat di daerahmu.';
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

    return DaisthSurface(
      style: DaisthSurfaceStyle.softPrimary,
      padding: const EdgeInsets.all(DaisthSpacing.xl),
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
              const SizedBox(width: DaisthSpacing.sm),
              Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
            ],
          ),
          const SizedBox(height: DaisthSpacing.sm),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!isLoading) ...[
            const SizedBox(height: DaisthSpacing.md),
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
  Widget build(BuildContext context) => DaisthSurface(
    padding: const EdgeInsets.symmetric(
      horizontal: DaisthSpacing.md,
      vertical: DaisthSpacing.sm,
    ),
    child: Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: DaisthSpacing.sm),
        const Expanded(child: Text('Menggunakan lokasi terakhir.')),
        TextButton(onPressed: onRefresh, child: const Text('Refresh')),
      ],
    ),
  );
}
