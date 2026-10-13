import 'package:flutter/material.dart';

import '../../../../core/design_system/components/daisth_segmented_progress.dart';
import '../../../../core/design_system/tokens/daisth_spacing.dart';

class DailyProgress extends StatelessWidget {
  const DailyProgress({
    required this.recordedCount,
    this.total = defaultTotal,
    super.key,
  });

  final int recordedCount;
  final int total;
  static const defaultTotal = 7;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Today', style: theme.textTheme.titleMedium),
        const SizedBox(height: DaisthSpacing.xs),
        Text(
          '$recordedCount of $total routines recorded',
          style: theme.textTheme.bodySmall?.copyWith(color: secondary),
        ),
        if (total > 0) ...[
          const SizedBox(height: DaisthSpacing.md),
          DaisthSegmentedProgress(
            completed: recordedCount.clamp(0, total),
            total: total,
          ),
        ],
      ],
    );
  }
}
