#!/usr/bin/env bash
#
# Runs the integration suite one file at a time.
#
# `flutter test integration_test -d <device>` starts a fresh app instance per
# file; on desktop those instances race for the same window and debug
# connection ("Error waiting for a debug connection"). Running each file in its
# own invocation is the reliable way to do it, and it also isolates the app
# state each file seeds into SharedPreferences.
#
# Usage:
#   scripts/run_integration_tests.sh [device] [files...]
#
#   scripts/run_integration_tests.sh                      # all files, on linux
#   scripts/run_integration_tests.sh linux                # same, explicit
#   scripts/run_integration_tests.sh emulator-5554        # on an Android device
#   scripts/run_integration_tests.sh linux integration_test/feature_flag_test.dart
#
# Each file goes through tool/test_runner.dart, which keeps the app's logs out
# of the console (they are shown for failing tests only) and writes a JUnit
# report per file to build/test-results/integration-<file>.xml.
#
# Environment:
#   FLUTTER  command used to invoke Flutter (default: flutter; set to
#            "fvm flutter" when using FVM; read by tool/test_runner.dart)
set -uo pipefail

DEVICE="${1:-linux}"
shift || true

if [ "$#" -gt 0 ]; then
  FILES=("$@")
else
  # Helpers are shared code, not a suite; only *_test.dart files run.
  mapfile -t FILES < <(find integration_test -maxdepth 1 -name '*_test.dart' | sort)
fi

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "No integration test files found." >&2
  exit 1
fi

echo "Running ${#FILES[@]} integration test file(s) on device '$DEVICE'"

failed=()
for file in "${FILES[@]}"; do
  echo ""
  echo "=== $file ==="
  report="build/test-results/integration-$(basename "$file" .dart).xml"
  if ! dart tool/test_runner.dart --junit "$report" -- "$file" -d "$DEVICE"; then
    failed+=("$file")
  fi
done

echo ""
if [ "${#failed[@]}" -gt 0 ]; then
  echo "FAILED (${#failed[@]}/${#FILES[@]}):"
  printf '  %s\n' "${failed[@]}"
  exit 1
fi

echo "All ${#FILES[@]} integration test file(s) passed."
