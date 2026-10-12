import 'package:flutter/material.dart';

import '../../../../core/design_system/components/istiqam_status_indicator.dart';
import '../../../../core/design_system/theme/istiqam_theme_extension.dart';
import '../../../../core/design_system/tokens/istiqam_spacing.dart';

class _RoutineEntry {
  const _RoutineEntry({
    required this.time,
    required this.title,
    required this.status,
    this.detail,
    this.isNext = false,
  });

  final String time;
  final String title;
  final RoutineStatus status;
  final String? detail;
  final bool isNext;
}

class RoutineTimeline extends StatelessWidget {
  const RoutineTimeline({super.key});

  static const _entries = [
    _RoutineEntry(
      time: '03:00',
      title: 'Sholat Malam',
      status: RoutineStatus.completed,
      detail: 'Completed · 03:38',
    ),
    _RoutineEntry(
      time: '04:31',
      title: 'Sholat Subuh',
      status: RoutineStatus.completed,
      detail: 'Completed · 04:52',
    ),
    _RoutineEntry(
      time: '07:00',
      title: 'Sholat Dhuha',
      status: RoutineStatus.completed,
      detail: 'Completed · 07:19',
    ),
    _RoutineEntry(
      time: '11:47',
      title: 'Sholat Zuhur',
      status: RoutineStatus.upcoming,
      detail: 'Next routine',
      isNext: true,
    ),
    _RoutineEntry(
      time: '15:08',
      title: 'Sholat Asar',
      status: RoutineStatus.upcoming,
    ),
    _RoutineEntry(
      time: '17:52',
      title: 'Sholat Maghrib',
      status: RoutineStatus.upcoming,
    ),
    _RoutineEntry(
      time: '19:01',
      title: 'Sholat Isya',
      status: RoutineStatus.upcoming,
    ),
    _RoutineEntry(
      time: '20:30',
      title: 'Daily Reflection',
      status: RoutineStatus.upcoming,
    ),
    _RoutineEntry(
      time: '21:00',
      title: 'Penutup Hari',
      status: RoutineStatus.upcoming,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final extension = Theme.of(context).extension<IstiqamThemeExtension>()!;
    return Column(
      children: [
        for (var index = 0; index < _entries.length; index++)
          _TimelineRow(
            entry: _entries[index],
            isLast: index == _entries.length - 1,
            connectorColor: extension.divider,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.entry,
    required this.isLast,
    required this.connectorColor,
  });

  final _RoutineEntry entry;
  final bool isLast;
  final Color connectorColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = entry.isNext
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final titleStyle = entry.isNext
        ? theme.textTheme.titleSmall
        : theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: IstiqamSpacing.xs),
              child: Text(
                entry.time,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: entry.isNext
                      ? color
                      : theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: Column(
              children: [
                IstiqamStatusIndicator(
                  status: entry.status,
                  size: entry.isNext ? 20 : 18,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: connectorColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: IstiqamSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: IstiqamSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title, style: titleStyle),
                  if (entry.detail != null) ...[
                    const SizedBox(height: IstiqamSpacing.xxs),
                    Text(
                      entry.detail!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: entry.status == RoutineStatus.completed
                            ? theme.colorScheme.onSurfaceVariant
                            : color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
