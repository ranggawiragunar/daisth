import 'package:flutter/material.dart';

import '../theme/istiqam_theme_extension.dart';

class IstiqamStatusIndicator extends StatelessWidget {
  const IstiqamStatusIndicator({
    required this.status,
    this.size = 20,
    super.key,
  });

  final RoutineStatus status;
  final double size;

  IconData get _icon => switch (status) {
    RoutineStatus.completed => Icons.check_rounded,
    RoutineStatus.partial => Icons.remove_rounded,
    RoutineStatus.due => Icons.schedule_rounded,
    RoutineStatus.upcoming => Icons.circle_outlined,
    RoutineStatus.unrecorded => Icons.circle_outlined,
    RoutineStatus.notToday => Icons.remove_circle_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).extension<IstiqamThemeExtension>()!.statusColor(status);
    final filled = status == RoutineStatus.completed;
    return Semantics(
      label: switch (status) {
        RoutineStatus.completed => 'Completed',
        RoutineStatus.partial => 'Partially completed',
        RoutineStatus.due => 'Due now',
        RoutineStatus.upcoming => 'Upcoming',
        RoutineStatus.unrecorded => 'Not recorded',
        RoutineStatus.notToday => 'Not scheduled today',
      },
      child: Container(
        width: size,
        height: size,
        decoration: filled
            ? BoxDecoration(color: color, shape: BoxShape.circle)
            : null,
        alignment: Alignment.center,
        child: Icon(
          _icon,
          size: size * 0.72,
          color: filled ? Theme.of(context).colorScheme.onPrimary : color,
        ),
      ),
    );
  }
}
