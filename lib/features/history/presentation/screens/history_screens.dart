import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../app/dependencies/app_dependencies.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/design_system/components/daisth_button.dart';
import '../../../../core/design_system/components/daisth_empty_state.dart';
import '../../../../core/design_system/components/daisth_surface.dart';
import '../../../../core/localization/daisth_terminology.dart';
import '../../../../core/design_system/tokens/daisth_spacing.dart';
import '../../../../core/time/domain/models/calendar_day.dart';
import '../../data/resolvers/history_routine_resolver_data.dart';
import '../../domain/models/history_day.dart';
import '../../domain/use_cases/build_history_day_use_case.dart';
import '../../domain/use_cases/get_history_range_use_case.dart';
import '../../../reflection/domain/models/daily_reflection.dart';
import '../../../reflection/domain/models/reflection_rhythm.dart';
import '../view_models/history_view_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    required this.dependencies,
    this.bottomContentPadding = 92,
    super.key,
  });
  final AppDependencies dependencies;
  final double bottomContentPadding;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryViewModel _model;

  @override
  void initState() {
    super.initState();
    final buildDay = BuildHistoryDayUseCase(
      recordRepository: widget.dependencies.routineRecordRepository,
      routineRepository: widget.dependencies.routineRepository,
      routineResolver: const HistoryRoutineResolverData(),
      reflectionRepository: widget.dependencies.reflectionRepository,
    );
    _model = HistoryViewModel(
      getHistory: GetHistoryRangeUseCase(
        recordRepository: widget.dependencies.routineRecordRepository,
        routineRepository: widget.dependencies.routineRepository,
        buildDay: buildDay,
        reflectionRepository: widget.dependencies.reflectionRepository,
      ),
      repository: widget.dependencies.routineRecordRepository,
      reflectionRepository: widget.dependencies.reflectionRepository,
    )..addListener(_changed);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await widget.dependencies.ensureRoutineDefinitionsReady();
    } catch (_) {
      // initialize() owns the user-facing retryable error state.
    }
    await _model.initialize();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _model.removeListener(_changed);
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_model.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    if (_model.errorMessage != null && _model.days.isEmpty) {
      return Scaffold(
        body: _ErrorState(message: _model.errorMessage!, onRetry: _initialize),
      );
    }
    if (!_model.hasMeaningfulHistory) {
      return Scaffold(
        body: DaisthEmptyState(
          imageAsset: 'assets/empty_states/empty_history_2048.png',
          bottomContentPadding: widget.bottomContentPadding,
          title: 'No history yet',
          description: 'Your recorded routines will appear here over time.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('History'), centerTitle: false),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              DaisthSpacing.xl,
              DaisthSpacing.md,
              DaisthSpacing.xl,
              widget.bottomContentPadding,
            ),
            itemCount: _model.days.length + (_model.hasEarlier ? 1 : 0),
            separatorBuilder: (_, _) =>
                const SizedBox(height: DaisthSpacing.sm),
            itemBuilder: (context, index) {
              if (index == _model.days.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: DaisthSpacing.md),
                  child: Center(
                    child: _model.isLoadingEarlier
                        ? const CircularProgressIndicator.adaptive()
                        : TextButton.icon(
                            onPressed: _model.loadEarlier,
                            icon: const Icon(PhosphorIconsRegular.arrowDown),
                            label: const Text('Load earlier'),
                          ),
                  ),
                );
              }
              final item = _model.days[index];
              final yesterday = CalendarDay.fromDateTime(
                DateTime.now(),
              ).addDays(-1);
              final dateLabel = item.day == yesterday
                  ? 'Yesterday'
                  : MaterialLocalizations.of(
                      context,
                    ).formatMediumDate(item.day.toDateTime());
              return _HistoryDayCard(
                day: item,
                label: dateLabel,
                onTap: () =>
                    context.push(RoutePaths.historyDay(item.day.toDateKey())),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: _model.errorMessage == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(DaisthSpacing.md),
              child: Text(
                _model.errorMessage!,
                style: theme.textTheme.bodySmall,
              ),
            ),
    );
  }
}

class HistoryDayScreen extends StatefulWidget {
  const HistoryDayScreen({
    required this.date,
    required this.dependencies,
    this.bottomContentPadding = 28,
    super.key,
  });
  final String date;
  final AppDependencies dependencies;
  final double bottomContentPadding;

  @override
  State<HistoryDayScreen> createState() => _HistoryDayScreenState();
}

class _HistoryDayScreenState extends State<HistoryDayScreen> {
  CalendarDay? _day;
  HistoryDayViewModel? _model;
  late final BuildHistoryDayUseCase _buildDay;

  @override
  void initState() {
    super.initState();
    _buildDay = BuildHistoryDayUseCase(
      recordRepository: widget.dependencies.routineRecordRepository,
      routineRepository: widget.dependencies.routineRepository,
      routineResolver: const HistoryRoutineResolverData(),
      reflectionRepository: widget.dependencies.reflectionRepository,
    );
    try {
      _day = CalendarDay.parseDateKey(widget.date);
      _model =
          HistoryDayViewModel(
              day: _day!,
              loadDay: _loadDay,
              repository: widget.dependencies.routineRecordRepository,
              reflectionRepository: widget.dependencies.reflectionRepository,
            )
            ..addListener(_changed)
            ..initialize();
    } on FormatException {
      _day = null;
    }
  }

