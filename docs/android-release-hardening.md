# Android Release Hardening (#018B)

Audit date: 14 October 2026. Scope: Android release readiness only.

## Toolchain and SDK

| Component | Observed version/value |
| --- | --- |
| Flutter | 3.44.0 stable (`559ffa3f75`) |
| Dart | 3.12.0 |
| JDK used by Flutter/Gradle | Oracle JDK 18.0.2.1 |
| Shell `java` | Homebrew OpenJDK 21.0.12.1; Flutter selects its configured JDK 18 |
| Gradle wrapper | 9.1.0 |
| Android Gradle Plugin | 9.0.1 |
| Declared Kotlin Gradle Plugin | 2.3.20 |
| Gradle embedded Kotlin | 2.2.0 |
| compileSdk / targetSdk | 36 / 36 |
| minSdk | 24 |
| NDK | 28.2.13676358 (Flutter default) |

The app takes `compileSdk`, `targetSdk`, `minSdk`, and NDK from the installed Flutter SDK. No SDK downgrade or speculative toolchain change was made. Flutter doctor reported that Android SDK licenses are not accepted on this workstation.

## Kotlin Gradle Plugin warning

Release APK and AAB builds reproduce Flutter 3.44's warning that the `firebase_auth` and `firebase_core` plugins apply KGP and that future Flutter versions will require plugins compatible with built-in Kotlin. AGP also reports Kotlin plugin use in several merged plugin modules, and warns that `android.builtInKotlin=false` and `android.newDsl=false` are deprecated. The installed Flutter 3.44 migration guidance keeps built-in Kotlin disabled; enabling it is supported in a newer Flutter baseline and requires all participating plugins to migrate. The current Firebase plugin changelogs do not document that migration. No compatible dependency-only fix was available, so the warning remains an upstream migration item. See [Flutter's built-in Kotlin migration guide](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin), [Android's AGP 9 migration guide](https://developer.android.com/build/migrate-to-built-in-kotlin), [firebase_core changelog](https://pub.dev/packages/firebase_core/changelog), and [firebase_auth changelog](https://pub.dev/packages/firebase_auth/changelog).

`flutter pub outdated` showed patch updates for `sqflite` (2.4.4+1 to 2.4.4+2) and the development-only `sqflite_common_ffi` (2.4.3 to 2.4.4). No dependency was changed because neither update addressed the KGP migration warning. No new dependency was added.

## Android 16, layout, navigation, and manifest

The app targets API 36. Existing #017.5 Android 16 device QA is the behavioral evidence for edge-to-edge, insets, keyboard, floating bottom dock, editor sheet, notification actions, and representative back navigation; this pass did not repeat full product QA. Current layout continues to use Flutter safe-area/inset handling, root-navigator routine sheets, and go_router/Flutter back handling. No legacy edge-to-edge opt-out or deprecated native back callback was introduced.

The merged release manifest has `usesCleartextTraffic=false`. The app's Overpass endpoints use HTTPS. App permissions cover coarse/fine location, notifications, boot restore, and exact alarms; merged dependencies add Internet/network state, vibration, biometric/Fingerprint, GSF read, and a generated signature-level dynamic-receiver permission. No contacts/SMS, overlay, battery-optimization exemption, full-screen intent, DND access, or `USE_EXACT_ALARM` permission was found. The exact-alarm permission is `SCHEDULE_EXACT_ALARM`.

Exported components are the launcher activity and Google/Firebase redirect or revocation components, plus AndroidX Profile Installer's DUMP-protected receiver. App notification receivers remain `exported=false`. Firebase/Google and Profile Installer exported components are dependency-owned and retain their declared intent filters or permission protection.

`allowBackup` remains enabled for non-database preferences. The legacy and Android 12+ extraction rules exclude the SQLite database from cloud backup and device transfer because it contains local routine history and private Reflection notes. Consequently, local-only SQLite data does not restore through Android system backup; users need optional Daisth sync for cross-device continuity. Theme/reminder preferences may still transfer.

## Release logging and signing

The reminder background-action exception/stack trace is now printed only in debug mode. Settings QA controls and reminder diagnostics are already guarded by `kDebugMode`, so they are excluded from release compilation. No credentials or private signing material were added.

The hardcoded debug-key release signing fallback was removed. If ignored `android/key.properties` supplies all four values (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`) and the key exists, Gradle signs with that developer-owned upload key. In its absence, release outputs are unsigned. `android/key.properties.example` contains placeholders; `.gitignore` ignores real key properties and keystores. No upload keystore exists in this checkout.

Therefore the release certificate fingerprints are not yet available and cannot be registered with Firebase. Before a Play upload, configure the private upload key, derive its SHA-1 and SHA-256 certificate fingerprints, and add them to the Firebase Android app. Also register the Play App Signing certificate fingerprints for Play-distributed sign-in after Play App Signing is configured. Firebase configuration was not changed.

## Artifacts and 16 KB page compatibility

Both release build commands succeeded:

| Artifact | Size | Signing |
| --- | ---: | --- |
| `build/app/outputs/flutter-apk/app-release.apk` | 76,605,539 bytes | Unsigned |
| `build/app/outputs/bundle/release/app-release.aab` | 75,304,733 bytes | Unsigned |

APK metadata was verified as `com.rendev.daisth`, version code 1, version name 1.0.0, min SDK 24, target SDK 36. `zipalign -c -P 16 -v 4` passed. Bundletool 1.18.3 reports native libraries use `PAGE_ALIGNMENT_16K`. All nine packaged ELF shared libraries have LOAD segment alignment of at least 16 KB. Static APK/AAB/ELF checks pass.

Runtime testing on a 16 KB page-size system remains unavailable: the attached Android 16 Xiaomi reports a 4 KB page size, and the installed emulator images do not include a 16 KB image. Android 16 release smoke testing was not attempted because the release APK is correctly unsigned and would not install as a production release. No app install or user data was changed in this pass.

## Remaining release gates and build notes

- Obtain and configure the developer-owned upload key, then rebuild and verify the signed APK/AAB.
- Register upload-key and Play App Signing SHA-1/SHA-256 fingerprints with Firebase.
- Re-run release smoke QA using the signed artifact and a 16 KB page-size Android 16 device/emulator.
- Flutter doctor reports unaccepted Android SDK licenses on this workstation.
- Builds emit the unresolved Flutter/Firebase KGP migration warning, AGP 9 deprecated-flag warnings, and harmless R8 informational messages about upstream library metadata/rules. Builds complete successfully.
- Build output notes a Cupertino icon font expectation and tree-shakes app icon fonts; no Cupertino font is packaged. This did not prevent APK/AAB generation.
- App version/build number remains `1.0.0+1` / version code 1. Increment it before a subsequent Play release upload.

This document records Android release hardening only; iOS hardening and store/legal compliance are outside this context.
