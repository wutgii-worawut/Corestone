#!/usr/bin/env bash
# Drives the app on a running Android emulator for verification lanes.
# Usage:
#   tool/lanes/android.sh launch [flavor]   (default dev) build, install, launch, wait for first frame
#   tool/lanes/android.sh shot <file.png>   save a screenshot
#   tool/lanes/android.sh log               dump flutter logcat lines
set -euo pipefail

cmd="${1:?usage: android.sh launch|shot|log}"
flavor="${2:-dev}"
out_dir="${LANE_OUT:-/tmp/lanes}"
mkdir -p "$out_dir"

app_id() {
  local base
  base="$(sed -n 's/.*applicationId = "\(.*\)".*/\1/p' android/app/build.gradle.kts | head -1)"
  case "$flavor" in
    ""|prod) echo "$base" ;;
    *) echo "$base.$flavor" ;;
  esac
}

adb get-state >/dev/null 2>&1 || { echo "no emulator attached" >&2; exit 1; }

case "$cmd" in
  launch)
    args=(build apk --debug)
    [ -n "$flavor" ] && args+=(--flavor "$flavor" "--dart-define-from-file=config/$flavor.json")
    ${FLUTTER:-fvm flutter} "${args[@]}"
    apk="build/app/outputs/flutter-apk/app${flavor:+-$flavor}-debug.apk"
    adb install -r "$apk" >/dev/null
    for _ in $(seq 1 30); do
      adb shell cmd package resolve-activity --brief "$(app_id)" | grep -q MainActivity && break
      sleep 1
    done
    adb shell input keyevent KEYCODE_WAKEUP
    adb shell wm dismiss-keyguard
    adb logcat -c
    namespace="$(sed -n 's/.*namespace = "\(.*\)".*/\1/p' android/app/build.gradle.kts | head -1)"
    result="$(adb shell am start -W -n "$(app_id)/$namespace.MainActivity")"
    echo "$result" | grep -q "Status: ok" || { echo "$result" >&2; exit 1; }
    echo "launched $(app_id) $(echo "$result" | grep TotalTime)"
    ;;
  shot)
    file="${2:?usage: android.sh shot <file.png>}"
    adb exec-out screencap -p > "$out_dir/$file"
    echo "$out_dir/$file"
    ;;
  log)
    adb logcat -d -s flutter
    ;;
  *)
    echo "unknown command $cmd" >&2
    exit 2
    ;;
esac
