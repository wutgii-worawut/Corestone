# Sourced by tool scripts: sets FLUTTER to the Flutter that .fvmrc pins.
# Order: $FLUTTER if set, .fvm/flutter_sdk, then the fvm cache
# (${FVM_CACHE_PATH:-$HOME/fvm}/versions/<version>). A fresh clone has no
# .fvm/flutter_sdk link, and the dart/flutter on PATH may be a different
# version, so a missing pinned SDK is an error, never a silent fallback.
# Expects $repo to be the repo root.

if [ -z "${FLUTTER:-}" ]; then
  pinned="$(sed -n 's/.*"flutter": *"\([^"]*\)".*/\1/p' "$repo/.fvmrc")"
  sdk=""
  for candidate in "$repo/.fvm/flutter_sdk" \
    "${FVM_CACHE_PATH:-$HOME/fvm}/versions/$pinned"; do
    stamp="$candidate/bin/cache/flutter.version.json"
    if [ -n "$pinned" ] && [ -f "$stamp" ] &&
      grep -q "\"frameworkVersion\": *\"$pinned\"" "$stamp"; then
      sdk="$candidate"
      break
    fi
  done
  if [ -z "$sdk" ]; then
    echo "Flutter $pinned from .fvmrc is not installed; run: fvm install" >&2
    exit 2
  fi
  if [ "${OS:-}" = Windows_NT ]; then
    FLUTTER="$(cd "$sdk" && pwd -W)/bin/flutter.bat"
  else
    FLUTTER="$(cd "$sdk" && pwd -P)/bin/flutter"
  fi
fi
