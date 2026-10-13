# #017.5 Full Device QA & Regression Audit Ledger

This ledger records device checks that could not be completed during feature
implementation and must be revisited in the full device QA pass.

## #015 Onboarding and Authentication — pending device verification

- [ ] Fresh install onboarding, Skip, completion, restart, and page navigation.
- [ ] Existing v4 install migration skips onboarding; fresh v5 remains incomplete.
- [ ] Signed-out access to Today, History, and Routines.
- [ ] Google account picker, Firebase credential exchange, cancellation, and sign-out.
- [ ] Firebase Auth session persistence after restart.
- [ ] Offline auth failure and unavailable Firebase configuration behavior.
- [ ] Confirm local routine, custom routine, Reflection, theme, and reminder data
  remain intact after sign-in and sign-out.
- [ ] Light/dark auth screens, keyboard/autofill, and back navigation.
- [ ] Production account deletion flow after #016 defines cloud-data deletion.

Partial Android check completed on 13 October 2026 with the debug APK on
Android 16 (device 23122PCD1G): an existing install opened Today after upgrade,
and Account displayed the unavailable-service message while confirming local
Daisth remained usable. The install reused existing app data; it was not cleared
to simulate a fresh install. Fresh onboarding, auth operations/session
persistence, and the remaining items above are still pending.

Android Firebase configuration is present in the local checkout. Verify Android
Google sign-in, session persistence, and local-data preservation on device. The
current iOS `GoogleService-Info.plist` lacks Google OAuth client IDs and its
reversed URL scheme, so iOS sign-in QA remains blocked on refreshed generated
Firebase configuration. Device QA remains deferred to this ledger.

## #014 Daily Reflection — pending device verification

- [ ] Today Reflection card: unsaved/saved states, rhythm summary, navigation,
  and routine-progress isolation.
- [ ] Current Reflection save, edit, and confirmed delete.
- [ ] 20:30 Open-only notification; verify no Done/Snooze actions and Open
  navigates to `/reflection`.
- [ ] Save-before-reminder cancellation and clear-before-20:30 restoration.
- [ ] History Reflection view/edit and neutral absent state.
- [ ] Historical edit does not alter today's pending reminders.
- [ ] Reflection survives app restart.
- [ ] Light and dark theme rendering.
- [ ] Keyboard, multiline note, and text scaling behavior.
- [ ] Late historical entry uses the selected date and actual action timestamp.

Installation was attempted on the connected Android device, but Android
returned `INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`. Device
verification remains pending. No iOS device was connected for this pass.

## #016 Firestore Sync — live checks pending

- [ ] Android explicit-link confirmation, first merge, same-account resume,
  manual sync, sign-out retention, offline outbox retry, and account mismatch.
- [ ] Verify routine definitions/progress and Reflection sync across two devices.
- [ ] Verify archived routine and step data remain available after merge.
- [ ] Verify record and Reflection tombstones prevent stale-device resurrection.
- [ ] Verify per-device reminder state remains isolated after sync.
- [ ] iOS Google sign-in and Firestore sync after refreshing generated OAuth
  client IDs and reversed URL scheme in `GoogleService-Info.plist`.
- [x] Firestore rules compiled and deployed to Firebase project `daisthapp`
  on 13 October 2026. The deployed rules permit access only to the signed-in
  matching UID's `users/{uid}` path and deny all other paths.
- [ ] Confirm remote rules behavior with authenticated and mismatched accounts.

The project currently supports one SQLite dataset linked to one Firebase UID
per installation. Account profile switching and background sync are not
implemented. This is a deliberate MVP boundary.

## #017 Settings and account deletion — manual checks pending

- [ ] Settings groups and detail navigation in light and dark appearance.
- [ ] Theme choice persists after a process restart and remains device-local.
- [ ] Location allowed/denied/permanently denied/service-disabled transitions;
  verify explicit permission and system settings actions.
- [ ] Prayer refresh updates the schedule and reminder plan; no coordinates are
  shown in normal Settings.
- [ ] Change device timezone, resume Daisth, and verify schedule, reminder plan,
  and Reminder Health refresh without changing historical dates.
- [ ] Notification permission transitions, reminder toggle, precise/standard
  timing, and pending reminder list.
- [ ] Verify debug notification controls do not appear in a release build.
- [ ] Google sign-in and sync status on device.
- [ ] Delete Account: cancel confirmation, cancel reauthentication, reauthenticate,
  purge cloud collections, remove Firebase Auth user, and sign out.
- [ ] Verify routines, History, custom routines, Reflection, theme, and reminder
  preference remain on-device after linked-account deletion.
- [ ] Verify normal sign-out does not purge cloud data or unlink local sync.
- [ ] Verify deleting a different signed-in UID preserves the existing local
  UID link and outbox.

These checks are carried forward to #017.5. No local database reset control was
added. No Privacy Policy or Terms URL is configured; public legal URLs remain a
release requirement tracked for #018.
