# Daisth

Stay consistent in what matters.

Daisth is a local-first Muslim routine companion for daily worship, prayer
times, reminders, Quran reading, Dhikr, and nearby mosque discovery.

## Getting started

The Flutter package is `daisth`; Android and iOS use `com.rendev.daisth`. Use
Flutter 3.44.0 or a compatible stable SDK, then run:

```sh
flutter pub get
flutter run
```

Android is the primary target. The iOS project is available on macOS with
Xcode installed.

## Current status

Daily records and app preferences are stored in the local SQLite database
`daisth.db`; see `docs/persistence.md` for schema and date semantics. History
provides bounded, editable daily records, and routine management supports
customization of built-in and user-created routines. See `docs/history.md` and
`docs/routines.md` for their current behavior.

## Architecture

- `lib/app` contains application startup, dependency wiring, and navigation.
- `lib/core` contains shared design, persistence, settings, location, time, and
  timezone infrastructure.
- `lib/features` contains feature-first domain, data, and presentation layers.
- `docs` records architecture, assets, prayer time, reminders, and persistence.
