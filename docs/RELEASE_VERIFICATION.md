# Release Verification

This guide defines the evidence required for the Android and iOS development
MVP. Automated checks and build output are necessary but do not replace
hands-on device, accessibility, performance, compatibility, or network tests.

## Prerequisites

- Flutter stable and the Dart version accepted by `pubspec.yaml`.
- JDK 17 and an Android SDK for the Android build.
- macOS with Xcode for the iOS build.
- Android and iOS test devices or simulators.
- A current-stable Jellyfin server with a dedicated test account.
- A deterministic library containing 2,000 movie or whole-series candidates.
- A trusted test proxy such as mitmproxy or Charles for traffic inspection.

Record the Flutter version, Jellyfin version, server capabilities, host OS,
device model, device OS, and artifact checksum with every verification run.

## Automated Linux And Android Checks

Run from the project root:

```bash
flutter pub get
tool/verify.sh
tool/build_android_debug.sh
```

`tool/verify.sh` checks generated localization, formatting, strict analysis,
unit/widget tests, aggregate line coverage, and runtime configuration. The
Android script produces:

- `build/app/outputs/flutter-apk/app-debug.apk`
- `build/app/outputs/flutter-apk/app-debug.apk.sha256`

The GitHub Actions workflow runs the same commands and uploads both coverage
and Android artifacts. It does not prove Android installation, device flows,
iOS behavior, integration coverage, or release acceptance.

## Install And Launch

Install the Android artifact on an attached development device:

```bash
adb devices
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell monkey -p com.jellyfinpicker.jellyfin_picker 1
```

On macOS, build the iOS simulator application:

```bash
flutter build ios --debug --simulator
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
xcrun simctl launch booted com.jellyfinpicker.jellyfinPicker
```

Use Xcode with a development team to produce and install a signed device build.
Archive the build log, artifact checksum, installation result, and first-launch
screenshot. Do not mark iOS verified from project configuration or a Linux run.

## P0 Device Matrix

Run every PRD P0 journey on Android and iOS. Capture a screen recording and a
timestamped result log covering:

- HTTPS connection, authentication, secure restore, logout, and reconnect.
- Rejected public HTTP, confirmed private-LAN HTTP, and rejected invalid TLS.
- Catalog paging, combined filters, loading, empty, partial, and error states.
- Grid, swipe, and shuffle/reveal mode switching with shared session state.
- Like, reject, favorite add/remove, and watched-state non-mutation.
- Local state restart, named presets, recent picks, dismissals, and clear data.
- Missing optional Jellyfin fields and unsupported required capabilities.

Record failures as failures. A source inspection or widget test is supporting
evidence, not a substitute for these device journeys.

## Accessibility Evidence

For both platforms, retain screenshots and an accessibility hierarchy for the
smallest and largest supported phone sizes. Exercise portrait and landscape,
largest accessibility text, high contrast, and reduced motion. Verify semantic
labels, focus order, readable contrast, safe areas, and minimum touch targets.

## 2,000-Candidate Evidence

Use a deterministic fixture or test server that logs every request and returns
bounded pages. In a profile build, record:

- Time to the first usable page and every requested `StartIndex`/`Limit`.
- A scroll from the first page through later pages and back without gaps.
- Repeated swipe decisions, mode switches, and shuffle reveals.
- Frame timing and memory from Flutter DevTools during those interactions.
- A recording showing that interaction begins before all 2,000 items arrive.

Archive the fixture definition, server request log, DevTools timeline, memory
snapshot, and recording. Passing data-layer tests alone does not satisfy the UI
responsiveness requirement.

## Privacy And Network Evidence

Configure the device to use a trusted inspection proxy and clear its capture.
Exercise login, restore, catalog and image paging, every discovery mode,
persistence restart, favorite mutation, logout, and primary error paths. Export
the raw capture as HAR or the proxy-native format, then create a host summary.

The capture passes only when every remote request targets the configured
Jellyfin origin and no analytics, crash, credential, or discovery-history
traffic targets another service. Repeat the capture on Android and iOS. Redact
credentials and access tokens from shared evidence without removing host,
method, path, status, or timing fields.

Static dependency and source scans can support this result but cannot replace
the packet capture. Private-LAN HTTP must be tested only on an isolated test
network because its traffic is intentionally unencrypted after confirmation.

## Evidence Checklist

- Quality-gate log and `coverage/lcov.info`.
- Android and iOS artifacts, checksums, install logs, and launch screenshots.
- P0 result matrix and screen recordings for both platforms.
- Accessibility screenshots and hierarchies for both platforms.
- Exact Flutter, Jellyfin, device, and OS compatibility matrix.
- 2,000-item fixture, request log, performance timeline, and recording.
- Android and iOS traffic captures plus redacted host summaries.

Keep TASK-20.6 open until each acceptance criterion is backed by these fresh
artifacts. Never infer a device, iOS, performance, or privacy pass from CI.
