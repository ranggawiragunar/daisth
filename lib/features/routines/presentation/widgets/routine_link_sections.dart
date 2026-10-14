import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../core/design_system/components/daisth_surface.dart';
import '../../../../core/localization/daisth_terminology.dart';
import '../../../../core/localization/daisth_localizations.dart';
import '../../../../core/design_system/theme/daisth_theme_extension.dart';
import '../../../../core/design_system/tokens/daisth_radius.dart';
import '../../../../core/design_system/tokens/daisth_spacing.dart';

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
    title: DaisthLocalizations.text(
      context,
      id: 'Panduan & Bacaan',
      en: 'Guidance & Readings',
    ),
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
  Widget build(BuildContext context) {
    return _RoutineLinkSection(
      title: DaisthLocalizations.text(
        context,
        id: 'Aksi Bermanfaat',
        en: 'Helpful Actions',
      ),
      items: [
        RoutineLinkItem(
          actionId: 'nearby-mosque',
          title: DaisthTerminology.nearbyPrayerPlacesTitle(
            Localizations.localeOf(context),
          ),
          subtitle: DaisthTerminology.nearbyPrayerPlacesSubtitle(
            Localizations.localeOf(context),
          ),
          icon: PhosphorIconsRegular.mapPin,
        ),
        RoutineLinkItem(
          title: DaisthTerminology.postPrayerZikirTitle(
            Localizations.localeOf(context),
          ),
          subtitle: dhikrCompleted
              ? DaisthLocalizations.text(
                  context,
                  id: 'Zikir sudah tercatat',
                  en: 'Zikir recorded',
                )
              : prayerCompleted
              ? DaisthLocalizations.text(
                  context,
                  id: 'Mulai Zikir setelah salat',
                  en: 'Start Zikir after prayer',
                )
              : DaisthLocalizations.text(
                  context,
                  id: 'Tersedia setelah salat',
                  en: 'Available after prayer',
                ),
          icon: PhosphorIconsRegular.handsPraying,
          isActionAvailable: prayerCompleted,
        ),
      ],
      onTap: onTap,
    );
  }
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
    final extension = theme.extension<DaisthThemeExtension>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: DaisthSpacing.md),
        DaisthSurface(
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
                    endIndent: DaisthSpacing.md,
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
          borderRadius: BorderRadius.circular(DaisthRadius.large),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DaisthSpacing.md,
              vertical: DaisthSpacing.sm,
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
                const SizedBox(width: DaisthSpacing.sm),
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
                  const SizedBox(width: DaisthSpacing.xs),
                  Text(
                    item.meta!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: secondary,
                    ),
                  ),
                ],
                const SizedBox(width: DaisthSpacing.xs),
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
