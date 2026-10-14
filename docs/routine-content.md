# Routine notes and image attachments

Custom and default routines can carry optional user-authored notes and up to
eight gallery images. Notes and images are independent of checklist
completion. They are not copied into routine history records or notifications.

## Editor and local storage

Create and Edit use the root routes `/routines/new` and
`/routines/:routineId/edit`, outside the floating navigation shell. The editor
keeps the existing default-routine configuration restrictions; user notes and
images are separate from factory descriptions, checklist definitions, and
Reader source content. Unsaved changes prompt before leaving. New images remain
in temporary staging until Save succeeds.

Notes use Quill Delta JSON (`format_version = 1`) plus derived plain text in
`routine_contents`. Whitespace-only content has no row. Delta is capped at
700 KiB and plain text at 50,000 characters. Images are separate entities in
`routine_attachments`; Quill image embeds are not supported.

Images come from the system photo library only. The app normalizes them to
JPEG (PNG inputs are retained as PNG), limits the longest side to 2048 px,
uses quality 85, strips EXIF, and rejects output above 8 MiB. A routine may
have at most eight images. Durable files live beneath the app's
Application Support `routine_attachments/<routineId>/` directory. SQLite
stores a relative path, never the picker URI or an absolute device path.
Startup cleanup removes abandoned staging files and unreferenced local files.

Android cloud backup and device transfer exclude this directory. iOS marks the
Application Support attachment directory as excluded from backup. Sign-out
and account unlink preserve local content. Delete Account purges the linked
UID's Storage prefix before Firestore and Firebase Auth deletion; local files
remain on the device.

## Persistence and synchronization

Schema v8 adds `routine_contents` and `routine_attachments`; the additive v7
to v8 migration preserves existing records and definitions. Content and
attachment metadata are local-first and are saved with the routine definition,
checklist, and outbox mutations in one SQLite transaction. Files are moved to
durable storage before the transaction; an unsuccessful transaction removes
new files, while cleanup of unreferenced old files is best-effort.

When the user has explicitly linked and enabled account sync, notes are stored
as owner-scoped Firestore documents under `users/{uid}/routineContents`.
Attachment metadata is stored under `users/{uid}/routineAttachments`; image
bytes are uploaded to authenticated Firebase Storage at
`users/{uid}/routine-attachments/{attachmentId}/image.jpg` or `.png`.
The checksum avoids uploading unchanged bytes. Metadata tombstones are written
before remote blobs are deleted. Upload, metadata write, and delete failures
leave the outbox operation pending for retry. Local files remain the immediate
display source. A remote-only image is lazily downloaded on Routine Detail only
when the current signed-in UID still matches the linked sync UID; its checksum
is verified before it is cached locally. The cache write does not enqueue
another cloud mutation.

The corresponding owner-only Storage rules are in `storage.rules` and wired
through `firebase.json`. They allow only the matching authenticated UID and
image objects up to 8 MiB. Rules are source configuration; this change does
not deploy Firebase rules. Deployment and live Storage QA remain required
before enabling synced images for users.

## Archive, history, and privacy

Archiving a routine does not delete its notes or attachments. History continues
to use the routine definition and record tables and does not duplicate note
bodies or image metadata. Current stored titles and archived definitions remain
available to historical records.

Notes and selected images are personal user content. On-device files are
excluded from operating-system backups; when account sync is activated, note
text and attachment metadata/image bytes are transmitted to the user's private
Firebase account data. No image EXIF is intentionally retained. The app does
not request camera access or broad storage access.
