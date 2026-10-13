# Optional Google authentication

Daisth remains usable without an account. Onboarding does not request sign-in,
and authentication does not gate Today, Prayer Times, Routines, Reader, Dhikr,
Mosque Finder, History, Penutup Hari, Reflection, Reminders, or Settings. Google
Sign-In is the only authentication provider. Account access can enable optional
Firestore sync only after a separate explicit link confirmation.

## Local-first boundary

SQLite remains the source of truth for routines, progress, History, Reflection,
theme, and reminders. Signing in alone does not assign local data to an account.
After explicit activation, only routine definitions, routine step definitions,
routine records, routine step records, and Daily Reflection synchronize beneath
the linked UID. Firebase Auth owns session persistence. Credentials and tokens
are not copied into SQLite. Reminder background actions remain local and do not
initialize Firebase or Google Sign-In.

## Architecture and behavior

`AuthRepository` is implemented by `AuthRepositoryData`, which delegates
Firebase and Google SDK work to `FirebaseAuthService`. The domain exposes only
plain-Dart `AuthUser`, explicit signed-out/signed-in/unavailable session states,
and safe `AuthFailure` values. Presentation never displays SDK exception text.
Google account-picker cancellation returns quietly to the signed-out Account
screen. Normal sign-out ends Firebase and Google sessions after confirmation,
while preserving SQLite, the linked UID, and pending sync outbox. A different
Google UID cannot sync with that local dataset. See [sync.md](sync.md) for the
merge and account-ownership rules.

The Google Sign-In singleton is initialized once before its first operation.
The flow obtains a Google ID token, exchanges it for a Firebase credential, and
maps the Firebase user into `AuthUser`. Daisth requests no Google API scopes.
When Firebase cannot initialize, the account capability is unavailable while
local features continue to work.

## Firebase and Google configuration

The configured Firebase project is `daisthapp`, with Android application ID
`com.rendev.daisth` and iOS bundle ID `com.rendev.daisth`. Firebase Core uses
`lib/firebase_options.dart`; Android also uses its generated
`android/app/google-services.json` and the Google Services Gradle plugin.
Keep these files generated from the Firebase Console or FlutterFire tooling;
do not fabricate project configuration.

Google authentication must be enabled in Firebase Console. The Android debug
SHA-1 is registered there. To inspect the local signing fingerprints, run:

```bash
cd android
./gradlew signingReport
```

The current iOS `GoogleService-Info.plist` has no `CLIENT_ID` or
`REVERSED_CLIENT_ID`, so iOS Google Sign-In still needs a refreshed Firebase
configuration with the OAuth client values and URL scheme. Do not remove or
rewrite Flutter Swift Package references to work around local `xcodeproj`
tooling. iOS live sign-in remains unverified until that generated configuration
is available.

Firebase Auth session persistence is native. Firestore is configured for
private user-scoped sync; it is not a UI repository. Account deletion is
available from the signed-in Account screen. It requires confirmation and
Google reauthentication, purges the user's known Firestore collections before
deleting Firebase Auth, and disconnects Google afterward. Deleting the account
does not delete local SQLite data. When the deleted UID matches the local sync
link, the link and pending outbox are cleared while the stable device ID is
retained. A different local UID link is left untouched. Cloud purge failure
leaves Firebase Auth and local linkage intact so the user can retry. See
[sync.md](sync.md) for purge ordering and sync exclusion.
