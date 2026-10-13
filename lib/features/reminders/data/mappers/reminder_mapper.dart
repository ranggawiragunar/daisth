import 'dart:convert';

import '../../domain/models/reminder.dart';
import '../../domain/models/reminder_payload.dart';
import '../../domain/models/reminder_priority.dart';
import '../models/reminder_schedule_data.dart';

class ReminderMapper {
  ReminderScheduleData toScheduleData(Reminder reminder) {
    final identity = reminder.id;
    final dateKey = reminder.dateKey ?? _dateFromIdentity(identity);
    final notificationId = stableNotificationId(identity);
    final payload = jsonEncode({
      'v': 1,
      'app': 'daisth',
      'type': 'routine',
      'routineId': reminder.routineId,
      'identity': identity,
      'date': dateKey,
      'kind': switch (reminder.type) {
        ReminderType.primary => 'primary',
        ReminderType.followUp => 'followUp',
        ReminderType.snooze => 'snooze',
      },
      'title': reminder.title,
      'tz': reminder.timezoneIdentifier,
      'scheduledAt': reminder.scheduledAt.toIso8601String(),
    });
    return ReminderScheduleData(
      notificationId: notificationId,
      identity: identity,
      routineId: reminder.routineId,
      title: reminder.title,
      body: reminder.body,
      scheduledAt: reminder.scheduledAt,
      channelId: reminder.priority == ReminderPriority.high
          ? highChannelId
          : standardChannelId,
      payload: payload,
      actionable: reminder.actionable,
    );
  }

  Reminder? fromPending({
    required int notificationId,
    required String? title,
    required String? body,
    required String? payload,
  }) {
    if (payload == null) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic> ||
          decoded['app'] != 'daisth' ||
          decoded['v'] != 1 ||
          decoded['type'] != 'routine') {
        return null;
      }
      final routineId = decoded['routineId'];
      final identity = decoded['identity'];
      final scheduledString = decoded['scheduledAt'];
      if (routineId is! String ||
          identity is! String ||
          scheduledString is! String) {
        return null;
      }
      final scheduledAt = DateTime.tryParse(scheduledString);
      if (scheduledAt == null) return null;
      final kind = switch (decoded['kind']) {
        'followUp' => ReminderType.followUp,
        'snooze' => ReminderType.snooze,
        _ => ReminderType.primary,
      };
      return Reminder(
        id: identity,
        routineId: routineId,
        title:
            title ?? (decoded['title'] as String? ?? _fallbackTitle(routineId)),
        body: body ?? '',
        scheduledAt: scheduledAt,
        priority: _highPriorityRoutines.contains(routineId)
            ? ReminderPriority.high
            : ReminderPriority.medium,
        type: kind,
        dateKey: decoded['date'] as String?,
        timezoneIdentifier: decoded['tz'] as String? ?? 'UTC',
        actionable: !_referenceRoutines.contains(routineId),
      );
    } on Object {
      return null;
    }
  }

  String? routeForPayload(String? payload) {
    final parsed = ReminderPayload.tryParse(payload);
    if (parsed == null) return null;
    if (_referenceRoutines.contains(parsed.routineId) ||
        parsed.routineId == 'debug-test') {
      return '/today';
    }
    return '/routines/${parsed.routineId}';
  }

  int stableNotificationId(String value) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  String _dateFromIdentity(String identity) {
    final match = RegExp(r'(\d{4}-\d{2}-\d{2})$').firstMatch(identity);
    return match?.group(1) ?? DateTime.now().toIso8601String().substring(0, 10);
  }

  String _fallbackTitle(String routineId) => switch (routineId) {
    'subuh' => 'Subuh segera masuk',
    'zuhur' => 'Waktu Zuhur mendekat',
    'asar' => 'Waktu Asar mendekat',
    'maghrib' => 'Waktu Maghrib mendekat',
    'isya' => 'Waktu Isya mendekat',
    'dhuha' => 'Waktu Dhuha',
    'sholat-malam' => 'Sholat Malam',
    'reflection' => 'Refleksi hari ini',
    'penutup-hari' => 'Penutup Hari',
    _ => 'Pengingat Daisth',
  };

  static const _referenceRoutines = {'reflection', 'penutup-hari'};
  static const _highPriorityRoutines = {
    'subuh',
    'zuhur',
    'asar',
    'maghrib',
    'isya',
    'sholat-malam',
  };
  static const highChannelId = 'daisth_high';
  static const standardChannelId = 'daisth_standard';
}