  Future<HistoryDay> _loadDay(CalendarDay day) async {
    await widget.dependencies.ensureRoutineDefinitionsReady();
    return _buildDay(day);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _model?.removeListener(_changed);
    _model?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_day == null) return _InvalidHistoryRoute();
    return AnimatedBuilder(
      animation: _model!,
      builder: (context, _) => FutureBuilder<HistoryDay>(
        future: _model!.future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator.adaptive()),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Scaffold(
              body: _ErrorState(
                message: 'History belum dapat dimuat.',
                onRetry: _model!.reload,
              ),
            );
          }
          final historyDay = snapshot.data!;
          final mandatory = historyDay.entries
              .where((entry) => entry.isMandatory)
              .toList();
          final other = historyDay.entries
              .where((entry) => !entry.isMandatory)
              .toList();
          return Scaffold(
            appBar: AppBar(title: const Text('Day Detail')),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    DaisthSpacing.xl,
                    DaisthSpacing.lg,
                    DaisthSpacing.xl,
                    widget.bottomContentPadding,
                  ),
                  children: [
                    Text(
                      MaterialLocalizations.of(
                        context,
                      ).formatFullDate(_day!.toDateTime()),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: DaisthSpacing.xl),
                    if (historyDay.entries.isEmpty &&
                        historyDay.reflection == null)
                      const Text(
                        'No local history is available for this date.',
                      ),
                    for (final entry in mandatory)
                      _HistoryEntryTile(entry: entry, day: _day!),
                    if (other.isNotEmpty) ...[
                      const SizedBox(height: DaisthSpacing.lg),
                      Text(
                        'Other recorded routines',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: DaisthSpacing.sm),
                      for (final entry in other)
                        _HistoryEntryTile(entry: entry, day: _day!),
                    ],
                    const SizedBox(height: DaisthSpacing.lg),
                    Text(
                      'Reflection',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: DaisthSpacing.sm),
                    _HistoryReflectionTile(
                      day: _day!,
                      reflection: historyDay.reflection,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryReflectionTile extends StatelessWidget {
  const _HistoryReflectionTile({required this.day, required this.reflection});

  final CalendarDay day;
  final DailyReflection? reflection;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push(RoutePaths.historyReflection(day.toDateKey())),
    borderRadius: BorderRadius.circular(18),
    child: DaisthSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reflection == null
                ? 'No reflection recorded.'
                : _rhythmLabel(reflection!.rhythm),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (reflection?.note case final note?) ...[
            const SizedBox(height: DaisthSpacing.xs),
            Text(
              note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

String _rhythmLabel(ReflectionRhythm rhythm) => switch (rhythm) {
  ReflectionRhythm.steady => 'Terasa mengalir',
  ReflectionRhythm.mixed => 'Naik turun',
  ReflectionRhythm.heavy => 'Terasa berat',
};

class _HistoryDayCard extends StatelessWidget {
  const _HistoryDayCard({
    required this.day,
    required this.label,
    required this.onTap,
  });
  final HistoryDay day;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: DaisthSurface(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: DaisthSpacing.xs),
                Text(
                  _summaryText(day.summary),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            PhosphorIconsRegular.caretRight,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    ),
  );
}

class _HistoryEntryTile extends StatelessWidget {
  const _HistoryEntryTile({required this.entry, required this.day});
  final HistoryRoutineEntry entry;
  final CalendarDay day;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DaisthSpacing.sm),
    child: InkWell(
      onTap: () => context.push(
        RoutePaths.historyRoutine(day.toDateKey(), entry.routine.id),
      ),
      borderRadius: BorderRadius.circular(18),
      child: DaisthSurface(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _historyRoutineTitle(
                  context,
                  entry.routine.id,
                  entry.routine.title,
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Text(
              _statusText(entry.status),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: _statusColor(context, entry.status),
              ),
            ),
            const SizedBox(width: DaisthSpacing.xs),
            Icon(
              PhosphorIconsRegular.caretRight,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    ),
  );
}

String _historyRoutineTitle(BuildContext context, String id, String fallback) {
  final localized = DaisthTerminology.routineTitle(
    id,
    Localizations.localeOf(context),
  );
  return localized.isEmpty ? fallback : localized;
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(DaisthSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: DaisthSpacing.md),
          DaisthButton(label: 'Try again', onPressed: onRetry),
        ],
      ),
    ),
  );
}

class _InvalidHistoryRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Tanggal history tidak valid.'),
          const SizedBox(height: DaisthSpacing.md),
          TextButton(
            onPressed: () => context.go(RoutePaths.history),
            child: const Text('Kembali ke History'),
          ),
        ],
      ),
    ),
  );
}

String _statusText(HistoryRoutineStatus status) => switch (status) {
  HistoryRoutineStatus.completed => 'Completed',
  HistoryRoutineStatus.partial => 'Partial',
  HistoryRoutineStatus.notToday => 'Not Today',
  HistoryRoutineStatus.unrecorded => 'Unrecorded',
};

Color _statusColor(BuildContext context, HistoryRoutineStatus status) {
  final colors = Theme.of(context).colorScheme;
  return switch (status) {
    HistoryRoutineStatus.completed => colors.primary,
    HistoryRoutineStatus.partial => colors.secondary,
    HistoryRoutineStatus.notToday ||
    HistoryRoutineStatus.unrecorded => colors.onSurfaceVariant,
  };
}

String _summaryText(HistorySummary summary) {
  final parts = <String>[];
  if (summary.completed > 0) parts.add('${summary.completed} completed');
  if (summary.partial > 0) parts.add('${summary.partial} partial');
  if (summary.notToday > 0) parts.add('${summary.notToday} not today');
  if (summary.unrecorded > 0) parts.add('${summary.unrecorded} unrecorded');
  return parts.join(' · ');
}
