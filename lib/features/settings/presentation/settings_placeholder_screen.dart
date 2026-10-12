import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/istiqam_spacing.dart';

class SettingsPlaceholderScreen extends StatelessWidget {
  const SettingsPlaceholderScreen({super.key});

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
              Icon(Icons.settings_outlined, color: colors.primary, size: 32),
              const SizedBox(height: IstiqamSpacing.lg),
              Text('Settings', style: textTheme.titleLarge),
              const SizedBox(height: IstiqamSpacing.sm),
              Text(
                'Settings will be available in a later update.',
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
