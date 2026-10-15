# Daisth QA Ledger

Last full audit: **14 October 2026**. Device: Xiaomi 23122PCD1G, Android 16
(SDK 36), `Asia/Jakarta`. Installed package: `com.rendev.daisth`, Daisth
debug build `1.0.0+1005`. See the continuation results below for the latest status.

Status meanings: **PASS** was exercised and observed; **FAIL** is a reproduced
defect; **BLOCKED** could not be completed because of a stated environment,
account, data-safety, or device-input limitation; **NOT APPLICABLE** does not
apply to this platform/check.

## #017.5 audit outcome

**BLOCKED for the full audit.** The #017.5B continuation below verifies the
critical Android notification, Reader, Dhikr, Penutup Hari, authentication,
sync and account-deletion preservation gates. Fresh install, isolated custom
routine QA, second account/device and iOS remain environment/data-safety
blockers. Earlier rows are preserved as the original pass observations and are
superseded only by explicitly retested continuation results. No existing app
data was uninstalled or cleared.

| Area | Status | Platform / result |
|---|---|---|
| Package, label, upgrade, cold launch | PASS | Android 16, 14 Oct. `com.rendev.daisth` and Daisth branding verified. Existing `+1001` installation was safely updated to `+1002`, then `+1003`; Today opened and existing local history remained. Splash showed the Daisth mark and tagline, with no Istiqam text. |
| Fresh install and onboarding | BLOCKED | Android. Device had an existing non-debuggable install with user data and no safe backup path. Uninstall/clear-data was not performed. Existing-install launch skipped onboarding as expected. Fresh onboarding, Skip, all three pages, and completion are covered by automated tests, but not a genuine device clean install. |
| Existing install migration | PASS | Android. Existing-install upgrade retained Today and History data and did not show onboarding. Exact historic v4/v5 migration is covered by migration tests, not recreated manually. |
| Bottom navigation and detail back flow | PASS | Android. Today, History, Settings, Routines, day detail, and routine detail opened; dock selection and hidden detail dock appeared as expected. |
| Theme selection/restart | PASS | Android. Dark was selected, survived force-stop/relaunch, and rendered Today dark. Preference was restored to System; system appearance was light. Other major screens were not exhaustively checked in all three modes. |
| Location permission grant/deny | PASS | Android. Revoked permission produced a calm setup state; explicit permission action opened Android's prompt; precise/while-using grant restored location availability. No permission prompt appeared automatically on launch. |
| Location service disabled | PASS | Android. System location off produced the disabled state and opened Android Location Settings; service was restored afterward. |
| Prayer Time / timezone | PASS | Android. Device timezone showed `Asia/Jakarta`; all five prayer times appeared plausible for Jakarta. Device timezone was not changed during this pass. |
| Mosque Finder, refresh, stale cache, map handoff | PASS with limits | Android, #017.5B wireless continuation. Live nearby results and OSM attribution verified; refresh repeated the query and updated distances; Navigate launched turn-by-turn navigation. Provider temporarily returned unavailable twice and later recovered. Stale-cache-specific behavior was not isolated. |
| Routine completion and restart | PASS | Android. Dhuha required step completed while optional extra rakaat stayed unchecked; completion survived force-stop/relaunch. The temporary record was undone and Today returned to 0/7. |
| Other default routines / Not Today | BLOCKED | Android. Sholat Malam, mandatory prayer completion/undo, optional Not Today reason flow, and default reset/edit controls were not all exercised on-device. Automated regression tests remain passing. |
| Custom routine create/edit/archive | BLOCKED | Android. No custom routine existed before QA. Creation/archive would leave persistent user data, so no temporary definition was introduced without a safe cleanup path. |
| Reader and Penutup Hari readings | PASS | Android #017.5B: all six readings and requested RTL, controls, themes, metadata, scrolling, back and completion behavior verified. |
| Dhikr Counter | PASS | Android #017.5B: count, auto advance, undo, reset and final completion verified; optional step restored. |
| History list/day detail | PASS | Android. History began at Yesterday and summarized `1 completed · 4 unrecorded`; day detail displayed mandatory prayers in fixed order and showed missing Subuh as Unrecorded. No score/streak language appeared. |
| Historical routine edit/clear | PASS | Android. Historical Subuh showed `Editing Tue, Oct 13`, could be marked Completed, then Clear record returned it to Unrecorded with the required confirmation. Today remained unchanged and scheduled alarm count remained 23 before/after. |
| Reflection historical save/delete | PASS | Android. Historical Reflection opened for the selected day, saved a rhythm, then confirmed deletion. Routine records remained separate; scheduled alarm count stayed unchanged. Current-day save/restart and 20:30 notification behavior were not exercised. |
| Notification permission, reminder settings, exact timing | PASS | Android. Notification permission Allowed, exact-alarm capability available, Reminder Health reported Precise timing, timezone Asia/Jakarta, and future reminders were listed. Denied state and Android notification settings round-trip were exercised; permission and Reminders On were restored. |
| Reminder test notification / Open | PASS | Android. Debug-only test control scheduled and displayed `Uji aksi · Sholat Dhuha` with Done/Snooze/Open. Open launched Dhuha detail without completing it. |
| Terminated Done/Snooze | PASS | Android #017.5B. Actual terminated notification actions persisted one Done record and one +10-minute Snooze with follow-up suppression; see continuation details. |
| Follow-up, repeat snooze, completion-after-snooze, composite Done | PASS with limits | Android #017.5B: one representative follow-up remained singular across reconciliation, repeat snooze retained one future item, and completion cancelled snooze. Timed follow-up delivery and separate composite Done were not waited/isolated. |
| Google Sign-In and auth persistence/sign-out | PASS with limits | Android #017.5B: approved test account signed in, remained after process replacement, and signed out normally. Initial sign-in picker auto-selection means cancellation was not tested. Delete reauth picker cancellation was tested separately. |
| Firestore link/basic/offline/tombstone sync | PASS | Android #017.5B test account: initial and subsequent records synced under users/{uid}; offline outbox survived locally then flushed; Reflection tombstone observed. Account was later deleted as authorized. |
| Two-device convergence/account mismatch | BLOCKED | Android. Only one physical Android device was connected; no safe second test account was available. |
| Delete Account and local-data preservation | PASS | Android #017.5B: approved test Daisth/Firebase user deleted; cloud root/collections/Auth user absent. App signed out and local History/progress/Reflection/settings persisted. |
| Settings / About / privacy copy | PASS | Android. Settings groups and Prayer & Location, Notifications, Account, and Data & Privacy routes rendered. No raw coordinates were shown. About/license/legal-link audit was not completed; public legal URLs remain an #018 release requirement. |
| Reminder debug control absent from release | PASS | Android. Test control is guarded by `kDebugMode`; `flutter build apk --release` succeeded. Release APK was not installed on the device. |
| Lifecycle / restart local state | PASS | Android. Dark preference and Dhuha completion survived process restart; Dhuha was then undone. Existing History and Reflection data remained available. Full custom routine, reminder preference, and Reflection restart matrix was not exercised. |
| iOS build and smoke | BLOCKED | macOS checkout has no iOS device/simulator result for this pass. Existing `GoogleService-Info.plist` lacks `CLIENT_ID` and `REVERSED_CLIENT_ID`; do not invent OAuth values. Physical iOS notification-action QA is also blocked. |

