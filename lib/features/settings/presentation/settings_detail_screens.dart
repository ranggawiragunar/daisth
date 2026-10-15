import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/design_system/assets/daisth_assets.dart';
import '../../../core/design_system/components/daisth_feature_visual.dart';
import '../../../core/design_system/components/daisth_surface.dart';
import '../../../core/design_system/tokens/daisth_spacing.dart';
import '../../../core/localization/daisth_localizations.dart';
import '../../../core/localization/daisth_terminology.dart';
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
        DaisthLocalizations.text(
          context,
          id: 'Lokasi terakhir tersedia',
          en: 'Last known location available',
        ),
      LocationAccessStatus.granted when session.schedule != null =>
        DaisthLocalizations.text(
          context,
          id: 'Lokasi tersedia',
          en: 'Location available',
        ),
      LocationAccessStatus.granted => DaisthLocalizations.text(
        context,
        id: 'Izin diberikan',
        en: 'Permission granted',
      ),
      LocationAccessStatus.denied => DaisthLocalizations.text(
        context,
        id: 'Perlu izin lokasi',
        en: 'Location permission needed',
      ),
      LocationAccessStatus.deniedForever => DaisthLocalizations.text(
        context,
        id: 'Izin perlu diubah di Pengaturan',
        en: 'Change location permission in Settings',
      ),
      LocationAccessStatus.serviceDisabled => DaisthLocalizations.text(
        context,
        id: 'Layanan lokasi tidak aktif',
        en: 'Location services are off',
      ),
      null => DaisthLocalizations.text(
        context,
        id: 'Tidak tersedia',
        en: 'Unavailable',
      ),
    };

    return _SettingsDetailScaffold(
      title: DaisthLocalizations.text(
        context,
        id: 'Waktu Salat & Lokasi',
        en: 'Prayer & Location',
      ),
      children: [
        const Align(
          alignment: Alignment.centerRight,
          child: DaisthFeatureVisual(
            asset: DaisthAssets.prayerLocationSettings,
            height: 48,
          ),
        ),
        DaisthSurface(
          child: Column(
            children: [
              _ValueRow(
                label: DaisthLocalizations.text(
                  context,
                  id: 'Lokasi',
                  en: 'Location',
                ),
                value: locationLabel,
              ),
              const SizedBox(height: DaisthSpacing.md),
              _ValueRow(
                label: DaisthLocalizations.text(
                  context,
                  id: 'Perhitungan',
                  en: 'Calculation',
                ),
                value: 'KEMENAG',
              ),
              const SizedBox(height: DaisthSpacing.md),
              _ValueRow(
                label: DaisthTerminology.prayerName(
                  'asar',
                  Localizations.localeOf(context),
                ),
                value: DaisthLocalizations.text(
                  context,
                  id: 'Syafi’i',
                  en: 'Shafi',
                ),
              ),
              const SizedBox(height: DaisthSpacing.md),
              _ValueRow(
                label: DaisthLocalizations.text(
                  context,
                  id: 'Zona waktu',
                  en: 'Timezone',
                ),
                value:
                    timezone ??
                    DaisthLocalizations.text(
                      context,
                      id: 'Tidak tersedia',
                      en: 'Unavailable',
                    ),
              ),
              const SizedBox(height: DaisthSpacing.md),
              _ValueRow(
                label: DaisthLocalizations.text(
                  context,
                  id: 'Jadwal terakhir diperbarui',
                  en: 'Schedule last updated',
                ),
                value: session.lastUpdated == null
                    ? DaisthLocalizations.text(
                        context,
                        id: 'Belum tersedia',
                        en: 'Not available yet',
                      )
                    : MaterialLocalizations.of(context).formatTimeOfDay(
                        TimeOfDay.fromDateTime(session.lastUpdated!.toLocal()),
                      ),
              ),
              if (session.usedLastKnownLocation) ...[
                const SizedBox(height: DaisthSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    DaisthLocalizations.text(
                      context,
                      id: 'Menggunakan lokasi terakhir yang tersedia.',
                      en: 'Using the last known location.',
                    ),
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
                    _localizedSettingsError(context, _error!),
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
                      : const Icon(PhosphorIconsRegular.arrowClockwise),
                  label: Text(
                    DaisthLocalizations.text(
                      context,
                      id: 'Perbarui lokasi & waktu salat',
                      en: 'Refresh location & prayer times',
                    ),
                  ),
                ),
              ),
              if (status == LocationAccessStatus.denied) ...[
                const SizedBox(height: DaisthSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _requestLocation,
                  icon: const Icon(PhosphorIconsRegular.mapPin),
                  label: Text(
                    DaisthLocalizations.text(
                      context,
                      id: 'Izinkan lokasi',
                      en: 'Allow location',
                    ),
                  ),
                ),
              ],
              if (status == LocationAccessStatus.deniedForever ||
                  status == LocationAccessStatus.serviceDisabled) ...[
                const SizedBox(height: DaisthSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _openLocationSettings,
                  icon: const Icon(PhosphorIconsRegular.gear),
                  label: Text(
                    status == LocationAccessStatus.deniedForever
                        ? DaisthLocalizations.text(
                            context,
                            id: 'Buka pengaturan aplikasi',
                            en: 'Open app settings',
                          )
                        : DaisthLocalizations.text(
                            context,
                            id: 'Buka pengaturan lokasi',
                            en: 'Open location settings',
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: DaisthSpacing.md),
        Text(
          DaisthLocalizations.text(
            context,
            id: 'Daisth menggunakan lokasi perangkat untuk menghitung waktu salat dan menemukan masjid terdekat. Koordinat tidak ditampilkan di sini.',
            en: 'Daisth uses your device location to calculate prayer times and find nearby Masjid and Mushola. Coordinates are not shown here.',
          ),
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
        title: Text(
          DaisthLocalizations.text(
            context,
            id: 'Waktu presisi',
            en: 'Precise reminders',
          ),
        ),
        content: Text(
          DaisthLocalizations.text(
            context,
            id: 'Android dapat meminta izin tambahan agar pengingat lebih dekat dengan waktu yang dijadwalkan.',
            en: 'Android may request additional access so reminders can be delivered closer to their scheduled time.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              DaisthLocalizations.text(context, id: 'Nanti', en: 'Not now'),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              DaisthLocalizations.text(
                context,
                id: 'Lanjutkan',
                en: 'Continue',
              ),
            ),
          ),
        ],
      ),
    );
    if (accepted == true) await vm.requestExactAlarmPermission();
  }

  @override
  Widget build(BuildContext context) {
    final permission = switch (vm.permissionStatus) {
      ReminderPermissionStatus.granted => DaisthLocalizations.text(
        context,
        id: 'Diizinkan',
        en: 'Allowed',
      ),
      ReminderPermissionStatus.denied => DaisthLocalizations.text(
        context,
        id: 'Perlu perhatian',
        en: 'Needs attention',
      ),
      ReminderPermissionStatus.unavailable => DaisthLocalizations.text(
        context,
        id: 'Tidak tersedia',
        en: 'Unavailable',
      ),
    };
    final precise = switch (vm.exactAlarmStatus) {
      ExactAlarmStatus.enabled => DaisthLocalizations.text(
        context,
        id: 'Waktu presisi',
        en: 'Precise timing',
      ),
      ExactAlarmStatus.needsPermission => DaisthLocalizations.text(
        context,
        id: 'Waktu standar',
        en: 'Standard timing',
      ),
      ExactAlarmStatus.unavailable => DaisthLocalizations.text(
        context,
        id: 'Waktu standar',
        en: 'Standard timing',
      ),
    };
    final health = !vm.remindersEnabled
        ? DaisthLocalizations.text(context, id: 'Nonaktif', en: 'Off')
        : vm.permissionStatus != ReminderPermissionStatus.granted
        ? DaisthLocalizations.text(
            context,
            id: 'Perlu perhatian',
            en: 'Needs attention',
          )
        : precise;

    return _SettingsDetailScaffold(
      title: DaisthLocalizations.text(
        context,
        id: 'Notifikasi',
        en: 'Notifications',
      ),
      children: [
        const Align(
          alignment: Alignment.centerRight,
          child: DaisthFeatureVisual(
            asset: DaisthAssets.notificationsSettings,
            height: 48,
          ),
        ),
        DaisthSurface(
          padding: const EdgeInsets.all(DaisthSpacing.lg),
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    DaisthLocalizations.text(
                      context,
                      id: 'Pengingat',
                      en: 'Reminders',
                    ),
                  ),
                  subtitle: Text(
                    vm.remindersEnabled
                        ? DaisthLocalizations.text(
                            context,
                            id: 'Aktif',
                            en: 'On',
                          )
                        : DaisthLocalizations.text(
                            context,
                            id: 'Nonaktif',
                            en: 'Off',
                          ),
                  ),
                  value: vm.remindersEnabled,
                  onChanged: vm.isLoading ? null : _toggle,
                ),
                const SizedBox(height: DaisthSpacing.sm),
                _ValueRow(
                  label: DaisthLocalizations.text(
                    context,
                    id: 'Izin notifikasi',
                    en: 'Notification permission',
                  ),
                  value: permission,
                ),
                if (vm.permissionStatus == ReminderPermissionStatus.denied) ...[
                  const SizedBox(height: DaisthSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: vm.isLoading
                        ? null
                        : vm.requestNotificationPermission,
                    icon: const Icon(PhosphorIconsRegular.gear),
                    label: Text(
                      DaisthLocalizations.text(
                        context,
                        id: 'Izinkan notifikasi',
                        en: 'Allow notifications',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: vm.isLoading
                        ? null
                        : () async {
                            await vm.openNotificationSettings();
                            await vm.refreshPermissionStatus();
                          },
                    child: Text(
                      DaisthLocalizations.text(
                        context,
                        id: 'Buka pengaturan aplikasi',
                        en: 'Open app settings',
                      ),
                    ),
                  ),
                ],
                if (defaultTargetPlatform == TargetPlatform.android) ...[
                  const SizedBox(height: DaisthSpacing.md),
                  _ValueRow(
                    label: DaisthLocalizations.text(
                      context,
                      id: 'Waktu',
                      en: 'Timing',
                    ),
                    value: precise,
                  ),
                  if (vm.exactAlarmStatus == ExactAlarmStatus.needsPermission)
                    OutlinedButton.icon(
                      onPressed: vm.isLoading ? null : _requestPrecise,
                      icon: const Icon(PhosphorIconsRegular.clock),
                      label: Text(
                        DaisthLocalizations.text(
                          context,
                          id: 'Aktifkan waktu presisi',
                          en: 'Enable precise timing',
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: DaisthSpacing.md),
                _ValueRow(
                  label: DaisthLocalizations.text(
                    context,
                    id: 'Zona waktu',
                    en: 'Timezone',
                  ),
                  value:
                      vm.deviceTimezone?.ianaName ??
                      DaisthLocalizations.text(
                        context,
                        id: 'Tidak tersedia',
                        en: 'Unavailable',
                      ),
                ),
                const SizedBox(height: DaisthSpacing.md),
                _ValueRow(
                  label: DaisthLocalizations.text(
                    context,
                    id: 'Kesehatan Pengingat',
                    en: 'Reminder Health',
                  ),
                  value: health,
                ),
                const SizedBox(height: DaisthSpacing.md),
                _ValueRow(
                  label: DaisthLocalizations.text(
                    context,
                    id: 'Pengingat mendatang',
                    en: 'Upcoming reminders',
                  ),
                  value: '${vm.pendingReminders.length}',
                ),
                if (vm.lastReminderAction != null) ...[
                  const SizedBox(height: DaisthSpacing.md),
                  _ValueRow(
                    label: DaisthLocalizations.text(
                      context,
                      id: 'Aksi terakhir',
                      en: 'Last action',
                    ),
                    value: _actionLabel(context, vm.lastReminderAction!),
                  ),
                ],
                const SizedBox(height: DaisthSpacing.md),
                OutlinedButton.icon(
                  onPressed: () =>
                      _showPendingReminders(context, vm.todayPendingReminders),
                  icon: const Icon(PhosphorIconsRegular.calendar),
                  label: Text(
                    DaisthLocalizations.text(
                      context,
                      id: 'Jadwal hari ini · ${vm.scheduledTodayCount}',
                      en: "Today's schedule · ${vm.scheduledTodayCount}",
                    ),
                  ),
                ),
                if (vm.errorMessage != null) ...[
                  const SizedBox(height: DaisthSpacing.sm),
                  Text(
                    _localizedSettingsError(context, vm.errorMessage!),
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
                    icon: const Icon(PhosphorIconsRegular.bellSimpleRinging),
                    label: Text(
                      DaisthLocalizations.text(
                        context,
                        id: 'Kirim notifikasi uji',
                        en: 'Send test reminder',
                      ),
                    ),
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
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) => SafeArea(
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
            DaisthSpacing.screenHorizontal,
            DaisthSpacing.sm,
            DaisthSpacing.screenHorizontal,
            DaisthSpacing.xl,
          ),
          children: [
            Text(
              DaisthLocalizations.text(
                context,
                id: 'Jadwal hari ini',
                en: "Today's schedule",
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: DaisthSpacing.md),
            if (reminders.isEmpty)
              Text(
                DaisthLocalizations.text(
                  context,
                  id: 'Tidak ada pengingat mendatang hari ini.',
                  en: 'No upcoming reminders today.',
                ),
              )
            else
              for (final reminder in reminders)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(reminder.title, maxLines: 2),
                  subtitle: Text(switch (reminder.type) {
                    ReminderType.primary => DaisthLocalizations.text(
                      context,
                      id: 'Pengingat utama',
                      en: 'Primary reminder',
                    ),
                    ReminderType.followUp => DaisthLocalizations.text(
                      context,
                      id: 'Pengingat lanjutan',
                      en: 'Follow-up reminder',
                    ),
                    ReminderType.snooze => DaisthLocalizations.text(
                      context,
                      id: 'Pengingat tunda',
                      en: 'Snoozed reminder',
                    ),
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

String _actionLabel(BuildContext context, String value) => switch (value) {
  'done' => DaisthLocalizations.text(context, id: 'Selesai', en: 'Done'),
  'snooze' => DaisthLocalizations.text(context, id: 'Ditunda', en: 'Snoozed'),
  'open' => DaisthLocalizations.text(context, id: 'Dibuka', en: 'Opened'),
  _ => DaisthLocalizations.text(
    context,
    id: 'Terakhir diperbarui',
    en: 'Last updated',
  ),
};

class DataPrivacySettingsScreen extends StatelessWidget {
  const DataPrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => _SettingsDetailScaffold(
    title: DaisthLocalizations.text(
      context,
      id: 'Data & Privasi',
      en: 'Data & Privacy',
    ),
    children: [
      const Align(
        alignment: Alignment.centerRight,
        child: DaisthFeatureVisual(asset: DaisthAssets.dataPrivacy, height: 48),
      ),
      DaisthSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DaisthLocalizations.text(
                context,
                id: 'Data Daisth',
                en: 'Daisth data',
              ),
            ),
            SizedBox(height: DaisthSpacing.sm),
            Text(
              DaisthLocalizations.text(
                context,
                id: 'Rutinitas, riwayat, dan Reflection tersimpan di perangkat ini secara default.',
                en: 'Routines, History, and Reflection are stored on this device by default.',
              ),
            ),
            SizedBox(height: DaisthSpacing.md),
            Text(
              DaisthLocalizations.text(
                context,
                id: 'Sinkronisasi cloud bersifat opsional. Jika diaktifkan, rutinitas, riwayat, dan isi Reflection disinkronkan secara privat ke Firestore di bawah UID akun yang terhubung.',
                en: 'Cloud sync is optional. When enabled, routines, History, and Reflection are privately synced to Firestore under the linked account UID.',
              ),
            ),
            SizedBox(height: DaisthSpacing.md),
            Text(
              DaisthLocalizations.text(
                context,
                id: 'Lokasi diproses di perangkat untuk menghitung waktu salat. Saat mencari masjid terdekat, koordinat dikirim ke layanan OpenStreetMap/Overpass. Jika kamu membuka navigasi, koordinat tujuan masjid diteruskan ke Google Maps. Daisth tidak menyimpan koordinat lokasi di Firestore.',
                en: 'Location is processed on-device to calculate prayer times. When you search for nearby Masjid or Mushola, coordinates are sent to OpenStreetMap/Overpass. Opening navigation shares the destination coordinates with Google Maps. Daisth does not store location coordinates in Firestore.',
              ),
            ),
            SizedBox(height: DaisthSpacing.md),
            Text(
              DaisthLocalizations.text(
                context,
                id: 'Catatan Reflection tidak dimasukkan ke payload notifikasi. Daisth saat ini tidak menyertakan Firebase Analytics.',
                en: 'Reflection notes are not included in notification payloads. Daisth does not currently include Firebase Analytics.',
              ),
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
            leading: const Icon(PhosphorIconsRegular.user),
            title: Text(
              DaisthLocalizations.text(
                context,
                id: 'Akun & Sinkronisasi',
                en: 'Account & Sync',
              ),
            ),
            subtitle: Text(
              DaisthLocalizations.text(
                context,
                id: 'Kelola akun cloud dan sinkronisasi',
                en: 'Manage your cloud account and sync',
              ),
            ),
            trailing: const Icon(PhosphorIconsRegular.caretRight),
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
    title: DaisthLocalizations.text(
      context,
      id: 'Tentang Daisth',
      en: 'About Daisth',
    ),
    children: [
      DaisthSurface(
        child: Column(
          children: [
            Image.asset(DaisthAssets.wordmark, height: 44, fit: BoxFit.contain),
            const SizedBox(height: DaisthSpacing.md),
            Text(
              DaisthLocalizations.text(
                context,
                id: 'Tetap konsisten pada hal yang berarti.',
                en: 'Stay consistent in what matters.',
              ),
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
            leading: const Icon(PhosphorIconsRegular.fileText),
            title: Text(
              DaisthLocalizations.text(
                context,
                id: 'Lisensi sumber terbuka',
                en: 'Open-source licenses',
              ),
            ),
            trailing: const Icon(PhosphorIconsRegular.caretRight),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Daisth',
              applicationLegalese: DaisthLocalizations.text(
                context,
                id: 'Tetap konsisten pada hal yang berarti.',
                en: 'Stay consistent in what matters.',
              ),
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

String _localizedSettingsError(
  BuildContext context,
  String message,
) => switch (message) {
  'Status perangkat tidak tersedia.' => DaisthLocalizations.text(
    context,
    id: message,
    en: 'Device status is unavailable.',
  ),
  'Jadwal belum dapat diperbarui. Periksa izin dan lokasi.' =>
    DaisthLocalizations.text(
      context,
      id: message,
      en: 'The schedule could not be refreshed. Check location access and try again.',
    ),
  'Jadwal belum dapat diperbarui. Coba lagi.' => DaisthLocalizations.text(
    context,
    id: message,
    en: 'The schedule could not be refreshed. Try again.',
  ),
  'Izin lokasi belum dapat diperbarui.' => DaisthLocalizations.text(
    context,
    id: message,
    en: 'Location access could not be updated.',
  ),
  'Pengaturan pengingat belum dapat dimuat.' => DaisthLocalizations.text(
    context,
    id: message,
    en: 'Reminder settings could not be loaded.',
  ),
  'Izinkan notifikasi agar pengingat dapat dijadwalkan.' =>
    DaisthLocalizations.text(
      context,
      id: message,
      en: 'Allow notifications to schedule reminders.',
    ),
  'Lokasi belum tersedia. Muat waktu salat di Pengaturan → Waktu Salat & Lokasi terlebih dahulu.' =>
    DaisthLocalizations.text(
      context,
      id: message,
      en: 'Location is unavailable. Load prayer times in Settings → Prayer & Location first.',
    ),
  'Pengingat belum dapat dijadwalkan. Coba lagi nanti.' =>
    DaisthLocalizations.text(
      context,
      id: message,
      en: 'Reminders could not be scheduled. Try again later.',
    ),
  'Pengingat belum dapat dinonaktifkan. Coba lagi.' => DaisthLocalizations.text(
    context,
    id: message,
    en: 'Reminders could not be turned off. Try again.',
  ),
  'Pengaturan pengingat presisi belum dapat dibuka.' =>
    DaisthLocalizations.text(
      context,
      id: message,
      en: 'Precise reminder settings could not be opened.',
    ),
  'Status notifikasi belum dapat diperbarui.' => DaisthLocalizations.text(
    context,
    id: message,
    en: 'Notification status could not be refreshed.',
  ),
  'Izin notifikasi belum dapat diperbarui.' => DaisthLocalizations.text(
    context,
    id: message,
    en: 'Notification permission could not be updated.',
  ),
  'Pengaturan perangkat belum dapat diperbarui.' => DaisthLocalizations.text(
    context,
    id: message,
    en: 'Device settings could not be refreshed.',
  ),
  'Pengingat belum dapat diperbarui.' => DaisthLocalizations.text(
    context,
    id: message,
    en: 'Reminders could not be refreshed.',
  ),
  _ => message,
};

class _SettingsDetailScaffold extends StatelessWidget {
  const _SettingsDetailScaffold({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 16),
      ),
      centerTitle: true,
    ),
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
