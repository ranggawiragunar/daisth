# Google Play Data Safety worksheet

**Status: DRAFT — not submitted to Play Console.** Audit date: 14 October 2026. This maps observed app behavior to the current Play categories; the developer must review current Console wording, Firebase/Google/Apple SDK disclosures, and vendor contracts before submission. Play's definition includes data transmitted by SDKs, and ephemeral data still belongs in the form response even where it may not appear in the public section. See [Play Data Safety guidance](https://support.google.com/googleplay/android-developer/answer/10787469) and [User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311).

## Data inventory

| Data / closest Play type | Transmitted and use | Optional? | Draft answer / review |
|---|---|---:|---|
| Name — Personal info / Name | Provider/Firebase Auth profile may supply display name for account identity and account UI. | Yes, account is optional | Collected when signing in. App-functionality purpose. Confirm provider SDK disclosures and exact Firebase profile fields. |
| Email address — Personal info / Email address | Google/Apple provider and Firebase Auth may supply the account email. | Yes | Collected for account/authentication. May vary by provider (Apple relay email). |
| Profile photo/avatar — Photos and videos (conditional review) | Auth profile may expose a photo URL which the Account screen can load. Daisth does not upload the avatar. | Yes, account is optional | Confirm whether the current Play taxonomy treats provider-supplied avatar retrieval as this data type; reconcile provider SDK disclosure before Console submission. |
| Firebase UID — Personal info / User IDs | Firebase Auth identity; Firestore account path is scoped beneath this UID. | Yes | Collected for account management, security, and sync. |
| Prayer/routine participation that reveals religious beliefs — Personal info / Political or religious beliefs | Locally recorded by default. When sync is explicitly activated, routine definitions and records transmit to private Firestore beneath the signed-in UID. | Yes | Likely collected for app functionality for opted-in sync accounts because prayer records may reveal religious belief. Confirm in Play Console with owner/legal review. |
| Custom routine text and Reflection note — App activity / Other user-generated content | Local by default; transmitted to private Firestore only after explicit sync activation. | Yes | Collected for app functionality for opted-in sync accounts. Reflection note is user-authored content. |
| User-selected routine images — Photos and videos | Selected from the system photo library, stored in app support locally, and uploaded to owner-scoped Firebase Storage only after explicit sync activation. | Yes, sync is optional | Collected for app functionality for opted-in sync accounts. Confirm final taxonomy, Firebase SDK disclosures, and Storage deployment before Play submission. |
| Routine/checklist interaction state and historical actions — App activity / Other actions (taxonomy review) | Transmitted to private Firestore only after explicit sync activation. | Yes | Likely app functionality. Confirm whether Console also calls for this type beyond the belief/content classifications above. |
| Random installation ID / source device ID — Device or other IDs | Generated randomly; included as sync metadata to resolve source/conflicts. Not IMEI, Android ID, IDFA, or advertising ID. | Yes | Collected only with cloud sync; can be associated with the account dataset, so not anonymous. App functionality/security. |
| Precise location — Location | Prayer-time location is processed on device. Nearby Mosque sends coordinates over HTTPS to `overpass-api.de` or `overpass.private.coffee`; explicit navigation opens Google Maps with the selected destination coordinates. Daisth keeps search results and a rounded coordinate-bucket key in process memory only; the five-minute cache is not persisted to SQLite/Firestore, though stale entries can remain in memory until replacement/process end. | Feature/permission optional | For Play response include the outbound Overpass request in the form even if ephemeral. Provider retention/processing is not established by this code audit: **REVIEW REQUIRED BEFORE PLAY CONSOLE SUBMISSION**. Determine whether transmission qualifies as ephemeral under the current policy and whether provider is a service provider or recipient. Do not answer “not collected” merely because coordinates are not persistently stored by Daisth. |
| Local notification/runtime state, theme, permissions, timezone, onboarding state | Stored/used on device; not written into Firestore sync entities. | N/A | Not collected off-device by Daisth code. Recheck merged SDK behavior and release manifests. |

## Collection, sharing, and security worksheet

- **Collection:** account and synced records are transmitted off-device only after account sign-in/sync activation. Nearby Mosque transmits coordinates when the feature requests them; treat this as a distinct outbound collection path. Play says SDK/library transfers count too.
- **Ephemeral location:** the app sends the search coordinate in the Overpass query and does not persist it in Daisth SQLite/Firestore. Whether the provider retains request logs or uses the coordinate beyond real-time service is not established here. Confirm provider terms/retention; only then decide the final ephemeral disclosure answer.
- **Sharing:** Firebase Auth/Firestore, Google Sign-In, and Apple Sign-In receive data to provide requested account/auth/sync functions. Mark them as service providers only if current contracts and actual use satisfy Play's service-provider definition. Overpass receives location as an external search provider; Google Maps receives destination coordinates when the user chooses navigation. Review whether these are “shared” under the current Console definitions. No ads, data broker, or sale behavior is present in the app code audit.
- **Purpose:** account management, app functionality (sync/search/navigation), and security/conflict resolution. No advertising or analytics purpose identified.
- **Encryption in transit:** YES, draft, for these implemented external requests because the inspected endpoints use HTTPS/TLS. Do not infer encryption at rest; no at-rest claim is made here.
- **Deletion:** in-app account deletion exists and removes the Firebase account and known Daisth cloud data. Local SQLite remains. A working external web deletion resource is still required and must be entered before release.
- **User data not automatically synced:** local theme, notification permission, exact-alarm capability, snooze/follow-up state, onboarding, timezone runtime state, and location permission state.

## Console questions requiring owner review

1. Confirm each data type above against Play's live taxonomy and every included SDK/provider's current data disclosures.
2. Check provider-supplied profile photo URL/image handling and any technical/device data disclosed by Firebase Auth, Firestore, Firebase Storage, Google Sign-In, and Apple Sign-In SDK providers.
3. Resolve location request retention/ephemeral processing and third-party sharing classification.
4. Confirm disclosure of prayer records as “Political or religious beliefs” and the correct additional category for routine/checklist state.
5. Decide whether account/sync and mosque search are optional collection in the relevant Console questions; account/sync clearly is optional.
6. Complete security practices, data deletion questions, and user-data declarations truthfully. Do not claim deletion from local SQLite.
7. Enter the real Privacy Policy and external account deletion URLs, developer contact, and account deletion request mechanism.

This worksheet is not a completed declaration or legal determination.
