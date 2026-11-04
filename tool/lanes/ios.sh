#!/usr/bin/env bash
# Drives the app on a booted iOS simulator for verification lanes. macOS only.
# Usage:
#   tool/lanes/ios.sh launch [flavor]   build for the simulator, install, launch
#   tool/lanes/ios.sh shot <file.png>   save a screenshot
#   tool/lanes/ios.sh log               stream the last minute of app logs
set -euo pipefail

cmd="${1:?usage: ios.sh launch|shot|log}"
flavor="${2:-}"
out_dir="${LANE_OUT:-/tmp/lanes}"
mkdir -p "$out_dir"

bundle_id() {
  plutil -extract CFBundleIdentifier raw "$(app_path)/Info.plist"
}

app_path() {
  ls -dt build/ios/iphonesimulator/*.app | head -1
}

xcrun simctl list devices booted | grep -q Booted || { echo "no booted simulator" >&2; exit 1; }

case "$cmd" in
  launch)
    args=(build ios --simulator --debug)
    [ -n "$flavor" ] && args+=(--flavor "$flavor" "--dart-define-from-file=config/$flavor.json")
    ${FLUTTER:-flutter} "${args[@]}"
    xcrun simctl install booted "$(app_path)"
    xcrun simctl launch booted "$(bundle_id)"
    sleep 5
    echo "launched $(bundle_id)"
    ;;
  shot)
    file="${2:?usage: ios.sh shot <file.png>}"
    xcrun simctl io booted screenshot "$out_dir/$file"
    echo "$out_dir/$file"
    ;;
  log)
    xcrun simctl spawn booted log show --last 1m --predicate 'process == "Runner"'
    ;;
  *)
    echo "unknown command $cmd" >&2
    exit 2
    ;;
esac
