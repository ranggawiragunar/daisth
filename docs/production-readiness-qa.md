# Daisth Production Readiness QA

**Date:** 15 October 2026 (Asia/Jakarta)
**Repository:** `/Users/user/Projects/Flutter Projects/daisth`
**Scope:** Final engineering, Android-device, and release-build QA continuation. This report records observed evidence and does not certify store release.

## A. Final readiness status

**QA OPEN — several release gates remain.** In the primary Owner profile, prayer times and manual refresh worked, Reminder Health showed global reminders On and upcoming alarms, and a custom QA reminder delivered with Done/Snooze/Open actions. The first custom Snooze failed: the background action parser rejected generated custom routine IDs. That defect is fixed and physically retested after an in-place debug update that preserved app data: the custom Snooze queued and delivered one +10-minute reminder, and custom Done completed the QA routine and cleared its pending reminder. Open was not retested in Owner during this pass because the user needed a faster closeout; prior Android QA had exercised Open in Second Space. The earlier XSpace inability to load prayer times and its global Reminders switch staying Off remain profile-specific observations, not evidence of the Owner behavior. Routine Notes and synthetic image lifecycle are also physically verified in XSpace. Xiaomi permits ADB screenshots/log reads but rejects injected taps (`INJECT_EVENTS`); the user handled device navigation. The final 30-asset and ID/EN × light/dark physical matrices remain incomplete. iOS runtime QA is unavailable because Xcode's iOS 26.2 platform/runtime is not installed.

## B. Environment

- Flutter 3.44.0 stable (`559ffa3f75`); Dart 3.12.0.
- macOS 26.3; Android SDK 36; Java 18.0.2.1. Android SDK licenses are not accepted.
- Physical device: Xiaomi 23122PCD1G (`garnet`), Android 16 / API 36, 1220×2712, density 480.
- Android users reported: 0 Owner, 11 “security space”, 999 XSpace. Final reminder action verification was done in primary Owner user 0. No app data was cleared, no package was uninstalled, and no account/cloud data was changed during this pass.
- Firebase: no live read/write was performed in this pass. Existing `docs/qa-latest.md` and `docs/qa-ledger.md` record historical test-account work and the still-unverified live tombstone replacement behavior.
- Current screenshot evidence: `/tmp/daisth_qa_20261015/today-xspace.png` (English, light, Today location-setup state), `/tmp/daisth_qa_20261015/settings-xspace.png` (English, light, Settings overview), `/tmp/daisth_qa_20261015/language-settings.png` (pre-fix picker), `/tmp/daisth_qa_20261015/language-settings-after-fix.png` (post-fix picker), and routine editor/save/relaunch screenshots under `/tmp/daisth_qa_20261015/`. The QA routine was reopened after relaunch and Notes are visible in Routine Detail: `/tmp/daisth_qa_20261015/notes-postfix-detail.png`. Synthetic attachment evidence: `attachment-saved-detail.png`, `attachment-viewer.png`, `attachment-cancelled-detail.png`, `attachment-removed-detail.png`, and `attachment-after-relaunch-detail.png`. The generated picker image was cleaned from XSpace and `/tmp`. Process logs: `/tmp/daisth_qa_20261015/daisth-process.log` and `/tmp/daisth_qa_20261015/daisth-process-after-fix.log`.
- Language/theme matrix completed in this final continuation: English + light only. Historical Android evidence is summarized in section E and in the linked ledger; no claim is made for an unobserved combination.

## C. Starting baseline

- Starting baseline from the immediately preceding visual integration pass: `flutter analyze` passed, `flutter test` passed with 282 tests, and the 30 visual assets had production references.
- Starting worktree was clean at HEAD `29804a3 Migration Visual Assets` before the QA edits recorded below.
- Earlier QA history is preserved in `docs/qa-latest.md` and `docs/qa-ledger.md`; those records include limitations and must not be read as a pass for this final physical matrix.

## D. Findings and fixes

