import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/daisth_spacing.dart';
import '../../../../core/localization/daisth_localizations.dart';

class DhikrSequenceProgress extends StatelessWidget {
  const DhikrSequenceProgress({
    required this.currentItemIndex,
    required this.completedItemCount,
    required this.itemCount,
    required this.isCompleted,
    super.key,
  });

  final int currentItemIndex;
  final int completedItemCount;
  final int itemCount;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isCompleted
              ? DaisthLocalizations.text(
                  context,
                  id: '$itemCount dari $itemCount bagian',
                  en: '$itemCount of $itemCount sections',
                )
              : DaisthLocalizations.text(
                  context,
                  id: 'Bagian ${currentItemIndex + 1} dari $itemCount',
                  en: 'Section ${currentItemIndex + 1} of $itemCount',
                ),
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: DaisthSpacing.sm),
        Row(
          children: [
            for (var index = 0; index < itemCount; index++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 4,
                  decoration: BoxDecoration(
                    color: index < completedItemCount || isCompleted
                        ? colors.primary
                        : index == currentItemIndex
                        ? colors.primary.withValues(alpha: 0.44)
                        : colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              if (index < itemCount - 1)
                const SizedBox(width: DaisthSpacing.xs),
            ],
          ],
        ),
      ],
    );
  }
}