## Defect log

### QA-0175-01 — Android notification actions lacked a receiver

- **Scenario:** Tap Done or Snooze on an Android routine reminder while Daisth
  is terminated.
- **Root cause:** `android/app/src/main/AndroidManifest.xml` declared the
  scheduled notification and boot receivers but omitted the
  `flutter_local_notifications` `ActionBroadcastReceiver` required to dispatch
  notification actions.
- **Fix:** Added the plugin receiver with `android:exported="false"`.
- **Regression coverage:** Added a test that asserts the receiver remains
  declared in the Android manifest. Existing reminder action use-case tests
  still cover Done/Snooze domain behavior.
- **Final device result:** **BLOCKED** for post-fix acceptance. The updated
  manifest is in the installed APK, but a terminated Done/Snooze state change
  was not conclusively observed through the available ADB interaction. Do not
  treat callback/broadcast presence alone as a pass.

## Automated verification — 14 October 2026

| Command | Status | Result |
|---|---|---|
| `flutter clean` | PASS | Completed. |
| `flutter pub get` | PASS | Dependencies resolved; no dependency was added. 23 packages have newer versions outside current constraints. |
| `dart format lib test` | PASS | 270 files, no changes on final format. |
| `flutter analyze` | PASS | No issues found. |
| `flutter test` | PASS | **238 tests passed** (237 baseline plus the manifest regression test). Google Fonts emitted runtime-fetch-disabled warnings because Plus Jakarta Sans font files are not bundled as assets; tests still passed. |
| `flutter build apk --debug` | PASS | Debug APK built at `build/app/outputs/flutter-apk/app-debug.apk`. |
| `flutter build apk --debug --build-number=1003` | PASS | Built and installed over `+1002` without clearing local data. |
| `flutter build apk --release` | PASS | Release APK built locally (77.2 MB); it was not distributed or installed. Flutter warned that no CupertinoIcons font asset was found, but build succeeded. |
| `git diff --check` | PASS | Clean. |
| `flutter pub deps --style=compact` | PASS | Completed; no new package added for this QA fix. |

The first automated run had two Today widget failures because the fake routine
repository used a fixed 13 October 2026 creation date while the device date was
14 October 2026. The fixture now uses the current date; the full suite then
passed. This was test-fixture date drift, not a product behavior change.

