# Jellyfilter architecture

The project keeps cross-cutting concerns in `lib/core/`, app composition and
concrete route assembly in `lib/app.dart`, and product work in flat feature
modules under `lib/features/`.

Each feature owns three layers:

```text
presentation -> domain <- data
```

- `domain/` contains entities, failures, and repository contracts.
- `data/` contains DTOs, data sources, and repository implementations.
- `presentation/` contains pages, widgets, and feature state.

The dependency rules are:

- Presentation depends on its own domain contracts, never on data classes.
- Data depends on its own domain contracts, never on another feature's data.
- Domain has no Flutter, network, storage, or other feature dependencies.
- Core contains only cross-cutting contracts and tokens; it does not import
  feature presentation or assemble concrete routes.
- Shared catalog media candidates, image metadata, media types, and filters
  live in `lib/core/media/`. Discovery consumes these neutral contracts and
  never imports the catalog feature domain; catalog data maps transport data
  into the same neutral model.
- App composition injects one `GoRouter` instance into the root widget so
  rebuilds cannot reset navigation state.

The foundation establishes these boundaries without adding placeholder feature
behavior.
