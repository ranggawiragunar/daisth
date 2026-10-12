import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/istiqam_spacing.dart';

class RoutinesPlaceholderScreen extends StatelessWidget {
  const RoutinesPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(IstiqamSpacing.section),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.checklist_rounded, color: colors.primary, size: 32),
              const SizedBox(height: IstiqamSpacing.lg),
              Text('Routines', style: textTheme.titleLarge),
              const SizedBox(height: IstiqamSpacing.sm),
              Text(
                'Your routines will be easier to manage here soon.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
