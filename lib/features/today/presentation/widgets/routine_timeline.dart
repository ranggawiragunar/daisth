import 'package:flutter/material.dart';

import '../../../../core/design_system/components/istiqam_status_indicator.dart';
import '../../../../core/design_system/theme/istiqam_theme_extension.dart'
    as design;
import '../../../../core/design_system/tokens/istiqam_radius.dart';
import '../../../../core/design_system/tokens/istiqam_spacing.dart';
import '../../../prayer_times/domain/models/prayer_day_schedule.dart';
import '../../../prayer_times/domain/models/prayer_name.dart';
import '../../../prayer_times/domain/models/prayer_period_state.dart';
import '../../../prayer_times/presentation/prayer_time_presentation.dart';

class _RoutineEntry {
  const _RoutineEntry({
    required this.time,
    required this.title,
    required this.status,
    this.detail,
    this.routineId,
    this.prayer,
    this.isCurrent = false,
    this.isEvening = false,
  });

  final String time;
  final String title;
  final design.RoutineStatus status;
  final String? detail;
  final String? routineId;
  final PrayerName? prayer;
  final bool isCurrent;
  final bool isEvening;
}

class RoutineTimeline extends StatelessWidget {
  const RoutineTimeline({
    required this.schedule,
    required this.period,
    this.onRoutineTap,
    super.key,
  });

  final PrayerDaySchedule? schedule;
  final PrayerPeriodState? period;
  final ValueChanged<String>? onRoutineTap;

  List<_RoutineEntry> _entries() {
    _RoutineEntry prayerEntry(PrayerName prayer) {
      final isFocused = period?.focusPrayer == prayer;
      return _RoutineEntry(
        time: schedule == null
            ? '--:--'
            : PrayerTimePresentation.time(schedule!.timeFor(prayer)),
        title: 'Sholat ${PrayerTimePresentation.label(prayer)}',
        routineId: PrayerTimePresentation.routineId(prayer),
        prayer: prayer,
        status: isFocused && period?.currentPrayer == prayer
            ? design.RoutineStatus.due
            : design.RoutineStatus.upcoming,
        detail: isFocused ? period?.focusLabel : null,
        isCurrent: isFocused,
      );
    }

    return [
      const _RoutineEntry(
        time: '03:00',
        title: 'Sholat Malam',
        routineId: 'sholat-malam',
        status: design.RoutineStatus.upcoming,
      ),
      prayerEntry(PrayerName.fajr),
      const _RoutineEntry(
        time: '07:00',
        title: 'Sholat Dhuha',
        routineId: 'dhuha',
        status: design.RoutineStatus.upcoming,
      ),
      prayerEntry(PrayerName.dhuhr),
      prayerEntry(PrayerName.asr),
      prayerEntry(PrayerName.maghrib),
      prayerEntry(PrayerName.isha),
      const _RoutineEntry(
        time: '20:30',
        title: 'Daily Reflection',
        status: design.RoutineStatus.upcoming,
        isEvening: true,
      ),
      const _RoutineEntry(
        time: '21:00',
        title: 'Penutup Hari',
        status: design.RoutineStatus.upcoming,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final extension = Theme.of(
      context,
    ).extension<design.IstiqamThemeExtension>()!;
    final entries = _entries();
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
          const SizedBox(height: IstiqamSpacing.xxs),
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
      padding: EdgeInsets.only(top: entry.isEvening ? IstiqamSpacing.md : 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: entry.isCurrent ? currentFill : Colors.transparent,
          borderRadius: BorderRadius.circular(IstiqamRadius.medium),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: IstiqamSpacing.xs,
          vertical: entry.isCurrent ? IstiqamSpacing.xs : 0,
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
                    IstiqamStatusIndicator(
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
              const SizedBox(width: IstiqamSpacing.sm),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: entry.isCurrent ? 0 : 13),
                  child: entry.isCurrent
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: IstiqamSpacing.md,
                            vertical: IstiqamSpacing.sm,
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
          borderRadius: BorderRadius.circular(IstiqamRadius.medium),
          child: row,
        ),
      ),
    );
  }
}
