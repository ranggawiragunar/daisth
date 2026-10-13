import 'package:flutter/material.dart';

import '../../../../core/design_system/components/istiqam_segmented_progress.dart';
import '../../../../core/design_system/tokens/istiqam_spacing.dart';

class DailyProgress extends StatelessWidget {
  const DailyProgress({required this.recordedCount, super.key});

  final int recordedCount;
  static const total = 7;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Today', style: theme.textTheme.titleMedium),
        const SizedBox(height: IstiqamSpacing.xs),
        Text(
          '$recordedCount of $total routines recorded',
          style: theme.textTheme.bodySmall?.copyWith(color: secondary),
        ),
        const SizedBox(height: IstiqamSpacing.md),
        IstiqamSegmentedProgress(completed: recordedCount, total: total),
      ],
    );
  }
}
