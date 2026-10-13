import 'package:flutter/material.dart';

import '../theme/daisth_theme_extension.dart';
import '../tokens/daisth_radius.dart';
import '../tokens/daisth_spacing.dart';

class DaisthSegmentedProgress extends StatelessWidget {
  const DaisthSegmentedProgress({
    required this.completed,
    required this.total,
    this.height = 5,
    super.key,
  }) : assert(total > 0),
       assert(completed >= 0 && completed <= total);

  final int completed;
  final int total;
  final double height;

  @override
  Widget build(BuildContext context) {
    final extension = Theme.of(context).extension<DaisthThemeExtension>()!;
    final colors = Theme.of(context).colorScheme;
    final remainder = Theme.of(context).brightness == Brightness.dark
        ? colors.onSurface.withValues(alpha: 0.14)
        : extension.border;
    return Semantics(
      label: '$completed of $total routines recorded',
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var index = 0; index < total; index++) ...[
              if (index > 0) const SizedBox(width: DaisthSpacing.sm),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  height: height,
                  decoration: BoxDecoration(
                    color: index < completed ? colors.primary : remainder,
                    borderRadius: BorderRadius.circular(DaisthRadius.pill),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
