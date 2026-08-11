# Catalog feature boundary

Catalog-specific `domain/`, `data/`, and `application/` code lives here;
presentation screens remain intentionally deferred. The data repository emits
bounded Jellyfin pages and the application Cubit consumes those page states.
Import only shared core contracts and this feature's own layers.
