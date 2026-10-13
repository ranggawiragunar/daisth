import '../../domain/models/prayer_key.dart';
import '../../domain/models/routine_definition.dart';
import '../../domain/models/routine_origin.dart';
import '../../domain/models/routine_priority.dart';
import '../../domain/models/routine_schedule.dart';

abstract final class DefaultRoutineTemplateCatalog {
  static const keys = [
    'sholat-malam',
    'subuh',
    'dhuha',
    'zuhur',
    'asar',
    'maghrib',
    'isya',
    'penutup-hari',
  ];

  static List<RoutineDefinition> definitions(DateTime now) {
    final instant = now.toUtc();
    return [
      _fixed(
        'sholat-malam',
        'Sholat Malam',
        180,
        RoutinePriority.high,
        0,
        instant,
      ),
      _prayer(
        'subuh',
        'Subuh',
        PrayerKey.subuh,
        RoutinePriority.high,
        1,
        instant,
      ),
      _fixed('dhuha', 'Dhuha', 420, RoutinePriority.medium, 2, instant),
      _prayer(
        'zuhur',
        'Zuhur',
        PrayerKey.zuhur,
        RoutinePriority.high,
        3,
        instant,
      ),
      _prayer('asar', 'Asar', PrayerKey.asar, RoutinePriority.high, 4, instant),
      _prayer(
        'maghrib',
        'Maghrib',
        PrayerKey.maghrib,
        RoutinePriority.high,
        5,
        instant,
      ),
      _prayer('isya', 'Isya', PrayerKey.isya, RoutinePriority.high, 6, instant),
      _fixed(
        'penutup-hari',
        'Penutup Hari',
        1260,
        RoutinePriority.medium,
        7,
        instant,
      ),
    ];
  }

  static RoutineDefinition _fixed(
    String id,
    String title,
    int minutes,
    RoutinePriority priority,
    int order,
    DateTime now,
  ) => RoutineDefinition(
    id: id,
    origin: RoutineOrigin.defaultRoutine,
    templateKey: id,
    title: title,
    description: null,
    isEnabled: true,
    isArchived: false,
    schedule: RoutineSchedule.fixed(minutes),
    reminderEnabled: true,
    priority: priority,
    sortOrder: order,
    createdAt: now,
    updatedAt: now,
  );

  static RoutineDefinition _prayer(
    String id,
    String title,
    PrayerKey key,
    RoutinePriority priority,
    int order,
    DateTime now,
  ) => RoutineDefinition(
    id: id,
    origin: RoutineOrigin.defaultRoutine,
    templateKey: id,
    title: title,
    description: null,
    isEnabled: true,
    isArchived: false,
    schedule: RoutineSchedule.prayer(key),
    reminderEnabled: true,
    priority: priority,
    sortOrder: order,
    createdAt: now,
    updatedAt: now,
  );
}
