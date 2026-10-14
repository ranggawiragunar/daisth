import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/app_settings/domain/repositories/app_settings_repository.dart';
import '../../../../core/timezone/domain/models/device_timezone.dart';
import '../../../../core/timezone/domain/repositories/timezone_repository.dart';
import '../../../prayer_times/presentation/prayer_schedule_session.dart';
import '../../domain/models/exact_alarm_status.dart';
import '../../domain/models/reminder.dart';
import '../../domain/models/reminder_permission_status.dart';
import '../../domain/models/reminder_priority.dart';
import '../../domain/models/reminder_scheduling_mode.dart';
import '../../domain/models/reminder_schedule_summary.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../domain/repositories/routine_reminder_state_repository.dart';
import '../../../../core/time/domain/models/calendar_day.dart';
import '../../domain/use_cases/reminder_reschedule_policy.dart';
import '../../domain/use_cases/schedule_today_reminders_use_case.dart';

class ReminderSettingsViewModel extends ChangeNotifier {
  ReminderSettingsViewModel({
    required this.reminderRepository,
    required this.timezoneRepository,
    required this.scheduleTodayReminders,
    required this.prayerScheduleSession,
    this.appSettingsRepository,
    this.reminderStateRepository,
    this.languageCode = 'en',
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    prayerScheduleSession.addListener(_onPrayerScheduleChanged);
  }

  final ReminderRepository reminderRepository;
  final TimezoneRepository timezoneRepository;
  final ScheduleTodayRemindersUseCase scheduleTodayReminders;
  final PrayerScheduleSession prayerScheduleSession;
  final AppSettingsRepository? appSettingsRepository;
  final RoutineReminderStateRepository? reminderStateRepository;
  final DateTime Function() _clock;
  final ReminderReschedulePolicy _reschedulePolicy =
      const ReminderReschedulePolicy();
  String languageCode;

  bool remindersEnabled = false;
  bool isLoading = false;
  String? errorMessage;
  ReminderPermissionStatus permissionStatus =
      ReminderPermissionStatus.unavailable;
  ExactAlarmStatus exactAlarmStatus = ExactAlarmStatus.unavailable;
  DeviceTimezone? deviceTimezone;
  ReminderScheduleSummary? lastSummary;
  List<Reminder> pendingReminders = const [];
  String? lastReminderAction;
  DateTime? lastReminderActionAt;
  DateTime? _lastPlanDate;
  String? _lastPlanTimezone;
  DateTime? _lastPrayerScheduleUpdatedAt;
  bool _initialized = false;
  bool _rescheduleInProgress = false;

  int get scheduledTodayCount {
    final now = _clock();
    return pendingReminders
        .where((reminder) => _sameDate(reminder.scheduledAt, now))
        .length;
  }

  List<Reminder> get todayPendingReminders {
    final now = _clock();
    return List.unmodifiable(
      pendingReminders.where(
        (reminder) => _sameDate(reminder.scheduledAt, now),
      ),
    );
  }

  Future<void> initialize() async {
    if (_initialized || isLoading) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final settings = await appSettingsRepository?.getSettings();
      remindersEnabled = settings?.remindersEnabled ?? false;
      permissionStatus = await reminderRepository.getPermissionStatus();
      exactAlarmStatus = await reminderRepository.getExactAlarmStatus();
      deviceTimezone = await timezoneRepository.getDeviceTimezone();
      await _refreshPending();
      if (remindersEnabled &&
          permissionStatus == ReminderPermissionStatus.granted &&
          prayerScheduleSession.schedule != null) {
        await _reschedule();
      }
      _initialized = true;
    } catch (_) {
      errorMessage = 'Pengaturan pengingat belum dapat dimuat.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> enableReminders() async {
    if (isLoading) return false;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      permissionStatus = await reminderRepository.getPermissionStatus();
      if (permissionStatus != ReminderPermissionStatus.granted) {
        permissionStatus = await reminderRepository.requestPermission();
      }
      if (permissionStatus != ReminderPermissionStatus.granted) {
        errorMessage = 'Izinkan notifikasi agar pengingat dapat dijadwalkan.';
        return false;
      }
      exactAlarmStatus = await reminderRepository.getExactAlarmStatus();
      final summary = await scheduleTodayReminders(
        schedule: prayerScheduleSession.schedule,
        now: _clock(),
      );
      lastSummary = summary;
      deviceTimezone = summary.plan.timezone;
      _lastPlanDate = summary.plan.date;
      _lastPlanTimezone = summary.plan.timezone.ianaName;
      _lastPrayerScheduleUpdatedAt = prayerScheduleSession.lastUpdated;
      await _saveReminderPreference(true);
      remindersEnabled = true;
      await _refreshPending();
      return true;
    } catch (_) {
      errorMessage = 'Pengingat belum dapat dijadwalkan. Coba lagi nanti.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> disableReminders() async {
    if (isLoading) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await reminderRepository.cancelAllDaisthReminders();
      await _saveReminderPreference(false);
      remindersEnabled = false;
      lastSummary = null;
      _lastPlanDate = null;
      _lastPlanTimezone = null;
      await _refreshPending();
    } catch (_) {
      errorMessage = 'Pengingat belum dapat dinonaktifkan. Coba lagi.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestExactAlarmPermission() async {
    if (isLoading) return;
    isLoading = true;
    notifyListeners();
    try {
      exactAlarmStatus = await reminderRepository.requestExactAlarmPermission();
      if (remindersEnabled) await _reschedule();
    } catch (_) {
      errorMessage = 'Pengaturan pengingat presisi belum dapat dibuka.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPermissionStatus() async {
    try {
      permissionStatus = await reminderRepository.getPermissionStatus();
      exactAlarmStatus = await reminderRepository.getExactAlarmStatus();
      await _refreshPending();
    } catch (_) {
      errorMessage = 'Status notifikasi belum dapat diperbarui.';
    }
    notifyListeners();
  }

  Future<void> requestNotificationPermission() async {
    if (isLoading) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      permissionStatus = await reminderRepository.requestPermission();
      await _refreshPending();
    } catch (_) {
      errorMessage = 'Izin notifikasi belum dapat diperbarui.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> openNotificationSettings() async {
    await reminderRepository.openNotificationSettings();
  }

  Future<void> sendTestReminder() async {
    if (!kDebugMode || permissionStatus != ReminderPermissionStatus.granted) {
      return;
    }
    final now = _clock();
    final scheduledAt = now.add(const Duration(seconds: 7));
    final dateKey =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    await reminderRepository.schedule(
      Reminder(
        id: 'dhuha-primary-test-$dateKey',
        routineId: 'dhuha',
        title: languageCode == 'id'
            ? 'Uji aksi · Salat Dhuha'
            : 'Action test · Duha prayer',
        body: languageCode == 'id'
            ? 'Notifikasi lokal dan aksi pengingat berfungsi.'
            : 'Local notifications and reminder actions are working.',
        scheduledAt: scheduledAt,
        priority: ReminderPriority.medium,
        dateKey: dateKey,
        timezoneIdentifier: deviceTimezone?.ianaName ?? 'UTC',
      ),
      mode: exactAlarmStatus == ExactAlarmStatus.enabled
          ? ReminderSchedulingMode.exact
          : ReminderSchedulingMode.inexact,
    );
    await _refreshPending();
    notifyListeners();
  }

  Future<void> onAppResumed() async {
    if (isLoading) return;
    try {
      permissionStatus = await reminderRepository.getPermissionStatus();
      exactAlarmStatus = await reminderRepository.getExactAlarmStatus();
      final current = _clock();
      deviceTimezone = await timezoneRepository.getDeviceTimezone();
      if (!remindersEnabled ||
          permissionStatus != ReminderPermissionStatus.granted) {
        await _refreshPending();
        notifyListeners();
        return;
      }
      final shouldReschedule = _reschedulePolicy.shouldReschedule(
        scheduledDate: _lastPlanDate,
        scheduledTimezone: _lastPlanTimezone,
        currentDate: current,
        currentTimezone: deviceTimezone!.ianaName,
      );
      if (!shouldReschedule) {
        await prayerScheduleSession.refreshIfStale(now: current);
        await _refreshPending();
        notifyListeners();
        return;
      }
      await prayerScheduleSession.refresh(now: current);
      await _reschedule(now: current);
    } catch (_) {
      errorMessage = 'Pengaturan perangkat belum dapat diperbarui.';
      notifyListeners();
    }
  }

  Future<void> onLanguageChanged() async {
    if (!remindersEnabled ||
        permissionStatus != ReminderPermissionStatus.granted) {
      return;
    }
    await _reschedule(now: _clock());
  }

  Future<void> refreshDeviceStatus() async {
    if (isLoading) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      permissionStatus = await reminderRepository.getPermissionStatus();
      exactAlarmStatus = await reminderRepository.getExactAlarmStatus();
      deviceTimezone = await timezoneRepository.getDeviceTimezone();
      await _refreshPending();
      if (remindersEnabled &&
          permissionStatus == ReminderPermissionStatus.granted) {
        await prayerScheduleSession.refresh(requestPermission: false);
        await _reschedule(now: _clock());
      }
    } catch (_) {
      errorMessage = 'Pengaturan perangkat belum dapat diperbarui.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _onPrayerScheduleChanged() {
    final scheduleUpdatedAt = prayerScheduleSession.lastUpdated;
    if (!remindersEnabled ||
        permissionStatus != ReminderPermissionStatus.granted ||
        scheduleUpdatedAt == null ||
        scheduleUpdatedAt == _lastPrayerScheduleUpdatedAt ||
        prayerScheduleSession.schedule == null) {
      return;
    }
    unawaited(_reschedule());
  }

  Future<void> _reschedule({DateTime? now}) async {
    if (_rescheduleInProgress ||
        permissionStatus != ReminderPermissionStatus.granted ||
        prayerScheduleSession.schedule == null) {
      return;
    }
    _rescheduleInProgress = true;
    try {
      final summary = await scheduleTodayReminders(
        schedule: prayerScheduleSession.schedule,
        now: now ?? _clock(),
      );
      lastSummary = summary;
      deviceTimezone = summary.plan.timezone;
      _lastPlanDate = summary.plan.date;
      _lastPlanTimezone = summary.plan.timezone.ianaName;
      _lastPrayerScheduleUpdatedAt = prayerScheduleSession.lastUpdated;
      await _refreshPending();
      notifyListeners();
    } catch (_) {
      errorMessage = 'Pengingat belum dapat diperbarui.';
      notifyListeners();
    } finally {
      _rescheduleInProgress = false;
    }
  }

  Future<void> _refreshPending() async {
    pendingReminders = await reminderRepository.getPendingReminders();
    final repository = reminderStateRepository;
    if (repository != null) {
      final states = await repository.getStatesForDay(
        CalendarDay.fromDateTime(_clock()),
      );
      states.sort(
        (a, b) => (b.lastActionAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(
              a.lastActionAt ?? DateTime.fromMillisecondsSinceEpoch(0),
            ),
      );
      final last = states.where((s) => s.lastAction != null).firstOrNull;
      lastReminderAction = last?.lastAction;
      lastReminderActionAt = last?.lastActionAt;
    }
  }

  Future<void> _saveReminderPreference(bool enabled) async {
    final repository = appSettingsRepository;
    if (repository == null) return;
    final current = await repository.getSettings();
    await repository.saveSettings(
      current.copyWith(remindersEnabled: enabled, updatedAt: _clock().toUtc()),
    );
  }

  bool _sameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  @override
  void dispose() {
    prayerScheduleSession.removeListener(_onPrayerScheduleChanged);
    super.dispose();
  }
}
