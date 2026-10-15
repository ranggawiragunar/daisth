import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/design_system/assets/daisth_assets.dart';
import '../../../core/design_system/components/daisth_button.dart';
import '../../../core/design_system/components/daisth_feature_visual.dart';
import '../../../core/design_system/components/daisth_notice.dart';
import '../../../core/design_system/components/daisth_notice_controller.dart';
import '../../../core/design_system/components/daisth_progress_bar.dart';
import '../../../core/design_system/components/daisth_surface.dart';
import '../../../core/design_system/theme/daisth_theme_extension.dart';
import '../../../core/design_system/tokens/daisth_radius.dart';
import '../../../core/design_system/tokens/daisth_spacing.dart';
import '../../../core/localization/daisth_localizations.dart';
import '../../../core/localization/daisth_terminology.dart';
import '../../../core/time/domain/models/calendar_day.dart';
import '../../prayer_times/domain/models/prayer_name.dart';
import '../../prayer_times/presentation/prayer_schedule_session.dart';
import '../../prayer_times/presentation/prayer_time_presentation.dart';
import '../domain/models/routine.dart';
import '../domain/models/routine_attachment.dart';
import '../domain/models/routine_content.dart';
import '../domain/models/routine_status.dart' as routine_domain;
import '../domain/models/routine_step.dart';
import '../domain/repositories/routine_record_repository.dart';
import '../domain/use_cases/mark_routine_complete_use_case.dart';
import '../domain/use_cases/mark_routine_not_today_use_case.dart';
import '../domain/use_cases/set_routine_step_completion_use_case.dart';
import 'view_models/routine_detail_view_model.dart';
import '../data/services/routine_attachment_file_service.dart';
import 'widgets/routine_link_sections.dart';
import 'widgets/routine_sheets.dart';
import 'widgets/routine_steps_card.dart';

class RoutineDetailScreen extends StatefulWidget {
  const RoutineDetailScreen({
    required this.routine,
    required this.noticeController,
    required this.routineRecordRepository,
    required this.setRoutineStepCompletion,
    required this.markRoutineComplete,
    required this.markRoutineNotToday,
    this.prayerScheduleSession,
    this.calendarDay,
    this.historical = false,
    this.userContent,
    this.attachments = const [],
    this.attachmentFileService,
    this.resolveRemoteAttachment,
    super.key,
  });

  final Routine routine;
  final DaisthNoticeController noticeController;
  final RoutineRecordRepository routineRecordRepository;
  final SetRoutineStepCompletionUseCase setRoutineStepCompletion;
  final MarkRoutineCompleteUseCase markRoutineComplete;
  final MarkRoutineNotTodayUseCase markRoutineNotToday;
  final PrayerScheduleSession? prayerScheduleSession;
  final CalendarDay? calendarDay;
  final bool historical;
  final RoutineContent? userContent;
  final List<RoutineAttachment> attachments;
  final RoutineAttachmentFileService? attachmentFileService;
  final Future<File?> Function(RoutineAttachment)? resolveRemoteAttachment;

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  late final RoutineDetailViewModel _viewModel;
  QuillController? _notesController;
  Routine get _routine => _viewModel.routine;
  List<RoutineStep> get _steps => _viewModel.steps;
  routine_domain.RoutineStatus get _completionState => _viewModel.status;
  String get _displayRoutineTitle {
    final localized = DaisthTerminology.routineTitle(
      _routine.id,
      Localizations.localeOf(context),
    );
    return localized.isEmpty ? _routine.title : localized;
  }

  String get _displayRoutineDescription {
    final localized = DaisthTerminology.routineDescription(
      _routine.id,
      Localizations.localeOf(context),
    );
    return localized.isEmpty ? _routine.description : localized;
  }

  List<RoutineStep> get _displaySteps {
    final locale = Localizations.localeOf(context);
    return [
      for (final step in _steps)
        RoutineStep(
          id: step.id,
          title: DaisthTerminology.routineStepTitle(
            _routine.id,
            step.id,
            step.title,
            locale,
          ),
          subtitle: DaisthTerminology.routineStepSubtitle(
            _routine.id,
            step.id,
            step.subtitle,
            locale,
          ),
          requirement: step.requirement,
          completed: step.completed,
          badge: DaisthTerminology.routineStepBadge(step.badge, locale),
          guidanceTitle: DaisthTerminology.routineStepGuidanceTitle(
            _routine.id,
            step.id,
            step.guidanceTitle,
            locale,
          ),
          guidanceType: step.guidanceType,
          rakaatCount: step.rakaatCount,
          sectionTitle: DaisthTerminology.routineStepSectionTitle(
            _routine.id,
            step.sectionTitle,
            locale,
          ),
          readerContentId: step.readerContentId,
        ),
    ];
  }