## Earlier QA notes carried forward

- **#008 Reminder Engine:** Settings/permission/timing state and a primary test
  notification were exercised on Android. The terminated actions and complete
  follow-up matrix remain blocked as detailed above.
- **#009 Persistence:** Local Dhuha progress and theme survived process restart.
  The full restart matrix for custom routines, Reflection, and reminder
  preference remains unverified.
- **#010 Reminder Actions:** Domain tests pass; Android Open passed. Terminated
  Done/Snooze remain blocked pending verified post-fix device interaction.
- **#011 Routine Management:** Default routine UI appeared in Today/Routines;
  custom creation/edit/archive and full reset behavior remain blocked.
- **#012 History:** Mandatory Unrecorded, historical completion, and Clear were
  exercised on Android and passed.
- **#013 Penutup Hari:** Automated content/completion tests pass; full reading
  and reminder QA remains blocked on device.
- **#014 Reflection:** Historical save/delete and reminder isolation passed;
  current-day, restart, and scheduled reminder checks remain blocked.
- **#015 Authentication / #016 Sync / #017 Settings:** Settings and local
  permission flows passed. Online sign-in/sync and destructive account deletion
  remain blocked for the reasons above.

## Existing release constraint

No Privacy Policy or Terms URL is configured. Public legal URLs remain a
release requirement tracked for #018. No local database reset control was
added.


## #017.5B continuation — 14 October 2026

These results supersede the earlier blocked rows only for the checks explicitly
listed here. Earlier observations remain in the ledger. No uninstall or app-data
clear was performed. The user approved the test Google account, its Daisth cloud
account deletion, one device reboot, and location transmission to Overpass.
Airplane mode was on, but Wi-Fi was connected and validated; the earlier inference
that airplane mode alone meant no network was incorrect.

| Check | Status | Observed result |
|---|---|---|
| Terminated Done | PASS | On +1003, verified no app PID before tapping actual notification Done. SQLite had exactly one current-day Dhuha Completed record, required step true and optional step false; follow-up/snooze removed; reopened Today reflected completion. Temporary state was undone. |
| Terminated Snooze | PASS | After the approved reboot, actual cold notification Snooze created exactly one future reminder at action time +10 minutes. Automatic follow-up was suppressed. Repeat Snooze retained the same logical ID and one future reminder. |
| Follow-up and snooze cancellation | PASS | Representative Zuhur had one follow-up across restart/reconciliation. Completing Dhuha cancelled its snooze. Actual hours-later timed delivery was not observed. |
| Reader | PASS | All six Penutup Hari contents opened. Arabic RTL, translation/transliteration toggles, 130%/100% text size, light/dark, source metadata, scrolling and back navigation inspected. Opening content alone did not check any step. Theme restored to System. |
| Dhikr | PASS | Increment, automatic stage advancement, undo across stage boundary, confirmed reset, 100-count/four-part completion and return to the optional routine step verified. Opening alone did not complete the step. |
| Penutup Hari | PASS | One required step gave Partial; all six gave Completed with Wudu untouched; undo gave Partial. Restart retained state. All temporary required states restored to false. |
| Reflection today | PASS | Disposable note saved, Today updated, swipe-away/relaunch retained note/rhythm, edit saved, and only the QA entry was deleted. A separate disposable Reflection was then used for sync QA. |
| Mandatory prayer | PASS | Subuh complete/undo verified; Not Today unavailable. Required completion and optional Dhikr were temporarily retained for cloud/local preservation verification. |
| Mosque provider results | PASS | Live Overpass search returned nearby entries in ascending distance (128 m, 168 m, 200 m, etc.). Attribution sheet displayed OpenStreetMap and ODbL with its link. Refresh/external handoff require their own result below. |
| Custom routine | BLOCKED | No disposable custom routine exists; persistent production-like definitions were not fabricated. |
| Google Sign-In | PASS | Normal sign-out preserved data; Google Sign-In succeeded with the explicitly approved test account. Google auto-selected its previously authorized account, so picker cancellation was not observed. Auth remained signed in after +1005 process replacement. |
| Firestore initial/basic sync | PASS | Initial link completed under users/{uid}. After the tombstone fix, current Subuh completion and disposable Reflection verified by read-only Firestore inspection; outbox 0 and last error null. |
| Fresh onboarding | BLOCKED | Existing data retained; no safe isolated fresh-install device. |
| Account mismatch / two devices | BLOCKED | No second disposable Google account or second physical device. |
| iOS | BLOCKED | Valid CLIENT_ID / REVERSED_CLIENT_ID absent; no completed device/simulator QA. |

### QA-0175-02 — background SQLite connection closed foreground database

