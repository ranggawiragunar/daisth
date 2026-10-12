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
