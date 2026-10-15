import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/design_system/assets/daisth_assets.dart';
import '../../../core/design_system/components/daisth_feature_visual.dart';
import '../../../core/design_system/components/daisth_surface.dart';
import '../../../core/design_system/theme/daisth_theme_extension.dart';
import '../../../core/design_system/tokens/daisth_radius.dart';
import '../../../core/design_system/tokens/daisth_spacing.dart';
import '../../../core/app_settings/domain/models/app_settings.dart';
import '../../../core/localization/daisth_localizations.dart';

class SettingsPlaceholderScreen extends StatelessWidget {
  const SettingsPlaceholderScreen({
    required this.themeMode,
    required this.onThemeModeChanged,
    this.languagePreference = AppLanguagePreference.system,
    this.onLanguagePreferenceChanged,
    this.bottomContentPadding = 0,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final AppLanguagePreference languagePreference;
  final ValueChanged<AppLanguagePreference>? onLanguagePreferenceChanged;
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DaisthLocalizations.text(
                        context,
                        id: 'Pengaturan',
                        en: 'Settings',
                      ),
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  const DaisthFeatureVisual(
                    asset: DaisthAssets.settingsMain,
                    height: 42,
                    width: 64,
                  ),
                ],
              ),
              const SizedBox(height: DaisthSpacing.section),
              _AppearanceSelector(
                themeMode: themeMode,
                onChanged: onThemeModeChanged,
              ),
              const SizedBox(height: DaisthSpacing.section),
              _LanguageSelector(
                preference: languagePreference,
                onChanged: onLanguagePreferenceChanged,
              ),
              const SizedBox(height: DaisthSpacing.section),
              _SettingsGroup(
                title: DaisthLocalizations.text(
                  context,
                  id: 'Waktu Salat & Lokasi',
                  en: 'Prayer & Location',
                ),
                children: [
                  _SettingsDestination(
                    key: const ValueKey('settings-prayer-location'),
                    title: DaisthLocalizations.text(
                      context,
                      id: 'Waktu Salat & Lokasi',
                      en: 'Prayer & Location',
                    ),
                    subtitle: DaisthLocalizations.text(
                      context,
                      id: 'Jadwal, izin lokasi, dan zona waktu',
                      en: 'Schedule, location access, and timezone',
                    ),
                    icon: PhosphorIconsRegular.mapPin,
                    onTap: () =>
                        context.push(RoutePaths.settingsPrayerLocation),
                  ),
                ],
              ),
              _SettingsGroup(
                title: DaisthLocalizations.text(
                  context,
                  id: 'Notifikasi',
                  en: 'Notifications',
                ),
                children: [
                  _SettingsDestination(
                    key: const ValueKey('settings-notifications'),
                    title: DaisthLocalizations.text(
                      context,
                      id: 'Pengingat & Kesehatan Pengingat',
                      en: 'Reminders & Reminder Health',
                    ),
                    subtitle: DaisthLocalizations.text(
                      context,
                      id: 'Izin, waktu pengingat, dan status perangkat',
                      en: 'Permissions, reminder times, and device status',
                    ),
                    icon: PhosphorIconsRegular.bellSimple,
                    onTap: () => context.push(RoutePaths.settingsNotifications),
                  ),
                ],
              ),
              _SettingsGroup(
                title: DaisthLocalizations.text(
                  context,
                  id: 'Akun & Sinkronisasi',
                  en: 'Account & Sync',
                ),
                children: [
                  _SettingsDestination(
                    key: const ValueKey('settings-account'),
                    title: DaisthLocalizations.text(
                      context,
                      id: 'Akun',
                      en: 'Account',
                    ),
                    subtitle: DaisthLocalizations.text(
                      context,
                      id: 'Google Sign-In dan sinkronisasi opsional',
                      en: 'Google Sign-In and optional sync',
                    ),
                    icon: PhosphorIconsRegular.user,
                    onTap: () => context.push(RoutePaths.account),
                  ),
                ],
              ),
              _SettingsGroup(
                title: DaisthLocalizations.text(
                  context,
                  id: 'Data & Privasi',
                  en: 'Data & Privacy',
                ),
                children: [
                  _SettingsDestination(
                    key: const ValueKey('settings-privacy'),
                    title: DaisthLocalizations.text(
                      context,
                      id: 'Data & Privasi',
                      en: 'Data & Privacy',
                    ),
                    subtitle: DaisthLocalizations.text(
                      context,
                      id: 'Penyimpanan lokal, sinkronisasi, dan lokasi',
                      en: 'Local storage, sync, and location',
                    ),
                    icon: PhosphorIconsRegular.shieldCheck,
                    onTap: () => context.push(RoutePaths.settingsPrivacy),
                  ),
                ],
              ),
              _SettingsGroup(
                title: DaisthLocalizations.text(
                  context,
                  id: 'Tentang',
                  en: 'About',
                ),
                children: [
                  _SettingsDestination(
                    key: const ValueKey('settings-about'),
                    title: DaisthLocalizations.text(
                      context,
                      id: 'Tentang Daisth',
                      en: 'About Daisth',
                    ),
                    subtitle: DaisthLocalizations.text(
                      context,
                      id: 'Informasi aplikasi dan lisensi sumber terbuka',
                      en: 'App information and open-source licenses',
                    ),
                    icon: PhosphorIconsRegular.info,
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
        trailing: const Icon(PhosphorIconsRegular.caretRight),
        onTap: onTap,
      ),
    );
  }
}

