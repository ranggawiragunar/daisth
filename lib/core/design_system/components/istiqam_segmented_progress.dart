import 'package:flutter/material.dart';

import '../theme/istiqam_theme_extension.dart';
import '../tokens/istiqam_radius.dart';
import '../tokens/istiqam_spacing.dart';

class IstiqamSegmentedProgress extends StatelessWidget {
  const IstiqamSegmentedProgress({
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
    final extension = Theme.of(context).extension<IstiqamThemeExtension>()!;
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
              if (index > 0) const SizedBox(width: IstiqamSpacing.sm),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  height: height,
                  decoration: BoxDecoration(
                    color: index < completed ? colors.primary : remainder,
                    borderRadius: BorderRadius.circular(IstiqamRadius.pill),
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
