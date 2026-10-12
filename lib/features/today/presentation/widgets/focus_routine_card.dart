import 'package:flutter/material.dart';

import '../../../../core/design_system/components/istiqam_button.dart';
import '../../../../core/design_system/components/istiqam_surface.dart';
import '../../../../core/design_system/tokens/istiqam_spacing.dart';

class FocusRoutineCard extends StatelessWidget {
  const FocusRoutineCard({super.key});

  void _openRoutine(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Routine details are coming soon.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return IstiqamSurface(
      style: IstiqamSurfaceStyle.softPrimary,
      radius: 20,
      padding: const EdgeInsets.all(IstiqamSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wb_sunny_outlined, size: 16, color: colors.primary),
              const SizedBox(width: IstiqamSpacing.sm),
              Text(
                'NEXT ROUTINE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                '11:47',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: IstiqamSpacing.lg),
          Text('Sholat Zuhur', style: theme.textTheme.titleLarge),
          const SizedBox(height: IstiqamSpacing.xs),
          Text(
            'Starts in 12 minutes',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: IstiqamSpacing.xl),
          IstiqamButton(
            label: 'Open Routine',
            onPressed: () => _openRoutine(context),
            compact: true,
            icon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }
}
