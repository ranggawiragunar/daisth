# A. Status

**MAP MIGRATION COMPLETE — LOCAL QA PASSED — PHYSICAL QA PENDING**

The checked-out implementation had no map renderer before this work, so this
change adds the MapLibre basemap to the existing Mosque Finder results screen.
The app-owned map failure state remains separate from location and Overpass
search states. No code-owned map blocker was found in local QA.

# B. Approved pre-migration baseline

- Flutter: 3.44.0 stable, revision `559ffa3f75` (2026-05-15).
- Dart: 3.12.0.
- Android SDK: 36.0.0.
- Gradle: 9.1.0.
- Android Gradle Plugin: 9.0.1.
- Baseline regression suite: 286 passing tests.
- Baseline release APK: built, 226.2 MB.
- Baseline release AAB: built, 223.9 MB.
- Baseline `flutter analyze` and `git diff --check`: passed.
- JDK before migration: 18.0.2.1. The selected MapLibre release requires JDK 21
  for Android, so Flutter's configured JDK was changed to Homebrew OpenJDK
  21.0.12.1. Gradle/AGP and app Java source compatibility were not upgraded.

# C. Old renderer/provider

Source audit found no `flutter_map`, `MapController`, `MapOptions`, `TileLayer`,
`MarkerLayer`, `latlong2`, `tile.openstreetmap.org`, or existing map widget in
the checked-out production source. The earlier OSM public-raster renderer
described in the migration request was absent from this repository state.

The existing Mosque Finder loaded OpenStreetMap places through the public
Overpass primary/fallback endpoints and showed a nearby place list. That POI
provider and its location, cache, classification, distance, and directions
behavior remain in place.

# D. New renderer/provider

- Renderer: MapLibre Flutter `maplibre_gl`.
- Basemap: OpenFreeMap Liberty in light mode and OpenFreeMap Dark in dark mode;
  both URLs are centralized in `DaisthMapConfig`.
- POI provider: existing Overpass service; OpenFreeMap supplies only map tiles.
- Location: existing foreground location resolution; the map uses the result's
  resolved origin and does not request new permission.
- Directions: existing `MapNavigationService` flow.
- Credentials: no OpenFreeMap key, Google Maps key, or Mapbox token.
- Style URLs, camera zooms, and style-load timeout are centralized in
  `DaisthMapConfig`. OpenFreeMap's official styles repository documents its
  Dark style URL; both styles were smoke-tested over HTTPS.

# E. Package/version compatibility

Added stable `maplibre_gl` 0.27.1. It supports the repository's Flutter 3.44 / Dart
3.12 toolchain and iOS deployment target 15.0. The package release supports
Android API 21+ and requires JDK 21 for Android; Flutter's Android minimum SDK
setting is used by the app. The existing Android release build passed with the
current Gradle 9.1.0 and AGP 9.0.1. Version 0.27.1 was selected for current
Flutter 3.44 / AGP 9 compatibility. The iOS native package resolution added
MapLibre GL Native distribution 6.28.0 to `Package.resolved`.

# F. Files changed

- Presentation: `lib/features/mosque/presentation/screens/mosque_finder_screen.dart`;
  new `lib/features/mosque/presentation/map/mosque_map_panel.dart`,
  `mosque_map_coordinate_mapper.dart`, and `mosque_map_marker.dart`.
- Shared configuration: new `lib/core/maps/daisth_map_config.dart`.
- Android: `android/app/src/main/AndroidManifest.xml` explicitly declares
  `INTERNET`; no map/location permissions or API keys were added.
- iOS: both Xcode workspace `Package.resolved` files record the MapLibre native
  distribution dependency. No Info.plist or deployment target changes were
  needed.
- Dependencies: `pubspec.yaml`, `pubspec.lock`.
- Tests: `test/mosque/mosque_map_test.dart`,
  `test/mosque/mosque_finder_screen_test.dart`.
- Documentation: `docs/architecture.md`, `docs/project-context.md`, this report.

# G. Behavior preservation matrix

| Existing behavior | Result |
| --- | --- |
| Mosque Finder route and screen hierarchy | Preserved; map appears in results above the existing list |
| Location permission/current location | Preserved; no additional permission |
| Loading, permission, no-location, Overpass error and empty states | Preserved |
| Overpass POI search, cache, classification, radius and ordering | Preserved |
| Nearby list, names, distances and result limit | Preserved |
| Current location marker | Added using the resolved origin as its own stable marker |
| Mosque/Mushola markers and marker-to-place association | Added with stable Overpass IDs |
| Marker selection | Selects the corresponding place and presents its existing directions card |
| Refresh/retry | Existing search refresh retained; map has an independent retry state |
| External walking directions | Existing `MapNavigationService` retained |
| Android Back/navigation | Existing route/navigation unchanged |
| Indonesian/English and light/dark Daisth surface | App-owned copy is localized; map switches between verified OpenFreeMap Liberty and Dark styles |

# H. Coordinate-safety verification

