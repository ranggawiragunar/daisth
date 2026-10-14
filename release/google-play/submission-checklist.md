# Google Play submission checklist

**Current result: BLOCKED.** Checklist state audited 14 October 2026.

| Item | State |
|---|---|
| Product/package identity | Daisth / `com.rendev.daisth`; verify in final signed artifact. |
| Target API | 36 in current Flutter baseline; meets the current Android 16 API 36 new-app/update threshold effective 31 Aug 2026. Verify final merged manifest at upload. |
| Release AAB | Local unsigned build can be produced; unsigned artifact cannot be submitted as a completed release artifact. |
| Upload key / Play App Signing | **BLOCKED — USER INPUT REQUIRED:** real upload keystore and private Gradle signing configuration; configure Play App Signing in Console. |
| Firebase release SHA | **BLOCKED — USER INPUT REQUIRED:** register upload certificate and Play App Signing certificate SHA-1/SHA-256 in Firebase; test Google sign-in with signed artifact. |
| Firestore rules deployment | **BLOCKED / verify:** repository rules are UID-scoped, but production deployment must be confirmed before enabling sync for release users. |
| Signed release smoke QA | **BLOCKED:** install/test signed build on Android device; verify sign in, sync, delete, location, reminder flows. |
| Privacy Policy | **BLOCKED:** public HTTPS URL and in-app working access missing. |
| External account deletion | **BLOCKED:** public URL with real monitored request mechanism missing. In-app Delete Account exists. |
| Data Safety | Draft at `data-safety.md`; owner/legal/provider review and Console submission required. |
| Content rating | Complete Play's rating questionnaire in Console; no official rating assigned here. |
| App access | Core app is available signed out. Supply a disposable test account only if account-specific review is needed. |
| Permissions | Current manifest declares coarse/fine location, POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, and SCHEDULE_EXACT_ALARM. Explain location use, reminder purpose, reboot restoration. No `USE_EXACT_ALARM`, full-screen intent, or DND bypass. Confirm any live Console declarations. |
| Exact alarms | Permission is `SCHEDULE_EXACT_ALARM`, not restricted `USE_EXACT_ALARM`; still document/review actual user-visible reminder use against current policy and Android behavior. |
| Store listing/assets | Draft exists. Verify icon, genuine phone/tablet screenshots, feature graphic if applicable, metadata, category, and localization in Console. |
| Developer/contact identity | **BLOCKED — USER INPUT REQUIRED:** legal/developer display identity, support contact, privacy contact, public support URL. |
| Version/build | Current `1.0.0+1`. Use `+2` only if `+1` has never been uploaded; never move versionCode backward from any uploaded artifact. |

Current official guidance: [target API level](https://developer.android.com/google/play/requirements/target-sdk), [Data Safety](https://support.google.com/googleplay/android-developer/answer/10787469), [account deletion](https://support.google.com/googleplay/android-developer/answer/13327111), and [developer policy/exact alarm](https://support.google.com/googleplay/android-developer/answer/18258653).