  int get _completedRequiredCount => _viewModel.completedRequiredCount;
  int get _requiredCount => _viewModel.requiredCount;
  bool get _allRequiredDone => _viewModel.allRequiredCompleted;
  bool get _hasRemainingSteps => _viewModel.hasRemainingSteps;
  String? get _notTodayReason => _viewModel.notTodayReason;
  String? _lastDisplayedError;

  @override
  void initState() {
    super.initState();
    _notesController = _createNotesController(widget.userContent);
    _viewModel = RoutineDetailViewModel(
      routine: widget.routine,
      repository: widget.routineRecordRepository,
      setStepCompletion: widget.setRoutineStepCompletion,
      markRoutineComplete: widget.markRoutineComplete,
      markRoutineNotToday: widget.markRoutineNotToday,
      calendarDay: widget.calendarDay,
    );
    _viewModel.addListener(_onViewModelChanged);
    widget.prayerScheduleSession?.addListener(_onViewModelChanged);
    unawaited(_viewModel.initialize());
  }

  @override
  void didUpdateWidget(covariant RoutineDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userContent?.serializedDelta ==
        widget.userContent?.serializedDelta) {
      return;
    }
    _notesController?.dispose();
    _notesController = _createNotesController(widget.userContent);
  }

  QuillController? _createNotesController(RoutineContent? content) {
    if (content == null || !content.hasMeaningfulText) return null;
    try {
      return QuillController(
        document: Document.fromJson(
          jsonDecode(content.serializedDelta) as List,
        ),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _notesController?.dispose();
    _viewModel
      ..removeListener(_onViewModelChanged)
      ..dispose();
    widget.prayerScheduleSession?.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    setState(() {});
    final error = _viewModel.errorMessage;
    if (error != null && error != _lastDisplayedError) {
      _lastDisplayedError = error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showNotice(
            type: DaisthNoticeType.error,
            title: switch (error) {
              'Progress routine belum dapat dimuat.' =>
                DaisthLocalizations.text(
                  context,
                  id: error,
                  en: 'Routine progress could not be loaded.',
                ),
              'Progress routine belum dapat disimpan. Coba lagi.' =>
                DaisthLocalizations.text(
                  context,
                  id: error,
                  en: 'Routine progress could not be saved. Try again.',
                ),
              _ => error,
            },
          );
        }
      });
    } else if (error == null) {
      _lastDisplayedError = null;
    }
  }

  String _statusLabel(BuildContext context) => switch (_completionState) {
    routine_domain.RoutineStatus.pending =>
      widget.historical
          ? DaisthLocalizations.text(
              context,
              id: 'Belum tercatat',
              en: 'Unrecorded',
            )
          : DaisthLocalizations.text(
              context,
              id: 'Belum dimulai',
              en: 'Not started',
            ),
    routine_domain.RoutineStatus.partial => DaisthLocalizations.text(
      context,
      id: 'Sebagian · $_completedRequiredCount dari $_requiredCount',
      en: 'Partial · $_completedRequiredCount of $_requiredCount',
    ),
    routine_domain.RoutineStatus.completed => _completedStatusLabel(context),
    routine_domain.RoutineStatus.notToday => DaisthLocalizations.text(
      context,
      id: 'Tidak dilakukan hari ini',
      en: 'Not today',
    ),
  };

  String? get _scheduledPrayerTime {
    final prayer = _prayerForRoutine(_routine.id);
    final schedule = widget.historical
        ? null
        : widget.prayerScheduleSession?.schedule;
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

  String _completedStatusLabel(BuildContext context) {
    if (_routine.id == 'dhuha') {
      return DaisthLocalizations.text(
        context,
        id: 'Selesai · ${_viewModel.completedRakaat} rakaat',
        en: 'Completed · ${_viewModel.completedRakaat} rakaat',
      );
    }
    if (_routine.id == 'zuhur' && _viewModel.justCompleted) {
      return DaisthLocalizations.text(
        context,
        id: 'Baru saja dicatat',
        en: 'Recorded just now',
      );
    }
    return DaisthLocalizations.text(
      context,
      id: 'Selesai · $_completedRequiredCount dari $_requiredCount',
      en: 'Completed · $_completedRequiredCount of $_requiredCount',
    );
  }

  void _showNotice({
    required DaisthNoticeType type,
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

  Future<void> _toggleStep(String id) async {
    HapticFeedback.selectionClick();
    if (await _viewModel.toggleStep(id)) _announceCompletion();
  }

  void _announceCompletion() {
    if (widget.historical) return;
    HapticFeedback.mediumImpact();
    _showNotice(
      type: DaisthNoticeType.success,
      title: DaisthLocalizations.text(
        context,
        id: '$_displayRoutineTitle dicatat',
        en: '$_displayRoutineTitle recorded',
      ),
    );
  }

  Future<void> _markAllRemaining() async {
    final routineTitle = _displayRoutineTitle;
    final isEnglish = DaisthLocalizations.isEnglish(context);
    final completed = _routine.id == 'penutup-hari'
        ? await _viewModel.markRequiredStepsDone()
        : await _viewModel.markAllRemaining();
    if (!completed) return;
    if (widget.historical) return;
    HapticFeedback.mediumImpact();
    _showNotice(
      type: DaisthNoticeType.success,
      title: isEnglish ? '$routineTitle recorded' : '$routineTitle dicatat',
    );
  }

  Future<void> _markSimplePrayerDone() async {
    final routineTitle = _displayRoutineTitle;
    final isEnglish = DaisthLocalizations.isEnglish(context);
    if (!await _viewModel.markRequiredStepsDone()) return;
    if (widget.historical) return;
    HapticFeedback.mediumImpact();
    _showNotice(
      type: DaisthNoticeType.success,
      title: isEnglish ? '$routineTitle recorded' : '$routineTitle dicatat',
    );
  }

  Future<void> _markNotToday() async {
    final result = await showNotTodaySheet(context);
    if (!mounted || result == null) return;
    final didSave = await _viewModel.markNotToday(reason: result.reason);
    if (!didSave || !mounted) return;
    if (widget.historical) return;
    _showNotice(
      type: DaisthNoticeType.neutral,
      title: DaisthLocalizations.text(
        context,
        id: 'Status rutinitas diperbarui',
        en: 'Routine status updated',
      ),
      message: result.reason,
    );
  }

  Future<void> _openStep(RoutineStep step) {
    if (step.readerContentId != null) {
      _openReaderContent(step.readerContentId);
      return Future<void>.value();
    }
    return showRoutineStepSheet(
      context: context,
      step: step,
      onToggle: () => unawaited(_toggleStep(step.id)),
      onOpenReading: _openReader,
    );
  }

  void _openReader() => _showNotice(
    type: DaisthNoticeType.info,
    title: DaisthLocalizations.text(
      context,
      id: 'Reader segera hadir',
      en: 'Reader is coming soon',
    ),
  );

  void _openReaderContent(String? contentId) {
    if (contentId == null) {
      _openReader();
      return;
    }
    final path = RoutePaths.reader(_routine.id, contentId);
    if (widget.historical) {
      context.push(
        '$path?historyDate=${Uri.encodeQueryComponent(_viewModel.calendarDay.toDateKey())}',
      );
    } else {
      context.go(path);
    }
  }

  void _onMenuSelected(String value) {
    if (value == 'edit' && !widget.historical) {
      context.push(RoutePaths.routineEdit(_routine.id));
      return;
    }
    _showNotice(
      type: DaisthNoticeType.info,
      title: DaisthLocalizations.text(
        context,
        id: 'Fitur segera hadir',
        en: 'Feature coming soon',
      ),
      message: value == 'edit'
          ? DaisthLocalizations.text(
              context,
              id: 'Edit rutinitas akan tersedia nanti.',
              en: 'Routine editing will be available later.',
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<DaisthThemeExtension>()!;
    final hasIllustration = _routine.illustrationAsset != null;
    final metadata = [
      if (!widget.historical) _scheduledPrayerTime ?? _routine.preferredTime,
      if (!widget.historical)
        DaisthTerminology.routineContextLabel(
          _routine.id,
          _routine.contextLabel,
          Localizations.localeOf(context),
        ),
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
                  if (widget.historical)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DaisthSpacing.xl,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          DaisthLocalizations.text(
                            context,
                            id: 'Mengedit ${MaterialLocalizations.of(context).formatMediumDate(_viewModel.calendarDay.toDateTime())}',
                            en: 'Editing ${MaterialLocalizations.of(context).formatMediumDate(_viewModel.calendarDay.toDateTime())}',
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        DaisthSpacing.xl,
                        DaisthSpacing.md,
                        DaisthSpacing.xl,
                        DaisthSpacing.xxl,
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
                                          _displayRoutineTitle,
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        if (metadata.isNotEmpty) ...[
                                          const SizedBox(
                                            height: DaisthSpacing.xs,
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
                                    const SizedBox(width: DaisthSpacing.md),
                                    _RoutineIllustration(
                                      asset: _routine.id == 'sholat-malam'
                                          ? DaisthAssets.sholatMalam
                                          : DaisthAssets.routineProgress,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: DaisthSpacing.md),
                              Text(
                                _displayRoutineDescription,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: DaisthSpacing.xl),
                              const Align(
                                alignment: Alignment.centerRight,
                                child: DaisthFeatureVisual(
                                  asset: DaisthAssets.routineDetailSupport,
                                  height: 50,
                                ),
                              ),
                              const SizedBox(height: DaisthSpacing.xs),
                              _RoutineProgressSummary(
                                status: _statusLabel(context),
                                completedRequired: _completedRequiredCount,
                                requiredCount: _requiredCount,
                                progress: _requiredCount == 0
                                    ? 0
                                    : _completedRequiredCount / _requiredCount,
                                notTodayReason: _notTodayReason,
                              ),
                              const SizedBox(height: DaisthSpacing.section),
                              Text(
                                DaisthLocalizations.text(
                                  context,
                                  id: 'Rangkaian',
                                  en: 'Routine steps',
                                ),
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: DaisthSpacing.md),
                              RoutineStepsCard(
                                steps: _displaySteps,
                                onToggle: _toggleStep,
                                onOpenStep: _openStep,
                              ),
                              if (_guidanceItems.isNotEmpty) ...[
                                const SizedBox(height: DaisthSpacing.section),
                                RoutineGuidanceSection(
                                  items: _guidanceItems,
                                  onTap: _onGuidanceTap,
                                  title: _routine.id == 'sholat-malam'
                                      ? DaisthLocalizations.text(
                                          context,
                                          id: 'Bacaan Zikir & Sholawat',
                                          en: 'Zikir & Sholawat Readings',
                                        )
                                      : null,
                                ),
                              ],
                              if (_isMandatoryPrayer && !widget.historical) ...[
                                const SizedBox(height: DaisthSpacing.section),
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
                              if (_notesController != null ||
                                  widget.attachments.isNotEmpty) ...[
                                const SizedBox(height: DaisthSpacing.section),
                                if (_notesController != null) ...[
                                  Text(
                                    DaisthLocalizations.text(
                                      context,
                                      id: 'Catatan',
                                      en: 'Notes',
                                    ),
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: DaisthSpacing.sm),
                                  DaisthSurface(
                                    child: QuillEditor.basic(
                                      controller: _notesController!,
                                      config: QuillEditorConfig(
                                        padding: EdgeInsets.zero,
                                        minHeight: 12,
                                        onLaunchUrl: _launchSafeLink,
                                      ),
                                    ),
                                  ),
                                ],
                                if (widget.attachments.isNotEmpty) ...[
                                  if (_notesController != null)
                                    const SizedBox(height: DaisthSpacing.lg),
                                  Text(
                                    DaisthLocalizations.text(
                                      context,
                                      id: 'Gambar',
                                      en: 'Images',
                                    ),
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: DaisthSpacing.sm),
                                  _RoutineAttachmentGrid(
                                    attachments: widget.attachments,
                                    fileService: widget.attachmentFileService,
                                    resolveRemoteAttachment:
                                        widget.resolveRemoteAttachment,
                                  ),
                                ],
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
          _buildBottomActions(context, theme, extension),
        ],
      ),
    );
  }

  Future<void> _launchSafeLink(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !const {'https', 'http', 'mailto'}.contains(uri.scheme.toLowerCase())) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List<RoutineLinkItem> get _guidanceItems {
    if (_routine.id == 'sholat-malam') {
      final english = DaisthLocalizations.isEnglish(context);
      return [
        RoutineLinkItem(
          title: english
              ? 'After Taubat Prayer'
              : 'Bacaan setelah Sholat Taubat',
          subtitle: 'Istighfar · Sayyidul Istighfar',
          meta: DaisthLocalizations.text(context, id: 'Pembaca', en: 'Reader'),
          readerContentId: 'taubat-after-prayer',
          semanticLabel: english
              ? 'Open post-prayer reading for Taubat'
              : 'Buka bacaan setelah Sholat Taubat',
        ),
        RoutineLinkItem(
          title: english ? 'After Hajat Prayer' : 'Bacaan setelah Sholat Hajat',
          subtitle: english
              ? 'Praise & Sholawat · Dua for Hajat'
              : 'Pujian & Sholawat · Doa Hajat',
          meta: DaisthLocalizations.text(context, id: 'Pembaca', en: 'Reader'),
          readerContentId: 'hajat-after-prayer',
          semanticLabel: english
              ? 'Open post-prayer reading for Hajat'
              : 'Buka bacaan setelah Sholat Hajat',
        ),
      ];
    }
    if (_routine.id == 'dhuha') {
      return [
        RoutineLinkItem(
          title: DaisthLocalizations.text(
            context,
            id: 'Panduan Sholat Dhuha',
            en: 'Duha Prayer Guide',
          ),
          subtitle: DaisthLocalizations.text(
            context,
            id: 'Bacaan dan panduan ringkas',
            en: 'Short reading and guidance',
          ),
          meta: DaisthLocalizations.text(context, id: 'Bacaan', en: 'Reading'),
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
    if (widget.historical) {
      context.push(path);
    } else {
      context.go(path);
    }
  }

  Future<void> _openHelpfulAction(RoutineLinkItem item) async {
    if (item.actionId == 'nearby-mosque') {
      context.go(RoutePaths.mosques(_routine.id));
      return;
    }
    if (!_allRequiredDone) {
      _showNotice(
        type: DaisthNoticeType.info,
        title: DaisthLocalizations.text(
          context,
          id: 'Selesaikan salat terlebih dahulu',
          en: 'Complete the prayer first',
        ),
      );
      return;
    }
    if (_steps.any(
      (step) => step.id == 'post-prayer-dhikr' && step.completed,
    )) {
      _showNotice(
        type: DaisthNoticeType.info,
        title: DaisthLocalizations.text(
          context,
          id: 'Zikir sudah tercatat',
          en: 'Zikir already recorded',
        ),
      );
      return;
    }
    final completed = await context.push<bool>(
      RoutePaths.dhikr(_routine.id, 'post-prayer'),
    );
    if (!mounted || completed != true) return;
    await _viewModel.completeOptionalStep('post-prayer-dhikr');
  }

  Widget _buildBottomActions(
    BuildContext context,
    ThemeData theme,
    DaisthThemeExtension extension,
  ) {
    final isSimplePrayer = _isMandatoryPrayer;
    final showPrimary =
        _completionState != routine_domain.RoutineStatus.notToday &&
        (isSimplePrayer
            ? !_allRequiredDone
            : _routine.steps.isEmpty
            ? _completionState != routine_domain.RoutineStatus.completed
            : _routine.id == 'penutup-hari'
            ? !_allRequiredDone
            : _hasRemainingSteps && _routine.isComposite);
    final showNotToday =
        _viewModel.isOptional &&
        _completionState != routine_domain.RoutineStatus.notToday;
    final showClear = widget.historical && _viewModel.hasRecord;
    if (!showPrimary && !showNotToday && !showClear) {
      return const SizedBox.shrink();
    }

    final label = _routine.steps.isEmpty
        ? DaisthLocalizations.text(
            context,
            id: 'Tandai Selesai',
            en: 'Mark Done',
          )
        : isSimplePrayer
        ? DaisthLocalizations.text(
            context,
            id: 'Tandai $_displayRoutineTitle Selesai',
            en: 'Mark $_displayRoutineTitle Done',
          )
        : _steps.any((step) => step.completed)
        ? DaisthLocalizations.text(
            context,
            id: 'Tandai Sisanya Selesai',
            en: 'Mark Remaining Done',
          )
        : DaisthLocalizations.text(
            context,
            id: 'Tandai Semua Selesai',
            en: 'Mark All Done',
          );
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: extension.divider)),
        ),
        padding: const EdgeInsets.fromLTRB(
          DaisthSpacing.xl,
          DaisthSpacing.md,
          DaisthSpacing.xl,
          DaisthSpacing.sm,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showClear)
                  TextButton(
                    onPressed: _viewModel.isLoading || _viewModel.isSaving
                        ? null
                        : _confirmClearRecord,
                    child: Text(
                      DaisthLocalizations.text(
                        context,
                        id: 'Hapus catatan',
                        en: 'Clear record',
                      ),
                    ),
                  ),
                if (showPrimary)
                  SizedBox(
                    width: double.infinity,
                    child: DaisthButton(
                      label: label,
                      onPressed: _viewModel.isLoading
                          ? null
                          : isSimplePrayer
                          ? _markSimplePrayerDone
                          : _routine.steps.isEmpty
                          ? _markSimpleRoutineDone
                          : _markAllRemaining,
                    ),
                  ),
                if (showNotToday) ...[
                  if (showPrimary) const SizedBox(height: DaisthSpacing.xs),
                  TextButton(
                    onPressed: _viewModel.isLoading ? null : _markNotToday,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                      minimumSize: const Size(44, 44),
                    ),
                    child: Text(
                      DaisthLocalizations.text(
                        context,
                        id: 'Tidak Hari Ini',
                        en: 'Not Today',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClearRecord() async {
    final mandatory = !_routine.isOptional;
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          DaisthLocalizations.text(
            context,
            id: 'Hapus catatan ini?',
            en: 'Clear this record?',
          ),
        ),
        content: Text(
          mandatory
              ? DaisthLocalizations.text(
                  context,
                  id: 'Hari ini akan kembali menjadi Belum tercatat.',
                  en: 'This day will return to Unrecorded.',
                )
              : DaisthLocalizations.text(
                  context,
                  id: 'Rutinitas ini akan dihapus dari riwayat hari tersebut.',
                  en: "This routine will be removed from this day's history.",
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              DaisthLocalizations.text(context, id: 'Batal', en: 'Cancel'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              DaisthLocalizations.text(
                context,
                id: 'Hapus catatan',
                en: 'Clear record',
              ),
            ),
          ),
        ],
      ),
    );
    if (!mounted || shouldClear != true) return;
    if (await _viewModel.clearRecord() && mounted) context.pop();
  }

  Future<void> _markSimpleRoutineDone() async {
    if (!await _viewModel.markSimpleRoutineDone()) return;
    HapticFeedback.mediumImpact();
    _announceCompletion();
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
          Text(
            DaisthLocalizations.text(
              context,
              id: 'Detail Rutinitas',
              en: 'Routine Detail',
            ),
            style: theme.textTheme.titleMedium,
          ),
          Row(
            children: [
              IconButton(
                tooltip: DaisthLocalizations.text(
                  context,
                  id: 'Kembali',
                  en: 'Back',
                ),
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
                tooltip: DaisthLocalizations.text(
                  context,
                  id: 'Opsi lainnya',
                  en: 'More options',
                ),
                onSelected: onMenuSelected,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(
                      DaisthLocalizations.text(
                        context,
                        id: 'Edit Rutinitas',
                        en: 'Edit Routine',
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'history',
                    child: Text(
                      DaisthLocalizations.text(
                        context,
                        id: 'Lihat Riwayat',
                        en: 'View History',
                      ),
                    ),
                  ),
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

class _RoutineAttachmentGrid extends StatelessWidget {
  const _RoutineAttachmentGrid({
    required this.attachments,
    required this.fileService,
    required this.resolveRemoteAttachment,
  });

  final List<RoutineAttachment> attachments;
  final RoutineAttachmentFileService? fileService;
  final Future<File?> Function(RoutineAttachment)? resolveRemoteAttachment;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: attachments.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: DaisthSpacing.sm,
      mainAxisSpacing: DaisthSpacing.sm,
    ),
    itemBuilder: (context, index) {
      final attachment = attachments[index];
      final service = fileService;
      if (service == null) return const SizedBox.shrink();
      return _RoutineAttachmentTile(
        attachment: attachment,
        fileService: service,
        resolveRemoteAttachment: resolveRemoteAttachment,
      );
    },
  );
}

class _RoutineAttachmentTile extends StatefulWidget {
  const _RoutineAttachmentTile({
    required this.attachment,
    required this.fileService,
    required this.resolveRemoteAttachment,
  });

  final RoutineAttachment attachment;
  final RoutineAttachmentFileService fileService;
  final Future<File?> Function(RoutineAttachment)? resolveRemoteAttachment;

  @override
  State<_RoutineAttachmentTile> createState() => _RoutineAttachmentTileState();
}

class _RoutineAttachmentTileState extends State<_RoutineAttachmentTile> {
  late final Future<File?> _file = _resolve();

  Future<File?> _resolve() async {
    final local = await widget.fileService.resolve(
      widget.attachment.localRelativePath,
    );
    if (local != null) return local;
    return widget.resolveRemoteAttachment?.call(widget.attachment);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<File?>(
    future: _file,
    builder: (context, snapshot) {
      final file = snapshot.data;
      if (file == null) {
        return DaisthSurface(
          child: Icon(
            snapshot.connectionState == ConnectionState.waiting
                ? PhosphorIconsRegular.cloudArrowDown
                : PhosphorIconsRegular.imageBroken,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(DaisthRadius.large),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => Scaffold(
                  appBar: AppBar(),
                  body: Center(
                    child: InteractiveViewer(
                      minScale: 0.7,
                      maxScale: 4,
                      child: Image.file(file, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ),
            child: Image.file(file, fit: BoxFit.cover, cacheWidth: 520),
          ),
        ),
      );
    },
  );
}

class _RoutineIllustration extends StatelessWidget {
  const _RoutineIllustration({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    final extension = Theme.of(context).extension<DaisthThemeExtension>()!;
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: extension.artMatte,
        borderRadius: BorderRadius.circular(DaisthRadius.large),
      ),
      padding: const EdgeInsets.all(DaisthSpacing.xs),
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        semanticLabel: DaisthLocalizations.text(
          context,
          id: 'Ilustrasi progres rutinitas',
          en: 'Routine progress illustration',
        ),
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
            padding: const EdgeInsets.all(DaisthSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DaisthFeatureVisual(
                    asset: DaisthAssets.genericError,
                    height: 104,
                  ),
                  const SizedBox(height: DaisthSpacing.lg),
                  Text(
                    DaisthLocalizations.text(
                      context,
                      id: 'Rutinitas tidak tersedia',
                      en: 'Routine unavailable',
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: DaisthSpacing.sm),
                  Text(
                    DaisthLocalizations.text(
                      context,
                      id: 'Rutinitas ini tidak dapat ditemukan.',
                      en: 'This routine could not be found.',
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: DaisthSpacing.xl),
                  DaisthButton(
                    label: DaisthLocalizations.text(
                      context,
                      id: 'Kembali',
                      en: 'Back',
                    ),
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
    return DaisthSurface(
      style: DaisthSurfaceStyle.softPrimary,
      padding: const EdgeInsets.all(DaisthSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(status, style: theme.textTheme.titleSmall)),
              if (progress >= 1) ...[
                const DaisthFeatureVisual(
                  asset: DaisthAssets.genericSuccess,
                  height: 30,
                  width: 38,
                ),
                const SizedBox(width: DaisthSpacing.xs),
              ],
              Text(
                DaisthLocalizations.text(
                  context,
                  id: '$completedRequired dari $requiredCount selesai',
                  en: '$completedRequired of $requiredCount completed',
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: DaisthSpacing.sm),
          DaisthProgressBar(value: progress, height: 5),
          if (notTodayReason != null) ...[
            const SizedBox(height: DaisthSpacing.sm),
            Text(
              DaisthLocalizations.text(
                context,
                id: 'Alasan: $notTodayReason',
                en: 'Reason: ${_localizedNotTodayReason(notTodayReason!)}',
              ),
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

String _localizedNotTodayReason(String reason) => switch (reason) {
  'Ketiduran' => 'Overslept',
  'Tidak sempat' => 'Ran out of time',
  'Bepergian' => 'Travelling',
  'Kondisi fisik' => 'Physical condition',
  'Lainnya' => 'Other',
  _ => reason,
};
