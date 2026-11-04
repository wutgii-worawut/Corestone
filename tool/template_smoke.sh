#!/bin/sh
# The template done check: renames a copy of this checkout to acme_app, then
# analyzes, tests and builds it for Android. Exits non-zero on any failure.
# Usage: tool/template_smoke.sh
# The copy is HEAD plus uncommitted edits to tracked files; untracked files
# are left out. iOS is not built. Uses the fvm-pinned SDK in .fvm/flutter_sdk
# as tool/run_patrol.sh does; FLUTTER overrides it.
set -u

repo="$(cd "$(dirname "$0")/.." && pwd)"
if [ -z "${FLUTTER:-}" ]; then
  FLUTTER=flutter
  if [ -d "$repo/.fvm/flutter_sdk" ]; then
    if [ "${OS:-}" = Windows_NT ]; then
      FLUTTER="$(cd "$repo/.fvm/flutter_sdk" && pwd -W)/bin/flutter.bat"
    else
      FLUTTER="$(cd "$repo/.fvm/flutter_sdk" && pwd -P)/bin/flutter"
    fi
  fi
fi
dart="${FLUTTER%flutter*}dart${FLUTTER##*flutter}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
app="$tmp/acme_app"
ref="$(git -C "$repo" stash create 2>/dev/null)"
ref="${ref:-$(git -C "$repo" rev-parse HEAD)}"

summary=""
failed=""
total_start=$(date +%s)

# step <name> <command...>: runs the command in the copy unless a step failed.
step() {
  name="$1"
  shift
  if [ -n "$failed" ]; then
    summary="$summary
SKIP  $name"
    return
  fi
  start=$(date +%s)
  if (cd "$app" && "$@") >"$tmp/step.log" 2>&1; then
    result=PASS
  else
    result=FAIL
    failed="$name"
    echo "---- $name failed; last 40 lines:" >&2
    tail -n 40 "$tmp/step.log" >&2
  fi
  summary="$summary
$result  $name ($(($(date +%s) - start)) s)"
}

# Only the generator, its test, the license files and TEMPLATE.md may still
# name the template.
leftover_identity() {
  found="$(git grep -l -i --untracked -e corestone -e wutstack |
    grep -v -x -e NOTICE -e LICENSE -e TEMPLATE.md \
      -e tool/new_project.dart -e test/tool/new_project_test.dart)"
  [ -z "$found" ] || { echo "template identity left in:"; echo "$found"; return 1; }
}

mkdir "$app"
step "copy $(git -C "$repo" rev-parse --short HEAD)" \
  sh -c "git clone -q --no-checkout '$repo' . && git checkout -q $ref"
step "generate acme_app" "$dart" run tool/new_project.dart \
  --name acme_app --org com.acme --display-name "Acme"
step "no template identity left" leftover_identity
step "pub get" "$FLUTTER" pub get
step "analyze" "$FLUTTER" analyze
step "test" "$FLUTTER" test
step "build apk debug dev" "$FLUTTER" build apk --debug --flavor dev \
  --dart-define-from-file=config/dev.json
step "build apk release prod" "$FLUTTER" build apk --release --flavor prod \
  --dart-define-from-file=config/prod.json

echo "template smoke:$summary"
echo "total $(($(date +%s) - total_start)) s. iOS not built: unverified."
if [ -n "$failed" ]; then
  echo "FAIL at: $failed"
  exit 1
fi
echo PASS
