import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/design_system/assets/daisth_assets.dart';
import '../../../core/design_system/components/daisth_surface.dart';
import '../../../core/design_system/tokens/daisth_spacing.dart';
import '../../../core/location/domain/models/location_access_status.dart';
import '../../../core/location/domain/repositories/location_repository.dart';
import '../../../core/timezone/domain/repositories/timezone_repository.dart';
import '../../prayer_times/presentation/prayer_schedule_session.dart';
import '../../reminders/domain/models/exact_alarm_status.dart';
import '../../reminders/domain/models/reminder.dart';
import '../../reminders/domain/models/reminder_permission_status.dart';
import '../../reminders/presentation/view_models/reminder_settings_view_model.dart';

class PrayerLocationSettingsScreen extends StatefulWidget {
  const PrayerLocationSettingsScreen({
    required this.locationRepository,
    required this.timezoneRepository,
    required this.prayerScheduleSession,
    required this.reminderSettings,
    super.key,
  });

  final LocationRepository locationRepository;
  final TimezoneRepository timezoneRepository;
  final PrayerScheduleSession prayerScheduleSession;
  final ReminderSettingsViewModel reminderSettings;

  @override
  State<PrayerLocationSettingsScreen> createState() =>
      _PrayerLocationSettingsScreenState();
}

