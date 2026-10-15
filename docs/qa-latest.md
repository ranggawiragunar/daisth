# Daisth — QA Report for Final QA Planning

**Updated:** 15 October 2026 (Asia/Jakarta)  
**Repository:** `/Users/user/Projects/Flutter Projects/daisth`  
**Android device used:** Xiaomi 23122PCD1G, Android 16 / API 36  
**Package:** `com.rendev.daisth` · **app version:** `1.0.0+1005` in the recorded device audit  
**Current automation:** 282 passing tests  
**Latest overall gate:** **BLOCKED pending a live Firestore tombstone check**

This report consolidates the device checks, automated verification, defects,
limitations, and latest retest results recorded in `docs/qa-ledger.md`. It is
intended as handoff context for planning the final QA pass. Historical results
are identified by date; a later result supersedes an earlier one only for the
same behavior and only when the later test actually exercised it.

## Executive summary

- Major Android flows have been exercised on the physical Xiaomi: Today,
  prayer status, History, Reader, Dhikr, Penutup Hari, Reflection, mosque
  search/navigation, reminder actions, Google sign-in, sync, account deletion,
  settings, and custom routine editing.
- The ledger records a successful isolated Second Space onboarding run on
  14 October, including both normal completion and Skip paths. It was **not
  repeated** during the 15 October closure pass because the profile was already
  initialized and contains QA data.
- Custom routine create/edit/archive has device passes. On 15 October the
  previously created QA routine was edited, reopened to verify checklist
  persistence, then archived; it disappeared from active Routines and Today.
  That final routine pass did not cover every requested field or reminder and
  progress behavior.
- A live Reflection tombstone was observed before the latest full-document
  replacement fix, and that observation exposed the stale-field defect. The
  later replacement fix has automated coverage, but its **live post-fix result
  is unverified**. On 15 October, the supplied UID had no Firestore user root
  and its Reflection collection was empty, so there was no live document to
  compare before and after deletion.
- Latest automated run: `flutter analyze` passed, `flutter test --no-pub`
  passed (**282 tests**), source/test format check passed (298 files, zero
  changed), and `git diff --check` passed. Debug and release APK builds passed
  earlier for the audited source; no APK rebuild was needed for the latest
  documentation-only update.
- Do not treat this as store-release approval. Physical iOS, iOS notification
  actions, two-device convergence, and the latest tombstone replacement behavior
  remain open. Legal URLs are also not configured.

## Device and profile safety

- Primary Android user `0` and Second Space user `10` were used at different
  times. The Second Space account was explicitly approved for sync testing.
- The user authorized enabling sync and merging that profile's local routines,
  records, Reflection, editor content, and possible attachments. Sync remains
  enabled in Second Space.
- No account was deleted in the 15 October closure pass. The separate disposable
  account used in the earlier Delete Account scenario was deleted only after
  explicit approval; that Google account itself was not deleted.
- No manual SQLite edits or direct SQLite cleanup were performed. Existing
  primary-profile data and the unlinked local outbox were preserved.
- Xiaomi previously rejected an in-place install for user 10 with
  `INSTALL_FAILED_USER_RESTRICTED`; no device security setting was changed.
  The current session was left in Second Space on Today.

## Functional QA results

