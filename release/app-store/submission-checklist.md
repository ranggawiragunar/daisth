# App Store submission checklist

**Current result: BLOCKED.** Checklist state audited 14 October 2026.

| Item | State |
|---|---|
| App identity | Daisth / `com.rendev.daisth`; verify final archive bundle ID. |
| Apple Developer capability | **BLOCKED — USER INPUT REQUIRED:** developer account/team and enabled Sign in with Apple capability for the App ID. |
| Firebase Apple provider | **BLOCKED:** verify/enable provider and production identifiers/secrets in Firebase/Apple developer account. No owner credentials were present. |
| Apple account inputs | **USER INPUT REQUIRED:** Apple Developer Team ID, enabled App ID capability, and required Service ID/Key ID/private key configured securely in Apple/Firebase consoles. Do not commit `.p8` or credentials. |
| Firestore rules deployment | **BLOCKED / verify:** repository rules are UID-scoped, but production deployment must be confirmed before enabling sync for release users. |
| iOS Google configuration | Generated Firebase iOS OAuth configuration is present locally; signed-device sign-in remains unverified. |
| Signing/provisioning | **BLOCKED — USER INPUT REQUIRED:** team, distribution certificate, provisioning profile, and App Store Connect app record. |
| iOS runtime/device | **BLOCKED:** prior environment had no usable iOS 26.2 simulator runtime and physical device QA was unavailable. Recheck once the owner's environment/device is ready. |
| App Store archive | Not produced/verified as a signed distributable archive. |
| Physical-device QA | **BLOCKED:** sign-in, deletion, sync, location, reminders, and notification actions need signed-device validation. |
| Privacy Policy URL | **BLOCKED — USER INPUT REQUIRED:** public HTTPS URL and working in-app access. |
| App Privacy | Draft worksheet exists; owner/legal/provider review and App Store Connect entry required. |
| Account deletion | In-app action exists; test Apple token revocation on a configured production-like account. Local SQLite remains by design. |
| Support URL | **BLOCKED — USER INPUT REQUIRED:** real monitored support page/contact and App Store Connect URL. |
| Review notes/test account | Draft exists. Determine reviewer account/access strategy; no credentials in repository. |
| Listing/screenshots | Draft exists; genuine final iPhone/iPad screenshots and required metadata/assets remain. |
| Age rating | Complete App Store Connect questionnaire; do not infer official rating here. |
| Version/build | Current `1.0.0+1`. Choose a build number above any build uploaded to App Store Connect; never move backward. |

Apple guidance: [App Privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy), [account deletion](https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion/), and [Sign in with Apple token revocation](https://developer.apple.com/documentation/technotes/tn3194-handling-account-deletions-and-revoking-tokens-for-sign-in-with-apple).
