import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../core/design_system/components/istiqam_button.dart';
import '../../../../core/design_system/theme/istiqam_theme_extension.dart';
import '../../../../core/design_system/tokens/istiqam_colors.dart';
import '../../../../core/design_system/tokens/istiqam_radius.dart';
import '../../../../core/design_system/tokens/istiqam_spacing.dart';

class FocusRoutineCard extends StatelessWidget {
  const FocusRoutineCard({this.onOpenRoutine, super.key});

  final VoidCallback? onOpenRoutine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final extension = theme.extension<IstiqamThemeExtension>()!;
    final cardColor = extension.softSurface;
    final heroAsset = isDark
        ? 'assets/illustrations/today_hero_dark.png'
        : 'assets/illustrations/today_hero_light.png';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      builder: (context, opacity, child) => Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(0, 5 * (1 - opacity)),
          child: child,
        ),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(IstiqamRadius.xLarge),
          border: Border.all(color: extension.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.035),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                heroAsset,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0, 0.45, 1],
                    colors: isDark
                        ? [
                            cardColor.withValues(alpha: 0.98),
                            cardColor.withValues(alpha: 0.76),
                            cardColor.withValues(alpha: 0.08),
                          ]
                        : [
                            IstiqamColors.primary50.withValues(alpha: 0.99),
                            IstiqamColors.primary50.withValues(alpha: 0.84),
                            IstiqamColors.primary50.withValues(alpha: 0.04),
                          ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(IstiqamSpacing.xl),
              child: FractionallySizedBox(
                widthFactor: 0.84,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PhosphorIconsRegular.sunHorizon,
                          size: 16,
                          color: colors.primary,
                        ),
                        const SizedBox(width: IstiqamSpacing.sm),
                        Text(
                          'NEXT ROUTINE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.primary,
                            letterSpacing: 1.15,
                            fontWeight: FontWeight.w600,
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
                    const SizedBox(height: IstiqamSpacing.md),
                    Row(
                      children: [
                        Icon(
                          PhosphorIconsRegular.clock,
                          size: 16,
                          color: colors.primary,
                        ),
                        const SizedBox(width: IstiqamSpacing.sm),
                        Text(
                          '11:47',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colors.primary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: IstiqamSpacing.lg),
                    IstiqamButton(
                      label: 'Open Routine',
                      onPressed: onOpenRoutine,
                      compact: true,
                      icon: PhosphorIconsRegular.arrowRight,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
