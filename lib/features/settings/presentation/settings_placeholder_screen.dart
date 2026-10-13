import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/design_system/components/daisth_notice_controller.dart';
import '../../../core/design_system/components/daisth_notice.dart';
import '../../../core/design_system/components/daisth_surface.dart';
import '../../../core/design_system/theme/daisth_theme_extension.dart';
import '../../../core/design_system/tokens/daisth_radius.dart';
import '../../../core/design_system/tokens/daisth_spacing.dart';
import '../../../core/location/domain/models/location_access_status.dart';
import '../../prayer_times/presentation/prayer_schedule_session.dart';
import '../../prayer_times/presentation/prayer_time_presentation.dart';
import '../../reminders/domain/models/exact_alarm_status.dart';
import '../../reminders/domain/models/reminder_permission_status.dart';
import '../../reminders/domain/models/reminder.dart';
import '../../reminders/presentation/view_models/reminder_settings_view_model.dart';
import '../../../app/router/route_paths.dart';
import '../../../features/auth/domain/models/auth_session.dart';
import '../../../features/auth/presentation/auth_view_model.dart';

class SettingsPlaceholderScreen extends StatefulWidget {
  const SettingsPlaceholderScreen({
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.prayerScheduleSession,
    required this.reminderSettings,
    required this.noticeController,
    this.authViewModel,
    this.bottomContentPadding = 0,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final PrayerScheduleSession prayerScheduleSession;
  final ReminderSettingsViewModel reminderSettings;
  final DaisthNoticeController noticeController;
  final AuthViewModel? authViewModel;
  final double bottomContentPadding;

  @override
  State<SettingsPlaceholderScreen> createState() =>
      _SettingsPlaceholderScreenState();
}

class _SettingsPlaceholderScreenState extends State<SettingsPlaceholderScreen> {
  PrayerScheduleSession get _session => widget.prayerScheduleSession;
  ReminderSettingsViewModel get _reminders => widget.reminderSettings;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onChanged);
    _reminders.addListener(_onChanged);
    widget.authViewModel?.addListener(_onChanged);
    unawaited(_reminders.initialize());
  }

