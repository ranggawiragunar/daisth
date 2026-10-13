import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../core/design_system/components/daisth_surface.dart';
import '../../../../core/design_system/theme/daisth_theme_extension.dart';
import '../../../../core/design_system/tokens/daisth_radius.dart';
import '../../../../core/design_system/tokens/daisth_spacing.dart';
import '../../domain/models/routine_step.dart';

class RoutineStepsCard extends StatelessWidget {
  const RoutineStepsCard({
    required this.steps,
    required this.onToggle,
    required this.onOpenStep,
    super.key,
  });

  final List<RoutineStep> steps;
  final ValueChanged<String> onToggle;
  final ValueChanged<RoutineStep> onOpenStep;

  @override
  Widget build(BuildContext context) {
    final extension = Theme.of(context).extension<DaisthThemeExtension>()!;
    return DaisthSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            _RoutineStepTile(
              step: steps[index],
              onToggle: () => onToggle(steps[index].id),
              onOpen: steps[index].hasGuidance
                  ? () => onOpenStep(steps[index])
                  : null,
            ),
            if (index < steps.length - 1)
              Divider(
                height: 1,
                indent: 60,
                endIndent: DaisthSpacing.md,
                color: extension.divider,
              ),
          ],
        ],
      ),
    );
  }
}

class _RoutineStepTile extends StatelessWidget {
  const _RoutineStepTile({
    required this.step,
    required this.onToggle,
    required this.onOpen,
  });

  final RoutineStep step;
  final VoidCallback onToggle;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelColor = theme.colorScheme.onSurfaceVariant;
    final badge = step.badge ?? (step.isRequired ? null : 'Optional');
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 68),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DaisthSpacing.md),
        child: Row(
          children: [
            Semantics(
              key: ValueKey('routine-step-toggle-${step.id}'),
              button: true,
              checked: step.completed,
              label:
                  '${step.title}, ${step.completed ? 'completed' : 'not completed'}',
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(DaisthRadius.pill),
                child: SizedBox(
                  width: 44,
                  height: 56,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: step.completed
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: step.completed
                              ? theme.colorScheme.primary
                              : labelColor.withValues(alpha: 0.55),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: step.completed
                          ? Icon(
                              PhosphorIconsBold.check,
                              color: theme.colorScheme.onPrimary,
                              size: 13,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: onOpen,
                canRequestFocus: onOpen != null,
                borderRadius: BorderRadius.circular(DaisthRadius.medium),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: step.completed
                                    ? labelColor
                                    : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: DaisthSpacing.xs,
                              runSpacing: DaisthSpacing.xxs,
                              children: [
                                Text(
                                  step.subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: labelColor,
                                  ),
                                ),
                                if (badge != null) _StepBadge(label: badge),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (onOpen != null) ...[
                        const SizedBox(width: DaisthSpacing.xs),
                        Icon(
                          PhosphorIconsRegular.caretRight,
                          size: 16,
                          color: labelColor,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(DaisthRadius.pill),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontSize: 10,
        ),
      ),
    );
  }
}