class _PrayerLocationSettingsScreenState
    extends State<PrayerLocationSettingsScreen> {
  LocationAccessStatus? _access;
  String? _timezone;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.prayerScheduleSession.addListener(_changed);
    widget.reminderSettings.addListener(_changed);
    unawaited(_refreshStatus());
  }

  @override
  void dispose() {
    widget.prayerScheduleSession.removeListener(_changed);
    widget.reminderSettings.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshStatus() async {
    try {
      final access = await widget.locationRepository.checkAccess();
      final timezone = await widget.timezoneRepository.getDeviceTimezone();
      if (!mounted) return;
      setState(() {
        _access = access;
        _timezone = timezone.ianaName;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Status perangkat tidak tersedia.');
    }
  }

  Future<void> _refreshPrayerTimes() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.prayerScheduleSession.refresh(requestPermission: false);
      await _refreshStatus();
      await widget.reminderSettings.onAppResumed();
      if (widget.prayerScheduleSession.calculationError != null ||
          widget.prayerScheduleSession.isLocationUnavailable) {
        _error = 'Jadwal belum dapat diperbarui. Periksa izin dan lokasi.';
      }
    } catch (_) {
      _error = 'Jadwal belum dapat diperbarui. Coba lagi.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestLocation() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await widget.prayerScheduleSession.requestLocation();
      await _refreshStatus();
      await widget.reminderSettings.onAppResumed();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Izin lokasi belum dapat diperbarui.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openLocationSettings() async {
    if (_access == LocationAccessStatus.deniedForever) {
      await widget.prayerScheduleSession.openAppSettings();
    } else {
      await widget.prayerScheduleSession.openLocationSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = widget.prayerScheduleSession;
    final status = session.accessStatus ?? _access;
    final timezone =
        widget.reminderSettings.deviceTimezone?.ianaName ?? _timezone;
    final locationLabel = switch (status) {
      LocationAccessStatus.granted when session.usedLastKnownLocation =>
        'Lokasi terakhir tersedia',
      LocationAccessStatus.granted when session.schedule != null =>
        'Lokasi tersedia',
      LocationAccessStatus.granted => 'Izin diberikan',
      LocationAccessStatus.denied => 'Perlu izin lokasi',
      LocationAccessStatus.deniedForever => 'Izin perlu diubah di Pengaturan',
      LocationAccessStatus.serviceDisabled => 'Layanan lokasi tidak aktif',
      null => 'Tidak tersedia',
    };

    return _SettingsDetailScaffold(
      title: 'Prayer & Location',
      children: [
        DaisthSurface(
          child: Column(
            children: [
              _ValueRow(label: 'Location', value: locationLabel),
              const SizedBox(height: DaisthSpacing.md),
              const _ValueRow(label: 'Calculation', value: 'KEMENAG'),
              const SizedBox(height: DaisthSpacing.md),
              const _ValueRow(label: 'Asar', value: 'Shafi'),
              const SizedBox(height: DaisthSpacing.md),
              _ValueRow(label: 'Timezone', value: timezone ?? 'Tidak tersedia'),
              const SizedBox(height: DaisthSpacing.md),
              _ValueRow(
                label: 'Jadwal terakhir diperbarui',
                value: session.lastUpdated == null
                    ? 'Belum tersedia'
                    : MaterialLocalizations.of(context).formatTimeOfDay(
                        TimeOfDay.fromDateTime(session.lastUpdated!.toLocal()),
                      ),
              ),
              if (session.usedLastKnownLocation) ...[
                const SizedBox(height: DaisthSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Menggunakan lokasi terakhir yang tersedia.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: DaisthSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: DaisthSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _refreshPrayerTimes,
                  icon: _loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: const Text('Perbarui lokasi & waktu salat'),
                ),
              ),
              if (status == LocationAccessStatus.denied) ...[
                const SizedBox(height: DaisthSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _requestLocation,
                  icon: const Icon(Icons.location_on_outlined),
                  label: const Text('Izinkan lokasi'),
                ),
              ],
              if (status == LocationAccessStatus.deniedForever ||
                  status == LocationAccessStatus.serviceDisabled) ...[
                const SizedBox(height: DaisthSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _openLocationSettings,
                  icon: const Icon(Icons.settings_outlined),
                  label: Text(
                    status == LocationAccessStatus.deniedForever
                        ? 'Buka pengaturan aplikasi'
                        : 'Buka pengaturan lokasi',
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: DaisthSpacing.md),
        Text(
          'Daisth menggunakan lokasi perangkat untuk menghitung waktu salat dan menemukan masjid terdekat. Koordinat tidak ditampilkan di sini.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({
    required this.reminderSettings,
    super.key,
  });

  final ReminderSettingsViewModel reminderSettings;

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  ReminderSettingsViewModel get vm => widget.reminderSettings;

  @override
  void initState() {
    super.initState();
    vm.addListener(_changed);
    unawaited(_loadDeviceStatus());
  }

  Future<void> _loadDeviceStatus() async {
    await vm.initialize();
    await vm.refreshDeviceStatus();
  }

  @override
  void dispose() {
    vm.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _toggle(bool enabled) async {
    if (enabled) {
      await vm.enableReminders();
    } else {
      await vm.disableReminders();
    }
  }

  Future<void> _requestPrecise() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Waktu presisi'),
        content: const Text(
          'Android dapat meminta izin tambahan agar pengingat lebih dekat dengan waktu yang dijadwalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nanti'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    if (accepted == true) await vm.requestExactAlarmPermission();
  }

  @override
  Widget build(BuildContext context) {
    final permission = switch (vm.permissionStatus) {
      ReminderPermissionStatus.granted => 'Allowed',
      ReminderPermissionStatus.denied => 'Needs attention',
      ReminderPermissionStatus.unavailable => 'Tidak tersedia',
    };
    final precise = switch (vm.exactAlarmStatus) {
      ExactAlarmStatus.enabled => 'Precise timing',
      ExactAlarmStatus.needsPermission => 'Standard timing',
      ExactAlarmStatus.unavailable => 'Standard timing',
    };
    final health = !vm.remindersEnabled
        ? 'Off'
        : vm.permissionStatus != ReminderPermissionStatus.granted
        ? 'Needs attention'
        : precise;

    return _SettingsDetailScaffold(
      title: 'Notifications',
      children: [
        DaisthSurface(
          padding: const EdgeInsets.all(DaisthSpacing.lg),
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reminders'),
                  subtitle: Text(vm.remindersEnabled ? 'On' : 'Off'),
                  value: vm.remindersEnabled,
                  onChanged: vm.isLoading ? null : _toggle,
                ),
                const SizedBox(height: DaisthSpacing.sm),
                _ValueRow(label: 'Notification permission', value: permission),
                if (vm.permissionStatus == ReminderPermissionStatus.denied) ...[
                  const SizedBox(height: DaisthSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: vm.isLoading
                        ? null
                        : vm.requestNotificationPermission,
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Izinkan notifikasi'),
                  ),
                  TextButton(
                    onPressed: vm.isLoading
                        ? null
                        : () async {
                            await vm.openNotificationSettings();
                            await vm.refreshPermissionStatus();
                          },
                    child: const Text('Buka pengaturan aplikasi'),
                  ),
                ],
                if (defaultTargetPlatform == TargetPlatform.android) ...[
                  const SizedBox(height: DaisthSpacing.md),
                  _ValueRow(label: 'Timing', value: precise),
                  if (vm.exactAlarmStatus == ExactAlarmStatus.needsPermission)
                    OutlinedButton.icon(
                      onPressed: vm.isLoading ? null : _requestPrecise,
                      icon: const Icon(Icons.schedule_outlined),
                      label: const Text('Aktifkan waktu presisi'),
                    ),
                ],
                const SizedBox(height: DaisthSpacing.md),
                _ValueRow(
                  label: 'Timezone',
                  value: vm.deviceTimezone?.ianaName ?? 'Tidak tersedia',
                ),
                const SizedBox(height: DaisthSpacing.md),
                _ValueRow(label: 'Reminder Health', value: health),
                const SizedBox(height: DaisthSpacing.md),
                _ValueRow(
                  label: 'Pengingat mendatang',
                  value: '${vm.pendingReminders.length}',
                ),
                if (vm.lastReminderAction != null) ...[
                  const SizedBox(height: DaisthSpacing.md),
                  _ValueRow(
                    label: 'Aksi terakhir',
                    value: _actionLabel(vm.lastReminderAction!),
                  ),
                ],
                const SizedBox(height: DaisthSpacing.md),
                OutlinedButton.icon(
                  onPressed: () =>
                      _showPendingReminders(context, vm.todayPendingReminders),
                  icon: const Icon(Icons.event_note_outlined),
                  label: Text('Jadwal hari ini · ${vm.scheduledTodayCount}'),
                ),
                if (vm.errorMessage != null) ...[
                  const SizedBox(height: DaisthSpacing.sm),
                  Text(
                    vm.errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (kDebugMode) ...[
                  const SizedBox(height: DaisthSpacing.sm),
                  OutlinedButton.icon(
                    onPressed:
                        vm.isLoading ||
                            vm.permissionStatus !=
                                ReminderPermissionStatus.granted
                        ? null
                        : () => unawaited(vm.sendTestReminder()),
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Kirim notifikasi uji'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

void _showPendingReminders(BuildContext context, List<Reminder> reminders) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
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
              'Jadwal hari ini',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: DaisthSpacing.md),
            if (reminders.isEmpty)
              const Text('Tidak ada pengingat mendatang hari ini.')
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
    ),
  );
}

String _actionLabel(String value) => switch (value) {
  'done' => 'Selesai',
  'snooze' => 'Ditunda',
  'open' => 'Dibuka',
  _ => 'Terakhir diperbarui',
};

class DataPrivacySettingsScreen extends StatelessWidget {
  const DataPrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => _SettingsDetailScaffold(
    title: 'Data & Privacy',
    children: [
      DaisthSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Data Daisth'),
            SizedBox(height: DaisthSpacing.sm),
            Text(
              'Rutinitas, riwayat, dan Reflection tersimpan di perangkat ini secara default.',
            ),
            SizedBox(height: DaisthSpacing.md),
            Text(
              'Sinkronisasi cloud bersifat opsional. Jika diaktifkan, rutinitas, riwayat, dan isi Reflection disinkronkan secara privat ke Firestore di bawah UID akun yang terhubung.',
            ),
            SizedBox(height: DaisthSpacing.md),
            Text(
              'Lokasi diproses di perangkat untuk menghitung waktu salat. Saat mencari masjid terdekat, koordinat dikirim ke layanan OpenStreetMap/Overpass. Jika kamu membuka navigasi, koordinat tujuan masjid diteruskan ke Google Maps. Daisth tidak menyimpan koordinat lokasi di Firestore.',
            ),
            SizedBox(height: DaisthSpacing.md),
            Text(
              'Catatan Reflection tidak dimasukkan ke payload notifikasi. Daisth saat ini tidak menyertakan Firebase Analytics.',
            ),
          ],
        ),
      ),
      const SizedBox(height: DaisthSpacing.md),
      DaisthSurface(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('Account & Sync'),
            subtitle: const Text('Kelola akun cloud dan sinkronisasi'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(RoutePaths.account),
          ),
        ),
      ),
    ],
  );
}

class AboutDaisthScreen extends StatelessWidget {
  const AboutDaisthScreen({super.key});

  @override
  Widget build(BuildContext context) => _SettingsDetailScaffold(
    title: 'About Daisth',
    children: [
      DaisthSurface(
        child: Column(
          children: [
            Image.asset(DaisthAssets.wordmark, height: 44, fit: BoxFit.contain),
            const SizedBox(height: DaisthSpacing.md),
            Text(
              'Stay consistent in what matters.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      const SizedBox(height: DaisthSpacing.md),
      DaisthSurface(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Open-source licenses'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Daisth',
              applicationLegalese: 'Stay consistent in what matters.',
              applicationIcon: Padding(
                padding: const EdgeInsets.all(DaisthSpacing.sm),
                child: Image.asset(DaisthAssets.mark, width: 40, height: 40),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _SettingsDetailScaffold extends StatelessWidget {
  const _SettingsDetailScaffold({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), centerTitle: true),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.all(DaisthSpacing.screenHorizontal),
            children: children,
          ),
        ),
      ),
    ),
  );
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      const SizedBox(width: DaisthSpacing.md),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}
