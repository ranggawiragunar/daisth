import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../core/design_system/components/istiqam_surface.dart';
import '../../../../core/design_system/theme/istiqam_theme_extension.dart';
import '../../../../core/design_system/tokens/istiqam_radius.dart';
import '../../../../core/design_system/tokens/istiqam_spacing.dart';

class RoutineLinkItem {
  const RoutineLinkItem({
    required this.title,
    required this.subtitle,
    this.meta,
    this.readerContentId,
    this.actionId,
    this.icon = PhosphorIconsRegular.bookOpenText,
    this.isActionAvailable = true,
  });

  final String title;
  final String subtitle;
  final String? meta;
  final String? readerContentId;
  final String? actionId;
  final IconData icon;
  final bool isActionAvailable;
}

class RoutineGuidanceSection extends StatelessWidget {
  const RoutineGuidanceSection({
    required this.items,
    required this.onTap,
    super.key,
  });

  final List<RoutineLinkItem> items;
  final ValueChanged<RoutineLinkItem> onTap;

  @override
  Widget build(BuildContext context) => _RoutineLinkSection(
    title: 'Guidance & Readings',
    items: items,
    onTap: onTap,
  );
}

class RoutineHelpfulActions extends StatelessWidget {
  const RoutineHelpfulActions({
    required this.onTap,
    required this.prayerCompleted,
    required this.dhikrCompleted,
    super.key,
  });

  final ValueChanged<RoutineLinkItem> onTap;
  final bool prayerCompleted;
  final bool dhikrCompleted;

  @override
  Widget build(BuildContext context) => _RoutineLinkSection(
    title: 'Helpful Actions',
    items: [
      const RoutineLinkItem(
        actionId: 'nearby-mosque',
        title: 'Nearby Mosque',
        subtitle: 'Find a place to pray nearby',
        icon: PhosphorIconsRegular.mapPin,
      ),
      RoutineLinkItem(
        title: 'Post-Prayer Dhikr',
        subtitle: dhikrCompleted
            ? 'Dzikir sudah tercatat'
            : prayerCompleted
            ? 'Mulai dzikir setelah sholat'
            : 'Available after prayer',
        icon: PhosphorIconsRegular.handsPraying,
        isActionAvailable: prayerCompleted,
      ),
    ],
    onTap: onTap,
  );
}

class _RoutineLinkSection extends StatelessWidget {
  const _RoutineLinkSection({
    required this.title,
    required this.items,
    required this.onTap,
  });

  final String title;
  final List<RoutineLinkItem> items;
  final ValueChanged<RoutineLinkItem> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<IstiqamThemeExtension>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: IstiqamSpacing.md),
        IstiqamSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                _RoutineLinkTile(
                  key: ValueKey('routine-link-${items[index].title}'),
                  item: items[index],
                  onTap: () => onTap(items[index]),
                ),
                if (index < items.length - 1)
                  Divider(
                    height: 1,
                    indent: 58,
                    endIndent: IstiqamSpacing.md,
                    color: extension.divider,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RoutineLinkTile extends StatelessWidget {
  const _RoutineLinkTile({required this.item, required this.onTap, super.key});

  final RoutineLinkItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      label: '${item.title}. ${item.subtitle}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(IstiqamRadius.large),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: IstiqamSpacing.md,
              vertical: IstiqamSpacing.sm,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  height: 40,
                  child: Icon(
                    item.icon,
                    size: 19,
                    color: item.isActionAvailable
                        ? theme.colorScheme.primary
                        : secondary,
                  ),
                ),
                const SizedBox(width: IstiqamSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: item.isActionAvailable
                              ? theme.colorScheme.onSurface
                              : secondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.meta != null) ...[
                  const SizedBox(width: IstiqamSpacing.xs),
                  Text(
                    item.meta!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: secondary,
                    ),
                  ),
                ],
                const SizedBox(width: IstiqamSpacing.xs),
                Icon(
                  PhosphorIconsRegular.caretRight,
                  size: 16,
                  color: secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
