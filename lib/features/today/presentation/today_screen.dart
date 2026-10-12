import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/istiqam_colors.dart';
import '../../../core/design_system/tokens/istiqam_spacing.dart';
import 'widgets/daily_progress.dart';
import 'widgets/focus_routine_card.dart';
import 'widgets/routine_timeline.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ambience = theme.brightness == Brightness.dark
        ? IstiqamColors.darkPrimary.withValues(alpha: 0.09)
        : IstiqamColors.primary200.withValues(alpha: 0.28);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        gradient: RadialGradient(
          center: const Alignment(0.9, -1.0),
          radius: 1.15,
          colors: [
            ambience,
            theme.scaffoldBackgroundColor.withValues(alpha: 0),
          ],
        ),
      ),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: IstiqamSpacing.contentMaxWidth,
            ),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    IstiqamSpacing.screenHorizontal,
                    IstiqamSpacing.lg,
                    IstiqamSpacing.screenHorizontal,
                    IstiqamSpacing.massive,
                  ),
                  sliver: SliverList.list(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Assalamu'alaikum",
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: IstiqamSpacing.xxs),
                          Text(
                            'Monday, 12 October',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: IstiqamSpacing.xl),
                      const FocusRoutineCard(),
                      const SizedBox(height: IstiqamSpacing.xxl),
                      const DailyProgress(),
                      const SizedBox(height: IstiqamSpacing.section),
                      Text(
                        "Today's Routine",
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: IstiqamSpacing.lg),
                      const RoutineTimeline(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
