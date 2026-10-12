import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/istiqam_spacing.dart';

class HistoryPlaceholderScreen extends StatelessWidget {
  const HistoryPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) => const _PlaceholderScreen(
    icon: Icons.history_rounded,
    title: 'History',
    description: 'Your routine history will appear here.',
  );
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

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
              Icon(icon, color: colors.primary, size: 32),
              const SizedBox(height: IstiqamSpacing.lg),
              Text(title, style: textTheme.titleLarge),
              const SizedBox(height: IstiqamSpacing.sm),
              Text(
                description,
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
