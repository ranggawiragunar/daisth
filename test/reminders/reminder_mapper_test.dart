import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/app/router/reminder_notification_route_resolver.dart';
import 'package:daisth/features/reminders/data/mappers/reminder_mapper.dart';
import 'package:daisth/features/reminders/domain/models/reminder.dart';
import 'package:daisth/features/reminders/domain/models/reminder_priority.dart';
import 'package:daisth/features/reminders/domain/models/reminder_payload.dart';
import 'package:daisth/features/reminders/domain/models/reminder_action.dart';

void main() {
  final mapper = ReminderMapper();

  test('routine payload routes to routine detail and remains stable', () {
    final reminder = Reminder(
      id: 'zuhur-primary-2026-10-13',
      routineId: 'zuhur',
      title: 'Waktu Zuhur mendekat',
      body: 'Sekitar 10 menit lagi.',
      scheduledAt: DateTime(2026, 10, 13, 11, 50),
      priority: ReminderPriority.high,
    );
    final first = mapper.toScheduleData(reminder);
    final second = mapper.toScheduleData(reminder);

    expect(first.notificationId, second.notificationId);
    expect(first.channelId, ReminderMapper.highChannelId);
    expect(mapper.routeForPayload(first.payload), '/routines/zuhur');
    expect(
      mapper.routeForPayload(mapper.toScheduleData(_routine('subuh')).payload),
      '/routines/subuh',
    );
    expect(
      mapper.routeForPayload(
        mapper.toScheduleData(_routine('maghrib')).payload,
      ),
      '/routines/maghrib',
    );
  });

  test('reflection uses its system target; Penutup Hari opens its routine', () {
    final reflection = _routine('reflection').copyWithTargetReflection();
    final data = mapper.toScheduleData(reflection);
    final payload = ReminderPayload.tryParse(data.payload)!;
    expect(payload.targetType, ReminderTargetType.reflection);
    expect(data.payload, contains('"type":"reflection"'));
    expect(data.payload, contains('"target":"reflection"'));
    expect(data.payload, isNot(contains('"routineId"')));
    expect(data.actionable, isFalse);
    expect(mapper.routeForPayload(data.payload), '/reflection');
    final previousPayload =
        '{"v":1,"app":"daisth","type":"routine","routineId":"reflection","identity":"reflection-primary-2026-10-13","date":"2026-10-13","kind":"primary","title":"Refleksi hari ini","tz":"Asia/Jakarta","scheduledAt":"2026-10-13T20:30:00.000"}';
    expect(mapper.routeForPayload(previousPayload), '/reflection');
    expect(
      mapper.routeForPayload(
        mapper.toScheduleData(_routine('penutup-hari')).payload,
      ),
      '/routines/penutup-hari',
    );
    expect(mapper.toScheduleData(_routine('penutup-hari')).actionable, isTrue);
  });

  test('malformed and unknown payloads safely fall back to Today', () {
    final resolver = ReminderNotificationRouteResolver(mapper);
    expect(resolver.resolve('{not json'), '/today');
    expect(
      resolver.resolve(
        '{"v":1,"app":"daisth","type":"routine","routineId":"unknown"}',
      ),
      '/today',
    );
    expect(resolver.resolve(null), '/today');
  });

  test(
    'payload preserves date, kind, title and timezone and rejects malformed data',
    () {
      final reminder = Reminder(
        id: 'zuhur-snooze-2026-10-13',
        routineId: 'zuhur',
        title: 'Zuhur',
        body: 'Tunda',
        scheduledAt: DateTime(2026, 10, 13, 12),
        priority: ReminderPriority.high,
        type: ReminderType.snooze,
        dateKey: '2026-10-13',
        timezoneIdentifier: 'Asia/Jakarta',
      );
      final payload = ReminderPayload.tryParse(
        mapper.toScheduleData(reminder).payload,
      )!;
      expect(payload.dateKey, '2026-10-13');
      expect(payload.kind, ReminderType.snooze);
      expect(payload.title, 'Zuhur');
      expect(payload.timezoneIdentifier, 'Asia/Jakarta');
      expect(ReminderPayload.tryParse('{bad'), isNull);
      expect(ReminderPayload.tryParse('{"v":8}'), isNull);
      expect(
        ReminderPayload.tryParse(
          '{"v":1,"app":"daisth","type":"routine","routineId":"zuhur","kind":"primary","title":"Z","date":"2026-99-99","tz":"Asia/Jakarta"}',
        ),
        isNull,
      );
      expect(
        ReminderPayload.tryParse(
          '{"v":1,"app":"daisth","type":"routine","routineId":"zuhur","kind":"primary","title":"Z","date":"2026-10-13","tz":"NotATimezone"}',
        ),
        isNull,
      );
      expect(ReminderActionIds.parse('daisth_done'), ReminderAction.done);
      expect(ReminderActionIds.parse('Complete'), isNull);
    },
  );

  test('stable ids differ by kind and match across mapper instances', () {
    final first = ReminderMapper();
    final second = ReminderMapper();
    final ids = [
      'zuhur-primary-2026-10-13',
      'zuhur-follow-up-2026-10-13',
      'zuhur-snooze-2026-10-13',
    ];
    final firstIds = ids.map(first.stableNotificationId).toList();
    expect(ids.map(second.stableNotificationId).toList(), firstIds);
    expect(firstIds.toSet(), hasLength(3));
  });
}

Reminder _routine(String routineId) => Reminder(
  id: '$routineId-primary-2026-10-13',
  routineId: routineId,
  title: 'Reminder',
  body: 'Reminder body',
  scheduledAt: DateTime(2026, 10, 13, 11, 50),
  priority: ReminderPriority.medium,
);

extension on Reminder {
  Reminder copyWithTargetReflection() => Reminder(
    id: id,
    routineId: routineId,
    title: title,
    body: body,
    scheduledAt: scheduledAt,
    priority: priority,
    type: type,
    dateKey: dateKey,
    timezoneIdentifier: timezoneIdentifier,
    actionable: false,
    targetType: ReminderTargetType.reflection,
  );
}
