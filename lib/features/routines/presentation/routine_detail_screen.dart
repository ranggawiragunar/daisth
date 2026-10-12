import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/design_system/components/istiqam_button.dart';
import '../../../core/design_system/components/istiqam_notice.dart';
import '../../../core/design_system/components/istiqam_notice_controller.dart';
import '../../../core/design_system/components/istiqam_progress_bar.dart';
import '../../../core/design_system/components/istiqam_surface.dart';
import '../../../core/design_system/theme/istiqam_theme_extension.dart';
import '../../../core/design_system/tokens/istiqam_radius.dart';
import '../../../core/design_system/tokens/istiqam_spacing.dart';
import '../../prayer_times/domain/models/prayer_name.dart';
import '../../prayer_times/presentation/prayer_schedule_session.dart';
import '../../prayer_times/presentation/prayer_time_presentation.dart';
import '../domain/models/routine.dart';
import '../domain/models/routine_status.dart' as routine_domain;
import '../domain/models/routine_step.dart';
import 'view_models/routine_detail_view_model.dart';
import 'widgets/routine_link_sections.dart';
import 'widgets/routine_sheets.dart';
import 'widgets/routine_steps_card.dart';

class RoutineDetailScreen extends StatefulWidget {
  const RoutineDetailScreen({
    required this.routine,
    required this.noticeController,
    this.prayerScheduleSession,
    super.key,
  });

  final Routine routine;
  final IstiqamNoticeController noticeController;
  final PrayerScheduleSession? prayerScheduleSession;

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  late final RoutineDetailViewModel _viewModel;
  Routine get _routine => _viewModel.routine;
  List<RoutineStep> get _steps => _viewModel.steps;
  routine_domain.RoutineStatus get _completionState => _viewModel.status;
  int get _completedRequiredCount => _viewModel.completedRequiredCount;
  int get _requiredCount => _viewModel.requiredCount;
  bool get _allRequiredDone => _viewModel.allRequiredCompleted;
  bool get _hasRemainingSteps => _viewModel.hasRemainingSteps;
  String? get _notTodayReason => _viewModel.notTodayReason;

  @override
  void initState() {
    super.initState();
    _viewModel = RoutineDetailViewModel(widget.routine);
    _viewModel.addListener(_onViewModelChanged);
    widget.prayerScheduleSession?.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel
      ..removeListener(_onViewModelChanged)
      ..dispose();
    widget.prayerScheduleSession?.removeListener(_onViewModelChanged);
    super.dispose();
  }

  String get _statusLabel => switch (_completionState) {
    routine_domain.RoutineStatus.pending => 'Belum dimulai',
    routine_domain.RoutineStatus.partial =>
      'Partial · $_completedRequiredCount of $_requiredCount',
    routine_domain.RoutineStatus.completed => _completedStatusLabel,
    routine_domain.RoutineStatus.notToday => 'Tidak dilakukan hari ini',
  };

  String? get _scheduledPrayerTime {
    final prayer = _prayerForRoutine(_routine.id);
    final schedule = widget.prayerScheduleSession?.schedule;
    if (prayer == null || schedule == null) return null;
    return PrayerTimePresentation.time(schedule.timeFor(prayer));
  }

  PrayerName? _prayerForRoutine(String id) => switch (id) {
    'subuh' => PrayerName.fajr,
    'zuhur' => PrayerName.dhuhr,
    'asar' => PrayerName.asr,
    'maghrib' => PrayerName.maghrib,
    'isya' => PrayerName.isha,
    _ => null,
  };

  bool get _isMandatoryPrayer => _prayerForRoutine(_routine.id) != null;

  String get _completedStatusLabel {
    if (_routine.id == 'dhuha') {
      return 'Completed · ${_viewModel.completedRakaat} rakaat';
    }
    if (_routine.id == 'zuhur' && _viewModel.justCompleted) {
      return 'Recorded just now';
    }
    return 'Completed · $_completedRequiredCount of $_requiredCount';
  }

  void _showNotice({
    required IstiqamNoticeType type,
    required String title,
    String? message,
  }) {
    widget.noticeController.show(
      context,
      type: type,
      title: title,
      message: message,
    );
  }

  void _toggleStep(String id) {
    HapticFeedback.selectionClick();
    if (_viewModel.toggleStep(id)) _announceCompletion();
  }

  void _announceCompletion() {
    HapticFeedback.mediumImpact();
    _showNotice(
      type: IstiqamNoticeType.success,
      title: '${_routine.title.replaceFirst('Sholat ', '')} recorded',
    );
  }

  void _markAllRemaining() {
    if (!_viewModel.markAllRemaining()) return;
    HapticFeedback.mediumImpact();
    _showNotice(
      type: IstiqamNoticeType.success,
      title: '${_routine.title} recorded',
    );
  }

