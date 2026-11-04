#!/usr/bin/env bash
# Writes each flavor's Firebase config files from base64 environment values,
# for CI and new machines. The files are gitignored; never commit them.
# Usage: tool/firebase_config.sh [flavor ...]   (default: dev stage prod)
#   GOOGLE_SERVICES_JSON_<FLAVOR>       -> android/app/src/<flavor>/google-services.json
#   GOOGLE_SERVICE_INFO_PLIST_<FLAVOR>  -> ios/config/<flavor>/GoogleService-Info.plist
# A flavor with no value keeps building, with push off on that platform.
set -euo pipefail
cd "$(dirname "$0")/.."

flavors=("$@")
[ ${#flavors[@]} -eq 0 ] && flavors=(dev stage prod)

write() {
  local name="$1" dest="$2"
  local value="${!name:-}"
  if [ -z "$value" ]; then
    echo "skip $dest ($name not set)"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  printf '%s' "$value" | base64 --decode > "$dest"
  echo "wrote $dest"
}

for flavor in "${flavors[@]}"; do
  upper="$(echo "$flavor" | tr '[:lower:]' '[:upper:]')"
  write "GOOGLE_SERVICES_JSON_$upper" "android/app/src/$flavor/google-services.json"
  write "GOOGLE_SERVICE_INFO_PLIST_$upper" "ios/config/$flavor/GoogleService-Info.plist"
done
