# Routine configuration

Daisth stores routine configuration separately from the daily progress rows.
The `routine_definitions` and `routine_step_definitions` tables describe what
the user plans to do. `routine_records`, `routine_step_records`, and
`routine_reminder_states` retain per-day progress and reminder actions.

## Default routines

The canonical default IDs are `sholat-malam`, `subuh`, `dhuha`, `zuhur`,
`asar`, `maghrib`, `isya`, and `penutup-hari`. The
`DefaultRoutineTemplateCatalog` is the factory catalog. Startup copies a
template only when its stable ID is missing; an existing definition is a
user-owned copy and is never silently refreshed. Reset to Default copies the
catalog's configurable values for that one routine and leaves daily history
intact.

Users can enable or disable defaults and toggle their reminders. Fixed times
can be edited for Sholat Malam, Dhuha, and Penutup Hari. Prayer routines keep a
stable prayer key and continue to use the current Prayer Time schedule. Default
titles and built-in capabilities remain part of the product definition.

Disabling a routine removes it from active Today planning and future reminder
scheduling. It does not create a Not Today record or erase earlier progress.
Default routines cannot be archived.

## Custom routines

Custom routines repeat daily at a fixed local wall-clock time. They are always
optional and can be marked Not Today using the existing routine behavior. A
custom routine may have no checklist, in which case the routine itself is the
completion action. If it has checklist steps, at least one must be required;
optional steps do not block completion.

Routine and step IDs are opaque and independent of titles. Renaming a routine
or step preserves its identity. Deleting a custom routine archives its
definition and disables it. Removing a checklist step archives that step.
These operations preserve daily records and reminder history for future
History support.

Custom definitions persist locally in `daisth.db`; cloud sync and complex
recurrence rules are outside this feature.