class _AppearanceSelector extends StatelessWidget {
  const _AppearanceSelector({required this.themeMode, required this.onChanged});

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<DaisthThemeExtension>()!;
    final options = [
      (
        ThemeMode.system,
        DaisthLocalizations.text(context, id: 'Sistem', en: 'System'),
        PhosphorIconsRegular.deviceMobile,
      ),
      (
        ThemeMode.light,
        DaisthLocalizations.text(context, id: 'Terang', en: 'Light'),
        PhosphorIconsRegular.sun,
      ),
      (
        ThemeMode.dark,
        DaisthLocalizations.text(context, id: 'Gelap', en: 'Dark'),
        PhosphorIconsRegular.moon,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          DaisthLocalizations.text(context, id: 'Tampilan', en: 'Appearance'),
          style: theme.textTheme.titleSmall,
        ),
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
              for (final option in options)
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

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.preference, required this.onChanged});

  final AppLanguagePreference preference;
  final ValueChanged<AppLanguagePreference>? onChanged;

  String _optionLabel(BuildContext context, AppLanguagePreference option) =>
      switch (option) {
        AppLanguagePreference.system => DaisthLocalizations.text(
          context,
          id: 'Ikuti Sistem',
          en: 'System Default',
        ),
        AppLanguagePreference.indonesian => 'Indonesia',
        AppLanguagePreference.english => 'English',
      };

  String _optionDescription(
    BuildContext context,
    AppLanguagePreference option,
  ) => switch (option) {
    AppLanguagePreference.system => DaisthLocalizations.text(
      context,
      id: 'Gunakan bahasa perangkat',
      en: 'Use your device language',
    ),
    AppLanguagePreference.indonesian => DaisthLocalizations.text(
      context,
      id: 'Gunakan Bahasa Indonesia',
      en: 'Use Indonesian',
    ),
    AppLanguagePreference.english => DaisthLocalizations.text(
      context,
      id: 'Gunakan Bahasa Inggris',
      en: 'Use English',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final label = _optionLabel(context, preference);
    return DaisthSurface(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          key: const ValueKey('settings-language'),
          minVerticalPadding: DaisthSpacing.md,
          title: Text(
            DaisthLocalizations.text(context, id: 'Bahasa', en: 'Language'),
          ),
          subtitle: Text(label),
          trailing: const Icon(PhosphorIconsRegular.caretRight),
          onTap: () => _showPicker(context),
        ),
      ),
    );
  }

  Future<void> _showPicker(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DaisthSpacing.screenHorizontal,
          DaisthSpacing.sm,
          DaisthSpacing.screenHorizontal,
          DaisthSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              DaisthLocalizations.text(
                sheetContext,
                id: 'Pilih bahasa',
                en: 'Choose language',
              ),
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            const SizedBox(height: DaisthSpacing.sm),
            for (final option in AppLanguagePreference.values)
              Semantics(
                button: true,
                selected: preference == option,
                label:
                    '${_optionLabel(sheetContext, option)}. '
                    '${_optionDescription(sheetContext, option)}',
                child: ListTile(
                  key: ValueKey('language-option-${option.name}'),
                  minVerticalPadding: DaisthSpacing.sm,
                  title: Text(_optionLabel(sheetContext, option)),
                  subtitle: Text(_optionDescription(sheetContext, option)),
                  trailing: preference == option
                      ? Icon(
                          PhosphorIconsRegular.checkCircle,
                          color: Theme.of(sheetContext).colorScheme.primary,
                        )
                      : const Icon(PhosphorIconsRegular.circle),
                  onTap: () {
                    onChanged?.call(option);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
