import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/app/router/reminder_notification_route_resolver.dart';
import 'package:daisth/features/reminders/data/mappers/reminder_mapper.dart';
import 'package:daisth/features/reminders/domain/models/reminder.dart';
import 'package:daisth/features/reminders/domain/models/reminder_priority.dart';

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

  test('reflection and closing reminders route to Today', () {
    expect(
      mapper.routeForPayload(
        mapper.toScheduleData(_routine('reflection')).payload,
      ),
      '/today',
    );
    expect(
      mapper.routeForPayload(
        mapper.toScheduleData(_routine('penutup-hari')).payload,
      ),
      '/today',
    );
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
}

Reminder _routine(String routineId) => Reminder(
  id: '$routineId-primary-2026-10-13',
  routineId: routineId,
  title: 'Reminder',
  body: 'Reminder body',
  scheduledAt: DateTime(2026, 10, 13, 11, 50),
  priority: ReminderPriority.medium,
);