  @override
  void dispose() {
    _session.removeListener(_onChanged);
    _reminders.removeListener(_onChanged);
    widget.authViewModel?.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _refresh() => unawaited(_session.refresh(requestPermission: true));

  Future<void> _onRemindersChanged(bool enabled) async {
    if (enabled) {
      final success = await _reminders.enableReminders();
      if (!mounted) return;
      if (success) {
        widget.noticeController.show(
          context,
          type: DaisthNoticeType.success,
          title: 'Reminders scheduled',
          message:
              '${_reminders.lastSummary?.scheduledCount ?? 0} reminders updated.',
        );
      }
    } else {
      await _reminders.disableReminders();
      if (mounted) {
        widget.noticeController.show(
          context,
          type: DaisthNoticeType.info,
          title: 'Reminders turned off',
          message: 'All Daisth reminders have been cancelled.',
        );
      }
    }
  }

  Future<void> _requestPreciseReminders() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Precise reminders'),
        content: const Text(
          'Android may require additional permission so prayer reminders can arrive closer to their scheduled time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (proceed == true) {
      await _reminders.requestExactAlarmPermission();
      if (mounted && _reminders.exactAlarmStatus == ExactAlarmStatus.enabled) {
        widget.noticeController.show(
          context,
          type: DaisthNoticeType.success,
          title: 'Precise reminders enabled',
        );
      }
    }
  }

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
              DaisthSpacing.screenHorizontal,
              DaisthSpacing.xl,
              DaisthSpacing.screenHorizontal,
              widget.bottomContentPadding + DaisthSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Settings', style: theme.textTheme.headlineSmall),
                const SizedBox(height: DaisthSpacing.section),
                _AppearanceSelector(
                  themeMode: widget.themeMode,
                  onChanged: widget.onThemeModeChanged,
                ),
                const SizedBox(height: DaisthSpacing.section),
                Text('Account', style: theme.textTheme.titleMedium),
                const SizedBox(height: DaisthSpacing.md),
                DaisthSurface(
                  padding: EdgeInsets.zero,
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: Icon(
                        Icons.person_outline_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      title: const Text('Account'),
                      subtitle: Text(switch (widget.authViewModel?.session) {
                        AuthSignedIn(:final user) => user.email,
                        AuthUnavailable() => 'Layanan akun tidak tersedia',
                        _ => 'Opsional · Belum terhubung',
                      }),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(RoutePaths.account),
                    ),
                  ),
                ),
                const SizedBox(height: DaisthSpacing.section),
                Text('Prayer & Location', style: theme.textTheme.titleMedium),
                const SizedBox(height: DaisthSpacing.md),
                DaisthSurface(
                  padding: const EdgeInsets.all(DaisthSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SettingsValueRow(
                        label: 'Location',
                        value: locationValue,
                      ),
                      const SizedBox(height: DaisthSpacing.md),
                      const _SettingsValueRow(
                        label: 'Calculation',
                        value: 'Indonesia (KEMENAG)',
                      ),
                      const SizedBox(height: DaisthSpacing.md),
                      const _SettingsValueRow(label: 'Asar', value: 'Shafi'),
                      const SizedBox(height: DaisthSpacing.md),
                      _SettingsValueRow(
                        label: 'Last updated',
                        value: updatedAt == null
                            ? '—'
                            : PrayerTimePresentation.time(updatedAt),
                      ),
                      if (_session.calculationError != null ||
                          _session.isLocationUnavailable) ...[
                        const SizedBox(height: DaisthSpacing.md),
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
                        const SizedBox(height: DaisthSpacing.md),
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
                      const SizedBox(height: DaisthSpacing.sm),
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
                        const SizedBox(height: DaisthSpacing.xs),
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
                const SizedBox(height: DaisthSpacing.section),
                _NotificationsSettingsSection(
                  viewModel: _reminders,
                  onRemindersChanged: _onRemindersChanged,
                  onRequestPrecise: _requestPreciseReminders,
                  onOpenSettings: _reminders.openNotificationSettings,
                ),
                const SizedBox(height: DaisthSpacing.lg),
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

class _NotificationsSettingsSection extends StatelessWidget {
  const _NotificationsSettingsSection({
    required this.viewModel,
    required this.onRemindersChanged,
    required this.onRequestPrecise,
    required this.onOpenSettings,
  });

  final ReminderSettingsViewModel viewModel;
  final ValueChanged<bool> onRemindersChanged;
  final VoidCallback onRequestPrecise;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final permission = switch (viewModel.permissionStatus) {
      ReminderPermissionStatus.granted => 'Allowed',
      ReminderPermissionStatus.denied => 'Not allowed',
      ReminderPermissionStatus.unavailable => 'Unavailable',
    };
    final precise = switch (viewModel.exactAlarmStatus) {
      ExactAlarmStatus.enabled => 'Enabled',
      ExactAlarmStatus.needsPermission => 'Needs permission',
      ExactAlarmStatus.unavailable => 'Unavailable',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Notifications', style: theme.textTheme.titleMedium),
        const SizedBox(height: DaisthSpacing.md),
        DaisthSurface(
          padding: const EdgeInsets.all(DaisthSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reminders', style: theme.textTheme.titleSmall),
                        const SizedBox(height: DaisthSpacing.xs),
                        Text(
                          viewModel.remindersEnabled ? 'On' : 'Off',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: viewModel.remindersEnabled,
                    onChanged: viewModel.isLoading ? null : onRemindersChanged,
                  ),
                ],
              ),
              const SizedBox(height: DaisthSpacing.md),
              _SettingsValueRow(
                label: 'Notification permission',
                value: permission,
              ),
              const SizedBox(height: DaisthSpacing.md),
              if (viewModel.permissionStatus ==
                  ReminderPermissionStatus.denied) ...[
                OutlinedButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Open Settings'),
                ),
              ],
              if (defaultTargetPlatform == TargetPlatform.android) ...[
                const SizedBox(height: DaisthSpacing.md),
                _SettingsValueRow(label: 'Precise reminders', value: precise),
                if (viewModel.exactAlarmStatus ==
                    ExactAlarmStatus.needsPermission) ...[
                  const SizedBox(height: DaisthSpacing.md),
                  OutlinedButton.icon(
                    onPressed: viewModel.isLoading ? null : onRequestPrecise,
                    icon: const Icon(Icons.schedule_outlined),
                    label: const Text('Enable'),
                  ),
                ],
              ],
              const SizedBox(height: DaisthSpacing.md),
              _SettingsValueRow(
                label: 'Timezone',
                value: viewModel.deviceTimezone?.ianaName ?? '—',
              ),
              const SizedBox(height: DaisthSpacing.md),
              _SettingsValueRow(
                label: 'Reminder health',
                value: !viewModel.remindersEnabled
                    ? 'Off'
                    : viewModel.permissionStatus ==
                          ReminderPermissionStatus.denied
                    ? 'Permission needed'
                    : viewModel.exactAlarmStatus == ExactAlarmStatus.enabled
                    ? 'Precise timing'
                    : 'Standard timing',
              ),
              const SizedBox(height: DaisthSpacing.md),
              _SettingsValueRow(
                label: 'Pending reminders',
                value: '${viewModel.pendingReminders.length}',
              ),
              if (viewModel.lastReminderAction != null) ...[
                const SizedBox(height: DaisthSpacing.md),
                _SettingsValueRow(
                  label: 'Last action',
                  value:
                      '${_actionLabel(viewModel.lastReminderAction!)}${viewModel.lastReminderActionAt == null ? '' : ' · ${_formatActionTime(viewModel.lastReminderActionAt!)}'}',
                ),
              ],
              const SizedBox(height: DaisthSpacing.md),
              InkWell(
                borderRadius: BorderRadius.circular(DaisthRadius.medium),
                onTap: () => _showPendingReminders(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: DaisthSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Scheduled today',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        '${viewModel.scheduledTodayCount} upcoming',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: DaisthSpacing.xs),
                      const Icon(Icons.chevron_right_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              if (viewModel.errorMessage != null) ...[
                const SizedBox(height: DaisthSpacing.sm),
                Text(
                  viewModel.errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              if (kDebugMode) ...[
                const SizedBox(height: DaisthSpacing.sm),
                OutlinedButton.icon(
                  onPressed:
                      viewModel.isLoading ||
                          viewModel.permissionStatus !=
                              ReminderPermissionStatus.granted
                      ? null
                      : () => unawaited(viewModel.sendTestReminder()),
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Send test reminder'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showPendingReminders(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final reminders = viewModel.todayPendingReminders;
        return SafeArea(
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
                  'Scheduled today',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: DaisthSpacing.md),
                if (reminders.isEmpty)
                  const Text('No upcoming reminders today.')
                else
                  for (final reminder in reminders)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(reminder.title),
                      subtitle: Text(switch (reminder.type) {
                        ReminderType.primary => 'Pengingat utama',
                        ReminderType.followUp => 'Pengingat lanjutan',
                        ReminderType.snooze => 'Pengingat tunda',
                      }),
                      trailing: Text(
                        '${reminder.scheduledAt.hour.toString().padLeft(2, '0')}:${reminder.scheduledAt.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _actionLabel(String action) => switch (action) {
  'done' => 'Selesai',
  'snooze' => 'Ditunda',
  'open' => 'Dibuka',
  _ => action,
};

String _formatActionTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

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
        const SizedBox(width: DaisthSpacing.md),
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
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? theme.colorScheme.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(DaisthRadius.medium),
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
