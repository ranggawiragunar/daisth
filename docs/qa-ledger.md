# #017.5 Full Device QA & Regression Audit Ledger

This ledger records device checks that could not be completed during feature
implementation and must be revisited in the full device QA pass.

## #015 Onboarding and Authentication — pending device verification

- [ ] Fresh install onboarding, Skip, completion, restart, and page navigation.
- [ ] Existing v4 install migration skips onboarding; fresh v5 remains incomplete.
- [ ] Signed-out access to Today, History, and Routines.
- [ ] Create account, verification delivery/resend/refresh, sign-out, and sign-in.
- [ ] Firebase Auth session persistence after restart and generic password reset.
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

Firebase project configuration is not present in this checkout, so live auth
QA requires Firebase Console setup and platform configuration. Device QA remains
deferred to this ledger.

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
