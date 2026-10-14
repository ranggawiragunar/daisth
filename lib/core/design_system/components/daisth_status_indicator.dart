import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../theme/daisth_theme_extension.dart';
import '../../localization/daisth_localizations.dart';

class DaisthStatusIndicator extends StatelessWidget {
  const DaisthStatusIndicator({
    required this.status,
    this.size = 20,
    this.isCurrent = false,
    super.key,
  });

  final RoutineStatus status;
  final double size;
  final bool isCurrent;

  IconData get _icon => switch (status) {
    RoutineStatus.completed => PhosphorIconsFill.check,
    RoutineStatus.partial => PhosphorIconsRegular.minus,
    RoutineStatus.due => PhosphorIconsRegular.clockCountdown,
    RoutineStatus.upcoming => PhosphorIconsRegular.circle,
    RoutineStatus.unrecorded => PhosphorIconsRegular.circle,
    RoutineStatus.notToday => PhosphorIconsRegular.minusCircle,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.extension<DaisthThemeExtension>()!.statusColor(status);
    final filled = status == RoutineStatus.completed;
    final label = switch (status) {
      RoutineStatus.completed => DaisthLocalizations.text(
        context,
        id: 'Selesai',
        en: 'Completed',
      ),
      RoutineStatus.partial => DaisthLocalizations.text(
        context,
        id: 'Sebagian selesai',
        en: 'Partially completed',
      ),
      RoutineStatus.due => DaisthLocalizations.text(
        context,
        id: 'Waktunya sekarang',
        en: 'Due now',
      ),
      RoutineStatus.upcoming => DaisthLocalizations.text(
        context,
        id: 'Akan datang',
        en: 'Upcoming',
      ),
      RoutineStatus.unrecorded => DaisthLocalizations.text(
        context,
        id: 'Belum tercatat',
        en: 'Not recorded',
      ),
      RoutineStatus.notToday => DaisthLocalizations.text(
        context,
        id: 'Tidak dijadwalkan hari ini',
        en: 'Not scheduled today',
      ),
    };

    return Semantics(
      label: label,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: isCurrent
              ? Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 1.5),
                    color: theme.colorScheme.surface.withValues(alpha: 0.88),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: size * 0.34,
                    height: size * 0.34,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : filled
              ? Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _icon,
                    size: size * 0.64,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : Icon(_icon, size: size * 0.82, color: color),
        ),
      ),
    );
  }
}
