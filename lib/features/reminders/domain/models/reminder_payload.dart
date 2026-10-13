import 'dart:convert';

import 'reminder.dart';

class ReminderPayload {
  const ReminderPayload({
    required this.routineId,
    required this.dateKey,
    required this.kind,
    required this.title,
    required this.timezoneIdentifier,
  });
  final String routineId;
  final String dateKey;
  final ReminderType kind;
  final String title;
  final String timezoneIdentifier;

  static ReminderPayload? tryParse(String? value) {
    if (value == null) return null;
    try {
      final json = jsonDecode(value);
      if (json is! Map<String, dynamic> ||
          json['v'] != 1 ||
          json['type'] != 'routine' ||
          json['app'] != 'daisth') {
        return null;
      }
      final routine = json['routineId'];
      final date = json['date'];
      final kind = json['kind'];
      final title = json['title'];
      final zone = json['tz'];
      if (routine is! String ||
          !_supported.contains(routine) ||
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

  static const _supported = {
    'sholat-malam',
    'subuh',
    'dhuha',
    'zuhur',
    'asar',
    'maghrib',
    'isya',
    'reflection',
    'penutup-hari',
    'debug-test',
  };
}
