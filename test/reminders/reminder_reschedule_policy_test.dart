import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/features/reminders/domain/use_cases/reminder_reschedule_policy.dart';

void main() {
  const policy = ReminderReschedulePolicy();
  final today = DateTime(2026, 10, 13);

  test('date changes require rebuilding the plan', () {
    expect(
      policy.shouldReschedule(
        scheduledDate: today,
        scheduledTimezone: 'Asia/Jakarta',
        currentDate: DateTime(2026, 10, 14),
        currentTimezone: 'Asia/Jakarta',
      ),
      isTrue,
    );
  });

  test('timezone changes require rebuilding the plan', () {
    expect(
      policy.shouldReschedule(
        scheduledDate: today,
        scheduledTimezone: 'Asia/Jakarta',
        currentDate: today,
        currentTimezone: 'America/New_York',
      ),
      isTrue,
    );
  });

  test('same date and timezone do not force a rebuild', () {
    expect(
      policy.shouldReschedule(
        scheduledDate: today,
        scheduledTimezone: 'Asia/Jakarta',
        currentDate: DateTime(2026, 10, 13, 23),
        currentTimezone: 'Asia/Jakarta',
      ),
      isFalse,
    );
  });
}
