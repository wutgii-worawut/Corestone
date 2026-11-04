#!/usr/bin/env bash
# Regenerates golden files.
# Usage:
#   tool/update_goldens.sh          platform goldens here, then CI goldens in WSL
#   tool/update_goldens.sh local    platform goldens only
#   tool/update_goldens.sh ci       CI goldens only
#   tool/update_goldens.sh verify   run the golden tests in WSL as CI does
# CI goldens must come from Linux to match the ubuntu runner, so on Windows they
# run inside WSL Ubuntu. Override WSL_FLUTTER to point at another Linux Flutter.
set -euo pipefail

mode="${1:-all}"
repo="$(cd "$(dirname "$0")/.." && pwd)"
wsl_flutter="${WSL_FLUTTER:-~/flutter-3.47.9/bin/flutter}"

in_linux() {
  local cmd="CI=true $wsl_flutter pub get >/dev/null && CI=true $wsl_flutter test --tags golden $*"
  if [ "$(uname -s)" = Linux ]; then
    (cd "$repo" && bash -c "$cmd")
  else
    local wsl_repo
    wsl_repo="$(wsl -e wslpath -a "$(cygpath -m "$repo")")"
    local status=0
    wsl -e bash -lc "cd '$wsl_repo' && $cmd" || status=$?
    # The Linux pub get rewrote .dart_tool with Linux paths; restore Windows ones.
    (cd "$repo" && ${FLUTTER:-fvm flutter} pub get >/dev/null)
    return "$status"
  fi
}

local_goldens() {
  (cd "$repo" && ${FLUTTER:-fvm flutter} test --update-goldens --tags golden)
}

case "$mode" in
  all) local_goldens; in_linux --update-goldens ;;
  local) local_goldens ;;
  ci) in_linux --update-goldens ;;
  verify) in_linux ;;
  *) echo "unknown mode $mode" >&2; exit 2 ;;
esac
