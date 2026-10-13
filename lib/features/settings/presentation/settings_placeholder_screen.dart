import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/design_system/components/daisth_surface.dart';
import '../../../core/design_system/theme/daisth_theme_extension.dart';
import '../../../core/design_system/tokens/daisth_radius.dart';
import '../../../core/design_system/tokens/daisth_spacing.dart';

class SettingsPlaceholderScreen extends StatelessWidget {
  const SettingsPlaceholderScreen({
    required this.themeMode,
    required this.onThemeModeChanged,
    this.bottomContentPadding = 0,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final double bottomContentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              DaisthSpacing.screenHorizontal,
              DaisthSpacing.xl,
              DaisthSpacing.screenHorizontal,
              bottomContentPadding + DaisthSpacing.xxl,
            ),
            children: [
              Text('Settings', style: theme.textTheme.headlineSmall),
              const SizedBox(height: DaisthSpacing.section),
              _AppearanceSelector(
                themeMode: themeMode,
                onChanged: onThemeModeChanged,
              ),
              const SizedBox(height: DaisthSpacing.section),
              _SettingsGroup(
                title: 'Prayer & Location',
                children: [
                  _SettingsDestination(
                    key: const ValueKey('settings-prayer-location'),
                    title: 'Prayer & Location',
                    subtitle: 'Jadwal, izin lokasi, dan zona waktu',
                    icon: Icons.location_on_outlined,
                    onTap: () =>
                        context.push(RoutePaths.settingsPrayerLocation),
                  ),
                ],
              ),
              _SettingsGroup(
                title: 'Notifications',
                children: [
                  _SettingsDestination(
                    key: const ValueKey('settings-notifications'),
                    title: 'Reminders & Reminder Health',
                    subtitle: 'Izin, waktu pengingat, dan status perangkat',
                    icon: Icons.notifications_none_rounded,
                    onTap: () => context.push(RoutePaths.settingsNotifications),
                  ),
                ],
              ),
              _SettingsGroup(
                title: 'Account & Sync',
                children: [
                  _SettingsDestination(
                    key: const ValueKey('settings-account'),
                    title: 'Account',
                    subtitle: 'Google Sign-In dan sinkronisasi opsional',
                    icon: Icons.person_outline_rounded,
                    onTap: () => context.push(RoutePaths.account),
                  ),
                ],
              ),
              _SettingsGroup(
                title: 'Data & Privacy',
                children: [
                  _SettingsDestination(
                    key: const ValueKey('settings-privacy'),
                    title: 'Data & Privacy',
                    subtitle: 'Penyimpanan lokal, sinkronisasi, dan lokasi',
                    icon: Icons.shield_outlined,
                    onTap: () => context.push(RoutePaths.settingsPrivacy),
                  ),
                ],
              ),
              _SettingsGroup(
                title: 'About',
                children: [
                  _SettingsDestination(
                    key: const ValueKey('settings-about'),
                    title: 'About Daisth',
                    subtitle: 'Tentang aplikasi dan lisensi sumber terbuka',
                    icon: Icons.info_outline_rounded,
                    onTap: () => context.push(RoutePaths.settingsAbout),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DaisthSpacing.section),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: DaisthSpacing.sm),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        DaisthSurface(
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: Column(children: children),
          ),
        ),
      ],
    ),
  );
}

class _SettingsDestination extends StatelessWidget {
  const _SettingsDestination({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: ListTile(
        minVerticalPadding: DaisthSpacing.md,
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _AppearanceSelector extends StatelessWidget {
  const _AppearanceSelector({required this.themeMode, required this.onChanged});

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;

  static const _options = [
    (ThemeMode.system, 'System', PhosphorIconsRegular.deviceMobile),
    (ThemeMode.light, 'Light', PhosphorIconsRegular.sun),
    (ThemeMode.dark, 'Dark', PhosphorIconsRegular.moon),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<DaisthThemeExtension>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Appearance', style: theme.textTheme.titleSmall),
        const SizedBox(height: DaisthSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: extension.softSurface,
            borderRadius: BorderRadius.circular(DaisthRadius.large),
            border: Border.all(color: extension.border),
          ),
          padding: const EdgeInsets.all(DaisthSpacing.xs),
          child: Row(
            children: [
              for (final option in _options)
                Expanded(
                  child: _AppearanceOption(
                    label: option.$2,
                    icon: option.$3,
                    selected: themeMode == option.$1,
                    onTap: () => onChanged(option.$1),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DaisthRadius.medium),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? theme.colorScheme.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(DaisthRadius.medium),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: foreground,
                      fontSize: 12,
                      height: 16 / 12,
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