| ID | Severity | Area | Symptom | Root cause | Fix | Regression test | Physical verification | Final status |
|---|---|---|---|---|---|---|---|---|
| QA-PR-01 | Low | Project docs | README said History and Routine Management were future work | Stale project overview | Updated README to describe existing features and link current docs | Not applicable | Not applicable | Fixed |
| QA-PR-02 | Low | Android config | Default Flutter template TODO remained above the already-correct application ID | Stale template comment | Removed obsolete TODO; package ID unchanged | Existing Android manifest/config tests | Not applicable | Fixed |
| QA-PR-03 | Environment | Android physical QA | ADB input taps fail with `INJECT_EVENTS`; shell user query says 0 while foreground Daisth task is user 999 | Xiaomi security/profile behavior; no Computer Use UI tool available | No bypass attempted. User navigated Settings and Language manually; captured screenshots/log evidence through ADB | Not applicable | Today, Settings, and language picker observed; broader final screen/flow matrix remains incomplete | Open / report gate |
| QA-PR-04 | Environment | iOS QA | `flutter build ios --release --no-codesign` cannot select the iOS SDK | Xcode iOS 26.2 platform/runtime is absent | No fake signing/platform setup | Not applicable | No iOS runtime/device inspection | Open / external platform gate |
| QA-PR-05 | Medium | Settings / language sheet | English option was obscured by the floating navigation dock on the device | The modal was pushed on the Settings branch navigator, below the shell dock | Added `useRootNavigator: true`; added router test that taps English while the shell is mounted | New router regression test passes | Fresh debug APK installed to XSpace without clearing data; user reopened picker; screenshot confirms all three options visible above dock | Fixed and physically verified |
| QA-PR-06 | Medium | Routine Detail / rich-text Notes | Notes were absent after opening the saved QA routine following restart | Routine Detail was first built while the optional-content query was pending; the same keyed state did not rebuild its Quill controller when content arrived | Added `didUpdateWidget` handling to replace/dispose the read-only Quill controller when serialized Notes change; added a late-content regression test | Focused regression passes; full suite is 284 tests and analyze passes | Debug APK installed in XSpace preserving app data; after relaunch the detail visibly shows both rich and plain Notes (`notes-postfix-detail.png`) | Fixed and physically verified |
| QA-PR-07 | High | Custom routine notification actions | Custom reminder Snooze did not produce its follow-up; Done could not be trusted for custom IDs | `ReminderPayload.tryParse` only accepted built-in routine IDs, so the background action handler discarded valid generated custom routine payloads | Accept only the generated `custom-<hex>-<12 hex>` ID format in addition to known built-in IDs; added payload parser regression and malformed-ID rejection | Focused test and full suite pass: 286 tests; analyze passes | After data-preserving Owner debug install, QA custom reminder fired, Snooze queued one exact +10-minute follow-up which appeared, then Done completed the custom routine and cleared the follow-up | Fixed and physically verified for Snooze/Done; Open not retested in Owner |

No schema or Flutter dependency changed in this continuation. The local Firebase Emulator harness uses a separate Node test-only dependency set.

## E. Full feature QA matrix

“Prior evidence” points to earlier actual device testing documented in the QA ledger; it is not a claim that the flow was repeated during this continuation.

