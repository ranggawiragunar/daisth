import 'package:flutter/material.dart';

import '../../../core/design_system/theme/istiqam_theme_extension.dart';
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
    return SafeArea(
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
                  IstiqamSpacing.xl,
                  IstiqamSpacing.screenHorizontal,
                  IstiqamSpacing.massive,
                ),
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Assalamu'alaikum",
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: IstiqamSpacing.xxs),
                              Text(
                                'Monday, 12 October',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme
                                  .extension<IstiqamThemeExtension>()!
                                  .border,
                            ),
                          ),
                          child: Icon(
                            Icons.person_outline_rounded,
                            color: colors.onSurfaceVariant,
                            size: 21,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: IstiqamSpacing.section),
                    const DailyProgress(),
                    const SizedBox(height: IstiqamSpacing.xxl),
                    const FocusRoutineCard(),
                    const SizedBox(height: IstiqamSpacing.section),
                    Text("Today's Routine", style: theme.textTheme.titleMedium),
                    const SizedBox(height: IstiqamSpacing.xl),
                    const RoutineTimeline(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
