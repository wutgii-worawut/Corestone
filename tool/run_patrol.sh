#!/usr/bin/env bash
# Runs the Patrol suite on one Android device against the mock API.
# Usage: ANDROID_SERIAL=emulator-5554 tool/run_patrol.sh [integration_test/app_test.dart]
# Needs patrol_cli (`fvm dart pub global activate patrol_cli`) and a booted
# emulator. Uses the fvm-pinned SDK in .fvm/flutter_sdk directly, because the
# `fvm` wrapper prints text that breaks patrol_cli's `flutter --version
# --machine` parse; FLUTTER overrides it. patrol_cli runs through the same
# SDK's dart, since a `patrol` shim built for another Dart SDK cannot load.
set -euo pipefail

target="${1:-integration_test/app_test.dart}"
: "${ANDROID_SERIAL:?set ANDROID_SERIAL to the device to test on}"
export ANDROID_SERIAL
if [ -z "${FLUTTER:-}" ]; then
  FLUTTER=flutter
  if [ -d .fvm/flutter_sdk ]; then
    if [ "${OS:-}" = Windows_NT ]; then
      FLUTTER="$(cd .fvm/flutter_sdk && pwd -W)/bin/flutter.bat"
    else
      FLUTTER="$(cd .fvm/flutter_sdk && pwd -P)/bin/flutter"
    fi
  fi
fi
export PATROL_FLUTTER_COMMAND="$FLUTTER"
dart="${FLUTTER%flutter*}dart${FLUTTER##*flutter}"
log="$(mktemp)"

$dart run tool/mock_api/server.dart >"$log" 2>&1 &
server=$!
# The quit call reaches the server behind a wrapper such as fvm.bat, which
# kill alone may leave running on Windows.
stop() {
  curl -s -o /dev/null http://localhost:8080/__mock/quit || true
  kill "$server" 2>/dev/null || true
  rm -f "$log"
}
trap stop EXIT
for _ in $(seq 1 60); do
  grep -q "Mock API listening" "$log" && break
  kill -0 "$server" 2>/dev/null || { cat "$log" >&2; exit 1; }
  sleep 1
done
grep -q "Mock API listening" "$log" || { echo "mock API did not start" >&2; exit 1; }

start=$SECONDS
$dart pub global run patrol_cli:main test --target "$target" --flavor dev \
  --dart-define-from-file=config/dev.json --device "$ANDROID_SERIAL"
echo "patrol: passed in $((SECONDS - start)) s"