  void _markSimplePrayerDone() {
    if (!_viewModel.markRequiredStepsDone()) return;
    HapticFeedback.mediumImpact();
    _showNotice(
      type: IstiqamNoticeType.success,
      title: '${_routine.title.replaceFirst('Sholat ', '')} recorded',
    );
  }

  Future<void> _markNotToday() async {
    final result = await showNotTodaySheet(context);
    if (!mounted || result == null) return;
    _viewModel.markNotToday(reason: result.reason);
    _showNotice(
      type: IstiqamNoticeType.neutral,
      title: 'Status routine diperbarui',
      message: result.reason,
    );
  }

  Future<void> _openStep(RoutineStep step) => showRoutineStepSheet(
    context: context,
    step: step,
    onToggle: () => _toggleStep(step.id),
    onOpenReading: () =>
        _showNotice(type: IstiqamNoticeType.info, title: 'Reader segera hadir'),
  );

  void _openReader() =>
      _showNotice(type: IstiqamNoticeType.info, title: 'Reader segera hadir');

  void _onMenuSelected(String value) {
    _showNotice(
      type: IstiqamNoticeType.info,
      title: 'Feature coming soon',
      message: value == 'edit' ? 'Edit Routine akan tersedia nanti.' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<IstiqamThemeExtension>()!;
    final hasIllustration = _routine.illustrationAsset != null;
    final metadata = [
      _scheduledPrayerTime ?? _routine.preferredTime,
      _routine.contextLabel,
    ].where((value) => value.isNotEmpty).join(' · ');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _DetailTopBar(onMenuSelected: _onMenuSelected),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        IstiqamSpacing.xl,
                        IstiqamSpacing.md,
                        IstiqamSpacing.xl,
                        IstiqamSpacing.xxl,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _routine.title,
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        if (metadata.isNotEmpty) ...[
                                          const SizedBox(
                                            height: IstiqamSpacing.xs,
                                          ),
                                          Text(
                                            metadata,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (hasIllustration) ...[
                                    const SizedBox(width: IstiqamSpacing.md),
                                    _RoutineIllustration(
                                      asset: _routine.illustrationAsset!,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: IstiqamSpacing.md),
                              Text(
                                _routine.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: IstiqamSpacing.xl),
                              _RoutineProgressSummary(
                                status: _statusLabel,
                                completedRequired: _completedRequiredCount,
                                requiredCount: _requiredCount,
                                progress: _requiredCount == 0
                                    ? 0
                                    : _completedRequiredCount / _requiredCount,
                                notTodayReason: _notTodayReason,
                              ),
                              const SizedBox(height: IstiqamSpacing.section),
                              Text(
                                'Rangkaian',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: IstiqamSpacing.md),
                              RoutineStepsCard(
                                steps: _steps,
                                onToggle: _toggleStep,
                                onOpenStep: _openStep,
                              ),
                              if (_guidanceItems.isNotEmpty) ...[
                                const SizedBox(height: IstiqamSpacing.section),
                                RoutineGuidanceSection(
                                  items: _guidanceItems,
                                  onTap: _onGuidanceTap,
                                ),
                              ],
                              if (_isMandatoryPrayer) ...[
                                const SizedBox(height: IstiqamSpacing.section),
                                RoutineHelpfulActions(
                                  onTap: _openHelpfulAction,
                                  prayerCompleted: _allRequiredDone,
                                  dhikrCompleted: _steps.any(
                                    (step) =>
                                        step.id == 'post-prayer-dhikr' &&
                                        step.completed,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomActions(theme, extension),
        ],
      ),
    );
  }

  List<RoutineLinkItem> get _guidanceItems {
    if (_routine.id == 'sholat-malam') {
      return const [
        RoutineLinkItem(
          title: 'Doa Sebelum Tidur',
          subtitle: 'Dibaca ketika hendak tidur · Reader preview',
          meta: 'Reader',
          readerContentId: 'doa-sebelum-tidur',
        ),
        RoutineLinkItem(
          title: 'Doa setelah Tahajud',
          subtitle: 'A short reflection after prayer',
          meta: 'Rich text',
        ),
        RoutineLinkItem(
          title: 'Panduan Witir',
          subtitle: 'Panduan singkat untuk menutup sholat malam',
          meta: 'Reading',
        ),
      ];
    }
    if (_routine.id == 'dhuha') {
      return const [
        RoutineLinkItem(
          title: 'Panduan Sholat Dhuha',
          subtitle: 'Bacaan dan panduan ringkas',
          meta: 'Reading',
        ),
      ];
    }
    return const [];
  }

  void _onGuidanceTap(RoutineLinkItem item) {
    final contentId = item.readerContentId;
    if (contentId == null) {
      _openReader();
      return;
    }
    final path = RoutePaths.reader(_routine.id, contentId);
    context.go(path);
  }

  Future<void> _openHelpfulAction(RoutineLinkItem item) async {
    if (item.actionId == 'nearby-mosque') {
      context.go(RoutePaths.mosques(_routine.id));
      return;
    }
    if (!_allRequiredDone) {
      _showNotice(
        type: IstiqamNoticeType.info,
        title: 'Selesaikan sholat terlebih dahulu',
      );
      return;
    }
    if (_steps.any(
      (step) => step.id == 'post-prayer-dhikr' && step.completed,
    )) {
      _showNotice(type: IstiqamNoticeType.info, title: 'Dzikir sudah tercatat');
      return;
    }
    final completed = await context.push<bool>(
      RoutePaths.dhikr(_routine.id, 'post-prayer'),
    );
    if (!mounted || completed != true) return;
    _viewModel.completeOptionalStep('post-prayer-dhikr');
  }

  Widget _buildBottomActions(ThemeData theme, IstiqamThemeExtension extension) {
    final isSimplePrayer = _isMandatoryPrayer;
    final showPrimary =
        _completionState != routine_domain.RoutineStatus.notToday &&
        (isSimplePrayer
            ? !_allRequiredDone
            : _hasRemainingSteps && _routine.isComposite);
    final showNotToday =
        _viewModel.isOptional &&
        _completionState != routine_domain.RoutineStatus.notToday;
    if (!showPrimary && !showNotToday) return const SizedBox.shrink();

    final label = isSimplePrayer
        ? 'Mark ${_routine.title.replaceFirst('Sholat ', '')} Done'
        : _steps.any((step) => step.completed)
        ? 'Mark Remaining Done'
        : 'Mark All Done';
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: extension.divider)),
        ),
        padding: const EdgeInsets.fromLTRB(
          IstiqamSpacing.xl,
          IstiqamSpacing.md,
          IstiqamSpacing.xl,
          IstiqamSpacing.sm,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showPrimary)
                  SizedBox(
                    width: double.infinity,
                    child: IstiqamButton(
                      label: label,
                      onPressed: isSimplePrayer
                          ? _markSimplePrayerDone
                          : _markAllRemaining,
                    ),
                  ),
                if (showNotToday) ...[
                  if (showPrimary) const SizedBox(height: IstiqamSpacing.xs),
                  TextButton(
                    onPressed: _markNotToday,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                      minimumSize: const Size(44, 44),
                    ),
                    child: const Text('Not Today'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({required this.onMenuSelected});

  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text('Routine Detail', style: theme.textTheme.titleMedium),
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(RoutePaths.today);
                  }
                },
                icon: const Icon(PhosphorIconsRegular.arrowLeft),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                tooltip: 'More options',
                onSelected: onMenuSelected,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit Routine')),
                  PopupMenuItem(value: 'history', child: Text('View History')),
                ],
                icon: const Icon(PhosphorIconsRegular.dotsThreeVertical),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutineIllustration extends StatelessWidget {
  const _RoutineIllustration({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    final extension = Theme.of(context).extension<IstiqamThemeExtension>()!;
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: extension.artMatte,
        borderRadius: BorderRadius.circular(IstiqamRadius.large),
      ),
      padding: const EdgeInsets.all(IstiqamSpacing.xs),
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        semanticLabel: 'Routine progress illustration',
      ),
    );
  }
}

