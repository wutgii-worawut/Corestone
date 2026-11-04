# Hand-off

Start here when you pick up Corestone in a new session. Read this file, then
`spec/decisions.md` and `spec/open-items.md`. Last updated 2026-11-05 at main
`437662a`.

## What this is

Corestone is the company Flutter template for new Android and iOS apps. It
ports the kept parts of SolGuruz Skelter (`D:\my_project\skelter`, Apache-2.0,
read-only reference, never edit it) into a fresh scaffold. Teams create a new
app with `tool/new_project.dart`; see `TEMPLATE.md`.

The 18-PR program in `spec/template-plan.md` is finished. Appendix F there maps
each plan id to its merged PR. The done check, `tool/template_smoke.sh`, passed
on main. iOS has never been built.

## How to start the next session

Open Claude Code in `D:\my_project\Corestone` and paste one of these. The
first line makes the agent load this hand-off before it touches anything.

Pick up work from the open items:

```
/pstack:poteto-mode อ่าน hand-off/README.md, spec/decisions.md และ spec/open-items.md ก่อน
แล้วทำ <ชื่อเรื่องจาก open-items> เป็น PR เดียวจาก main ตามกฎใน decisions.md
done คือ <สิ่งที่ต้องเห็น เช่น analyze/test ผ่าน และ lane บน Pixel_10_Pro>
```

Only get a status report, change nothing:

```
/pstack:poteto-mode อ่าน hand-off/README.md และ spec/open-items.md แล้วสรุปสถานะ
กับสิ่งที่ควรทำต่อ ยังไม่ต้องแก้โค้ด
```

Start a new app from the template (in the new app's repo, not here):

```
อ่าน TEMPLATE.md แล้วรัน tool/new_project.dart --name <name> --org <org> --display-name "<Name>"
ตรวจด้วย fvm flutter analyze, fvm flutter test และ build apk flavor dev
```

The OpenViking plugin also recalls the notes in
`viking://~/resources/Corestone/notes/` on its own; the files above stay the
source of truth.

## Ground rules from the operator

The full list is in `spec/decisions.md`. The ones that bite:

- The operator merges every PR. Open the PR and stop. Never merge, force-push
  or change a PR base.
- GitHub CI is disabled on purpose. Do not enable or dispatch any workflow
  unless the operator asks. Verify locally.
- Use the Pixel_10_Pro emulator. Do not touch Pixel_5. Never guess a device PIN
  or fingerprint, and stop after one failed device-auth attempt.
- Do not paste through the Windows clipboard in lanes.
- Report what you did not verify, especially iOS.

## Machine facts (Windows)

- Flutter 3.47.9 through fvm. In PowerShell use `fvm flutter ...`. In Git Bash,
  scripts source `tool/sdk.sh`, which finds the SDK that `.fvmrc` pins in the
  fvm cache. The `dart` on PATH is 3.9.0 and is too old.
- `fvm.bat` prints pub output that breaks patrol_cli, so `tool/run_patrol.sh`
  calls the pinned SDK directly.
- Start the mock API with `fvm dart tool/mock_api/server.dart`. `dart run`
  fails a native-assets check here. Stop it with `curl localhost:8080/__mock/quit`.
- CI-style goldens must come from Linux. `tool/update_goldens.sh` runs them in
  WSL Ubuntu, where Flutter 3.47.9 lives at `~/flutter-3.47.9`.
- `android/gradle.properties` has `kotlin.incremental=false` because the pub
  cache (C:) and the project (D:) are on different drives. See open items.
- Git uses CRLF on checkout, and `.gitattributes` keeps `*.sh` as LF.

## How to verify a change

| Check | Command |
|---|---|
| Static | `fvm flutter analyze` |
| Unit and widget | `fvm flutter test` |
| Goldens | `tool/update_goldens.sh verify` (Git Bash) |
| On a device | `ANDROID_SERIAL=<serial> tool/lanes/android.sh launch dev`, then `shot <name>.png` |
| End to end | `ANDROID_SERIAL=<serial> tool/run_patrol.sh` (7 cases, about 4 min) |
| Template done check | `tool/template_smoke.sh` (about 2 min) |

## Where things live

| Area | Path |
|---|---|
| Startup and DI | `lib/bootstrap.dart`, `lib/core/di/injection.dart` |
| Config and flavors | `lib/core/config/app_config.dart`, `config/*.json` |
| Routing | `lib/core/router/` (AutoRoute; regenerate with `fvm dart run build_runner build -d`) |
| Network | `lib/core/network/` (ApiClient, error mapper, pinning, auth interceptor) |
| Errors | `lib/core/errors/failure.dart` (sealed), `lib/features/system/system_pages.dart` (routing table) |
| Session | `lib/features/auth/` (SessionCubit, TokenStore, login) |
| PIN and biometric | `lib/features/app_lock/` |
| Push | `lib/core/push/push_service.dart` |
| Deep links | `lib/core/deep_link/` |
| Theme, l10n, layout | `lib/core/theme/`, `lib/l10n/`, `lib/core/layout/` |
| Tools | `tool/` (generator, mock API, lanes, Patrol, goldens, smoke, Firebase config) |

## Notes kept elsewhere

- OpenViking: `viking://~/resources/Corestone/notes/` has the program status
  (`template-plan-status.md`) and one design note per heavy PR (`cs-07-session.md`,
  `cs-08-login.md`, `cs-09-pin.md`, `cs-10-biometric.md`, `cs-12-system-screens.md`).
- Claude Code project memory has the operator's rules on emulators and CI.

## Good next steps

Pick from `spec/open-items.md`. The highest value:

1. Build and run iOS once, on a Mac or with a one-off `build.yml` run the
   operator approves.
2. Create a Firebase project and prove push plus App Distribution.
3. Decide the Android 7 and 8 theme question and `kotlin.incremental`.
4. Tick "Template repository" in the GitHub settings.

## Test APK for a real phone

Build an APK that runs with no backend (demo mode signs in with any
well-formed email and password; push and deep links stay off):

```sh
fvm flutter build apk --release --flavor dev --dart-define-from-file=config/dev.json --dart-define=DEMO_MODE=true
```

The output is `build/app/outputs/flutter-apk/app-dev-release.apk`, signed with
the debug key because `android/key.properties` is absent. The plain dev build
points at `http://10.0.2.2:8080`, which only works on an emulator.
