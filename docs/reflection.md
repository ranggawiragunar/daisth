# Daily Reflection

Daily Reflection is a private, local system feature, not a routine. It asks
“Bagaimana ritmemu hari ini?” and offers three neutral observations:

| Stable value | Label |
| --- | --- |
| `steady` | Terasa mengalir |
| `mixed` | Naik turun |
| `heavy` | Terasa berat |

A rhythm is required to save. A note is optional, multiline, and limited to 500
characters. Leading and trailing whitespace is trimmed; blank-only notes are
stored as `NULL`, while internal line breaks are preserved. Saving is explicit.
There are no scores, streaks, advice, or generated insights.

The `daily_reflections` table stores one row per local `CalendarDay` using its
`YYYY-MM-DD` `date_key`. The stable persisted rhythm values are not localized
labels. The first save sets `recorded_at_utc` and `updated_at_utc` to the actual
UTC action instant. Later edits preserve `recorded_at_utc` and update only
`updated_at_utc`. Notes remain on-device; they are not logged, sent to a
service, or included in reminder payloads.

`/reflection` edits today's `CalendarDay`; `/history/:date/reflection` edits the
selected historical day with the same screen and view model. Reflection is
shown separately from routine summaries in History. Its absence is neutral and
does not count as missing or incomplete. Late historical entry is supported.

The single daily reminder remains at 20:30 local device time with medium
priority. It is Open-only, routes to `/reflection`, and has no Snooze or
follow-up. A saved current-day reflection suppresses the reminder. Saving or
clearing a historical reflection never schedules, cancels, or reconciles
today's notifications.
