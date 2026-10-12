import 'package:flutter/material.dart';

import '../../../../core/design_system/theme/istiqam_theme_extension.dart';
import '../../../../core/design_system/tokens/istiqam_radius.dart';
import '../../../../core/design_system/tokens/istiqam_spacing.dart';
import '../../domain/models/dhikr_item.dart';

class DhikrCountSurface extends StatelessWidget {
  const DhikrCountSurface({
    required this.item,
    required this.count,
    required this.onTap,
    super.key,
  });

  final DhikrItem item;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<IstiqamThemeExtension>()!;
    return Semantics(
      button: true,
      onTap: onTap,
      label:
          '${item.title}, $count dari ${item.targetCount}. Tap untuk menghitung',
      child: ExcludeSemantics(
        child: Material(
          color: extension.softSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(IstiqamRadius.xLarge),
            side: BorderSide(color: extension.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const ValueKey('dhikr-count-tap-surface'),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 188),
              child: Padding(
                padding: const EdgeInsets.all(IstiqamSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.96, end: 1).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: child,
                        ),
                      ),
                      child: Text(
                        '$count',
                        key: ValueKey('dhikr-count-$count'),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontSize: 48,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: IstiqamSpacing.xxs),
                    Text(
                      'dari ${item.targetCount}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: IstiqamSpacing.md),
                    Text(
                      'Tap untuk menghitung',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