Reproduced after background Snooze followed by reopening Routine Detail:
`DatabaseException(database_closed 2)`. Background and foreground engines shared
a default sqflite native handle; background cleanup closed that shared handle.
The background database service now opens with `singleInstance: false`, while
foreground behavior stays unchanged. An actual SQLite regression test repeats
two background open/write/close cycles and verifies foreground access survives.
On +1004, background Snooze/Done and subsequent Routine Detail access passed.
Xiaomi later rejected another cold handler start with `proc frequent died` /
`startProcessLocked failed`; that additional attempt is an OEM limitation,
not evidence of a callback executing and failing.

### QA-0175-03 — remote tombstone crashed sync merge

Live sync stalled with `syncUnavailable` while five local changes remained safe
in the outbox. Runtime debugger traced a TypeError to `_applyRemote`: it cast the
null tombstone payload before checking `isDeleted`. Payload conversion now runs
only for upserts. SQLite regression coverage applies null-payload tombstones for
all five sync entity types. On +1005, Sync Now completed, outbox became empty,
and both routine and Reflection documents were verified remotely.

### Continuation automated verification

- `dart format lib test`: PASS, 271 files.
- `flutter analyze`: PASS, no issues.
- `flutter test`: PASS, **240 tests** (238 baseline plus connection isolation and tombstone regression).
- Debug +1005 build and upgrade install: PASS, existing data retained.
- Release +1005 build: PASS, 77.2 MB; not installed/distributed.
- `git diff --check`: PASS before the final ledger update; checked again afterward.
- No dependency or schema change. Existing font/Kotlin compatibility warnings remain.
- Generated untracked iOS SwiftPM Package.resolved remains untouched; it was produced by local Xcode resolution, not committed or deleted.


### Live sync / account completion results

| Check | Status | Observed result |
|---|---|---|
| Offline outbox | PASS | Wi-Fi off: disposable Reflection rhythm changed locally; one pending item and networkUnavailable. Wi-Fi restored: Sync Now emptied outbox and remote rhythm became mixed. Offline process-restart sub-check not completed (no recents card selected); not counted as a restart pass. |
| Tombstone | PASS | Disposable Reflection deletion reached Firestore with isDeleted true and a newer UTC timestamp. Existing merge writes retain previous fields on the tombstone document; deleted payload is not applied locally. Only QA content was deleted. |
| Google reauth cancellation | PASS | Delete Account displayed Google picker; Back cancelled it. Read-only checks confirmed user root/collections and Auth user still present, sync still linked, no local loss. Initial sign-in picker cancellation remains separately unobserved due automatic sign-in. |
| Delete Account | PASS | Retried with the explicitly approved account selected. Firestore users/{uid} returned 404, all five collections were empty, Firebase Auth lookup returned zero users, and Account showed signed-out Google continuation. Google account itself was not deleted. |
| Delete Account local preservation | PASS | Before cleanup: current Subuh required and Dhikr remained completed, Oct13 Isya history unchanged, QA Reflection remained, theme System and reminders enabled. Sync unlinked, initial_sync_completed 0, last sync cleared, old outbox 0, installation device ID unchanged. Existing automated deletion tests cover cross-account outbox isolation. |

Overall critical Android gates now have observed passes: Reader, Dhikr,
Penutup Hari, terminated Done/Snooze, Google Sign-In, basic sync, and account
local preservation. **#017.5 remains BLOCKED for full audit completion** by fresh
onboarding isolation, custom routine isolation, second account/device and iOS;
these are not silently promoted to PASS. No #018 work was started.


QA cleanup: disposable Reflection is absent again; current-day Subuh required
and Dhikr were restored false and no current routine record remains. Existing
Oct13 Isya record/timestamps are unchanged. System theme and reminders enabled
remain. QA-created false step rows and reminder-action metadata are retained
by normal application semantics; SQLite was never directly mutated for QA.
Wi-Fi was restored. Account remains signed out after the authorized deletion.


Mosque Finder provider availability briefly failed and ADB disconnected during
one earlier retry. The later wireless continuation below recovered and passed
refresh and Maps handoff; only stale-cache-only behavior remains unisolated.


## #017.5B resumed over wireless ADB — 14 October 2026

After the brief disconnect, the Xiaomi reconnected as
`192.168.101.77:41529` (model 23122PCD1G, Android 16). I relaunched Daisth;
Today displayed 0/7, History's original Oct13 Isya record was preserved, QA
Reflection remained absent, and the account remained signed out. The transient
QA Subuh required/Dhikr state remained restored false.

- Mosque Finder provider retry: after two provider-unavailable results, another
  retry returned seven nearby results. Distances were nearest-first (249 m,
  285 m, 461 m, 559 m, etc.).
- Refresh: tapping Muat ulang pencarian performed a fresh request and updated
  displayed distances by about 1 m. PASS.
- External handoff: tapping Navigate launched Google Maps turn-by-turn
  navigation with an 8 minute / 550 m route and visible next instruction. PASS.
