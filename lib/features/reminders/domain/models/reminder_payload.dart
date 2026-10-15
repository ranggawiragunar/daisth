import 'dart:convert';

import 'reminder.dart';

class ReminderPayload {
  const ReminderPayload({
    required this.routineId,
    required this.dateKey,
    required this.kind,
    required this.title,
    required this.timezoneIdentifier,
    this.targetType = ReminderTargetType.routine,
  });
  final String routineId;
  final String dateKey;
  final ReminderType kind;
  final String title;
  final String timezoneIdentifier;
  final ReminderTargetType targetType;

  static ReminderPayload? tryParse(String? value) {
    if (value == null) return null;
    try {
      final json = jsonDecode(value);
      if (json is! Map<String, dynamic> ||
          json['v'] != 1 ||
          (json['type'] != 'routine' && json['type'] != 'reflection') ||
          json['app'] != 'daisth') {
        return null;
      }
      final isReflection = json['type'] == 'reflection';
      final routine = isReflection ? 'reflection' : json['routineId'];
      final date = json['date'];
      final kind = json['kind'];
      final title = json['title'];
      final zone = json['tz'];
      if (routine is! String ||
          (!isReflection && !_isSupportedRoutineId(routine)) ||
          (isReflection && json['target'] != 'reflection') ||
          date is! String ||
          !_validDate(date) ||
          title is! String ||
          zone is! String ||
          !_validTimezone(zone)) {
        return null;
      }
      final reminderKind = switch (kind) {
        'primary' => ReminderType.primary,
        'followUp' => ReminderType.followUp,
        'snooze' => ReminderType.snooze,
        _ => null,
      };
      if (reminderKind == null) return null;
      return ReminderPayload(
        routineId: routine,
        dateKey: date,
        kind: reminderKind,
        title: title,
        timezoneIdentifier: zone,
        targetType: isReflection || routine == 'reflection'
            ? ReminderTargetType.reflection
            : ReminderTargetType.routine,
      );
    } on Object {
      return null;
    }
  }

  static bool _validDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return false;
    final year = int.tryParse(parts[0]),
        month = int.tryParse(parts[1]),
        day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return false;
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day;
  }

  static bool _validTimezone(String value) =>
      value == 'UTC' ||
      RegExp(r'^[A-Za-z_+-]+(?:/[A-Za-z0-9_+.-]+)+$').hasMatch(value);

  static bool _isSupportedRoutineId(String value) =>
      _supported.contains(value) ||
      RegExp(r'^custom-[0-9a-f]+-[0-9a-f]{12}$').hasMatch(value);

  static const _supported = {
    'sholat-malam',
    'subuh',
    'dhuha',
    'zuhur',
    'asar',
    'maghrib',
    'isya',
    'penutup-hari',
    'debug-test',
    // Older scheduled notifications represented this system target as a
    // routine ID. New payloads use type/target = reflection instead.
    'reflection',
  };
}
