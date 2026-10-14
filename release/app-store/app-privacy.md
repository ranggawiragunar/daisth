# App Store App Privacy worksheet

**Status: DRAFT — not submitted to App Store Connect.** Audit date: 14 October 2026. Apple requires disclosure for the app and integrated third-party partners. Confirm the exact answers with current SDK disclosures and Apple taxonomy before submission. See [Manage App Privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy) and [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/).

## Draft data types

| Apple data type | Daisth behavior | Linked to user? | Purpose / decision |
|---|---|---:|---|
| Contact Info — Name | Firebase/provider profile may contain a display name. | Yes, account | App Functionality (authentication/account display); optional account. Confirm provider behavior. |
| Contact Info — Email Address | Firebase Auth may receive provider email; Apple may provide relay email. | Yes, account | App Functionality (authentication/account). Optional account. |
| User Content — Photos or Videos | Users may select gallery images to attach to routines. Images stay on-device unless the user explicitly enables account sync, in which case the image is uploaded to the matching Firebase Storage account path. The account UI can also display a provider avatar; Daisth does not upload that avatar. | Yes; sync is optional | App Functionality. Confirm photo-library and Firebase Storage SDK disclosures and final Apple taxonomy before submission. |
| Identifiers — User ID | Firebase UID scopes private Firestore account data. | Yes | App Functionality (account/sync), security. |
| Identifiers — Device ID | Random installation ID/source device ID is synced as metadata for conflict/source tracking. It is not an advertising/system hardware ID. | Yes when sync enabled | App Functionality. Do not claim it is anonymous. Confirm whether Apple maps this implementation to Device ID in the live questionnaire. |
| Location — Precise Location | Prayer calculation itself is on-device. Nearby Mosque sends the current coordinate to `overpass-api.de` or `overpass.private.coffee`; chosen destination coordinates go to Google Maps after user navigation action. Daisth's five-minute search cache is in process memory only, not SQLite/Firestore. | Sent to third parties; association/retention unknown | App Functionality. Disclose outbound location; confirm whether Overpass request is retained/linked and how optional disclosure applies. **Review required.** |
| Sensitive Info — religious or philosophical beliefs | Prayer/routine content may reveal the user's religious practice; synchronized routine records are linked to the Firebase account. | Yes when sync enabled | App Functionality. Include if the actual data collected under Apple's definition represents religious beliefs; owner/legal review is required. |
| User Content — Other User Content | Optional Reflection note and user-entered/custom routine text may sync to private Firestore after explicit opt-in. Routine/checklist/history records are also synchronized. | Yes when sync enabled | App Functionality. Review whether routine records map additionally to Other Usage Data/Product Interaction based on Apple's definitions. |

## Tracking and third-party review

- **Tracking: NO, provisional.** App source contains no ad network, data broker, cross-app targeted ad/measurement flow, or ATT prompt/permission. No Firebase Analytics is included. Recheck every included SDK and provider's current declared practices before finalizing; a third-party SDK that tracks would change this answer.
- Firebase Authentication, Cloud Firestore, and Firebase Storage process account and opted-in sync data. Google Sign-In and Apple Sign-In process the authentication chosen by the user. OpenStreetMap/Overpass receives location query coordinates. Google Maps receives a selected destination when the user taps navigation. Do not mark “Data Not Collected.”
- Review current Firebase/Google/Apple SDK privacy disclosures for any technical/device data processed beyond the data flows visible in Daisth source; the audit did not infer SDK behavior from absent app-level analytics.
- Third-party SDK privacy manifests were present for the relevant bundled SDKs per #018C audit; no direct Daisth Required Reason API use was found in that audit. Privacy manifests and App Store Connect nutrition labels are different declarations. Recheck the final archive and all included SDK manifest versions.
- No claim is made about third-party at-rest encryption, provider log retention, or end-to-end encryption.

## Deletion and URL state

In-app account deletion exists and removes the Firebase account and known Daisth cloud-sync data after reauthentication. Local SQLite intentionally remains on the device. Apple-provider token revocation is implemented but awaits production configuration and physical QA. A public Privacy Policy URL is required by App Store Connect and is currently missing. A real Support URL is also missing. The repository drafts are not URLs.

**Owner/legal review required:** confirm optional collection disclosure, third-party provider data types/purposes, location and user-content categories, linked-to-user status, and final tracking answer before saving App Privacy in App Store Connect.
