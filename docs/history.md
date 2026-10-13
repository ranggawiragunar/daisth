# History

Daily Reflection appears in a separate section below routine entries. It shows
the selected rhythm and a short note preview, or the neutral message
`No reflection recorded.` when absent. Reflection does not affect routine
summary counts or become `Unrecorded`. The section opens the same editor for
the selected historical date; a late entry is allowed and does not change
today's reminders.

History is a local, observational view of routine records. It has no score,
completion percentage, streak, chart, badge, or failure language.

## Dates and boundaries

The History list starts with yesterday and loads at most 30 calendar days at a
time. `Load earlier` fetches the preceding window and stops at the earliest
meaningful local date: the earlier of the first `routine_records.date_key` and
the local `CalendarDay` of the earliest routine definition's `created_at_utc`.
When no prior local date exists, History shows an empty state. The current day
is not included in the list.

All identity and grouping use `CalendarDay` and persisted `date_key` values.
`recorded_at_utc`, `completed_at_utc`, and `updated_at_utc` are event instants;
they are not used to infer which calendar day owns a record.

## Historical day meaning

The five mandatory prayers (Subuh, Zuhur, Asar, Maghrib, Isya) appear in a
fixed order on every valid historical day. If a mandatory routine has no
routine record for that day, its status is `Unrecorded`. Optional routines are
shown only when a routine record exists; absence means nothing was recorded,
not `Unrecorded`.

Persisted statuses are presented as `Completed`, `Partial`, or `Not Today`.
`Unrecorded` is derived by History and is not persisted. Not Today remains
available only for optional routines. Summaries count these categories without
ranking or scoring the day.

Penutup Hari is optional: it appears only on dates with a routine record and
does not produce `Unrecorded` when absent.

## Definitions and editing

Routine identity stays keyed by stable IDs. History resolves persisted routine
definitions and custom steps with archived definitions included, so later
archiving does not hide old records. Unknown orphaned definitions use a neutral
`Routine` label rather than exposing the internal ID.

Day and routine detail routes are `/history/:date` and
`/history/:date/routines/:routineId`. Historical Routine Detail reuses the
existing screen and view model with an explicit selected `CalendarDay`.
Writes keep `date_key` tied to that selected day while event timestamps use the
actual current UTC instant. Existing `recorded_at_utc` remains unchanged on
edits; completion instants are renewed on re-completion.

Clearing a record transactionally removes the routine row, its step rows, and
that day's reminder-state row. The app's routine-change listener reconciles OS
reminders only for the current local day, so historical edits do not schedule
or cancel current notifications. Definition settings are not editable from
History.