- Attribution: already passed in the prior session; OSM and ODbL were shown.
  No external destination launch was performed for the attribution link.
- Provider availability fluctuated during the audit; no provider/UI patch was
  made. Live stale-cache-only behavior was not separately isolated.

The complete #017.5B worktree verification remains 240 passing tests, clean
analyze/format/diff check, and successful debug/release +1005 builds. No code
changed after those runs; only this ledger was updated. #017.5 remains BLOCKED
for the explicitly listed fresh-install, disposable custom routine, second
account/device and iOS environment items. No #018 work started.


Post-deletion local cleanup detail: restoring the QA Subuh completion to false and
opening the routine details after account deletion produced four ordinary local
outbox operations: Reflection delete, Subuh routine delete, and two Subuh step
upserts. At that point sync metadata remained unlinked (`linked_uid` null,
`initial_sync_completed` 0); device ID remained stable. These QA cleanup events
are not the previous account's queued cloud data. The account was not linked
again and no data was sent to another UID. They were left in SQLite rather than
mutated directly.

The follow-up tombstone content fix replaces complete entity documents, so
metadata-only tombstones clear prior fields. Mapper regression assertions,
240-test suite, analyzer and debug/release rebuild all passed. The +1006 debug
upgrade was installed wirelessly and Today reopened with local state preserved.
A live Firestore retest of this final fix was unavailable after the approved
test account was deleted; no test account was recreated.


### QA-0175-04 — tombstones retained old user fields in Firestore

The live Reflection tombstone had `isDeleted: true`, but the old `note` and
`rhythm` fields remained. `writeEntities` used `SetOptions(merge: true)` for
entity documents, merging metadata-only tombstones into old user content. Entity
serialization already produces complete maps, so batch writes now replace the
entire entity document. The existing mapper tombstone test now asserts the
encoded data contains neither `note` nor `rhythm`; `docs/sync.md` documents that
tombstones clear payload fields. All 240 tests, analyzer, debug and release
builds passed. Debug +1006 was installed over wireless ADB and local Today state
was preserved. Live Firestore confirmation of field removal could not be run
after deleting the only approved Firebase test account; it was not recreated.

After deletion, four unlinked local outbox entries were generated by returning
temporary QA Subuh/Dhikr and Reflection state to the original state through the
app. They remain local with `linked_uid` null; no account was re-linked and no
other UID received them. Direct SQLite cleanup was avoided.


## #017.5C closure pass — 14 October 2026

### Isolated Second Space QA

The disposable Android user completed the normal three-step onboarding and
reached Today without an unsolicited notification, location, or Google sign-in
prompt. History started empty, confirming local user0 history was not visible.
A separate reset of user10 app data verified the onboarding Skip path also
reached Today. Relaunch preserved the completed onboarding state.

A temporary custom routine was created, renamed, and archived through the app;
the active custom list returned to its empty state. During that flow the editor
sheet appeared below the floating dock, obscuring its Save action. The editor
sheets for create and edit now use the root navigator in
`lib/features/routines/presentation/routines_screen.dart`, so they can cover the
dock. `flutter analyze`, all 240 automated tests, and debug/release builds pass
with this source change. The updated debug APK installed successfully with an
explicit user10 scope. A manual retest of the Save button after this patch was
not completed: Android reported user10 active while the visible display stayed
black and the top resumed activity belonged to user0. No user0 app or data was
opened or changed.

### Tombstone and account lifecycle

Using only the disposable account selected on-device and the UID supplied by
the user for a targeted check, a saved Reflection was confirmed in Firestore.
Deleting it in the app and syncing produced a metadata-only tombstone: the
Reflection document had `isDeleted: true`, and the prior note/rhythm payload
fields were absent. After force-stop, relaunch, and another Sync Now, the
Reflection remained empty locally and the same tombstone remained remotely.

The approved Daisth account deletion then completed in the app. A targeted
read found the user root absent (404), all five supported entity collections
empty, and no Firebase Auth user for that test UID. The Google account itself
was not deleted. No other Firestore user roots were enumerated. The owner's
user0 database and its unlinked local outbox were left untouched.

### Verification

- `dart format lib/features/routines/presentation/routines_screen.dart`: PASS.
- `flutter analyze`: PASS, no issues.
- `flutter test`: PASS, **240 tests**.
- `flutter build apk --debug`: PASS; updated APK installed only for user10.
- `flutter build apk --release`: PASS, 77.2 MB.
- `git diff --check`: PASS before this ledger append; run again after append.
- No schema or dependency change. Existing test-time Google Fonts warning
  remains because Plus Jakarta Sans test assets are unavailable while runtime
  font fetching is disabled; production font behavior was not changed.

