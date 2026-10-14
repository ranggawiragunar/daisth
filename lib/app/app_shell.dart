import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../core/design_system/components/daisth_notice_controller.dart';
import '../core/design_system/tokens/daisth_radius.dart';
import '../core/design_system/tokens/daisth_spacing.dart';
import '../core/design_system/theme/daisth_theme_extension.dart';
import '../core/localization/daisth_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  static const contentBottomPadding = 92.0;

  final StatefulNavigationShell navigationShell;
  static const _destinations = [
    _Destination(
      'Today',
      'Hari Ini',
      PhosphorIconsRegular.house,
      PhosphorIconsFill.house,
    ),
    _Destination(
      'History',
      'Riwayat',
      PhosphorIconsRegular.chartBar,
      PhosphorIconsFill.chartBar,
    ),
    _Destination(
      'Routines',
      'Rutinitas',
      PhosphorIconsRegular.calendarCheck,
      PhosphorIconsFill.calendarCheck,
    ),
    _Destination(
      'Settings',
      'Pengaturan',
      PhosphorIconsRegular.gear,
      PhosphorIconsFill.gear,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<DaisthThemeExtension>()!;
    const dockHeight = 68.0;
    const dockBottomGap = 8.0;
    const dockHorizontalMargin = 14.0;
    final noticeBottomInset =
        MediaQuery.paddingOf(context).bottom + dockBottomGap + dockHeight + 16;
    return Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DaisthNoticeAnchor(
            bottomInset: noticeBottomInset,
            child: navigationShell,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  dockHorizontalMargin,
                  0,
                  dockHorizontalMargin,
                  dockBottomGap,
                ),
                child: Container(
                  height: dockHeight,
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? extension.softSurface
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(
                      DaisthRadius.xLarge + 4,
                    ),
                    border: Border.all(color: extension.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: theme.brightness == Brightness.dark
                              ? 0.22
                              : 0.075,
                        ),
                        blurRadius: 22,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(DaisthSpacing.xs),
                  child: Row(
                    children: [
                      for (var index = 0; index < _destinations.length; index++)
                        Expanded(
                          child: _NavigationItem(
                            key: ValueKey(
                              'navigation-${_destinations[index].enLabel.toLowerCase()}',
                            ),
                            destination: _destinations[index],
                            selected: navigationShell.currentIndex == index,
                            onTap: () => navigationShell.goBranch(
                              index,
                              initialLocation:
                                  index == navigationShell.currentIndex,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination(this.enLabel, this.idLabel, this.icon, this.selectedIcon);

  final String enLabel;
  final String idLabel;
  final IconData icon;
  final IconData selectedIcon;
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = DaisthLocalizations.text(
      context,
      id: destination.idLabel,
      en: destination.enLabel,
    );
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DaisthRadius.large),
        child: SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  key: ValueKey(
                    'navigation-icon-${destination.enLabel.toLowerCase()}',
                  ),
                  color: color,
                  size: 20,
                ),
                const SizedBox(height: 3),
                AnimatedContainer(
                  key: ValueKey(
                    'navigation-label-${destination.enLabel.toLowerCase()}',
                  ),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(DaisthRadius.pill),
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
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
