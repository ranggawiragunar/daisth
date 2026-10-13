import '../../../../core/time/domain/models/calendar_day.dart';
import '../../../routines/data/demo/routine_demo_data.dart';
import '../../../routines/domain/models/routine_status.dart';
import '../../../routines/domain/repositories/routine_record_repository.dart';
import '../../../routines/domain/use_cases/mark_routine_complete_use_case.dart';
import '../models/reminder.dart';
import '../models/exact_alarm_status.dart';
import '../models/reminder_action.dart';
import '../models/reminder_payload.dart';
import '../models/reminder_priority.dart';
import '../models/reminder_scheduling_mode.dart';
import '../repositories/reminder_repository.dart';
import '../repositories/routine_reminder_state_repository.dart';

class HandleReminderActionUseCase {
  HandleReminderActionUseCase({
    required this.routineRepository,
    required this.reminderStateRepository,
    required this.reminderRepository,
    required this.markRoutineComplete,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;
  final RoutineRecordRepository routineRepository;
  final RoutineReminderStateRepository reminderStateRepository;
  final ReminderRepository reminderRepository;
  final MarkRoutineCompleteUseCase markRoutineComplete;
  final DateTime Function() _clock;

  Future<void> call({
    required ReminderAction action,
    required ReminderPayload payload,
    DateTime? actionAt,
  }) async {
    final routine = RoutineDemoData.byId(payload.routineId);
    if (routine == null) return;
    final parts = payload.dateKey.split('-').map(int.parse).toList();
    final day = CalendarDay(year: parts[0], month: parts[1], day: parts[2]);
    final now = (actionAt ?? _clock()).toUtc();
    if (action == ReminderAction.open) {
      await reminderStateRepository.recordAction(
        day: day,
        routineId: routine.id,
        action: 'open',
        now: now,
      );
      return;
    }
    final current = await routineRepository.getRoutineRecord(day, routine.id);
    if (current?.status == RoutineStatus.completed ||
        current?.status == RoutineStatus.notToday) {
      if (current?.status == RoutineStatus.completed) {
        await _cancelFuture(payload, now);
      }
      return;
    }
    if (action == ReminderAction.done) {
      // Existing completion semantics preserve optional progress and mark only requirements.
      await markRoutineComplete(
        routine: routine,
        day: day,
        now: now,
        includeOptional: false,
      );
      await _cancelFuture(payload, now);
      await reminderStateRepository.recordAction(
        day: day,
        routineId: routine.id,
        action: 'done',
        now: now,
      );
      return;
    }
    final snoozedUntil = now.add(const Duration(minutes: 10));
    final id = '${routine.id}-snooze-${payload.dateKey}';
    final snooze = Reminder(
      id: id,
      routineId: routine.id,
      title: payload.title,
      body: 'Pengingat yang kamu tunda.',
      scheduledAt: snoozedUntil,
      priority: _priority(routine.id),
      type: ReminderType.snooze,
      dateKey: payload.dateKey,
      timezoneIdentifier: payload.timezoneIdentifier,
    );
    final exact = await reminderRepository.getExactAlarmStatus();
    await reminderRepository.schedule(
      snooze,
      mode: exact == ExactAlarmStatus.enabled
          ? ReminderSchedulingMode.exact
          : ReminderSchedulingMode.inexact,
    );
    await reminderStateRepository.recordSnooze(
      day: day,
      routineId: routine.id,
      snoozedUntil: snoozedUntil,
      now: now,
    );
    await _cancelKind(
      routine.id,
      payload.dateKey,
      ReminderType.followUp,
      payload,
    );
  }

  Future<void> _cancelFuture(ReminderPayload payload, DateTime now) async {
    for (final kind in [ReminderType.followUp, ReminderType.snooze]) {
      await _cancelKind(payload.routineId, payload.dateKey, kind, payload);
    }
    await reminderStateRepository.clearSnooze(
      _day(payload.dateKey),
      payload.routineId,
      now: now,
    );
    await reminderStateRepository.clearFollowUp(
      _day(payload.dateKey),
      payload.routineId,
      now: now,
    );
  }

  Future<void> _cancelKind(
    String routineId,
    String date,
    ReminderType kind,
    ReminderPayload payload,
  ) async {
    final tag = switch (kind) {
      ReminderType.followUp => 'follow-up',
      ReminderType.snooze => 'snooze',
      ReminderType.primary => 'primary',
    };
    await reminderRepository.cancel(
      Reminder(
        id: '$routineId-$tag-$date',
        routineId: routineId,
        title: payload.title,
        body: '',
        scheduledAt: DateTime.now(),
        priority: _priority(routineId),
        type: kind,
        dateKey: date,
        timezoneIdentifier: payload.timezoneIdentifier,
      ),
    );
  }

  CalendarDay _day(String date) {
    final p = date.split('-').map(int.parse).toList();
    return CalendarDay(year: p[0], month: p[1], day: p[2]);
  }

  ReminderPriority _priority(String id) =>
      const {
        'zuhur',
        'asar',
        'maghrib',
        'isya',
        'subuh',
        'sholat-malam',
      }.contains(id)
      ? ReminderPriority.high
      : ReminderPriority.medium;
}
