# Istiqam

Istiqam is a calm Muslim routine companion designed to help people stay
consistent with daily worship routines through reminders, completion, and
reflection.

## Getting started

This project was created with Flutter 3.44.0 stable and Dart 3.12.0. Use the
currently installed stable Flutter SDK, then run:

```sh
flutter pub get
flutter run
```

Android is the first target. The generated iOS project is retained and can be
run from macOS with Xcode installed.

## Current status

The initial foundation and static Today UI are implemented. Today uses sample
data for Monday, 12 October. History, Routines, and Settings are placeholders.

Firebase and business logic are intentionally not implemented yet. Prayer-time
calculation, reminders, location, authentication, and network access are also
outside this first slice.

## Architecture

- `lib/app` contains app configuration and the four destination shell.
- `lib/core/design_system` contains semantic colors, spacing, radius,
  typography, theme extensions, and reusable UI components.
- `lib/features` contains presentation-only screens for Today and the three
  placeholder destinations.
- `docs` records product context and the implemented design system.

Today is backed by local presentation constants. There are no repository or
domain layers because this slice has no persistence or business logic.