| Feature / state | Automated | Latest physical evidence | ID / EN | Light / dark | Result / limitation |
|---|---|---|---|---|---|
| Cold launch and shell navigation | Tests pass | Prior Android launch/back/tab checks; current Today visible | Both in prior runs; current EN | Prior light/dark spot checks | Prior PASS; final deep navigation not repeated |
| Onboarding pages, Skip, completion | Covered by widget/router tests | Normal and Skip paths recorded in ledger on 14 Oct | Prior ID/EN checks | Prior visual check | Prior PASS; not reset/repeated to protect profile data |
| Today, prayer schedule/focus, location unavailable | Tests pass | Owner Today showed Jakarta prayer schedule; Prayer & Location refresh updated successfully. XSpace still showed location/prayer load failure. | Current EN; prior ID | Current light; prior dark spot check | Owner schedule/refresh PASS; XSpace profile remains unable to load schedule |
| Routines list, custom CRUD/archive | Tests pass | Prior Second Space create/edit/archive; latest ledger lists untested fields | Prior ID/EN | Not all combinations | Partial PASS; final full editor matrix not exercised |
| Routine Detail / completion / historical edit | Tests pass | Prior mandatory completion/undo, History edit/Clear, routine persistence checks | Prior | Spot checks | Prior PASS with documented edge limits |
| Rich text / image attachments | Widget and repository tests | Notes visibly render after restart. Synthetic image add, viewer open, draft-remove cancellation (image remained), saved removal, and absent-after-relaunch were physically verified. Generated image cleaned up. | English/light partial | English/light partial | PASS for exercised flows |
| Reader, Penutup Hari, Taubat/Hajat | Content/widget tests pass | Prior Android RTL, scroll, source, theme, text-size and completion isolation checks | Prior ID/EN | Prior light/dark | Prior PASS; not repeated this continuation |
| Zikir counter | Flow tests pass | Prior increment/undo/reset/stages/full completion | Prior | Prior spot checks | Prior PASS |
| Reflection / persistence | Tests pass | Prior save/edit/delete/restart checks; latest cloud tombstone replacement not live-verified | Prior | Partial | Local PASS; live post-fix tombstone check blocked |
| History / pagination | Tests pass | Prior Yesterday, summaries, mandatory Unrecorded, edit and Clear | Prior | Partial | Prior PASS |
| Mosque Finder / attribution | Provider/UI tests pass | Prior live results, refresh, directions and OSM attribution; stale-cache-only not isolated | Prior | Partial | Prior PASS with provider/cache limits |
| Settings / language / appearance | New router regression plus existing tests | Settings overview and post-fix language picker inspected; all three language options visible above dock | Current EN | Current light | Language-sheet fix physically verified; other language/theme combinations not repeated |
| Auth / sync / account deletion | Tests pass | Prior approved test account sign-in/out, sync, local preservation and deletion | Prior | Not material | Prior PASS with live tombstone/two-device limits; no cloud access this pass |
| Reminders and actions | Tests pass, including custom-ID regression | Owner Reminder Health was On with exact alarms and Upcoming entries. Custom QA reminder delivery, background Snooze follow-up delivery, and Done completion were observed. XSpace prayer refresh still failed and its global switch stayed Off. | Current Owner EN; prior | Not material | Owner custom Snooze/Done PASS; Owner Open not retested; XSpace remains an environment/profile limitation |

## F. Visual 30-asset physical matrix

The asset inventory and production references are documented in `docs/visual-asset-inventory.md` and `asset_manifest.json`. The current physical screenshot is a location-setup state and contains none of the 30 3D visuals. Therefore this continuation does **not** claim visual inspection at the rendered size. All 30 are individually recorded as blocked for this final physical pass:

| ID | Intended screen | Runtime inspected in this pass | Status |
|---|---|---|---|
| 001 | Today light hero | No; Today was in location-setup state | BLOCKED |
| 002 | Today dark hero | No | BLOCKED |
| 003 | Onboarding intro | No | BLOCKED |
| 004 | Onboarding routine | No | BLOCKED |
| 005 | Onboarding calm | No | BLOCKED |
| 006 | Empty routines | No | BLOCKED |
| 007 | Routine editor header | Yes; create editor screenshot, English/light | PARTIAL — one locale/theme only |
| 008 | Routine attachment empty | No | BLOCKED |
| 009 | Routine progress | No | BLOCKED |
| 010 | Routine detail support | No | BLOCKED |
| 011 | Sholat Malam | No | BLOCKED |
| 012 | Taubat reading | No | BLOCKED |
| 013 | Hajat reading | No | BLOCKED |
| 014 | Reader header | No | BLOCKED |
| 015 | Zikir counter | No | BLOCKED |
| 016 | Zikir complete | No | BLOCKED |
| 017 | Reflection main | No | BLOCKED |
| 018 | Empty History | No | BLOCKED |
| 019 | History summary | No | BLOCKED |
| 020 | No location | No; setup state was rendered without this asset | BLOCKED |
| 021 | Mosque Finder header | No | BLOCKED |
| 022 | Prayer/location settings | No | BLOCKED |
| 023 | Settings main | Yes; English/light, overview art visible at actual device scale with no obvious crop/halo | PARTIAL — one locale/theme only |
| 024 | Notifications settings | No | BLOCKED |
| 025 | Account/sync | No | BLOCKED |
| 026 | Data/privacy | No | BLOCKED |
| 027 | Auth signed out | No | BLOCKED |
| 028 | Generic success | No | BLOCKED |
| 029 | Generic error | No | BLOCKED |
| 030 | Coming soon/unavailable | No | BLOCKED |

The screenshots provide visual spot checks of the Today greeting/date row, location setup card, summary, Reflection entry, routine list, floating dock, Settings overview, small Settings illustration, and post-fix language picker in English/light. The pre-fix picker screenshot shows the lower option obscured by the dock; the post-fix screenshot confirms the correction (QA-PR-05). This is not evidence for the full artwork set, dark mode, or other screens.

## G. Notification QA