The earlier #017.5 ledger blockers remain: iOS device/notification-action QA,
a second physical device/account scenario, and isolated Mosque stale-cache-only
behavior. The patched routine Save action also still needs a manual post-patch
retest in the disposable profile. Therefore #017.5C's onboarding, tombstone,
and account-cleanup checks passed, but the broader #017.5 device audit is not
fully closed. No #018 work was started.


## #017.5D — final routine editor verification — 14 October 2026

**#017.5: COMPLETE.** This entry supersedes the interim #017.5C note that the
routine editor still needed a manual retest. The sole remaining closure gate
passed on isolated Android user 10 (Second Space). The package was present for
that user. `cmd package resolve-activity --brief --user 10 com.rendev.daisth`
resolved to
`com.rendev.daisth/.MainActivity`.

An initial explicit `am start --user 10` while user 0 was foreground left the
owner launcher as the top activity. This explained the prior black screen: the
isolated user had not been switched into the foreground. No app crash or
Flutter/ActivityTaskManager error appeared in the relevant log check. After
`am switch-user 10`, Android reported user 10 and Daisth's MainActivity as the
top resumed activity; the UI rendered normally. All subsequent UI actions were
performed only while those user-10 foreground checks passed.

- **Create:** The editor appeared above the floating dock. Save Routine was
  fully visible with the keyboard closed and open. With the keyboard open,
  tapping Save Routine closed the sheet and added exactly one routine.
- **Edit:** The same routine opened in the edit sheet above the dock. Save
  Routine remained visible with the keyboard open; saving changed the existing
  title, closed the sheet, and left one routine (no duplicate).
- **Keyboard:** Dismissing the keyboard restored the form layout; the title,
  fields, and Save Routine remained visible and usable. No overflow or black
  sheet occurred.
- **Cleanup:** Both disposable routines used for the checks were removed via
  the app's delete confirmation. The custom-routine list returned to its empty
  state. SQLite was not edited directly.
- No additional production-code fix was needed beyond the existing
  `useRootNavigator: true` create/edit sheet patch.

Final pass verification: `flutter analyze` PASS; `flutter test` PASS (**240 tests**);
`git diff --check` PASS. The test run still prints the known GoogleFonts
warnings for missing Plus Jakarta Sans test assets while runtime font fetching
is disabled. No new APK build was needed because this pass made
 no code change; the debug and release builds for the patch are recorded above.

The following items remain documented as accepted #018 release risks and do
not block #017.5 closure: physical iOS QA and notification actions; two-device
Firestore convergence; manual second-account mismatch; isolated Mosque Finder
stale-cache behavior; waiting for actual delayed follow-up delivery; ordinary
Google picker cancellation; and the offline-outbox restart variant. No #018
work was started.


## Localization + Routine + Reader regression audit — 14 October 2026

### Scope and changes

The starting worktree was clean at `c73dce6` (`Adjustment Master Routine
Data`). This audit found English-mode UI strings that still came from Indonesian
defaults in Routine Detail, its checklist guidance sheet, and Dhikr. Built-in
routine titles, descriptions, contexts, step titles/subtitles, section labels,
badges, guidance titles, and related semantics now resolve by stable routine or
step ID. Custom routine text continues to use its saved content. Dhikr count,
sequence context, and the closing item are localized. A stale widget assertion
was updated for the English heading, and a regression test covers the Dhuha
guidance sheet title.

No database, schema, dependency, notification, Reader content, or account-sync
behavior changed. `flutter gen-l10n` is not configured in this project: the
Flutter `generate` flag is off and the app uses its existing manual
`DaisthLocalizations`/`DaisthTerminology` mapping without ARB files. Its
generator command therefore exits with the expected “generate flag turned on”
message; no generator configuration was added. `flutter pub get` did not change
`pubspec.lock`; incidental Swift package resolution entries were reverted.

### Automated verification

- `dart format lib test`: PASS, 298 files checked and no edits needed.
- `dart format .`: the repository-wide command entered generated
  `build/ios/SourcePackages` content and stopped on its missing
  `analysis_options.yaml`; the source and test trees were formatted separately
  and pass.
- Focused Routine Detail suite: PASS, 12 tests.
- `flutter analyze`: PASS, no issues.
- `flutter test --no-pub`: PASS, **281 tests** (276 at audit start, plus the
  regression coverage added during this pass; no tests were removed or skipped).
- `flutter build apk --debug --no-pub`: PASS.
- `flutter build apk --release --no-pub`: PASS, 84.6 MB.
- `flutter pub deps --style=compact`: PASS; no dependency was added.
- `git diff --check`: PASS.

The final test invocation showed no Google Fonts network-fetch warning. The app
bundles Plus Jakarta Sans, and its typography asset test passes; production font
behavior was not changed. Builds still print the existing Kotlin Gradle
Plugin migration notice for Firebase/image-compression plugins and a
CupertinoIcons font notice; both APK variants complete successfully.

### Primary Android profile smoke test

