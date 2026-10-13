# Optional account authentication

Daisth remains usable without an account. Onboarding introduces local routines,
History, and Reflection without requesting permissions or requiring sign-in.
Authentication currently supports Email/Password only and does not gate app
routes.

## Local-first boundary

SQLite remains the source of truth for routines, progress, History, Reflection,
theme, and reminders. Signing in or out does not change local data. Daisth does
not yet upload, download, merge, or assign local records to an account. Those
semantics belong to the later sync phase. Firebase Auth session persistence is
handled by the native Firebase SDK; credentials and tokens are not copied into
SQLite. Reminder background actions remain local and do not initialize Firebase.

## Architecture and behavior

`AuthRepository` is implemented by `AuthRepositoryData`, which delegates Firebase
SDK work to `FirebaseAuthService`. The domain exposes only `AuthUser`, explicit
signed-out/signed-in/unavailable session states, and safe `AuthFailure` values.
Presentation maps those failures to calm user-facing messages.

Create-account success is retained even when sending the verification email
fails. Verification is encouraged but never required to use the app. Password
reset confirmation is generic so it does not reveal whether an email is
registered. Signing out requires confirmation and preserves the local database.
Account deletion is deferred until cloud data deletion semantics are defined;
it remains a production release requirement tracked in the QA ledger.

## Firebase setup

1. Create/select the Daisth Firebase project.
2. Register Android application ID `com.rendev.daisth` and iOS bundle ID
   `com.rendev.daisth`.
3. Enable **Authentication → Email/Password** in Firebase Console.
4. Run the normal FlutterFire configuration workflow for the project and add
   the generated platform configuration to the app. Do not commit fabricated
   project IDs or API keys.

Firebase Core initialization is attempted after local services initialize. If
configuration is missing or Firebase is unavailable, the account screen shows
that account service is unavailable while local Daisth continues to work.
Firebase Auth uses its native session persistence. No Firestore or other cloud
data product is included in this phase.