Stable channels/actions and Android behavior were exercised in earlier QA: `daisth_high`, `daisth_standard`, `daisth_done`, `daisth_snooze`, and `daisth_open`. In this Owner continuation, a custom reminder was delivered, its Snooze action queued one +10-minute alarm and the follow-up notification appeared, and Done completed the routine and cleared the reminder. This exposed and verified the fix for custom routine IDs being rejected by the background payload parser. Open was not retested in Owner due to time; earlier Second Space Open evidence remains historical. A real Asar notification was left untouched. No local database inspection or cloud access was used.

## H. Auth / sync / account safety

- Earlier documented Google sign-in/out and local-data preservation used explicitly approved test accounts. Apple runtime remains an iOS gate.
- Earlier sync tests covered link/basic sync, offline outbox retry, account mismatch no-cloud-operation tests, and deletion of an explicitly approved disposable Daisth account. This continuation made no Firebase calls and deleted nothing.
- Live post-fix Firestore tombstone replacement remains unverified: latest history found no remote document to inspect. Two-device convergence also remains unverified.
- Added `tooling/firestore_rules_tests`, an isolated demo-project Firebase Emulator harness for unauthenticated denial, owner CRUD/tombstone update, and cross-user denial. `npm test` passed locally. No production Firestore call or rules deployment was made.

## I. Data / persistence

Prior Android and automated evidence covers routine progress, History, Reflection, archive, reminder state, settings, and local-preservation behavior; earlier tests cover schema migrations and connection isolation. The current pass did not mutate local records or attachments. Android backup configuration excludes the local SQLite database and attachment directory from backup/transfer; the regression test `test/android/android_backup_and_network_policy_test.dart` passes.

## J. Static / automated final verification

| Command | Result |
|---|---|
| `flutter pub get` (during final analyze/build) | PASS; lockfile unchanged. 37 newer versions remain outside current dependency constraints; no upgrades were made. |
| `dart format lib test` | PASS; 299 files, 0 changed. |
| `dart format --output=none --set-exit-if-changed lib test` | PASS after Notes change; 299 files, zero changed. |
| `dart format .` | Not cleanly applicable to the whole generated build tree: it hit an incomplete `build/ios/SourcePackages/...` dependency lacking `analysis_options.yaml` after formatting one generated file under ignored `build/`. Project `lib` and `test` formatting checks pass. |
| `flutter analyze` | PASS after Notes change; no issues found. |
| `flutter test` | PASS after Notes change: **284 tests**. |
| Reminder-settings follow-up (15 Oct) | `flutter analyze` PASS; targeted formatting PASS; `flutter test` PASS (**285 tests**); `git diff --check` PASS. Release APK rebuilt successfully at 226.2 MB. |
| Owner custom reminder action fix (15 Oct) | `dart format` PASS; targeted reminder tests PASS; `flutter analyze` PASS; `flutter test` PASS (**286 tests**); `git diff --check` PASS. Arm64 debug APK installed in Owner with `adb install -r`, preserving app data. |
| `git diff --check` | PASS. |
| `flutter build apk --release` | PASS after Notes fix; `build/app/outputs/flutter-apk/app-release.apk`, 226.2 MB. A later rebuild after the reminder-settings fix is recorded below. |
| `flutter build appbundle --release` | PASS after Notes fix; `build/app/outputs/bundle/release/app-release.aab`, 223.9 MB. |
| Latest release rebuilds after custom reminder parser fix | `flutter build apk --release` PASS (226.2 MB); `flutter build appbundle --release` PASS (223.9 MB). |
| `flutter build apk --debug` | PASS with the Notes fix; installed in XSpace with `-r` preserving app data. Notes were physically verified after restart. |
| `flutter build ios --release --no-codesign` | BLOCKED; Xcode iOS 26.2 platform/runtime is not installed. |
| `flutter gen-l10n` | Not applicable; the project uses its custom `DaisthLocalizations`/terminology layer and does not enable Flutter's generated localization (`flutter: generate: true` / ARB setup). A previous attempt confirmed this configuration gate. |

Android artifacts are local, unsigned release outputs; no upload key is configured. The APK is a universal local artifact; Play-delivered split size was not measured.

The reminder-settings fix’s release APK build completed successfully: build/app/outputs/flutter-apk/app-release.apk, 226.2 MB (703.7 seconds).

## K. Native Android QA

