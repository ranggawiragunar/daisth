import 'dart:convert';

import '../../domain/models/reminder.dart';
import '../../domain/models/reminder_priority.dart';
import '../models/reminder_schedule_data.dart';

class ReminderMapper {
  ReminderScheduleData toScheduleData(Reminder reminder) {
    final identity = reminder.id;
    final notificationId = _stableNotificationId(identity);
    final payload = jsonEncode({
      'v': 1,
      'app': 'istiqam',
      'type': 'routine',
      'routineId': reminder.routineId,
      'identity': identity,
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
          decoded['app'] != 'istiqam' ||
          decoded['v'] != 1 ||
          decoded['type'] != 'routine') {
        return null;
      }
      final id = decoded['identity'];
      final routineId = decoded['routineId'];
      final scheduledAtString = decoded['scheduledAt'];
      if (id is! String ||
          routineId is! String ||
          scheduledAtString is! String) {
        return null;
      }
      final scheduledAt = DateTime.tryParse(scheduledAtString);
      if (scheduledAt == null) return null;
      return Reminder(
        id: id,
        routineId: routineId,
        title: title ?? _fallbackTitle(routineId),
        body: body ?? '',
        scheduledAt: scheduledAt,
        priority:
            id.contains('primary-') &&
                const {
                  'subuh',
                  'zuhur',
                  'asar',
                  'maghrib',
                  'isya',
                  'sholat-malam',
                }.contains(routineId)
            ? ReminderPriority.high
            : ReminderPriority.medium,
      );
    } on FormatException {
      return null;
    }
  }

  String? routeForPayload(String? payload) {
    if (payload == null) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic> ||
          decoded['app'] != 'istiqam' ||
          decoded['v'] != 1 ||
          decoded['type'] != 'routine') {
        return null;
      }
      final routineId = decoded['routineId'];
      if (routineId is! String) return null;
      if (const {
        'reflection',
        'penutup-hari',
        'debug-test',
      }.contains(routineId)) {
        return '/today';
      }
      if (const {
        'sholat-malam',
        'dhuha',
        'subuh',
        'zuhur',
        'asar',
        'maghrib',
        'isya',
      }.contains(routineId)) {
        return '/routines/$routineId';
      }
      return null;
    } on FormatException {
      return null;
    }
  }

  int _stableNotificationId(String value) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
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
    _ => 'Pengingat Istiqam',
  };

  static const highChannelId = 'istiqam_high';
  static const standardChannelId = 'istiqam_standard';
}
