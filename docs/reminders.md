# Local reminders

Daisth schedules primary reminders on the device with
`flutter_local_notifications`. It builds a plan for today only and schedules
using the device's IANA timezone, resolved through `flutter_timezone` and
`timezone`. A timezone or calendar-date change is checked when the app resumes;
an explicit prayer-time refresh also rebuilds the remaining reminders.

The five mandatory prayers use the existing `PrayerDaySchedule`, with the
primary reminder ten minutes before Fajr, Dhuhr, Asr, Maghrib, and Isha. Sholat
Malam is planned for 03:00, Dhuha for 07:00, Daily Reflection for 20:30, and
Penutup Hari at its persisted preferred time (21:00 by default). Past primary times are skipped. One automatic
follow-up can be scheduled for each supported routine day. Zuhur, Asar, and
Maghrib use the next same-day prayer boundary with a one-hour window-end target
and a 45-minute minimum gap; Sholat Malam, Subuh, Dhuha, and Isya use one hour
after the primary reminder. Penutup Hari uses the same one-hour fallback.
Follow-up is skipped when its time has passed, the
routine is complete or Not Today, or the user has snoozed it.

Android uses the `daisth_high` channel for mandatory prayers and Sholat Malam,
and `daisth_standard` for Dhuha and evening reminders. If Android exact-alarm
access is granted, reminders use exact allow-while-idle scheduling. Otherwise
they use an inexact allow-while-idle schedule. Notification permission is
requested only after the user enables reminders in Settings. The app uses
standard system sound and vibration behavior; it does not request DND bypass,
full-screen intent, or critical-alert capabilities. iOS requests regular alert
and sound permission only when the user enables reminders.

Settings has a Notifications detail surface showing permission, precise or
standard timing, timezone, Reminder Health, last action, and upcoming reminders
without exposing plugin IDs. Debug-only test notification controls are guarded
by `kDebugMode`. The enabled preference is stored locally with
the app settings and restored on launch. OS permission remains controlled by
the operating system and is checked again when the app resumes. Daisth does
not request permission automatically during restoration.

On resume, the app refreshes notification and exact-alarm permission even when
reminders are off. It also refreshes device timezone and reconciles the current
schedule only when reminders are enabled and notification permission is
granted. `Standard timing` indicates inexact Android scheduling is available;
it is not an error state.

Actionable routine reminders offer Done, Snooze, and Open. Daily Reflection is
a local system reminder at 20:30 with medium priority. It is Open-only and
routes to `/reflection`; it has no Snooze or follow-up. When today's reflection
is already saved, reconciliation cancels or omits the pending Reflection
reminder. Saving before 20:30 removes that reminder; clearing before 20:30 may
restore it when reminders remain enabled and permission is granted. Clearing
after 20:30 does not schedule a retroactive reminder. Historical reflection
changes never reconcile today's notifications. Penutup Hari supports Done,
Snooze, and Open. Done uses the existing routine completion use case and payload date;
Penutup Hari Done completes its six required readings and leaves optional Wudu
unchanged. Snooze replaces one reminder ten minutes later and suppresses that
day's automatic follow-up. Open and body taps route to the matching Routine
Detail through `go_router` without changing progress.

Android Done/Snooze actions run in the notification background engine. The
top-level callback builds its own SQLite and reminder services and calls the
same `HandleReminderActionUseCase` used by foreground dispatch. iOS registers
routine and reference categories at initialization; the implicit Flutter
engine's plugin registrant callback supports the action engine. Daisth stores
the last action, snooze instant, follow-up instant, and suppression flag in
`routine_reminder_states`. On startup/resume, schedule reconciliation restores
future snoozes and eligible follow-ups while respecting persisted completion
and suppression.

Normal routine completion changes are observed through the routine repository
change stream and cancel that day's follow-up and snooze notifications.
Background Done performs cancellation after the SQLite completion commits.
