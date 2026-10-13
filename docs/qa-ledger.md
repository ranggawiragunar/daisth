# #017.5 Full Device QA & Regression Audit Ledger

This ledger records device checks that could not be completed during feature
implementation and must be revisited in the full device QA pass.

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
