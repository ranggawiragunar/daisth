# Local reminders

Istiqam schedules primary reminders on the device with
`flutter_local_notifications`. It builds a plan for today only and schedules
using the device's IANA timezone, resolved through `flutter_timezone` and
`timezone`. A timezone or calendar-date change is checked when the app resumes;
an explicit prayer-time refresh also rebuilds the remaining reminders.

The five mandatory prayers use the existing `PrayerDaySchedule`, with the
primary reminder ten minutes before Fajr, Dhuhr, Asr, Maghrib, and Isha. Sholat
Malam is planned for 03:00, Dhuha for 07:00, Daily Reflection for 20:30, and
Penutup Hari for 21:00. Past times are skipped. Only primary reminders are
scheduled.

Android uses the `istiqam_high` channel for mandatory prayers and Sholat Malam,
and `istiqam_standard` for Dhuha and evening reminders. If Android exact-alarm
access is granted, reminders use exact allow-while-idle scheduling. Otherwise
they use an inexact allow-while-idle schedule. Notification permission is
requested only after the user enables reminders in Settings. The app uses
standard system sound and vibration behavior; it does not request DND bypass,
full-screen intent, or critical-alert capabilities. iOS requests regular alert
and sound permission only when the user enables reminders.

Settings shows notification permission, precise-alarm availability, timezone,
and pending reminders for today. The enabled preference is stored locally with
the app settings and restored on launch. OS permission remains controlled by
the operating system and is checked again when the app resumes. Istiqam does
not request permission automatically during restoration.

Notification taps open the matching Routine Detail through `go_router`.
Reflection and Penutup Hari open Today. Done, Snooze, follow-up reminders,
persistent routine completion, Firebase, and multi-device coordination are
deferred until their required durable state exists.
