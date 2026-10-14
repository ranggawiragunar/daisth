# Daisth release preparation

**Audit date:** 14 October 2026  
**Product:** Daisth — *Stay consistent in what matters.*  
**Android application ID / iOS bundle ID:** `com.rendev.daisth`  
**Current package version:** `1.0.0+1` (version/build 1)  
**Implementation status:** #018 repository-side hardening and release preparation complete. This does not mean either platform or store is ready to submit.

## Product QA

The #017.5 ledger records Android QA and its remaining unverified cases. Preserve these medium/low risks: two-device Firestore convergence, manual second-account mismatch, isolated Mosque Finder stale-cache behavior, actual delayed follow-up delivery, ordinary Google picker cancellation, and offline-outbox restart variation. They are QA coverage gaps, not demonstrated defects. Physical iOS QA and iOS notification-action QA remain blocked by the lack of signing and a usable runtime/device. See [the QA ledger](../docs/qa-ledger.md).

## Android

**ANDROID RELEASE GATE: BLOCKED**

- No developer-owned upload keystore or release signing values are present. The release APK/AAB builds are unsigned.
- Upload-key and Play App Signing SHA-1/SHA-256 fingerprints are not registered/verified in Firebase. Production Google sign-in therefore has not passed signed-release smoke QA.
- Production Firestore rule deployment has not been independently verified; the repository rules are UID-scoped, but source files alone do not prove production deployment.
- No signed release smoke test has been performed.
- Before first upload, keep version `1.0.0+1` only if build 1 has never been uploaded; otherwise choose a version code strictly above the highest uploaded code. Current recommendation if still unused: `1.0.0+2`.
- Current Android target API is 36. `flutter build apk --release` and `flutter build appbundle --release` both pass locally; both outputs are unsigned. No upload or installation was performed.

## iOS

**IOS RELEASE GATE: BLOCKED**

- Apple Developer team/signing identity and provisioning profile are missing.
- Production Firebase Apple-provider setup is not verified. Google iOS and Apple sign-in have not passed signed-device QA.
- Production Firestore rule deployment has not been independently verified.
- The previously observed iOS 26.2 simulator runtime was unavailable; no physical iOS QA or notification-action QA was completed.
- An App Store archive and signed-device smoke test are still required.

## Store Compliance

**STORE COMPLIANCE GATE: BLOCKED**

- A source policy draft and account-deletion page draft exist below. Neither is a live public resource.
- **PUBLIC PRIVACY POLICY URL: USER INPUT REQUIRED.**
- **PUBLIC ACCOUNT DELETION URL: USER INPUT REQUIRED.** The page must give people outside the installed app a genuine request route.
- **USER INPUT REQUIRED — developer/legal identity, privacy contact, monitored support/deletion contact or web form, and support URL.**
- Google Play Data Safety and Apple App Privacy drafts are worksheets only. The owner must review provider disclosures and enter final truthful answers in the respective consoles.
- Store listings are drafts; icons, screenshots, required artwork, final age/content ratings, and review access arrangements must be completed by the owner.
- The in-app Data & Privacy page has accurate behavior copy but no Privacy Policy link because no real URL was supplied. Add a working public policy link there before store submission; do not substitute this repository file.
- No application dependencies were added for this pass. The Plus Jakarta Sans OFL license is included in the asset bundle and registered with Flutter's built-in license screen.

## User Inputs Required

1. Developer display/legal identity and jurisdiction details required by chosen store accounts.
2. Monitored privacy/support contact mechanism.
3. Live HTTPS Privacy Policy URL.
4. Live HTTPS account-deletion request URL with a genuine request mechanism that works after uninstall.
5. Android upload keystore, secure signing configuration, and resulting Firebase release SHA fingerprints.
6. Apple Developer account/Team ID, enabled App ID capability, required Service ID/Key ID/private key configured securely in Apple/Firebase consoles, provisioning/signing, and Firebase Apple provider setup. Do not commit `.p8` or credentials.
7. Verify and deploy production Firestore UID-scoped rules.
8. Owner/legal review of the two store disclosure worksheets and final store-console answers.
9. Review-account strategy if account/sync-only paths need reviewer access.

Never put passwords, private keys, Apple `.p8` files, or store credentials in this repository.

## Accepted Risks

| Risk | Severity | Rationale |
|---|---|---|
| Two-device Firestore convergence not physically tested | MEDIUM | Automated/live single-device sync coverage exists, but cross-device merge has not been observed. |
| Manual second-account mismatch not physically tested | MEDIUM | Account ownership behavior is implemented/tested but needs a disposable second-account device pass. |
| Mosque stale-cache scenario not isolated | LOW | Provider and refresh paths were exercised; the exact stale-cache failure case was not separately isolated. |
| Delayed reminder follow-up delivery not waited through | LOW | Policy and scheduling behavior were exercised, but elapsed-time delivery was not observed. |
| Ordinary Google picker cancellation not manually verified | LOW | Cancellation mapping/regression coverage exists; the ordinary picker cancellation UI was not confirmed. |
| Offline outbox restart variation not manually verified | LOW | Offline queue and restart behavior have automated/live surrounding coverage; one variation remains. |
| iOS physical QA and notification actions unavailable | RELEASE BLOCKER | iOS binary cannot be signed/installed and reviewed on-device in the available environment. |

## Next Release Actions

1. Supply the owner-controlled Android signing input and register signing fingerprints in Firebase; build, verify, and smoke-test a signed artifact.
2. Complete Apple Developer and Firebase provider configuration; build/install on a supported iOS device/runtime and verify sign-in, deletion, and notifications.
3. Supply and publish the Privacy Policy and external account-deletion resources with real monitored contacts; add the policy URL to Data & Privacy.
4. Owner/legal review the Play and App Store data disclosures; complete console declarations, listing, age/content questionnaires, artwork, and review access.
5. Confirm whether build 1 has ever been uploaded, then set a never-decreasing release build number.

## Documents

- [Privacy Policy source draft](legal/privacy-policy.md)
- [Account deletion web-page source draft](legal/account-deletion.md)
- [Google Play Data Safety worksheet](google-play/data-safety.md)
- [Google Play listing draft](google-play/listing.md)
- [Google Play submission checklist](google-play/submission-checklist.md)
- [App Store App Privacy worksheet](app-store/app-privacy.md)
- [App Store listing draft](app-store/listing.md)
- [App Store submission checklist](app-store/submission-checklist.md)