| Area | Latest status | What was observed / remaining limits |
|---|---|---|
| App identity, upgrade, launch | **PASS** | Daisth label and `com.rendev.daisth` verified. In-place debug APK upgrade on user 0 preserved app data; launch returned to Today. |
| Fresh onboarding | **PASS recorded 14 Oct; not repeated 15 Oct** | Ledger records all three onboarding pages and illustrations, navigation, Skip, normal completion to Today, no automatic location/notification/auth prompt, clean default routines, signed-out Account, and no old user0 History leakage. Relaunch did not show onboarding again. The 15 Oct check did not reset the already-used profile. |
| Today / navigation | **PASS** | Shell navigation, selected dock, Today-to-detail/back behavior, Today schedule and Prayer Focus were exercised. Latest Today showed 0/7 after archiving the QA custom routine. |
| Theme persistence | **PASS** | Dark survived force-stop/relaunch, then appearance was restored to System. Not every screen was exhaustively checked under all themes. |
| Language persistence | **PASS** | Second Space switched to Indonesian, force-stopped/reopened, remained Indonesian, then restored System Default. |
| Location and Prayer Time | **PASS** | Permission grant/deny, location service disabled/settings handoff, Jakarta timezone and plausible prayer times checked. No automatic permission prompt on launch. |
| Mosque Finder | **PASS with provider limitation** | Live Overpass results sorted nearest-first; refresh updated distances; Navigate opened Google Maps directions; OSM/ODbL attribution sheet rendered. Provider availability later fluctuated, including two unavailable results. Latest stale-cache-only scenario was not isolated and the attribution external link destination was not checked. Location transmission to Overpass had explicit user consent. |
| Routine Detail / mandatory prayer | **PASS** | Subuh/Fajr complete and undo paths checked; mandatory routines do not offer Not Today. An accidental Fajr tap was immediately undone and visible state returned to Not started; exact absence of an underlying empty record was not verified. |
| Routine checklist semantics | **PASS** | Dhuha required step completed while optional extra rakaat stayed unchecked; completion persisted across force-stop/relaunch, then test state was undone. Penutup Hari partial/completed/undo behavior was checked separately. |
| Routine Management — custom | **PASS for exercised paths** | Second Space custom routine created, renamed/edited, and archived through app UI. Create/edit sheets appeared above the dock; Save remained accessible with keyboard open; edit did not create a duplicate. On 15 Oct a required checklist step was added/saved/reopened, an edit persisted, and Archive removed the routine from active Routines and Today. The final exercise did not cover title/time/description edits, optional step, reminder, progress persistence, rich-text formatting, or attachment upload/download. The temporary routine is archived, not deleted. |
| History | **PASS** | History started from Yesterday; neutral summary rendered; mandatory prayers were in fixed order; missing mandatory item appeared Unrecorded; historical completion and Clear restored Unrecorded. Today and scheduled reminder count stayed unchanged during the historical edit test. |
| Historical Reflection | **PASS** | Reflection could be saved and deleted for a selected historical day; routine records remained separate and reminder schedule did not change. |
| Current-day Reflection | **PASS locally** | Save, edit, Today card update, process restart persistence, and deletion of QA content were exercised. On 15 Oct a temporary Reflection was saved/deleted and did not reappear locally after force-stop/relaunch and another Sync Now. |
| Reader / Qur'an and supplications | **PASS** | Six Penutup Hari readings opened; RTL Arabic, translation/transliteration visibility, text size, light/dark, source metadata, scrolling, and back flow were checked. Opening a reading alone did not complete its routine step. Content source/transliteration audit is documented separately in `docs/penutup-hari.md`. |
| Dhikr Counter | **PASS** | Increment, stage auto-advance, undo across boundary, confirmed reset, full 100-count/four-stage completion, return to Routine Detail, and optional-step isolation were checked. |
| Penutup Hari | **PASS** | One required step gave Partial; all six required readings gave Completed while optional Wudu remained untouched; undo returned to Partial; state survived restart. Temporary required states were restored. |
| Reminder settings and permissions | **PASS** | Notification permission, exact-alarm capability, precision status, timezone, Reminder Health, permission denial/settings round-trip, and a test notification were checked. Permission and reminder preference were restored. |
| Notification actions | **PASS on Android** | Terminated Done and Snooze were exercised in the earlier Second Space pass. Done persisted required progress without optional Dhikr. Snooze created one +10-minute item and suppressed follow-up; repeat snooze remained one logical reminder. Open navigation was also checked. A later primary-user test notification displayed Done/Snooze/Open, but actions were not invoked there because it contained user data. |
| Follow-up reminders | **PASS with timing limitation** | A representative follow-up remained unique through reconciliation; completion cancelled snooze. Waiting for the actual hours-later delivery was not done. |
| Google Sign-In / auth lifecycle | **PASS with limits** | Sign-in, persistence through process replacement, and ordinary sign-out were checked with an approved test account. Initial picker auto-selected its authorized account, so initial sign-in cancellation was not observed. |
| Firestore initial/basic sync | **PASS historically** | Earlier link/basic record and Reflection sync were verified by targeted Firestore reads; offline outbox queued while offline then flushed after reconnect. Offline restart variant was not completed. |
| Firestore tombstone: old merge behavior | **FAIL reproduced, then patched** | A live Reflection tombstone had `isDeleted=true` but retained old `note` and `rhythm`. Root cause was merge writes retaining stale domain fields. Entity writes were changed to replace whole documents; mapper regression asserts tombstones omit those payload fields. |
| Firestore tombstone: latest replacement fix live check | **BLOCKED** | On 15 Oct, sync UI showed zero queued changes and a newer last-sync time, but a narrow read of the supplied UID found `users/{uid}` 404 and an empty `dailyReflections` collection (HTTP 200). No pre-delete document snapshot was captured and no post-delete tombstone existed to inspect. Local no-resurrection passed; cloud field removal is not proven. |
| Delete Account / local preservation | **PASS for earlier disposable account** | Approved test Daisth account deletion removed its Firestore root/collections and Auth user; Google account remained. Local History/progress/Reflection/settings were preserved and sync unlinked. Not repeated in this closure; do not delete current Second Space data. |
| Settings / privacy | **PASS with release gap** | Appearance, language, reminder, account, and settings detail routes rendered. No raw coordinates displayed. Privacy Policy and Terms URLs are not configured and remain a release requirement. |
| iOS | **BLOCKED** | No completed physical iOS or simulator QA. Firebase iOS config lacks valid `CLIENT_ID` and `REVERSED_CLIENT_ID`; do not invent values. iOS notification actions are untested. |

## Defects found and fixes recorded

