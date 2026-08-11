#!/bin/bash
# Run the foundation quality gates.

set -euo pipefail

flutter gen-l10n
dart format . --output=none --line-length 80 --set-exit-if-changed
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage
tool/coverage_gate.sh coverage/lcov.info
flutter test \
  --dart-define=APP_ENVIRONMENT=staging \
  --dart-define=JELLYFIN_SERVER_URL=https://example.test \
  --dart-define=ENABLE_DIAGNOSTICS=true \
  tool/custom_environment_test.dart
