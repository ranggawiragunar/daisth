import 'package:flutter/material.dart';

import '../../../../core/design_system/components/daisth_status_indicator.dart';
import '../../../../core/localization/daisth_terminology.dart';
import '../../../../core/design_system/theme/daisth_theme_extension.dart'
    as design;
import '../../../../core/design_system/tokens/daisth_radius.dart';
import '../../../../core/design_system/tokens/daisth_spacing.dart';
import '../../../prayer_times/domain/models/prayer_day_schedule.dart';
import '../../../prayer_times/domain/models/prayer_name.dart';
import '../../../prayer_times/domain/models/prayer_period_state.dart';
import '../../../prayer_times/presentation/prayer_time_presentation.dart';
import '../../../routines/domain/models/routine_status.dart' as routine_domain;
import '../../../routines/domain/models/prayer_key.dart';
import '../../../routines/domain/models/routine_definition.dart';
import '../../../routines/domain/models/routine_schedule.dart';
import '../../../routines/domain/models/built_in_routine_defaults.dart';

class _RoutineEntry {
  const _RoutineEntry({
    required this.time,
    required this.title,
    required this.status,
    this.detail,
    this.routineId,
    this.prayer,
    this.isCurrent = false,
  });

  final String time;
  final String title;
  final design.RoutineStatus status;
  final String? detail;
  final String? routineId;
  final PrayerName? prayer;
  final bool isCurrent;
}

class RoutineTimeline extends StatelessWidget {
  const RoutineTimeline({
    required this.schedule,
    required this.period,
    this.onRoutineTap,
    this.recordedStatuses = const {},
    this.definitions,
    super.key,
  });

  final PrayerDaySchedule? schedule;
  final PrayerPeriodState? period;
  final ValueChanged<String>? onRoutineTap;
  final Map<String, routine_domain.RoutineStatus> recordedStatuses;
  final List<RoutineDefinition>? definitions;

  design.RoutineStatus _statusFor(
    String routineId,
    design.RoutineStatus scheduledStatus,
  ) => switch (recordedStatuses[routineId]) {
    routine_domain.RoutineStatus.completed => design.RoutineStatus.completed,
    routine_domain.RoutineStatus.partial => design.RoutineStatus.partial,
    routine_domain.RoutineStatus.notToday => design.RoutineStatus.notToday,
    _ => scheduledStatus,
  };

  List<_RoutineEntry> _entries(Locale locale) {
    if (definitions != null) return _managedEntries(locale);
    _RoutineEntry prayerEntry(PrayerName prayer) {
      final isFocused = period?.focusPrayer == prayer;
      return _RoutineEntry(
        time: schedule == null
            ? '--:--'
            : PrayerTimePresentation.time(schedule!.timeFor(prayer)),
        title: PrayerTimePresentation.label(prayer, locale),
        routineId: PrayerTimePresentation.routineId(prayer),
        prayer: prayer,
        status: _statusFor(
          PrayerTimePresentation.routineId(prayer),
          isFocused && period?.currentPrayer == prayer
              ? design.RoutineStatus.due
              : design.RoutineStatus.upcoming,
        ),
        detail: isFocused ? period?.focusLabel : null,
        isCurrent: isFocused,
      );
    }

    return [
      _RoutineEntry(
        time: '03:00',
        title: DaisthTerminology.nightPrayer(locale),
        routineId: 'sholat-malam',
        status: _statusFor('sholat-malam', design.RoutineStatus.upcoming),
      ),
      prayerEntry(PrayerName.fajr),
      _RoutineEntry(
        time: '07:00',
        title: DaisthTerminology.prayerName('dhuha', locale),
        routineId: 'dhuha',
        status: _statusFor('dhuha', design.RoutineStatus.upcoming),
      ),
      prayerEntry(PrayerName.dhuhr),
      prayerEntry(PrayerName.asr),
      prayerEntry(PrayerName.maghrib),
      prayerEntry(PrayerName.isha),
      _RoutineEntry(
        time: _formatMinutes(
          BuiltInRoutineDefaults.penutupHariMinutesAfterMidnight,
        ),
        title: DaisthTerminology.endOfDay(locale),
        routineId: 'penutup-hari',
        status: design.RoutineStatus.upcoming,
      ),
    ];
  }