1. **Android notification action receiver:** Added the required
   `ActionBroadcastReceiver` declaration; later terminated Done/Snooze device
   actions were observed passing.
2. **Background SQLite handle sharing:** Background notification database now
   opens with `singleInstance: false`. Regression test exercises repeated
   background opens/writes/closes and foreground access; device follow-up passed
   on +1004. A later OEM `proc frequent died` start failure remains an Android
   environment limitation, not proof of app callback failure.
3. **Remote tombstone merge crash:** Null tombstone payload was cast before
   deletion check. Sync now handles deletion before payload decode; automated
   tests cover the entity types.
4. **Stale fields on tombstone:** Firestore merge writes kept old Reflection
   fields. Entity writes now replace full documents; mapper test asserts `note`
   and `rhythm` are omitted. Live verification of this latest behavior remains
   blocked as described above.
5. **Routine editor below bottom dock:** Create/edit modal sheets use the root
   navigator; manual create/edit/save with keyboard open and archive passed.
6. **Quill localization error:** Registered
   `FlutterQuillLocalizations.delegate` and added a widget regression test.
   Notes rendered normally in the latest Second Space editor observation.
7. **English routine/Dhikr strings:** Built-in titles, descriptions, guidance,
   steps, and Dhikr status copy now localize by stable IDs; regression coverage
   was added. No localization generation/ARB infrastructure was introduced.

No new dependency or schema change was made for these fixes. The 15 October
closure itself was documentation/device QA only; no production source changed.

## Automated verification history

| Date / stage | Result |
|---|---|
| 14 Oct #017.5B | `flutter analyze` PASS; **240 tests** PASS; debug +1005 and release APK builds PASS; `git diff --check` PASS. |
| 14 Oct localization/routine/Reader audit | `flutter analyze` PASS; **281 tests** PASS; debug/release APK builds PASS (release 84.6 MB); dependency audit found no new package. Source/test format check passed. |
| After Quill fix | `flutter analyze` PASS; **282 tests** PASS; debug APK and release APK builds PASS (release 85.2 MB); format and diff checks PASS. |
| 15 Oct closure/document update | `flutter analyze` PASS; `flutter test --no-pub` PASS (**282 tests**); `dart format --output=none --set-exit-if-changed lib test` PASS (298 files, 0 changed); `git diff --check` PASS. No rebuild required for documentation-only update. |

Older ledger runs had Google Fonts warnings while runtime fetching was disabled;
later runs reported no such warning, and the bundled-font typography test
passed. Production font behavior was not changed. APK builds emitted existing
Kotlin Gradle migration/CupertinoIcons notices but succeeded.

## Remaining QA risks / planning inputs

### Must close before claiming final QA complete

1. **Live tombstone replacement test:** Confirm the Firebase Auth UID currently
   signed into Second Space. Create a disposable Reflection, sync, read and
   record its live Firestore fields, delete through Daisth, Sync Now, then read
   the same document and verify `isDeleted`/deletion metadata and absence of
   stale `note`/`rhythm`. Run Sync Now and restart/resync once more. Do not call
   an empty collection a tombstone pass. No account deletion is authorized by
   this report.
2. **Fresh onboarding:** A full normal and Skip path were recorded PASS on
   14 Oct. If final QA requires a fresh repeat, use a genuinely clean isolated
   Android user/profile or a new test device; do not clear the current Second
   Space or primary profile.
3. **Custom routine coverage gaps:** If final QA requires them, cover editing
   title, time, description and checklist; required/optional semantics;
   reminder enabled behavior; progress after process restart; and archive
   removal from both active Routines and Today. The current QA object is archived
   and should not be treated as deleted.

### Accepted or previously identified release risks

- Physical iOS and iOS notification-action QA.
- Two-device Firestore convergence and manual mismatch with a second Google
  account.
- Isolated Mosque Finder stale-cache-only behavior; provider availability was
  intermittent and timed follow-up delivery was not observed.
- Offline outbox behavior across app restart and ordinary initial Google picker
  cancellation.
- Rich-text formatting and routine image attachment upload/download on-device.
- Privacy Policy and Terms public URLs are not configured.
- Reminder state/persistence full matrix on a disposable device profile.

The earlier test account used for live sync and Delete Account QA was removed
only in the explicitly approved earlier account-deletion scenario. The separate
account associated with the current 15 October attempt was not cleaned up. No
claim is made that its Auth account or any remote data was deleted.

## Suggested prompt for final QA planning

> Use `docs/qa-latest.md` and `docs/qa-ledger.md` as the QA evidence. Produce a
> risk-ordered final QA plan for Daisth that closes the live post-fix Firestore
> tombstone check first, then any onboarding/custom-routine coverage gaps, while
> preserving existing user data and not deleting any account/cloud data without
> explicit approval. Separate automated checks, Android device steps, iOS
> configuration/device blockers, expected evidence, cleanup, and release
> criteria. Do not start implementation or claim PASS without observed evidence.
