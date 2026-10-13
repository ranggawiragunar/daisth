# Local persistence

Istiqam stores local app state in `istiqam.db`, managed by
`IstiqamDatabaseService`. The database currently uses schema version 1 and
SQLite migrations through `onCreate` and `onUpgrade`.

## Stored data

- `routine_records` stores a routine's status, completion instant, first
  recorded instant, last updated instant, and optional Not Today reason.
- `routine_step_records` stores each step's completion state and timestamps.
- `app_settings` stores the theme preference and reminder enabled preference.

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

This phase does not persist Dhikr counter position, location coordinates,
mosque results or cache entries, Reader presentation state, or remote account
data. Mosque and prayer-time behavior continue to use their existing services.
