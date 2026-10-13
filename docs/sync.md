# Account Data Sync

Daisth uses SQLite as its working source of truth. Feature screens and feature
repositories continue reading and writing SQLite. Firestore is an optional,
private account synchronization layer; a signed-out, offline, or unavailable
cloud service does not block local routine, History, Reflection, or Penutup Hari
work.

## Link model

Each installation has one local dataset and one stable random 192-bit device
identifier stored in `sync_metadata`. The identifier is generated with
`Random.secure()` and is not derived from device hardware, Firebase, email, or
UID. A Google sign-in does not claim local data. The user explicitly activates
sync from Account after seeing the account email and a merge confirmation.

The first activation reads the complete private Firestore dataset before
changing local linkage. If that read fails, `linked_uid` remains empty. The
first local merge and setting of `linked_uid` / `initial_sync_completed` happen
in one SQLite transaction. This release supports one local dataset linked to
one Firebase UID; account profile switching is not supported. Signing out
retains the local database, UID link, and pending outbox. A different signed-in
UID is locked out from all sync reads and writes until the originally linked
account signs in again.

## Data boundaries

The synchronized entities are:

- `routine_definitions`
- `routine_step_definitions`
- `routine_records`
- `routine_step_records`
- `daily_reflections`

Reminder runtime state, notification permissions and IDs, global reminder
preference, theme, onboarding state, location, timezone runtime state,
`sync_metadata`, and `sync_outbox` remain device-local. Each device independently
reconciles its reminders against SQLite.

Documents live only under `users/{uid}` and its entity collections. Each entity
has `schemaVersion`, `updatedAtUtc`, `sourceDeviceId`, `isDeleted`, and
`deletedAtUtc`; `serverUpdatedAt` is transport diagnostics only. Domain event
timestamps retain their existing meaning. Deleted records and reflections are
kept remotely as tombstones so another device cannot resurrect stale data.
Routine definitions are archived through their existing `isArchived` field.

## Merge and outbox

Local mutations write their outbox operation in the same SQLite transaction
as the entity mutation, including before a user links an account. The
coordinator performs no cloud work until that explicit link. Keeping the
pre-link outbox lets first sync merge local deletions as tombstones instead of
resurrecting stale cloud rows. The composite primary key
`(entity_type, entity_key)` coalesces repeated edits to the latest upsert or
delete. Firestore-applied writes use the sync repository's direct transaction
path and never enqueue a second operation.

Entities merge by `updated_at_utc` / `updatedAtUtc` (latest wins). At an exact
timestamp tie, a tombstone wins; otherwise lexical `sourceDeviceId` order gives
a deterministic winner. Client UTC clocks are used for this MVP. A severely
incorrect device clock can therefore affect conflict ordering; a logical clock
is deferred for a later architecture review.

The foreground coordinator runs after startup when linked, same-account sign
in, app resume, and manual Sync now. It pulls the account dataset, merges, then
flushes outbox writes in Firestore batches. There is no background worker or
continuous snapshot listener. Unsent work remains durable for the next eligible
foreground session. Firestore persistence is disabled so SQLite remains the
only offline store.

## Account deletion

`DeleteAccountUseCase` holds an exclusive sync-coordinator lock for the
currently authenticated UID so another pull or outbox write cannot race the
purge. It reauthenticates through Google and verifies the returned Firebase
identity before deleting data. `FirestoreAccountDataPurger` enumerates and
deletes each known Daisth subcollection in batches of at most 400 documents,
including tombstones, then deletes `users/{uid}`. Re-enumerating remaining
documents makes a retry safe after a partial purge. Firebase Auth deletion
occurs only after Firestore cleanup succeeds.

After successful Auth deletion, local sync metadata is unlinked only if its
`linked_uid` equals the deleted UID. This transaction clears sync timestamps,
the error, initial-sync flag, and outbox, while preserving `device_id`. A
mismatched local link remains unchanged. Routine, History, custom definition,
Reflection, theme, reminder settings, and all other SQLite feature data are
preserved. Normal sign-out does not purge cloud data or unlink sync.

Remote record/definition changes publish through existing repository change
streams. Composite routine records are recalculated from the merged step state
using the shared routine-status rule; a corrected status is queued once for
upload. Current-day changes can trigger the existing reminder reconciliation;
historical changes do not schedule or cancel notifications. Notification
background actions use only their existing local SQLite path.

## Security

`firestore.rules` scopes every user document to the authenticated matching UID
and denies all other paths. Deploy these rules to Firebase project `daisthapp`
before releasing account sync. Rules files in the repository are not proof of
deployment.

## Validation

Mapper validation rejects unknown entity schema versions, invalid dates,
required fields, enum values, and mandatory prayer `Not Today` states. Invalid
remote documents leave the local dataset untouched and surface a sync error.
Reflection note contents and cloud payloads are not logged.