  static String _formatMinutes(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  List<_RoutineEntry> _managedEntries(Locale locale) {
    int prayerMinutes(PrayerKey key) {
      final prayer = switch (key) {
        PrayerKey.subuh => PrayerName.fajr,
        PrayerKey.zuhur => PrayerName.dhuhr,
        PrayerKey.asar => PrayerName.asr,
        PrayerKey.maghrib => PrayerName.maghrib,
        PrayerKey.isya => PrayerName.isha,
      };
      final time = schedule?.timeFor(prayer);
      return time == null ? 24 * 60 : time.hour * 60 + time.minute;
    }

    final entries = <({int minute, _RoutineEntry entry})>[];
    for (final definition in definitions!) {
      final schedule = definition.schedule;
      final minute = switch (schedule) {
        FixedRoutineSchedule(:final value) => value,
        PrayerRoutineSchedule(:final value) => prayerMinutes(value),
      };
      final prayerKey = schedule is PrayerRoutineSchedule
          ? schedule.value
          : null;
      final prayer = switch (prayerKey) {
        PrayerKey.subuh => PrayerName.fajr,
        PrayerKey.zuhur => PrayerName.dhuhr,
        PrayerKey.asar => PrayerName.asr,
        PrayerKey.maghrib => PrayerName.maghrib,
        PrayerKey.isya => PrayerName.isha,
        null => null,
      };
      final isFocused = prayer != null && period?.focusPrayer == prayer;
      final fallbackStatus = isFocused && period?.currentPrayer == prayer
          ? design.RoutineStatus.due
          : design.RoutineStatus.upcoming;
      final localizedTitle = DaisthTerminology.routineTitle(
        definition.id,
        locale,
      );
      final title = localizedTitle.isEmpty ? definition.title : localizedTitle;
      final entry = _RoutineEntry(
        time: prayer == null
            ? '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}'
            : this.schedule == null
            ? '--:--'
            : PrayerTimePresentation.time(this.schedule!.timeFor(prayer)),
        title: title,
        routineId: definition.id,
        prayer: prayer,
        status: _statusFor(definition.id, fallbackStatus),
        detail: isFocused ? period?.focusLabel : null,
        isCurrent: isFocused,
      );
      entries.add((minute: minute, entry: entry));
    }
    entries.sort((first, second) => first.minute.compareTo(second.minute));
    return entries.map((item) => item.entry).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final extension = Theme.of(
      context,
    ).extension<design.DaisthThemeExtension>()!;
    final entries = _entries(Localizations.localeOf(context));
    return Column(
      children: [
        for (var index = 0; index < entries.length; index++)
          _TimelineRow(
            key: ValueKey(
              'today-routine-${entries[index].routineId ?? entries[index].title}',
            ),
            entry: entries[index],
            onTap: entries[index].routineId == null || onRoutineTap == null
                ? null
                : () => onRoutineTap!(entries[index].routineId!),
            isLast: index == entries.length - 1,
            connectorColor:
                entries[index].status == design.RoutineStatus.completed
                ? extension.completed.withValues(alpha: 0.42)
                : extension.divider,
            currentFill: extension.softSurface,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    super.key,
    required this.entry,
    required this.isLast,
    required this.connectorColor,
    required this.currentFill,
    this.onTap,
  });

  final _RoutineEntry entry;
  final bool isLast;
  final Color connectorColor;
  final Color currentFill;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final titleStyle = entry.isCurrent
        ? theme.textTheme.titleSmall
        : theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(entry.title, style: titleStyle),
        if (entry.detail != null) ...[
          const SizedBox(height: DaisthSpacing.xxs),
          Text(
            entry.detail!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: entry.isCurrent ? colors.primary : colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    final row = Padding(
      padding: EdgeInsets.zero,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: entry.isCurrent ? currentFill : Colors.transparent,
          borderRadius: BorderRadius.circular(DaisthRadius.medium),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: DaisthSpacing.xs,
          vertical: entry.isCurrent ? DaisthSpacing.xs : 0,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 52,
                child: Padding(
                  padding: const EdgeInsets.only(top: 11),
                  child: Text(
                    entry.time,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: entry.isCurrent
                          ? colors.primary
                          : colors.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 26,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    DaisthStatusIndicator(
                      status: entry.status,
                      size: entry.isCurrent ? 22 : 18,
                      isCurrent: entry.isCurrent,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 1,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          color: connectorColor,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: DaisthSpacing.sm),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: entry.isCurrent ? 0 : 13),
                  child: entry.isCurrent
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DaisthSpacing.md,
                            vertical: DaisthSpacing.sm,
                          ),
                          child: content,
                        )
                      : Padding(
                          padding: const EdgeInsets.only(top: 9),
                          child: content,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (onTap == null) return row;
    return Semantics(
      button: true,
      label: 'Buka detail ${entry.title}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DaisthRadius.medium),
          child: row,
        ),
      ),
    );
  }
}
