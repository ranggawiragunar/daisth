# Local persistence

Daisth stores local app state in `daisth.db`, managed by
`DaisthDatabaseService`. The database currently uses schema version 3 and
SQLite migrations through `onCreate` and `onUpgrade`.

## Stored data

- `routine_records` stores a routine's status, completion instant, first
  recorded instant, last updated instant, and optional Not Today reason.
- `routine_step_records` stores each step's completion state and timestamps.
- `app_settings` stores the theme preference and reminder enabled preference.
- `routine_reminder_states` stores one row per routine and calendar day,
  including snooze time, follow-up schedule/suppression, and the last action.
- `routine_definitions` stores user-owned default and custom routine
  configuration.
- `routine_step_definitions` stores custom checklist definitions. Removed
  steps are archived so historical records can still be interpreted.

Definitions/configuration are separate from daily progress:
`routine_definitions` and `routine_step_definitions` describe the user's plan;
`routine_records`, `routine_step_records`, and `routine_reminder_states` retain
day-specific progress and reminder actions. Disabling or archiving a routine
does not delete historical rows.

Routine keys use the device's local calendar date in `YYYY-MM-DD` form. Event
timestamps are stored as UTC ISO 8601 instants. This keeps records associated
with the day the user sees locally while retaining unambiguous event times.
Composite primary keys prevent duplicate routine or step rows for a day.

Routine and step changes are committed together in one SQLite transaction.
Status comes from the required steps: no completed required steps is pending,
some is partial, and all is completed. Optional steps can be saved without
changing required completion. Not Today is available only for optional
routines.

## Upgrade policy and scope

Schema changes must increment the database version and apply additive
migrations. Do not drop user data as part of an upgrade. The SQLite database
is the source of truth for daily routine progress and the two persisted app
preferences.

The version 1 to 2 migration creates `routine_reminder_states` additively and
leaves routine records, step records, and app settings intact. Its composite
key is `(date_key, routine_id)`; instants are stored as UTC ISO 8601 values.

The version 2 to 3 migration additively creates `routine_definitions` and
`routine_step_definitions`. It leaves existing routine records, reminder
states, and settings intact and does not seed product values. Startup bootstrap
inserts missing factory defaults into user-owned definitions without
overwriting existing configuration. An explicit per-routine reset copies that
routine's factory values again.

The development rebrand changed the database filename and application
identifier before release. No copy or migration from the previous development
database is included; a rebranded development install starts with a fresh local
database; existing Daisth installs upgrade in place to schema version 3.

This phase does not persist Dhikr counter position, location coordinates,
mosque results or cache entries, Reader presentation state, or remote account
data. Mosque and prayer-time behavior continue to use their existing services.