- Static: package/application ID and app label are Daisth; target SDK 36; main activity launcher/exported, internal receivers non-exported as configured; `usesCleartextTraffic=false`.
- Declared permissions are limited to fine/coarse location, notifications, boot rescheduling, and exact alarms; no camera, microphone, or broad storage permission found.
- Backup and data extraction XML exclude local database and attachment files, with automated regression coverage.
- Prior QA visually checked the Daisth launch splash and notification action icon. This pass did not open the launcher to inspect adaptive/themed icons or light/dark splash variants.

## L. Security / privacy QA

- Static search found no committed service-account key, private key, client secret, keystore, or hard-coded credentials among tracked files. Firebase client configuration remains public client config and secret values are not reproduced here.
- Production source logging is gated debug output in the background reminder action path; no token or user-record logging was found in the scan.
- Current app-process log review found no Flutter exception, fatal crash, RenderFlex overflow, missing asset, SQLite, or platform-channel error. It did include MIUI `MiuiPreloadClassImpl` and `AHardwareBuffer` errors; these are framework/OEM messages, not attributed to Daisth from available evidence.
- Android backup exclusions, cleartext policy, exported components, permission declarations, and iOS plist/ATS/permission strings were inspected. `plutil -lint` passed for the iOS Runner and Firebase plist files. OAuth values/signing configuration still need owner verification for iOS.

## M. Files changed during QA remediation

- **Production Dart:** `lib/features/settings/presentation/settings_placeholder_screen.dart` (`useRootNavigator: true` for the language picker); `lib/features/routines/presentation/routine_detail_screen.dart` (update Notes controller when asynchronous content changes); `lib/features/reminders/presentation/view_models/reminder_settings_view_model.dart` (explain the missing prayer-time prerequisite when reminder enablement fails); `lib/features/settings/presentation/settings_detail_screens.dart` (localized error copy); `lib/features/reminders/domain/models/reminder_payload.dart` (accept generated custom routine IDs in notification payloads).
- **Native Android:** `android/app/build.gradle.kts` (removed obsolete generated TODO only).
- **Native iOS:** none.
- **Tests:** `test/app/app_router_test.dart` (language picker remains tappable above the shell dock); `test/routines/routine_detail_test.dart` (late-loaded Notes content); `test/reminders/reminder_settings_view_model_test.dart` (location-unavailable enable failure keeps reminders Off and exposes a helpful message); `test/reminders/reminder_mapper_test.dart` (generated custom ID payload accepted; malformed custom ID rejected).
- **Docs/config:** `README.md` (updated stale feature status); this QA report; `tooling/firestore_rules_tests/` (local Firebase Emulator rules harness). No schema, Firebase rule, or Flutter dependency change.
- **Screenshots/logs:** stored under `/tmp/daisth_qa_20261015/`, outside Flutter runtime assets.

## N. Remaining QA gates

- **App-owned device QA:** Owner custom reminder delivery, background Snooze follow-up, and Done completion are verified after the parser fix. Owner Open action was not retested during this quick closeout. XSpace still cannot load prayer times and therefore did not enable global reminders in that profile. Do not touch the real Asar notification. Notes and image attachment lifecycle are physically verified. Xiaomi rejects ADB injected taps; user completes remaining screen interactions directly.
- Complete the ID/EN × light/dark physical matrix and all 30 visual placement inspections at rendered sizes, including Today light/dark hero.
- Verify sync offline-restart on device and live post-fix Firestore tombstone replacement with a disposable document; verify two-device convergence. Local Firestore Emulator rules tests pass, but production rules/deployment were not changed or tested.
- **External release gates:** install/configure Xcode's iOS 26.2 platform and run iOS/Apple Sign-In/notification QA with owner-managed OAuth, Team, capabilities, and provisioning; configure/protect an Android upload key and run a signed candidate smoke test; provide public Privacy Policy, Terms, support, and account-deletion URLs/mechanism.

## O. Known remaining app issues

Routine Detail previously omitted Notes when its asynchronous content query finished after the first frame. The controller-update fix is covered by regression test and rich/plain Notes are visible on the physical device after restart. Custom routine notification actions had a separate production defect: valid generated custom IDs were rejected before the background action could run. Parser validation is fixed and the Owner device verified custom Snooze delivery and Done. The Open action was not rechecked in Owner. XSpace still cannot load prayer times and its global Reminders switch remains Off; that profile-specific issue is documented without conflating it with the passing Owner scheduler. The attachment lifecycle is physically verified on Android.