The failed user10 install attempt remained `INSTALL_FAILED_USER_RESTRICTED`.
Following the user's instruction, the device check moved to primary user 0.
The device is Xiaomi 23122PCD1G, Android 16/API 36. Before installation,
`com.rendev.daisth` was present on user 0 and its installed APK certificate
matched the debug build (SHA-256
`8f33c6e524867e8bb66f00f1c98d7c984801c930bc53e2ce2780a5374a6b1dd1`). The
final debug APK was installed using `adb install --user 0 -r`, preserving the
existing app data. No uninstall, clear-data, database reset, or direct database
access occurred.

Daisth launched as the resumed user-0 activity and rendered the existing Today
screen after startup. The visible local Today state was 0/7; this was observed,
not edited. No routine, reflection, locale, account, reminder, cloud, or
attachment data was changed. This confirms in-place installation and startup
only; it is not a manual feature walkthrough.

### Remaining QA gates

All routine create/edit/archive and rich-text/image attachment flows, Sholat
Malam Taubat/Hajat Reader navigation and completion isolation, reminder
delivery/actions, cloud/outbox behavior, and iOS interaction were not exercised
on a disposable environment in this pass. Language switching and persistence
were later verified in Second Space as recorded below.
The primary profile contains user data, so no test entities or preference
changes were introduced there. Existing automated coverage passed, but does not
replace those device checks. Any release sign-off requiring those physical,
cloud, or iOS checks remains **BLOCKED**; no signing, distribution, or #019 work
was started.

### Second Space continuation — 14 October 2026

The user provided Second Space (Android user 10) with a separate signed-in
Google account for disposable QA. The account's Daisth sync toggle was off and
was left off. No cloud writes, test routines, reflections, attachments, or
account deletion were performed. The installed app remained the earlier build
because Xiaomi returned `INSTALL_FAILED_USER_RESTRICTED: Install canceled by
user` for the in-place debug update; the user confirmed that no install prompt
was visible. No further install attempt or device security setting change was
made.

The already-installed build was used to check language preference persistence:
Settings changed from System Default to Indonesian, the app was force-stopped
and reopened, and the UI remained Indonesian. The preference was then restored
to System Default and confirmed in Settings. This verifies language selection
and local persistence in the test profile. During the earlier editor walkthrough
the installed build displayed a `FlutterQuillLocalizations` runtime error in
Notes. The source fix now registers `FlutterQuillLocalizations.delegate`, and a
widget regression test through `DaisthApp` confirms that Notes renders without
an exception; the fix could not yet be rechecked on-device because the APK
update was rejected.

Latest source verification after the Quill fix: `flutter analyze` PASS,
`flutter test --no-pub` PASS (**282 tests**), debug APK build PASS, release APK
build PASS (85.2 MB), and `git diff --check` PASS. No dependency or production
font behavior changed. Device QA beyond the language preference check,
including verification of the fixed rich-text editor, remains blocked by the
OEM install restriction. The other listed cloud, reminder, attachment, and
iOS gates remain untested.

### Authorized sync and final Android continuation — 14 October 2026

The user explicitly authorized enabling and testing sync for the Second Space
QA account, including merging that profile's local routines, daily records,
Reflection, editor content, and any attachments into its Firestore/Storage
account. Sync was enabled in-app. The account page showed sync active and zero
pending changes; after creating the temporary routine
`Codex_QA_Sync_1014` (reminders off, no checklist or attachment), the last-sync
time refreshed and pending changes returned to zero. This is UI evidence that
the routine write reached the sync pipeline, not a direct Firestore document
read or a two-device convergence test. Sync remains enabled. No account or
cloud data was deleted.

The temporary routine is still present in Second Space. Its editor Notes region
on that installed build renders a red `FlutterQuillLocalizations` error that
occupies the editor viewport and prevents reaching Archive. The attempted
Second Space APK update again returned `INSTALL_FAILED_USER_RESTRICTED`; no
security setting was changed. The user had previously directed QA to use
primary space, where an in-place update succeeded with `adb install --user 0
-r` and preserved app data. After relaunch, the Add Routine editor's Notes
toolbar and editor rendered normally, verifying the Quill fix on device. The
opened blank draft was discarded without saving. The older Second Space build
and its temporary synced routine remain untouched pending a supported way to
update that Android user.

Reminder QA in primary space: notification permission was allowed, reminder
toggle active, precision status and timezone (`Asia/Jakarta`) were shown, and
the test notification button produced a visible Android notification titled
`Uji aksi · Salat Dhuha`. Expanded notification UI showed Done, Snooze 10
minutes, and Open actions. No action was invoked because this primary profile
contains user data and Done/Snooze would mutate its routine or reminder state.
Before sending the test notification, Reminder Health showed zero upcoming
reminders and zero items in today's schedule; afterward both displayed one.
No routine definition or completion was intentionally changed for this test.

