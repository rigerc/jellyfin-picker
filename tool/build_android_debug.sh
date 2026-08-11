#!/bin/bash
# Produce a checksummed Android development APK.

set -euo pipefail

readonly APK_PATH='build/app/outputs/flutter-apk/app-debug.apk'

flutter build apk --debug
sha256sum "${APK_PATH}" | tee "${APK_PATH}.sha256"
