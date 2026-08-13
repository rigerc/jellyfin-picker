# Changelog

## 1.0.7 — 2026-08-13

- Remove the remaining empty space below title details, including on devices
  with a bottom system inset.

## 1.0.6 — 2026-08-13

- Prevent the title details sheet from covering the lower part of the screen
  with a blank overlay when its content is shorter than the viewport.

## 1.0.5 — 2026-08-13

- Keep the saved session available when Jellyfin rejects an expired token so
  re-authentication can recover without losing the connection state.
- Retry transient secure-storage reads to preserve saved sessions and stable
  device identity across keychain or keystore misses.

## 1.0.4 — 2026-08-12

- Sort discovery by recently added, or filter to titles added within 7, 30, 90,
  or 365 days.
- Search titles by name and combine with media type, runtime, ratings, genre,
  release period, watched, favorite, content rating, and series state.
- Recently added, unwatched, and favorites are one tap away as quick filters.
- Active filters reset cleanly without clearing presets or your discovery
  history.
- Filter, search, and sort choices carry across the grid, swipe, and shuffle
  views and survive restarting the app.

## 1.0.3 — 2026-08-11

- Filters are grouped into roomier sections that remain comfortable at large
  text sizes.
- Discovery opens with a more distinctive cinema-style header and a live title
  count.
- Posters appear sooner through tiny blurred previews before the sharper image
  fades in.