Mosque Finder was opened in Second Space under the user's earlier explicit
consent to send location to Overpass. The first search and one in-app retry both
ended in `Nearby search could not load / The data service is unavailable`.
The map-data bottom sheet displayed OpenStreetMap attribution and its
OpenStreetMap link button. Provider success and the attribution link's external
destination were not verified. Location reached the app (Today showed local
prayer times); no location accuracy service was enabled.

During navigation, a coordinate tap accidentally marked Fajr complete. It was
immediately toggled back, and the routine detail returned to `Not started`,
`0 of 1 completed`. The visible completion state is restored; the app may retain
an empty/incomplete local record row, so the exact pre-tap database absence was
not re-established through UI. No other routine was intentionally changed.

### Remaining gates after this continuation

- Second Space: supported installation/update needed to archive the temporary
  sync routine and verify its tombstone; direct database/Firestore mutation was
  not used.
- Reminder actions Done/Snooze and actual scheduled prayer delivery remain
  untested against a disposable profile; only test notification delivery and
  action presentation were confirmed in primary space.
- Rich-text formatting, image attachment upload/download, routine edit/archive,
  cloud two-device convergence/offline outbox, and account mismatch remain
  unverified.
- Mosque Finder provider still failed twice; live result, refresh-success, and
  stale-cache behavior remain unverified.
- iOS device interaction remains unverified in this environment.

### #017.5C closure pass — 15 October 2026

**Fresh onboarding was not repeated in this pass.** The Second Space (Android
user 10) already had Daisth data and an established session, and the current
install restriction prevents updating that user's APK without resetting the
profile. The prior 14 October #017.5C entry records a successful isolated
onboarding run: all three pages, Skip and normal completion, fresh defaults,
and relaunch behavior. That recorded PASS remains the latest actual onboarding
result; the primary profile was not cleared or reinstalled for this pass.

**Custom routine create/edit/archive passed on the isolated device profile.**
The previously created disposable `Codex_QA_Sync_1014` routine was opened in
the editor. Its rich-text Notes toolbar/editor rendered without the earlier
localization exception. A required checklist step was added, saved, reopened,
and observed to persist; an edit to that step label also persisted on reopen.
The routine was then archived through the app's confirmation dialog. It
disappeared from active Routines, and Today changed from 8 routines to 7 with
the QA routine absent. The archived object is retained by the app, consistent
with archive semantics. This QA routine was already created while sync was
authorized and enabled; no new account was created and no cloud/account data
was deleted. No reminder was enabled, and no attachment was added. This does
not cover every requested field (title, time, description, optional step,
reminder, or progress persistence).

**Latest Firestore tombstone verification remains blocked.** In Second Space,
a temporary Oct 15 Reflection was saved through the UI, deleted through the
normal confirmation flow, followed by Sync Now, force-stop/relaunch, and a
second Sync Now. The app reported zero queued changes and a later last-sync
time; the Reflection did not reappear locally after relaunch. A narrowly scoped
read of the supplied disposable UID in project `daisthapp`, performed after
the deletion attempt, found no root `users/{uid}` document (404) and an
existing but empty `users/{uid}/dailyReflections` collection (HTTP 200, zero
documents). No pre-delete Firestore snapshot was obtained, so the attempted
Reflection's existence in Firestore before deletion was not established. Since
no post-delete live Reflection document existed to read, no actual tombstone
document could be inspected either. Therefore stale `note`/`rhythm` absence in
a tombstone is **not verified**; an empty collection is not a tombstone PASS.
No direct Firestore writes, account deletion, or account cleanup were
performed. The app's local no-resurrection behavior passed, but this does not
replace live tombstone verification.

No source code or dependencies changed in this closure pass. The QA device was
left in Second Space on Today; Sync remains enabled. The earlier note about an
accidental Fajr toggle and its visible restoration remains above.

Closure verification: `flutter analyze` PASS; `flutter test --no-pub` PASS
(**282 tests**); `dart format --output=none --set-exit-if-changed lib test`
PASS (298 files, 0 changed); `git diff --check` PASS. No APK rebuild was needed
for this documentation-only closure update.

### #017.5C final gates

- Fresh onboarding: **PASS recorded 14 October; not repeated 15 October**.
- Custom routine create/edit/archive on Second Space: **PASS** for the exercised
  create/checklist-edit/archive path; field and progress coverage is partial.
- Firestore replacement/tombstone behavior against an existing live document:
  **BLOCKED** because no document existed for inspection at the supplied UID.
- Local Reflection deletion and restart no-resurrection: **PASS**.
- Disposable account cleanup: **not performed**; no account or cloud data was
  deleted.
- Physical iOS QA, iOS notification actions, two-device convergence, and manual
  second-account mismatch remain documented **BLOCKED** for #018 risks.
