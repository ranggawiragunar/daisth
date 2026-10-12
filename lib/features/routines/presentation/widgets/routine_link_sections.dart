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
    this.icon = PhosphorIconsRegular.bookOpenText,
  });

  final String title;
  final String subtitle;
  final String? meta;
  final IconData icon;
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
  const RoutineHelpfulActions({required this.onTap, super.key});

  final ValueChanged<RoutineLinkItem> onTap;

  @override
  Widget build(BuildContext context) => _RoutineLinkSection(
    title: 'Helpful Actions',
    items: const [
      RoutineLinkItem(
        title: 'Nearby Mosque',
        subtitle: 'Find a place to pray nearby',
        icon: PhosphorIconsRegular.mapPin,
      ),
      RoutineLinkItem(
        title: 'Post-Prayer Dhikr',
        subtitle: 'Available after prayer',
        icon: PhosphorIconsRegular.handsPraying,
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
  const _RoutineLinkTile({required this.item, required this.onTap});

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
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: IstiqamSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: theme.textTheme.bodyMedium),
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
