# Settings

Settings groups the device and account controls into Appearance, Prayer &
Location, Notifications, Account & Sync, Data & Privacy, and About. The existing
System / Light / Dark theme choice stays in `app_settings` and remains local to
the installation.

## Prayer & Location

The page reuses `LocationRepository`, `PrayerScheduleSession`, and
`TimezoneRepository`. It reports permission/service state and whether a
last-known position was used, without rendering coordinates. Opening the page
checks status only. Location permission and system-settings actions happen only
after a user tap. Prayer calculation remains KEMENAG with Shafi Asr; settings do
not expose calculation controls. Refresh recalculates through the existing
prayer schedule use case and invokes the ordinary reminder refresh path.

The app lifecycle coordinator refreshes location access, current schedule,
notification permission, exact-alarm state, device timezone, and Reminder
Health after resume. Timezone is read from the device and is never a manually
editable preference. Historical `CalendarDay` values are not rewritten.

## Notifications

The page shows the local reminder toggle, notification permission, precise or
standard Android timing, current timezone, upcoming reminder count, last
reminder action, and the user-facing pending list. Plugin notification IDs are
not presented. Notification permission is requested only through a user action
or the existing reminder enable flow. If the OS permission prompt is no longer
available, the user can open Daisth's system notification settings. The exact
alarm action uses the installed notification plugin API and does not request
DND bypass, full-screen intent, or `USE_EXACT_ALARM`.

Developer test-notification controls are guarded by `kDebugMode` and are absent
from release builds. Theme and global reminder preference are stored locally
and do not enter the Firestore outbox.

## Data & Privacy

Routine, History, custom routine, Reflection, appearance, and reminder data are
stored locally. Cloud sync is optional; when active, the syncable records are
stored under the signed-in Firebase UID's private Firestore path. Location is
used for prayer times and nearby mosque search. Reflection notes are not placed
in notification payloads. Daisth currently does not include Firebase Analytics.
The screen does not invent a Privacy Policy or Terms URL.

## About

About uses existing Daisth brand assets and Flutter's built-in open-source
license page. Version/build display is deferred until the app exposes it
without an additional package.
