# Istiqam Architecture

Istiqam uses a feature-first structure. Feature-specific code belongs under
`lib/features/<feature>/`; `lib/core/` is reserved for infrastructure shared by
multiple features, such as the design system.

## Feature layers

- **Presentation** contains screens/views, widgets, and view models. A screen
  renders state, coordinates presentation interactions, opens local overlays,
  and requests navigation.
- **Domain** contains immutable business models and, when needed, repository
  contracts and meaningful use cases. It does not depend on Flutter UI or the
  data layer.
- **Data** contains source-specific models, mappers, repository implementations,
  services, and temporary demo fixtures. Data code may depend on domain models
  and contracts.

The dependency direction is `Presentation → Domain ← Data`. Domain must never
depend on data. Do not add empty layer folders or placeholder repositories,
services, mappers, or use cases. A use case is appropriate when logic is
meaningfully complex, reused, or coordinates multiple dependencies; it should
not merely forward one repository call.

## Models and naming

Domain models use clean business names such as `Routine`, `RoutineStep`, and
`RoutineStatus`, with final fields and immutable state transitions. Add a
separate data model only when a source-specific representation is genuinely
needed; its name uses the `Data` postfix, such as `RoutineData`.

Do not use DTO suffix in Istiqam.

Repository contracts use domain names, such as `RoutineRepository`. Concrete
repository implementations in the data layer use the Data suffix, for example
`RoutineRepositoryData`.

Do not prefix repository implementations with Firebase, Firestore, API, or
another source technology. Source technology belongs in service/source names
when the class directly interacts with that technology, for example
`RoutineFirestoreService`. A repository hides how data is assembled and may
coordinate multiple sources without exposing them to presentation or domain.

Mappers use names such as `RoutineMapper` and are added only when a distinct
data representation must be converted to or from a domain model. Views use
names such as `RoutineDetailScreen`; view models use `RoutineDetailViewModel`.
Use cases use descriptive names such as `ResolveRoutineScheduleUseCase` when
the work warrants one.

## Navigation and app state

`go_router` is Istiqam's application navigation standard. Route identities,
paths, shell branches, and root-level detail routes are centralized under
`lib/app/router/`. Main destinations use a `StatefulShellRoute.indexedStack`
with the floating navigation dock; detail routes sit on the root navigator
outside that shell.

Routine Detail currently uses demo fixtures from
`features/routines/data/demo/routine_demo_data.dart`. Its view model owns the
current in-memory session state. Step changes and Not Today reasons are
temporary and can reset when the detail route is closed and reopened. This
demo-state limitation is intentional until a real data source is introduced.

Reader follows the same feature-first structure: `ReaderContent` and
`ReaderSection` live in the domain, `ReaderDemoData` provides temporary local
fixtures, and `ReaderViewModel` owns visibility and text-size preferences for
the current screen session. Arabic remains visible for Arabic content; opening
a reading never changes a routine's completion state.

Dhikr follows the same local-session pattern: `DhikrSequence` and `DhikrItem`
are immutable domain models, `DhikrDemoData` provides the post-prayer fixture,
and `DhikrCounterViewModel` owns count, sequence progress, undo, and reset state.
Finishing the sequence returns a result to Routine Detail, where the optional
post-prayer step is marked complete. No counter progress is persisted.

## Real location and mosque data

The first real data feature is Mosque Finder. Its domain contract remains
provider-neutral (`MosqueRepository`), while `MosqueRepositoryData` coordinates
the provider mapper and `MosqueOverpassService`:

```text
MosqueRepository
↓
MosqueRepositoryData
↓
MosqueOverpassService
```

Reusable foreground location follows the same separation:

```text
LocationRepository
↓
LocationRepositoryData
↓
LocationGeolocatorService
```

Repository names stay technology-neutral. Service names may expose the
technology they directly call. `FindNearbyMosquesUseCase` coordinates the
location repository and mosque repository. Each search loads one geographically
constrained 5 km dataset, then selects the smallest effective radius (1.5 km,
3 km, or 5 km) locally based on whether it contains at least six places.
Results are deduplicated, sorted nearest-first, and capped at twenty.

`MosqueRepositoryData` owns a five-minute, in-memory cache keyed by rounded
coordinate buckets and radius. Fresh entries can satisfy normal loads. Expired
entries remain available as same-area fallback while the use case revalidates
them after resolving the current location. Distances are remapped from that
location. A successful non-empty response replaces the cache; an empty response
or provider failure preserves an existing non-empty entry. A different area
never reuses the old bucket. Explicit refresh bypasses a fresh-cache shortcut
while retaining same-area fallback. Cache data remains in memory for the app
session. `MosqueOverpassService` queries the primary public Overpass endpoint
first and tries the secondary endpoint once after a retryable primary network or
provider failure. Each endpoint has one nine-second attempt. These public endpoints are MVP infrastructure and
availability is not guaranteed. `AppDependencies` is the manual composition
root and owns the shared HTTP client. Mosque search requests a foreground
position only while the Finder is open; coordinates and search history are not
persisted.

Prayer time calculation follows the same repository boundary:

```text
PrayerTimeRepository
↑
PrayerTimeRepositoryData
↓
PrayerTimeAdhanService
```

`PrayerTimeAdhanService` is the only layer that depends on `adhan_dart`.
`PrayerTimeRepositoryData` maps its result into `PrayerDaySchedule`, and
`LoadTodayPrayerScheduleUseCase` coordinates the shared
`ResolveCurrentLocationUseCase` with `PrayerTimeRepository`. The session-level
`PrayerScheduleSession` holds the current schedule in memory for Today, Settings,
and Routine Detail without repeating location reads for each route.

Prayer times are calculated locally with the Indonesia (KEMENAG) preset and
Shafi Asr by default. The app uses foreground current-device location and
formats the returned values using the device's local timezone. This assumes the
device timezone matches the physical location; remote location selection and
coordinate-to-timezone lookup are not implemented. Coordinates and settings
are not persisted, and calculation does not use a Kemenag network service or
background location.
