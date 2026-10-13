import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as timezone;
import 'package:url_launcher/url_launcher.dart';

import '../mappers/reminder_mapper.dart';
import '../models/reminder_schedule_data.dart';
import 'reminder_notification_gateway.dart';
import 'reminder_background_action.dart';
import '../../domain/models/reminder_action.dart';

class ReminderLocalNotificationsService implements ReminderNotificationGateway {
  ReminderLocalNotificationsService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  void Function(String? payload)? _onNotificationTap;

  @override
  Future<void> initialize({
    void Function(String? payload)? onNotificationTap,
  }) async {
    _onNotificationTap = onNotificationTap;
    final initialized = await _plugin.initialize(
      settings: InitializationSettings(
        android: AndroidInitializationSettings('ic_daisth_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              'daisth_routine_reminder',
              actions: [
                DarwinNotificationAction.plain(
                  ReminderActionIds.done,
                  'Selesai',
                ),
                DarwinNotificationAction.plain(
                  ReminderActionIds.snooze,
                  'Ingatkan 10 menit lagi',
                ),
                DarwinNotificationAction.plain(
                  ReminderActionIds.open,
                  'Buka',
                  options: {DarwinNotificationActionOption.foreground},
                ),
              ],
            ),
            DarwinNotificationCategory(
              'daisth_reference_reminder',
              actions: [
                DarwinNotificationAction.plain(
                  ReminderActionIds.open,
                  'Buka',
                  options: {DarwinNotificationActionOption.foreground},
                ),
              ],
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.actionId?.isNotEmpty == true) {
          _onNotificationTap?.call(
            '${response.actionId}|${response.payload ?? ''}',
          );
        } else {
          _onNotificationTap?.call(response.payload);
        }
      },
      onDidReceiveBackgroundNotificationResponse:
          daisthBackgroundNotificationResponse,
    );
    if (initialized == false) {
      throw StateError('Local notification plugin initialization failed.');
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _androidPlugin;
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          ReminderMapper.highChannelId,
          'Daisth · Prioritas tinggi',
          description: 'Pengingat waktu sholat dan Sholat Malam.',
          importance: Importance.high,
          enableVibration: true,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          ReminderMapper.standardChannelId,
          'Daisth · Pengingat rutin',
          description: 'Pengingat Dhuha, refleksi, dan penutup hari.',
          importance: Importance.defaultImportance,
          enableVibration: true,
        ),
      );
    }
  }

  @override
  Future<String?> getLaunchPayload() async {
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp != true) return null;
    return launchDetails?.notificationResponse?.payload;
  }

  @override
  Future<bool?> areNotificationsEnabled() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidPlugin?.areNotificationsEnabled();
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return (await _iosPlugin?.checkPermissions())?.isEnabled;
    }
    return null;
  }

  @override
  Future<bool?> requestNotificationPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidPlugin?.requestNotificationsPermission();
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosPlugin?.requestPermissions(alert: true, sound: true);
    }
    return null;
  }

  @override
  Future<bool?> canScheduleExactNotifications() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    return _androidPlugin?.canScheduleExactNotifications();
  }

  @override
  Future<bool?> requestExactAlarmsPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    return _androidPlugin?.requestExactAlarmsPermission();
  }

  @override
  Future<void> schedule(
    ReminderScheduleData reminder, {
    required AndroidScheduleMode scheduleMode,
  }) {
    final local = timezone.local;
    final scheduledAt = reminder.scheduledAt;
    final scheduledDate = timezone.TZDateTime.from(scheduledAt, local);
    final highPriority = reminder.channelId == ReminderMapper.highChannelId;
    return _plugin.zonedSchedule(
      id: reminder.notificationId,
      title: reminder.title,
      body: reminder.body,
      scheduledDate: scheduledDate,
      payload: reminder.payload,
      androidScheduleMode: scheduleMode,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          reminder.channelId,
          highPriority
              ? 'Daisth · Prioritas tinggi'
              : 'Daisth · Pengingat rutin',
          channelDescription: highPriority
              ? 'Pengingat waktu sholat dan Sholat Malam.'
              : 'Pengingat Dhuha, refleksi, dan penutup hari.',
          importance: highPriority
              ? Importance.high
              : Importance.defaultImportance,
          priority: highPriority ? Priority.high : Priority.defaultPriority,
          enableVibration: true,
          playSound: true,
          icon: 'ic_daisth_notification',
          actions: reminder.actionable
              ? const [
                  AndroidNotificationAction(
                    ReminderActionIds.done,
                    'Selesai',
                    showsUserInterface: false,
                    cancelNotification: true,
                  ),
                  AndroidNotificationAction(
                    ReminderActionIds.snooze,
                    'Ingatkan 10 menit lagi',
                    showsUserInterface: false,
                    cancelNotification: true,
                  ),
                  AndroidNotificationAction(
                    ReminderActionIds.open,
                    'Buka',
                    showsUserInterface: true,
                    cancelNotification: true,
                  ),
                ]
              : const [
                  AndroidNotificationAction(
                    ReminderActionIds.open,
                    'Buka',
                    showsUserInterface: true,
                    cancelNotification: true,
                  ),
                ],
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          categoryIdentifier: reminder.actionable
              ? 'daisth_routine_reminder'
              : 'daisth_reference_reminder',
        ),
      ),
    );
  }

  @override
  Future<void> cancel(int notificationId) => _plugin.cancel(id: notificationId);

  @override
  Future<List<PendingNotificationRequest>> getPendingRequests() =>
      _plugin.pendingNotificationRequests();

  @override
  Future<bool> openNotificationSettings() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _androidPlugin?.openAppNotificationSettings() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return launchUrl(Uri.parse('app-settings:'));
    }
    return false;
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _iosPlugin => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();
}
