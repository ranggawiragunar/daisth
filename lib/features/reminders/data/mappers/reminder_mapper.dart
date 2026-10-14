import 'dart:convert';

import '../../domain/models/reminder.dart';
import '../../domain/models/reminder_payload.dart';
import '../../domain/models/reminder_priority.dart';
import '../models/reminder_schedule_data.dart';

class ReminderMapper {
  ReminderMapper({this.languageCode = 'id'});

  final String languageCode;

  bool get _english => languageCode.toLowerCase() == 'en';

  ReminderScheduleData toScheduleData(Reminder reminder) {
    final identity = reminder.id;
    final dateKey = reminder.dateKey ?? _dateFromIdentity(identity);
    final notificationId = stableNotificationId(identity);
    final payload = jsonEncode({
      'v': 1,
      'app': 'daisth',
      'type': reminder.targetType == ReminderTargetType.reflection
          ? 'reflection'
          : 'routine',
      if (reminder.targetType == ReminderTargetType.reflection)
        'target': 'reflection'
      else
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
          (decoded['type'] != 'routine' && decoded['type'] != 'reflection')) {
        return null;
      }
      final isReflection = decoded['type'] == 'reflection';
      final routineId = isReflection ? 'reflection' : decoded['routineId'];
      final identity = decoded['identity'];
      final scheduledString = decoded['scheduledAt'];
      if (routineId is! String ||
          (isReflection && decoded['target'] != 'reflection') ||
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
        targetType: isReflection || routineId == 'reflection'
            ? ReminderTargetType.reflection
            : ReminderTargetType.routine,
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
      return parsed.targetType == ReminderTargetType.reflection
          ? '/reflection'
          : '/today';
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
    'subuh' => _english ? 'Fajr is coming up' : 'Subuh segera masuk',
    'zuhur' => _english ? 'Dhuhr is coming up' : 'Waktu Zuhur mendekat',
    'asar' => _english ? 'Asr is coming up' : 'Waktu Asar mendekat',
    'maghrib' => _english ? 'Maghrib is coming up' : 'Waktu Maghrib mendekat',
    'isya' => _english ? 'Isha is coming up' : 'Waktu Isya mendekat',
    'dhuha' => _english ? 'Duha' : 'Waktu Dhuha',
    'sholat-malam' => _english ? 'Night Prayer' : 'Sholat Malam',
    'reflection' => 'Refleksi hari ini',
    'penutup-hari' => _english ? 'End of Day' : 'Penutup Hari',
    _ => _english ? 'Daisth reminder' : 'Pengingat Daisth',
  };

  static const _referenceRoutines = {'reflection'};
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
