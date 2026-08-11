# Jellyfin Picker

[![Android CI](https://github.com/rigerc/jellyfin-picker/actions/workflows/android-ci.yml/badge.svg)](https://github.com/rigerc/jellyfin-picker/actions/workflows/android-ci.yml)

Jellyfin Picker is a bright, local-first Flutter companion for discovering a
Jellyfin library. The foundation targets Android and iOS, uses Material 3,
and keeps all runtime configuration ready for `--dart-define` values.

## Prerequisites

- Flutter stable with Dart 3.12 or later.
- JDK 17 and an Android SDK for Android development.
- macOS with Xcode for iOS development and device builds.
- A current-stable Jellyfin server and a dedicated test account.

## Development

```bash
flutter pub get
flutter gen-l10n
flutter run
```

Run the local quality gates and build a checksummed Android development APK:

```bash
tool/verify.sh
tool/build_android_debug.sh
```

A server URL can be supplied without committing it to source:

```bash
flutter run --dart-define=JELLYFIN_SERVER_URL=https://jellyfin.example
```

The verification script enforces formatting, strict analysis, tests, and an
aggregate 80% LCOV line-coverage gate. Dart and Flutter LCOV output on this
toolchain does not emit branch metrics, so the gate does not claim branch
coverage.

CI runs these checks on Linux and compiles the Android debug APK. It does not
replace Android/iOS installation, device journeys, accessibility, performance,
current-stable Jellyfin compatibility, or network inspection. Follow
[Release Verification](docs/RELEASE_VERIFICATION.md) to collect that evidence.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for feature boundaries.

Confirmed private-LAN HTTP is additionally enabled at the platform boundary:
Android uses cleartext transport with `allowBackup=false` (the app rejects
public HTTP before any request), and iOS enables local networking plus a local
network usage explanation. Invalid TLS certificates are never bypassed.
