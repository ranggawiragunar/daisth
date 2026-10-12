import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/design_system/components/istiqam_surface.dart';
import '../../../core/design_system/theme/istiqam_theme_extension.dart';
import '../../../core/design_system/tokens/istiqam_radius.dart';
import '../../../core/design_system/tokens/istiqam_spacing.dart';
import '../../../core/location/domain/models/location_access_status.dart';
import '../../prayer_times/presentation/prayer_schedule_session.dart';
import '../../prayer_times/presentation/prayer_time_presentation.dart';

class SettingsPlaceholderScreen extends StatefulWidget {
  const SettingsPlaceholderScreen({
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.prayerScheduleSession,
    this.bottomContentPadding = 0,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final PrayerScheduleSession prayerScheduleSession;
  final double bottomContentPadding;

  @override
  State<SettingsPlaceholderScreen> createState() =>
      _SettingsPlaceholderScreenState();
}

class _SettingsPlaceholderScreenState extends State<SettingsPlaceholderScreen> {
  PrayerScheduleSession get _session => widget.prayerScheduleSession;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onChanged);
  }

  @override
  void dispose() {
    _session.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _refresh() => unawaited(_session.refresh(requestPermission: true));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schedule = _session.schedule;
    final updatedAt = _session.lastUpdated;
    final locationValue = schedule == null
        ? 'Not configured'
        : _session.usedLastKnownLocation
        ? 'Automatic / Current device · lokasi terakhir'
        : 'Automatic / Current device';

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              IstiqamSpacing.screenHorizontal,
              IstiqamSpacing.xl,
              IstiqamSpacing.screenHorizontal,
              widget.bottomContentPadding + IstiqamSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Settings', style: theme.textTheme.headlineSmall),
                const SizedBox(height: IstiqamSpacing.section),
                Text('Prayer & Location', style: theme.textTheme.titleMedium),
                const SizedBox(height: IstiqamSpacing.md),
                IstiqamSurface(
                  padding: const EdgeInsets.all(IstiqamSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SettingsValueRow(
                        label: 'Location',
                        value: locationValue,
                      ),
                      const SizedBox(height: IstiqamSpacing.md),
                      const _SettingsValueRow(
                        label: 'Calculation',
                        value: 'Indonesia (KEMENAG)',
                      ),
                      const SizedBox(height: IstiqamSpacing.md),
                      const _SettingsValueRow(label: 'Asar', value: 'Shafi'),
                      const SizedBox(height: IstiqamSpacing.md),
                      _SettingsValueRow(
                        label: 'Last updated',
                        value: updatedAt == null
                            ? '—'
                            : PrayerTimePresentation.time(updatedAt),
                      ),
                      if (_session.calculationError != null ||
                          _session.isLocationUnavailable) ...[
                        const SizedBox(height: IstiqamSpacing.md),
                        Text(
                          _session.accessStatus ==
                                  LocationAccessStatus.serviceDisabled
                              ? 'Layanan lokasi tidak aktif.'
                              : 'Jadwal belum dapat dimuat. Periksa akses lokasi lalu coba lagi.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                      if (schedule == null) ...[
                        const SizedBox(height: IstiqamSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed:
                                _session.isCheckingAccess || _session.isLoading
                                ? null
                                : _refresh,
                            child: const Text('Set up'),
                          ),
                        ),
                      ],
                      const SizedBox(height: IstiqamSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              _session.isCheckingAccess || _session.isLoading
                              ? null
                              : _refresh,
                          icon: _session.isLoading
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded),
                          label: const Text('Refresh prayer times'),
                        ),
                      ),
                      if (_session.accessStatus ==
                              LocationAccessStatus.deniedForever ||
                          _session.accessStatus ==
                              LocationAccessStatus.serviceDisabled) ...[
                        const SizedBox(height: IstiqamSpacing.xs),
                        TextButton(
                          onPressed:
                              _session.accessStatus ==
                                  LocationAccessStatus.deniedForever
                              ? _session.openAppSettings
                              : _session.openLocationSettings,
                          child: Text(
                            _session.accessStatus ==
                                    LocationAccessStatus.deniedForever
                                ? 'Buka Pengaturan'
                                : 'Buka Pengaturan Lokasi',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: IstiqamSpacing.section),
                _AppearanceSelector(
                  themeMode: widget.themeMode,
                  onChanged: widget.onThemeModeChanged,
                ),
                const SizedBox(height: IstiqamSpacing.lg),
                Text(
                  'Waktu sholat dihitung di perangkat menggunakan lokasi saat ini. Lokasi tidak disimpan.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

class _SettingsValueRow extends StatelessWidget {
  const _SettingsValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: IstiqamSpacing.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
