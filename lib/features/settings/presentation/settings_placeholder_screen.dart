import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/design_system/components/istiqam_empty_state.dart';
import '../../../core/design_system/theme/istiqam_theme_extension.dart';
import '../../../core/design_system/tokens/istiqam_radius.dart';
import '../../../core/design_system/tokens/istiqam_spacing.dart';

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
    return IstiqamEmptyState(
      imageAsset: 'assets/empty_states/empty_settings_2048.png',
      title: 'Pengaturan segera hadir',
      description:
          'Lokasi, reminder, tampilan, dan preferensi lainnya akan tersedia di sini.',
      bottomContentPadding: bottomContentPadding,
      footer: _AppearanceSelector(
        themeMode: themeMode,
        onChanged: onThemeModeChanged,
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
    final extension = theme.extension<IstiqamThemeExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Appearance', style: theme.textTheme.titleSmall),
        const SizedBox(height: IstiqamSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: extension.softSurface,
            borderRadius: BorderRadius.circular(IstiqamRadius.large),
            border: Border.all(color: extension.border),
          ),
          padding: const EdgeInsets.all(IstiqamSpacing.xs),
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
          borderRadius: BorderRadius.circular(IstiqamRadius.medium),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? theme.colorScheme.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(IstiqamRadius.medium),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: theme.brightness == Brightness.dark
                              ? 0.14
                              : 0.035,
                        ),
                        blurRadius: 7,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
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
