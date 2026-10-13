enum ReminderAction { done, snooze, open }

abstract final class ReminderActionIds {
  static const done = 'daisth_done';
  static const snooze = 'daisth_snooze';
  static const open = 'daisth_open';

  static ReminderAction? parse(String? id) => switch (id) {
    done => ReminderAction.done,
    snooze => ReminderAction.snooze,
    open => ReminderAction.open,
    _ => null,
  };
}
