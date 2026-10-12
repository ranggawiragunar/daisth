import 'package:flutter/material.dart';

import '../../../../core/design_system/components/istiqam_progress_bar.dart';
import '../../../../core/design_system/tokens/istiqam_spacing.dart';

class DailyProgress extends StatelessWidget {
  const DailyProgress({super.key});

  static const recorded = 3;
  static const total = 7;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Today', style: textTheme.titleLarge),
        const SizedBox(height: IstiqamSpacing.xs),
        Text(
          '$recorded of $total routines recorded',
          style: textTheme.bodyMedium?.copyWith(color: secondary),
        ),
        const SizedBox(height: IstiqamSpacing.md),
        const IstiqamProgressBar(value: recorded / total),
      ],
    );
  }
}