`MosqueMapCoordinateMapper` passes Daisth latitude/longitude fields to MapLibre
`LatLng` in latitude, longitude order. A regression test uses Jakarta-like test
coordinates and checks MapLibre's GeoJSON output uses longitude, latitude order.
Marker tests verify current location, Masjid, and Mushola retain their own
coordinates. Existing directions still use the domain `MosquePlace.coordinate`
without passing through the renderer mapper.

# I. Marker implementation

MapLibre circle annotations distinguish current location, Masjid, Mushola, and
other place types using Daisth theme colors. Marker data carries stable
`markerId` values; reserved current-location IDs, empty IDs, and duplicate place
IDs are filtered. Tapping a place annotation resolves its domain place by ID,
animates to that coordinate, and selects that place. The current-location
annotation is intentionally not selectable as a place.

# J. Error/retry architecture

The map panel has independent loading, ready, and recoverable failure states.
A style load gets a 20-second timeout, and annotation/style setup failures show
a localized retry control. The nearby place list remains available when only
the map fails. Map failure does not change Mosque Finder's location or Overpass
error states. Marker synchronization waits for style readiness and handles
result/selection changes, controller recreation, theme updates, and disposal
without fixed-delay setup.

# K. Attribution

MapLibre's built-in attribution control remains enabled on the map. The existing
information sheet now identifies OpenFreeMap, OpenMapTiles, and OpenStreetMap
ODbL data and retains its OpenStreetMap copyright link. Attribution is not
hidden behind the error overlay for a successfully displayed map.

# L. Dependencies added/removed

- Added: `maplibre_gl` 0.27.1 and its platform interface/web packages at 0.27.1.
- Removed: none; no old renderer dependency existed in the checked-out source.
- Retained: Overpass/network, geolocation, and URL launcher dependencies.
- No new secrets, map API keys, or competing renderer were introduced.

# M. Tests added/updated

- Theme configuration selects the verified Liberty/Dark style URLs.
- Coordinate adapter preserves lat/lng and GeoJSON axis order.
- Current location and Masjid/Mushola markers retain coordinates, type, and
  stable identity; duplicate, empty, and reserved IDs are rejected.
- Map marker tap selects its stable place ID.
- Map failure/retry stays separate from location failure and leaves the nearby
  list available.
- Selection remains associated through a light/Indonesian to dark/English
  theme-locale transition.
- Existing Mosque Finder tests remain and use a small fake renderer seam rather
  than instantiating native platform views.

# N. `flutter analyze`

PASS — no issues found after the final integration.

# O. `flutter test` exact count

PASS — 293 tests passed. Baseline was 286 passing tests; seven map tests were
added.

# P. `git diff --check`

PASS after final documentation/code edits.

# Q. APK release result/size

Baseline: PASS, 226.2 MB. Post-migration: PASS, 257.2 MB. The approximately
31 MB increase is the MapLibre native engine (`libmaplibre.so`, about 7.9–11.2
MB per bundled ABI). APK inspection found one MapLibre native library per ABI;
the old renderer was absent and no duplicate Mapbox/MapLibre engine was bundled.

# R. AAB release result/size

Baseline: PASS, 223.9 MB. Post-migration: PASS, 236.1 MB. The smaller increase
than the universal APK reflects app-bundle ABI delivery.

# S. iOS build/static result

Static configuration audit passed: iOS deployment target remains 15.0 and the
native MapLibre package is pinned in Swift Package Manager resolution. The
`flutter build ios --release --no-codesign` command was attempted but Xcode
cannot find the generic iOS destination because iOS 26.2 platform support is
not installed. This is an environment limitation, not a compile result.

# T. Emulator result

Not available. `flutter devices` listed macOS and Chrome only; ADB had no
devices. Flutter lists an iOS Simulator launcher, but its required iOS 26.2
runtime/platform is unavailable. No emulator provisioning was attempted.

# U. Physical-device QA

Pending — no physical device connected during implementation.

# V. Known code-owned map issues

None

## Provider smoke test

Before integration, the development machine successfully fetched the OpenFreeMap
Liberty and Dark style JSON and checked TileJSON plus style-referenced sprite,
glyph, and vector-tile resources. Requests returned HTTP 200 with the expected
JSON, PNG, protobuf, or vector-tile content type. No live-network call was added
to unit tests.

References: [MapLibre Flutter package requirements and 0.27.1 changelog](https://pub.dev/packages/maplibre_gl/changelog), [OpenFreeMap Quick Start](https://openfreemap.org/quick_start/), [OpenFreeMap style definitions](https://github.com/hyperknot/openfreemap-styles), and [OpenFreeMap attribution and service terms](https://openfreemap.org/).

## Physical follow-up checklist

- Use the PRIMARY / OWNER installation; do not use clone/XSpace as authority.
- Do not clear app data.
- Check map load, pan, pinch zoom, current location, and recenter.
- Check Masjid/Mushola markers, marker selection, and list interaction.
- Check search refresh, directions, external-app return, and Android Back.
- Check background/resume and repeated open/close.
- Check ID Light, ID Dark, EN Light, and EN Dark.
- Confirm attribution is visible.
- Simulate network failure and use map Retry.
- Inspect logcat and perform a release-mode smoke test if safe.
