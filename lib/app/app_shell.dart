import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../core/design_system/tokens/istiqam_radius.dart';
import '../features/history/presentation/history_placeholder_screen.dart';
import '../features/routines/presentation/routines_placeholder_screen.dart';
import '../features/settings/presentation/settings_placeholder_screen.dart';
import '../features/today/presentation/today_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _screens = [
    TodayScreen(),
    HistoryPlaceholderScreen(),
    RoutinesPlaceholderScreen(),
    SettingsPlaceholderScreen(),
  ];

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

  void _select(int index) {
    if (index == _selectedIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
          child: Row(
            children: [
              for (var index = 0; index < _destinations.length; index++)
                Expanded(
                  child: _NavigationItem(
                    destination: _destinations[index],
                    selected: _selectedIndex == index,
                    onTap: () => _select(index),
                  ),
                ),
            ],
          ),
        ),
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
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 42,
                height: 30,
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.76,
                        )
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(IstiqamRadius.medium),
                ),
                alignment: Alignment.center,
                child: Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
