import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../core/design_system/tokens/istiqam_radius.dart';
import '../core/design_system/tokens/istiqam_spacing.dart';
import '../core/design_system/theme/istiqam_theme_extension.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  static const contentBottomPadding = 92.0;

  final StatefulNavigationShell navigationShell;
  static const _destinations = [
    _Destination('Today', PhosphorIconsRegular.house, PhosphorIconsFill.house),
    _Destination(
      'History',
      PhosphorIconsRegular.chartBar,
      PhosphorIconsFill.chartBar,
    ),
    _Destination(
      'Routines',
      PhosphorIconsRegular.calendarCheck,
      PhosphorIconsFill.calendarCheck,
    ),
    _Destination('Settings', PhosphorIconsRegular.gear, PhosphorIconsFill.gear),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<IstiqamThemeExtension>()!;
    const dockHeight = 68.0;
    const dockBottomGap = 8.0;
    const dockHorizontalMargin = 14.0;
    return Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          navigationShell,
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
                      IstiqamRadius.xLarge + 4,
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
                  padding: const EdgeInsets.all(IstiqamSpacing.xs),
                  child: Row(
                    children: [
                      for (var index = 0; index < _destinations.length; index++)
                        Expanded(
                          child: _NavigationItem(
                            key: ValueKey(
                              'navigation-${_destinations[index].label.toLowerCase()}',
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
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
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
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(IstiqamRadius.large),
        child: SizedBox(
          height: 60,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(IstiqamRadius.large),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(height: 3),
                Text(
                  destination.label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