class RoutineUnavailableScreen extends StatelessWidget {
  const RoutineUnavailableScreen({required this.routineId, super.key});

  final String routineId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(IstiqamSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIconsRegular.magnifyingGlass,
                    size: 42,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: IstiqamSpacing.lg),
                  Text(
                    'Routine tidak tersedia',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: IstiqamSpacing.sm),
                  Text(
                    'Routine "$routineId" tidak dapat ditemukan.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: IstiqamSpacing.xl),
                  IstiqamButton(
                    label: 'Kembali',
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(RoutePaths.today);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutineProgressSummary extends StatelessWidget {
  const _RoutineProgressSummary({
    required this.status,
    required this.completedRequired,
    required this.requiredCount,
    required this.progress,
    required this.notTodayReason,
  });

  final String status;
  final int completedRequired;
  final int requiredCount;
  final double progress;
  final String? notTodayReason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IstiqamSurface(
      style: IstiqamSurfaceStyle.softPrimary,
      padding: const EdgeInsets.all(IstiqamSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(status, style: theme.textTheme.titleSmall)),
              Text(
                '$completedRequired of $requiredCount completed',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: IstiqamSpacing.sm),
          IstiqamProgressBar(value: progress, height: 5),
          if (notTodayReason != null) ...[
            const SizedBox(height: IstiqamSpacing.sm),
            Text(
              'Alasan: $notTodayReason',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
