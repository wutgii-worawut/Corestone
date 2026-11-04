# Corestone template plan

Corestone becomes the company Flutter template, built by porting the kept parts of SolGuruz Skelter into the fresh Corestone scaffold.
It is for every new mobile project, which starts from a generator instead of copying an old app.
The rule is that nothing from a REMOVE row enters the repo, and every PR leaves a building app on Android and iOS.
The PRs are CS-00 to CS-17, ordered by the dependency graph below.
The program is done when `template-smoke` builds a renamed project for Android and iOS.

## How to read this

One box is one unit of work. Every box names the evidence that checks it. A nested box is a sub-step of the box above it. Check a box only when its evidence exists, a file, a log line, a screenshot, a test run, or a SHA. The body is a how-to. The appendices explain and record.

The program runs `pstack/skills/poteto-mode/playbooks/autopilot-stack.md`. The operator lands every PR. Every PR stops at merge-ready.

Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

## Program checklist

### Arm the program

- [ ] State the protocol and this plan to the operator, then stop. Start execution only on the operator's explicit go.
- [ ] Read these at program start. Re-read them at every tick.
  - [ ] `pstack/skills/poteto-mode/playbooks/autopilot-stack.md` from the installed plugin.
  - [ ] `pstack/skills/swarm/SKILL.md` from the installed plugin.
  - [ ] `git show origin/main:tool/lanes/android.sh` and `git show origin/main:tool/lanes/ios.sh` as the control skill.
  - [ ] `pstack/skills/poteto-mode/playbooks/opening-a-pr.md` from the installed plugin.
  - [ ] `git show origin/main:spec/template-plan.md` for this plan.
- [ ] On the operator's go, arm the audit tick as `/loop 1h` with the tick prompt below. Never leave the cadence to memory.
- [ ] Use this tick prompt, verbatim. "Re-read the execution playbook from trunk. Audit the operation against it and fix drift in this tick. Probe every active lane and judge progress by side effects only. Stand down a stuck lane and dispatch its replacement now. Then post a short status message to the operator in chat only when the audit found a tracked change that no earlier status message reported, such as a PR opened, a code-ready head, a round launched or closed, a verdict, a merge, a stuck agent and the action taken, a blocker added or cleared, or a decision only the operator can make. Name every such change and nothing else. Do not repeat a table, the merged list, or an unchanged blocker. If the audit found none, end the turn with no reply text. Either way, log this tick's row in your decision trail. The row names the items reported, or none."
- [ ] On the operator's hold or stand-down, send every owner a zero-writes order at once.

### Spawn owners

- [ ] Spawn one owner per PR with the full lifecycle the execution playbook names.
- [ ] Follow this dependency graph. Base dependent work on the parent branch, because the execution playbook stacks.
  - [ ] CS-00, then CS-01, then CS-02 run in order from `main`.
  - [ ] CS-03, CS-05, CS-06 and CS-14 are independent after CS-02.
  - [ ] CS-04 after CS-03. CS-07 and CS-12 after CS-06. CS-11 after CS-07.
  - [ ] CS-08 after CS-07 and CS-04. CS-09 after CS-08. CS-10 after CS-09.
  - [ ] CS-16 after CS-10. CS-17 after CS-08 and CS-12.
  - [ ] CS-13 after CS-11, CS-16 and CS-17. CS-15 after CS-13 and CS-14.
- [ ] Hold the file boundaries. Only CS-01, CS-10, CS-11, CS-13, CS-15 and CS-16 touch `android/` or `ios/`. Only CS-00, CS-13 and CS-15 touch `.github/`. CS-14 touches only `tool/`, `test/tool/` and `TEMPLATE.md`.
- [ ] Hold the review gate. CS-02, CS-03, CS-04, CS-05, CS-08, CS-09, CS-10, CS-11, CS-12, CS-16, CS-17 change an interaction. They wait for the operator's review in chat with screenshots and a video before merge.

### PR mechanics, for every PR

- [ ] Resolve the forge once. Default to `gh`; if `command -v origin` succeeds and Origin can resolve the repository, use `origin pr` for every PR operation. Record any fallback to `gh`. Never require `gt`.
- [ ] Open the PR ready, never draft, per **Opening a PR**. Use `gh pr create --base <base-branch>`. A stack child targets its parent branch.
- [ ] Run `fvm flutter analyze` and `fvm flutter test` once before the PR-facing push. Push with hooks on.
- [ ] Run `/deslop` before each commit and `/no-comments` before review. `/deslop` ships in `cursor-team-kit`, so in Claude Code skip it with a one-line note.
- [ ] Triage every Bugbot and security-reviewer comment per `../references/bugbot-triage.md`. Bugbot is Cursor-only, so in Claude Code this applies to human and CI review comments.
- [ ] Rebase onto current trunk before the code-ready report and babysit. Keep that merge base in fix rounds. Rebase again only at merge prep, on a `git merge-tree` conflict with trunk, on a CI failure that comes from a change on trunk, or when a known concurrent change to the same files lands.

### Verdict and merge, for every PR

- [ ] A full swarm runs once, at the code-ready head. Another full swarm runs only for new behavior, a redesign, or a large new diff. A rebase, a merge-conflict resolution, or a minor fix gets a single verifier at the new head, and a wording-only change gets none. Run each full swarm per `pstack/skills/swarm/SKILL.md`. One gates lane. The ten live lanes from the PR's **Verify, live** block. The perf lane from its **Verify, perf** block. Two or more audit lanes, each with its own focus, that read the diff and the receipts and distrust the PR body. The root audits the receipts in the merge-ready report before the verdict.
- [ ] Judge every finding by the execution playbook's blocking rule. The verdict is clean when none blocks. A failure on trunk behavior in a lane marked `Regression lane against trunk.` is recorded against trunk and does not block the PR. A new head gets a fresh verdict, except for results that stay valid under the patch-id rule in `playbooks/shipping.md`.
- [ ] The root appends each verified PR to the stack and stops at merge-ready. The operator lands the stack bottom-up. A rebase that keeps the patch-id keeps the verdict, per `playbooks/shipping.md`.

### Boot recipe, for every live lane

Each live lane runs in its own git worktree at the PR head. Android lanes drive an emulator on the operator's machine. iOS lanes run on the GitHub macOS runner, because the operator's machine is Windows. Drive through `tool/lanes/android.sh` and `tool/lanes/ios.sh`, since the repo has no simulator-driving skill.

- [ ] `git fetch origin <head-branch> && git checkout <head SHA>`.
- [ ] Start `dart run tool/mock_api/server.dart` once CS-06 exists. Boot the emulator or simulator and wait for `sys.boot_completed` or `simctl bootstatus`.
- [ ] Deliver input only through `adb shell input`, `adb emu` and `xcrun simctl`. Read logs with `adb logcat -s flutter` and `xcrun simctl spawn booted log stream` only.
- [ ] Save every screenshot to `/tmp/swarm-<pr-id>/worker-<n>/<slug>.png` and return the paths with the report.

## Add license notice, repo hygiene and the CI skeleton (CS-00)

**Depends on.** None.

**Files.**

- [ ] Create `NOTICE` crediting SolGuruz Skelter under Apache-2.0.
- [ ] Create `LICENSE` with the Apache-2.0 text.
- [ ] Edit `.gitignore` to exclude `google-services.json`, `GoogleService-Info.plist`, `lib/firebase_options_*.dart` and `config/*.local.json`.
- [ ] Edit `analysis_options.yaml` with the lint set ported from `skelter/analysis_options.yaml`.
- [ ] Create `.github/workflows/ci.yml`.
- [ ] Create `tool/lanes/android.sh` and `tool/lanes/ios.sh`.
- [ ] Edit `README.md`.

**Build.**

- [ ] `ci.yml` runs `analyze`, `test`, `build-android` on ubuntu and `build-ios` with `flutter build ios --no-codesign` on macos, every job reading Flutter from `.fvmrc` through `flutter-version-file`.
- [ ] `tool/lanes/android.sh` installs a flavor, launches it, waits for the first frame and saves `adb exec-out screencap`. `tool/lanes/ios.sh` does the same with `xcrun simctl`.

**You see.**

- [ ] The Actions run shows four green jobs and the log prints `Flutter 3.47.9`.

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] `test/widget_test.dart` still passes. Run `fvm flutter analyze && fvm flutter test`.

**Verify, live.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked. Ten lanes on `inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. Launch the counter scaffold at trunk and head with `tool/lanes/android.sh`. Save `counter.png`. Pass when both show the same counter screen.
- [ ] Lane 2. Read the `build-ios` job log. Save `ios-job.png`. Pass when it ends with `Built build/ios/iphoneos/Runner.app`.
- [ ] Lane 3. Read the `analyze` job log. Save `analyze-job.png`. Pass when it prints `No issues found`.
- [ ] Lane 4. Open `NOTICE` in the PR file view. Save `notice.png`. Pass when it names SolGuruz Skelter and Apache-2.0.
- [ ] Lane 5. Boot the dev flavor on the Android emulator from a cold start with `tool/lanes/android.sh launch dev`. Save `android-cold-start.png`. Pass when the first route renders and logcat shows no `E/flutter` line.
- [ ] Lane 6. Boot the dev flavor on the iOS simulator on the macOS runner with `tool/lanes/ios.sh launch dev`. Save `ios-cold-start.png`. Pass when the first route renders and the simulator log shows no Flutter error.
- [ ] Lane 7. Background the app for 40 seconds on Android, then resume. Save `resume.png`. Pass when the app returns to the expected screen with no crash.
- [ ] Lane 8. Install the prod flavor release build on the Android emulator. Save `prod-release.png`. Pass when it starts with the prod app name and no debug banner.
- [ ] Lane 9. Rotate the Android emulator to landscape on the first screen. Save `landscape.png`. Pass when no overflow stripe or exception appears.
- [ ] Lane 10. Install dev, stage and prod side by side on the Android emulator. Save `side-by-side.png`. Pass when the launcher shows three icons with three names.

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] Metric. Cold start time to first frame, `timeToFirstFrameMicros`, for the dev flavor in profile mode on the Android emulator.
- [ ] Probe. Run `flutter run --profile --flavor dev --trace-startup` five times each at trunk and at the head, interleaved, and read `build/start_up_info.json`.
- [ ] Baseline. Record the trunk median first.
- [ ] Rule. Fail when the head median exceeds the trunk median by more than 15 percent.

**Review gate.** None. CS-00 is not review-gated.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] Review comment triage done.
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] The root appends it to the stack, and the operator lands it bottom-up.

## Add dev, stage and prod flavors on both platforms (CS-01)

**Depends on.** CS-00.

**Files.**

- [ ] Edit `android/app/build.gradle.kts`.
- [ ] Edit `ios/Runner.xcodeproj/project.pbxproj`.
- [ ] Create `ios/Flutter/Debug-dev.xcconfig` and the other eight flavor configs.
- [ ] Create `ios/Runner.xcodeproj/xcshareddata/xcschemes/dev.xcscheme`, `stage.xcscheme`, `prod.xcscheme`.
- [ ] Edit `ios/Podfile` so all nine configs map to debug or release.
- [ ] Create `config/dev.json`, `config/stage.json`, `config/prod.json`.
- [ ] Create `lib/core/config/app_config.dart`.

**Build.**

- [ ] `productFlavors` dev, stage and prod with `applicationIdSuffix` `.dev` and `.stage` and an `app_name` resValue per flavor.
- [ ] `AppConfig` reads `APP_FLAVOR`, `API_BASE_URL` and `CERT_SHA256` from `--dart-define-from-file`, replacing `flutter_dotenv` and the bundled `.env` asset.

**You see.**

- [ ] The launcher shows Corestone Dev, Corestone Stage and Corestone.

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] `test/core/config/app_config_test.dart` covers each flavor and the missing-key error. Run `fvm flutter test test/core/config`.

**Verify, live.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked. Ten lanes on `inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. Trunk has no flavors. Record that, then launch each flavor at the head. Save `flavors.png`. Pass when each build starts and shows its flavor name.
- [ ] Lane 2. Run `flutter build ios --flavor stage --no-codesign` on the macOS runner. Save `ios-stage.png`. Pass when the build succeeds with bundle id `com.wutstack.corestone.stage`.
- [ ] Lane 3. Build with a config file missing `API_BASE_URL`. Save `missing-key.png`. Pass when startup fails with the named missing key.
- [ ] Lane 4. Boot the dev flavor on the Android emulator from a cold start with `tool/lanes/android.sh launch dev`. Save `android-cold-start.png`. Pass when the first route renders and logcat shows no `E/flutter` line.
- [ ] Lane 5. Boot the dev flavor on the iOS simulator on the macOS runner with `tool/lanes/ios.sh launch dev`. Save `ios-cold-start.png`. Pass when the first route renders and the simulator log shows no Flutter error.
- [ ] Lane 6. Background the app for 40 seconds on Android, then resume. Save `resume.png`. Pass when the app returns to the expected screen with no crash.
- [ ] Lane 7. Install the prod flavor release build on the Android emulator. Save `prod-release.png`. Pass when it starts with the prod app name and no debug banner.
- [ ] Lane 8. Rotate the Android emulator to landscape on the first screen. Save `landscape.png`. Pass when no overflow stripe or exception appears.
- [ ] Lane 9. Install dev, stage and prod side by side on the Android emulator. Save `side-by-side.png`. Pass when the launcher shows three icons with three names.
- [ ] Lane 10. Set the Android font scale to 1.3 with `adb shell settings put system font_scale 1.3` and relaunch. Save `font-scale.png`. Pass when no text clips or overflows.

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] Metric. Cold start time to first frame, `timeToFirstFrameMicros`, for the dev flavor in profile mode on the Android emulator.
- [ ] Probe. Run `flutter run --profile --flavor dev --trace-startup` five times each at trunk and at the head, interleaved, and read `build/start_up_info.json`.
- [ ] Baseline. Record the trunk median first.
- [ ] Rule. Fail when the head median exceeds the trunk median by more than 15 percent.

**Review gate.** None. CS-01 is not review-gated.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] Review comment triage done.
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] The root appends it to the stack, and the operator lands it bottom-up.

## Port the core architecture shell with BLoC, GetIt and AutoRoute (CS-02)

**Depends on.** CS-01.

**Files.**

- [ ] Create `lib/bootstrap.dart`.
- [ ] Create `lib/core/di/injection.dart`.
- [ ] Create `lib/core/router/app_router.dart`.
- [ ] Create `lib/core/errors/failure.dart` and `exceptions.dart` from `skelter/lib/core/errors`.
- [ ] Create `lib/core/usecase/usecase.dart` and `lib/core/typedef.dart`.
- [ ] Create `lib/core/storage/prefs.dart` from `skelter/lib/shared_pref`.
- [ ] Create `lib/features/home/home_shell.dart`.
- [ ] Create `test/flutter_test_config.dart` and `dart_test.yaml`.
- [ ] Edit `pubspec.yaml`.

**Build.**

- [ ] `bootstrap()` runs `runZonedGuarded`, `Prefs.init()` and `configureDependencies()` before `runApp`, so DI never imports `main.dart`.
- [ ] `HomeShell` is an AutoRoute tabs route with a placeholder Home tab and a Settings tab.

**You see.**

- [ ] The app opens on the Home tab and switches to Settings.

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] `test/core/di/injection_test.dart` resolves every registration. `test/core/router/app_router_test.dart` pushes each route. Run `fvm flutter test`.

**Verify, live.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked. Ten lanes on `inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. Trunk shows the counter. Record that, then gate the head opening on the Home tab. Save `home-shell.png`. Pass when the Home tab renders.
- [ ] Lane 2. Tap the Settings tab. Save `settings-tab.png`. Pass when the Settings tab renders and Back exits the app.
- [ ] Lane 3. Throw a test error from a debug menu action. Save `zone-error.png`. Pass when the zone handler logs it and the app keeps running.
- [ ] Lane 4. Boot the dev flavor on the Android emulator from a cold start with `tool/lanes/android.sh launch dev`. Save `android-cold-start.png`. Pass when the first route renders and logcat shows no `E/flutter` line.
- [ ] Lane 5. Boot the dev flavor on the iOS simulator on the macOS runner with `tool/lanes/ios.sh launch dev`. Save `ios-cold-start.png`. Pass when the first route renders and the simulator log shows no Flutter error.
- [ ] Lane 6. Background the app for 40 seconds on Android, then resume. Save `resume.png`. Pass when the app returns to the expected screen with no crash.
- [ ] Lane 7. Install the prod flavor release build on the Android emulator. Save `prod-release.png`. Pass when it starts with the prod app name and no debug banner.
- [ ] Lane 8. Rotate the Android emulator to landscape on the first screen. Save `landscape.png`. Pass when no overflow stripe or exception appears.
- [ ] Lane 9. Install dev, stage and prod side by side on the Android emulator. Save `side-by-side.png`. Pass when the launcher shows three icons with three names.
- [ ] Lane 10. Set the Android font scale to 1.3 with `adb shell settings put system font_scale 1.3` and relaunch. Save `font-scale.png`. Pass when no text clips or overflows.

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] Metric. Cold start time to first frame, `timeToFirstFrameMicros`, for the dev flavor in profile mode on the Android emulator.
- [ ] Probe. Run `flutter run --profile --flavor dev --trace-startup` five times each at trunk and at the head, interleaved, and read `build/start_up_info.json`.
- [ ] Baseline. Record the trunk median first.
- [ ] Rule. Fail when the head median exceeds the trunk median by more than 15 percent.

**Review gate.** The operator reviews before merge.

- [ ] Copy the lane 1 to 4 screenshots into `spec/media/cs-02-review-<slug>.png`.
- [ ] Record a 30 to 60 second video with `adb shell screenrecord`. Save it as `spec/media/cs-02-review.mp4`.
- [ ] Post the screenshots and the video in chat. Stop at merge-ready. Wait for the operator's click.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] Review comment triage done.
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] The root appends it to the stack, and the operator lands it bottom-up.

## Refactor the theme into a Material 3 design system (CS-03)

**Depends on.** CS-02.

**Files.**

- [ ] Create `lib/core/theme/app_colors.dart` as a `ThemeExtension`.
- [ ] Create `lib/core/theme/app_theme.dart`.
- [ ] Create `lib/core/theme/app_text_styles.dart`.
- [ ] Create `lib/core/theme/theme_cubit.dart`.
- [ ] Create `lib/core/widgets/app_button.dart` and `lib/core/widgets/shimmer_box.dart`.
- [ ] Create `lib/features/settings/change_theme_screen.dart`.
- [ ] Create `assets/fonts/Inter/` with the weights mapped correctly.
- [ ] Edit `pubspec.yaml`.

**Build.**

- [ ] `AppTheme.light` and `AppTheme.dark` build a Material 3 `ColorScheme` from one seed plus the `AppColors` extension, so Material widgets pick up brand colors.
- [ ] `ThemeCubit` persists system, light or dark in `Prefs`.

**You see.**

- [ ] Settings then Theme switches light, dark and system live.

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] `test/core/theme/theme_cubit_test.dart` persists the choice. `test/core/widgets/app_button_golden_test.dart` renders every variant in light and dark. Run `fvm flutter test --tags golden`.

**Verify, live.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked. Ten lanes on `inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. Open Settings at trunk and head. Save `settings-theme.png`. Pass when the head adds the Theme row and the rest matches.
- [ ] Lane 2. Switch to dark. Save `dark.png`. Pass when every visible surface uses dark colors.
- [ ] Lane 3. Switch to dark, kill and relaunch. Save `dark-persisted.png`. Pass when the app starts dark.
- [ ] Lane 4. Set the device to dark with the app on system. Save `system-dark.png`. Pass when the app follows the device.
- [ ] Lane 5. Boot the dev flavor on the Android emulator from a cold start with `tool/lanes/android.sh launch dev`. Save `android-cold-start.png`. Pass when the first route renders and logcat shows no `E/flutter` line.
- [ ] Lane 6. Boot the dev flavor on the iOS simulator on the macOS runner with `tool/lanes/ios.sh launch dev`. Save `ios-cold-start.png`. Pass when the first route renders and the simulator log shows no Flutter error.
- [ ] Lane 7. Background the app for 40 seconds on Android, then resume. Save `resume.png`. Pass when the app returns to the expected screen with no crash.
- [ ] Lane 8. Install the prod flavor release build on the Android emulator. Save `prod-release.png`. Pass when it starts with the prod app name and no debug banner.
- [ ] Lane 9. Rotate the Android emulator to landscape on the first screen. Save `landscape.png`. Pass when no overflow stripe or exception appears.
- [ ] Lane 10. Install dev, stage and prod side by side on the Android emulator. Save `side-by-side.png`. Pass when the launcher shows three icons with three names.

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] Metric. Cold start time to first frame, `timeToFirstFrameMicros`, for the dev flavor in profile mode on the Android emulator.
- [ ] Probe. Run `flutter run --profile --flavor dev --trace-startup` five times each at trunk and at the head, interleaved, and read `build/start_up_info.json`.
- [ ] Baseline. Record the trunk median first.
- [ ] Rule. Fail when the head median exceeds the trunk median by more than 15 percent.

**Review gate.** The operator reviews before merge.

- [ ] Copy the lane 1 to 4 screenshots into `spec/media/cs-03-review-<slug>.png`.
- [ ] Record a 30 to 60 second video with `adb shell screenrecord`. Save it as `spec/media/cs-03-review.mp4`.
- [ ] Post the screenshots and the video in chat. Stop at merge-ready. Wait for the operator's click.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] Review comment triage done.
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] The root appends it to the stack, and the operator lands it bottom-up.

## Keep localization and add Thai (CS-04)

**Depends on.** CS-03.

**Files.**

- [ ] Create `l10n.yaml`.
- [ ] Create `lib/l10n/app_en.arb` with only the keys the kept screens use.
- [ ] Create `lib/l10n/app_th.arb`.
- [ ] Create `lib/core/locale/locale_cubit.dart`.
- [ ] Create `assets/fonts/NotoSansThai/`.
- [ ] Edit `lib/features/settings/settings_screen.dart`.

**Build.**

- [ ] `LocaleCubit` persists English, Thai or system and feeds `MaterialApp.router(locale:)`.
- [ ] `AppTextStyles` sets `fontFamilyFallback` to Noto Sans Thai, because Inter has no Thai glyphs.

**You see.**

- [ ] Settings then Language switches every visible string to Thai.

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] `l10n.yaml` sets `untranslated-messages-file` and `test/l10n/untranslated_test.dart` fails when it lists any key. Settings golden in `th`. Run `fvm flutter test`.

**Verify, live.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked. Ten lanes on `inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. Open Settings in English at trunk and head. Save `settings-en.png`. Pass when the English strings match.
- [ ] Lane 2. Switch to Thai. Save `settings-th.png`. Pass when every string is Thai and no glyph renders as a box.
- [ ] Lane 3. Set the device to Thai with the app on system. Save `system-th.png`. Pass when the app follows the device.
- [ ] Lane 4. Switch to Thai, kill and relaunch. Save `th-persisted.png`. Pass when the app starts in Thai.
- [ ] Lane 5. Boot the dev flavor on the Android emulator from a cold start with `tool/lanes/android.sh launch dev`. Save `android-cold-start.png`. Pass when the first route renders and logcat shows no `E/flutter` line.
- [ ] Lane 6. Boot the dev flavor on the iOS simulator on the macOS runner with `tool/lanes/ios.sh launch dev`. Save `ios-cold-start.png`. Pass when the first route renders and the simulator log shows no Flutter error.
- [ ] Lane 7. Background the app for 40 seconds on Android, then resume. Save `resume.png`. Pass when the app returns to the expected screen with no crash.
- [ ] Lane 8. Install the prod flavor release build on the Android emulator. Save `prod-release.png`. Pass when it starts with the prod app name and no debug banner.
- [ ] Lane 9. Rotate the Android emulator to landscape on the first screen. Save `landscape.png`. Pass when no overflow stripe or exception appears.
- [ ] Lane 10. Install dev, stage and prod side by side on the Android emulator. Save `side-by-side.png`. Pass when the launcher shows three icons with three names.

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] Metric. Cold start time to first frame, `timeToFirstFrameMicros`, for the dev flavor in profile mode on the Android emulator.
- [ ] Probe. Run `flutter run --profile --flavor dev --trace-startup` five times each at trunk and at the head, interleaved, and read `build/start_up_info.json`.
- [ ] Baseline. Record the trunk median first.
- [ ] Rule. Fail when the head median exceeds the trunk median by more than 15 percent.

**Review gate.** The operator reviews before merge.

- [ ] Copy the lane 1 to 4 screenshots into `spec/media/cs-04-review-<slug>.png`.
- [ ] Record a 30 to 60 second video with `adb shell screenrecord`. Save it as `spec/media/cs-04-review.mp4`.
- [ ] Post the screenshots and the video in chat. Stop at merge-ready. Wait for the operator's click.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] Review comment triage done.
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] The root appends it to the stack, and the operator lands it bottom-up.

## Replace sizer with breakpoint-based responsive layout (CS-05)

**Depends on.** CS-02.

**Files.**

- [ ] Create `lib/core/layout/breakpoints.dart`.
- [ ] Create `lib/core/layout/adaptive_scaffold.dart`.
- [ ] Edit `lib/features/home/home_shell.dart`.

**Build.**

- [ ] `WindowSize.of(context)` returns compact below 600, medium below 840 and expanded above, from `MediaQuery.sizeOf`.
- [ ] `AdaptiveScaffold` shows a bottom `NavigationBar` when compact and a `NavigationRail` otherwise.

**You see.**

- [ ] A tablet emulator shows a side rail. A phone shows a bottom bar.

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] `test/core/layout/adaptive_scaffold_golden_test.dart` renders 360, 700 and 1024 wide. Run `fvm flutter test --tags golden`.

**Verify, live.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked. Ten lanes on `inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. Open the home shell on a phone emulator at trunk and head. Save `phone-shell.png`. Pass when both show a bottom bar.
- [ ] Lane 2. Open the home shell on a 10 inch tablet emulator. Save `tablet-rail.png`. Pass when it shows a navigation rail.
- [ ] Lane 3. Resize a foldable emulator from folded to open. Save `fold.png`. Pass when the layout switches without losing the selected tab.
- [ ] Lane 4. Boot the dev flavor on the Android emulator from a cold start with `tool/lanes/android.sh launch dev`. Save `android-cold-start.png`. Pass when the first route renders and logcat shows no `E/flutter` line.
- [ ] Lane 5. Boot the dev flavor on the iOS simulator on the macOS runner with `tool/lanes/ios.sh launch dev`. Save `ios-cold-start.png`. Pass when the first route renders and the simulator log shows no Flutter error.
- [ ] Lane 6. Background the app for 40 seconds on Android, then resume. Save `resume.png`. Pass when the app returns to the expected screen with no crash.
- [ ] Lane 7. Install the prod flavor release build on the Android emulator. Save `prod-release.png`. Pass when it starts with the prod app name and no debug banner.
- [ ] Lane 8. Rotate the Android emulator to landscape on the first screen. Save `landscape.png`. Pass when no overflow stripe or exception appears.
- [ ] Lane 9. Install dev, stage and prod side by side on the Android emulator. Save `side-by-side.png`. Pass when the launcher shows three icons with three names.
- [ ] Lane 10. Set the Android font scale to 1.3 with `adb shell settings put system font_scale 1.3` and relaunch. Save `font-scale.png`. Pass when no text clips or overflows.

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] Metric. Cold start time to first frame, `timeToFirstFrameMicros`, for the dev flavor in profile mode on the Android emulator.
- [ ] Probe. Run `flutter run --profile --flavor dev --trace-startup` five times each at trunk and at the head, interleaved, and read `build/start_up_info.json`.
- [ ] Baseline. Record the trunk median first.
- [ ] Rule. Fail when the head median exceeds the trunk median by more than 15 percent.

**Review gate.** The operator reviews before merge.

- [ ] Copy the lane 1 to 4 screenshots into `spec/media/cs-05-review-<slug>.png`.
- [ ] Record a 30 to 60 second video with `adb shell screenrecord`. Save it as `spec/media/cs-05-review.mp4`.
- [ ] Post the screenshots and the video in chat. Stop at merge-ready. Wait for the operator's click.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] Review comment triage done.
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] The root appends it to the stack, and the operator lands it bottom-up.

## Refactor the Dio API layer into one ApiClient with a mock server (CS-06)

**Depends on.** CS-02.

**Files.**

- [ ] Create `lib/core/network/api_client.dart`.
- [ ] Create `lib/core/network/error_mapper.dart`.
- [ ] Create `lib/core/network/pinning.dart`.
- [ ] Create `tool/mock_api/server.dart`.
- [ ] Edit `lib/core/di/injection.dart`.

**Build.**

- [ ] `ApiClient` owns one `Dio` with timeouts from `AppConfig`, optional pinning against a list of SHA-256 pins, and opt-in caching per call instead of `forceCache` by default.
- [ ] `mapDioError` turns every `DioException` into a typed `Failure`.
- [ ] `tool/mock_api/server.dart` is a `dart:io` server for `/auth/login`, `/auth/refresh`, `/me` and `/devices`.

**You see.**

- [ ] `dart run tool/mock_api/server.dart` prints its port, and the dev flavor on the emulator reaches it at `10.0.2.2`.

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] `test/core/network/api_client_test.dart` covers timeout, 401, 500, bad JSON and pin mismatch with a fake `HttpClientAdapter`. Run `fvm flutter test test/core/network`.

**Verify, live.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked. Ten lanes on `inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. Trunk has no API layer. Record that, then call `/me` from a debug action at the head. Save `me-call.png`. Pass when the response shows on screen.
- [ ] Lane 2. Stop the mock server and call `/me`. Save `offline.png`. Pass when the mapped connection failure shows, not a stack trace.
- [ ] Lane 3. Set a wrong `CERT_SHA256` against an HTTPS endpoint. Save `pin-fail.png`. Pass when the request fails with the pinning failure.
- [ ] Lane 4. Boot the dev flavor on the Android emulator from a cold start with `tool/lanes/android.sh launch dev`. Save `android-cold-start.png`. Pass when the first route renders and logcat shows no `E/flutter` line.
- [ ] Lane 5. Boot the dev flavor on the iOS simulator on the macOS runner with `tool/lanes/ios.sh launch dev`. Save `ios-cold-start.png`. Pass when the first route renders and the simulator log shows no Flutter error.
- [ ] Lane 6. Background the app for 40 seconds on Android, then resume. Save `resume.png`. Pass when the app returns to the expected screen with no crash.
- [ ] Lane 7. Install the prod flavor release build on the Android emulator. Save `prod-release.png`. Pass when it starts with the prod app name and no debug banner.
- [ ] Lane 8. Rotate the Android emulator to landscape on the first screen. Save `landscape.png`. Pass when no overflow stripe or exception appears.
- [ ] Lane 9. Install dev, stage and prod side by side on the Android emulator. Save `side-by-side.png`. Pass when the launcher shows three icons with three names.
- [ ] Lane 10. Set the Android font scale to 1.3 with `adb shell settings put system font_scale 1.3` and relaunch. Save `font-scale.png`. Pass when no text clips or overflows.

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] Metric. Median time per request through `ApiClient` with every interceptor, on a fake adapter. Trunk lacks the layer, so this is an absolute budget.
- [ ] Probe. Run `fvm flutter test test/perf/api_client_bench_test.dart` five times at the head. It sends 1000 requests and prints the median.
- [ ] Baseline. Record the raw `Dio` median on the same fake adapter first as the floor.
- [ ] Rule. Fail when the `ApiClient` median exceeds the raw floor by more than 1 ms.

**Review gate.** None. CS-06 is not review-gated.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] Review comment triage done.
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] The root appends it to the stack, and the operator lands it bottom-up.

## Move the session into secure storage with token refresh (CS-07)

**Depends on.** CS-06.

**Files.**

- [ ] Create `lib/core/storage/secure_store.dart`.
- [ ] Create `lib/features/auth/data/token_store.dart`.
- [ ] Create `lib/features/auth/domain/auth_repository.dart`.
- [ ] Create `lib/features/auth/data/rest_auth_repository.dart` and `fake_auth_repository.dart`.
- [ ] Create `lib/features/auth/session_cubit.dart`.
- [ ] Create `lib/core/network/auth_interceptor.dart`.
- [ ] Create `lib/core/router/auth_guard.dart`.

**Build.**

- [ ] `SessionState` is a sealed class with `unknown`, `authenticated` and `unauthenticated`.
- [ ] `AuthInterceptor` is a `QueuedInterceptor` that attaches the access token and runs one refresh for any number of concurrent 401s, then logs out when refresh fails.
- [ ] Logout clears `SecureStore` only, so theme and language survive.

**You see.**

- [ ] Killing the app while signed in reopens signed in, and an expired token refreshes without a visible error.

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] `test/core/network/auth_interceptor_test.dart` sends five concurrent 401s and asserts one refresh call. `test/features/auth/session_cubit_test.dart` covers logout keeping prefs. Run `fvm flutter test`.

**Verify, live.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked. Ten lanes on `inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. Trunk has no session. Record that, then sign in through a debug action at the head and relaunch. Save `session-restore.png`. Pass when the app opens signed in.
- [ ] Lane 2. Make the mock server expire the access token, then call `/me`. Save `refresh.png`. Pass when the call succeeds and the server log shows one refresh.
- [ ] Lane 3. Make refresh fail. Save `forced-logout.png`. Pass when the app routes to the signed-out state.
- [ ] Lane 4. Run `adb shell run-as com.wutstack.corestone.dev cat shared_prefs/*.xml`. Save `no-plain-token.png`. Pass when no token string appears.
- [ ] Lane 5. Boot the dev flavor on the Android emulator from a cold start with `tool/lanes/android.sh launch dev`. Save `android-cold-start.png`. Pass when the first route renders and logcat shows no `E/flutter` line.
- [ ] Lane 6. Boot the dev flavor on the iOS simulator on the macOS runner with `tool/lanes/ios.sh launch dev`. Save `ios-cold-start.png`. Pass when the first route renders and the simulator log shows no Flutter error.
- [ ] Lane 7. Background the app for 40 seconds on Android, then resume. Save `resume.png`. Pass when the app returns to the expected screen with no crash.
- [ ] Lane 8. Install the prod flavor release build on the Android emulator. Save `prod-release.png`. Pass when it starts with the prod app name and no debug banner.
- [ ] Lane 9. Rotate the Android emulator to landscape on the first screen. Save `landscape.png`. Pass when no overflow stripe or exception appears.
- [ ] Lane 10. Install dev, stage and prod side by side on the Android emulator. Save `side-by-side.png`. Pass when the launcher shows three icons with three names.

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] Metric. Cold start time to first frame, `timeToFirstFrameMicros`, for the dev flavor in profile mode on the Android emulator.
- [ ] Probe. Run `flutter run --profile --flavor dev --trace-startup` five times each at trunk and at the head, interleaved, and read `build/start_up_info.json`.
- [ ] Baseline. Record the trunk median first.
- [ ] Rule. Fail when the head median exceeds the trunk median by more than 15 percent.

**Review gate.** None. CS-07 is not review-gated.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] Review comment triage done.
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] The root appends it to the stack, and the operator lands it bottom-up.

## Refactor login, logout and account deletion onto the REST session (CS-08)

**Depends on.** CS-07 and CS-04.

**Files.**

- [ ] Create `lib/features/auth/presentation/login_screen.dart`.
- [ ] Create `lib/features/auth/presentation/login_bloc.dart`.
- [ ] Create `lib/features/settings/delete_account_screen.dart`.
- [ ] Edit `lib/features/settings/settings_screen.dart`.
- [ ] Edit `lib/l10n/app_en.arb` and `app_th.arb`.

**Build.**

- [ ] Email and password login through `AuthRepository`, with the field validators ported from `skelter/lib/validators`.
- [ ] Delete account calls `DELETE /me`, then logs out, because both stores require in-app deletion.
- [ ] `DEMO_MODE=true` on dev binds `FakeAuthRepository`, so the template runs with no backend.

**You see.**

- [ ] Login, logout and delete account work against the mock server and in demo mode.

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] `test/features/auth/login_bloc_test.dart` covers success, wrong password and offline. Login golden in `en` and `th`. Run `fvm flutter test`.

**Verify, live.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked. Ten lanes on `inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. Trunk has no login. Record that, then sign in with the mock user at the head. Save `login-ok.png`. Pass when Home shows.
- [ ] Lane 2. Sign in with a wrong password. Save `login-wrong.png`. Pass when the localized error shows and the fields keep their text.
- [ ] Lane 3. Sign out from Settings. Save `logout.png`. Pass when the login screen shows and theme stays as set.
- [ ] Lane 4. Delete the account. Save `delete.png`. Pass when the server log shows `DELETE /me` and the app returns to login.
- [ ] Lane 5. Boot the dev flavor on the Android emulator from a cold start with `tool/lanes/android.sh launch dev`. Save `android-cold-start.png`. Pass when the first route renders and logcat shows no `E/flutter` line.
- [ ] Lane 6. Boot the dev flavor on the iOS simulator on the macOS runner with `tool/lanes/ios.sh launch dev`. Save `ios-cold-start.png`. Pass when the first route renders and the simulator log shows no Flutter error.
- [ ] Lane 7. Background the app for 40 seconds on Android, then resume. Save `resume.png`. Pass when the app returns to the expected screen with no crash.
- [ ] Lane 8. Install the prod flavor release build on the Android emulator. Save `prod-release.png`. Pass when it starts with the prod app name and no debug banner.
- [ ] Lane 9. Rotate the Android emulator to landscape on the first screen. Save `landscape.png`. Pass when no overflow stripe or exception appears.
- [ ] Lane 10. Install dev, stage and prod side by side on the Android emulator. Save `side-by-side.png`. Pass when the launcher shows three icons with three names.

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] Metric. Cold start time to first frame, `timeToFirstFrameMicros`, for the dev flavor in profile mode on the Android emulator.
- [ ] Probe. Run `flutter run --profile --flavor dev --trace-startup` five times each at trunk and at the head, interleaved, and read `build/start_up_info.json`.
- [ ] Baseline. Record the trunk median first.
- [ ] Rule. Fail when the head median exceeds the trunk median by more than 15 percent.

**Review gate.** The operator reviews before merge.

- [ ] Copy the lane 1 to 4 screenshots into `spec/media/cs-08-review-<slug>.png`.
- [ ] Record a 30 to 60 second video with `adb shell screenrecord`. Save it as `spec/media/cs-08-review.mp4`.
- [ ] Post the screenshots and the video in chat. Stop at merge-ready. Wait for the operator's click.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] Review comment triage done.
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] The root appends it to the stack, and the operator lands it bottom-up.

## Add the app PIN lock (CS-09)

**Depends on.** CS-08.

**Files.**

- [ ] Create `lib/features/app_lock/pin_repository.dart`.
- [ ] Create `lib/features/app_lock/app_lock_cubit.dart`.
- [ ] Create `lib/features/app_lock/lock_screen.dart`.
- [ ] Create `lib/features/app_lock/set_pin_screen.dart`.
- [ ] Edit `lib/core/router/app_router.dart`.
- [ ] Edit `pubspec.yaml` to add `cryptography`.

**Build.**

- [ ] `PinRepository` stores a salted PBKDF2 hash in `SecureStore`, never the PIN.
- [ ] `AppLockState` is a sealed class with `noPin`, `locked`, `unlocked` and `lockedOut`.
- [ ] `AppLifecycleListener` locks after 30 seconds in background, and five wrong PINs log the user out.

**You see.**

- [ ] After sign in the user sets a six digit PIN, and every cold start or long background shows the lock screen.

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] `test/features/app_lock/app_lock_cubit_test.dart` uses a fake clock for the 30 second rule and the five-failure logout. `test/features/app_lock/pin_repository_test.dart` asserts the stored value differs from the PIN. Run `fvm flutter test`.

**Verify, live.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked. Ten lanes on `inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. Trunk has no lock. Record that, then sign in at the head and set PIN 135790. Save `set-pin.png`. Pass when Home shows after confirmation.
- [ ] Lane 2. Kill and relaunch. Save `cold-lock.png`. Pass when the lock screen shows before Home.
- [ ] Lane 3. Background for 10 seconds and resume. Save `short-bg.png`. Pass when Home shows with no lock.
- [ ] Lane 4. Enter five wrong PINs. Save `lockout.png`. Pass when the app logs out to login.
- [ ] Lane 5. Change the PIN from Settings. Save `change-pin.png`. Pass when only the new PIN unlocks.
- [ ] Lane 6. Boot the dev flavor on the Android emulator from a cold start with `tool/lanes/android.sh launch dev`. Save `android-cold-start.png`. Pass when the first route renders and logcat shows no `E/flutter` line.
- [ ] Lane 7. Boot the dev flavor on the iOS simulator on the macOS runner with `tool/lanes/ios.sh launch dev`. Save `ios-cold-start.png`. Pass when the first route renders and the simulator log shows no Flutter error.
- [ ] Lane 8. Background the app for 40 seconds on Android, then resume. Save `resume.png`. Pass when the app returns to the expected screen with no crash.
- [ ] Lane 9. Install the prod flavor release build on the Android emulator. Save `prod-release.png`. Pass when it starts with the prod app name and no debug banner.
- [ ] Lane 10. Rotate the Android emulator to landscape on the first screen. Save `landscape.png`. Pass when no overflow stripe or exception appears.

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] Metric. Time from the sixth digit to the unlocked Home frame. Trunk lacks the feature, so this is an absolute budget.
- [ ] Probe. Run the PIN unlock Patrol test five times on the Android emulator and on the macOS runner simulator, reading the timeline marks around `verifyPin`.
- [ ] Baseline. Record the median frame time of Home without a lock on the same device first.
- [ ] Rule. Fail when the unlock median exceeds 400 ms on the Android emulator.

**Review gate.** The operator reviews before merge.

- [ ] Copy the lane 1 to 4 screenshots into `spec/media/cs-09-review-<slug>.png`.
- [ ] Record a 30 to 60 second video with `adb shell screenrecord`. Save it as `spec/media/cs-09-review.mp4`.
- [ ] Post the screenshots and the video in chat. Stop at merge-ready. Wait for the operator's click.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] Review comment triage done.
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] The root appends it to the stack, and the operator lands it bottom-up.

## Refactor biometrics into a shortcut on the lock screen (CS-10)

**Depends on.** CS-09.

**Files.**

- [ ] Create `lib/features/app_lock/biometric_service.dart` from `skelter/lib/services/local_auth_services.dart`.
- [ ] Edit `lib/features/app_lock/lock_screen.dart`.
- [ ] Edit `android/app/src/main/kotlin/com/wutstack/corestone/MainActivity.kt` to extend `FlutterFragmentActivity`.
- [ ] Edit `ios/Runner/Info.plist` to add `NSFaceIDUsageDescription`.
- [ ] Edit `lib/features/settings/settings_screen.dart`.

**Build.**

- [ ] Biometric success unlocks the lock. Failure or cancel falls back to the PIN pad and never exits the app.

**You see.**

- [ ] With biometrics on, the lock screen prompts for a fingerprint and shows the PIN pad behind it.

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] `test/features/app_lock/biometric_unlock_test.dart` covers success, cancel and not enrolled with a fake `LocalAuthentication`. Run `fvm flutter test`.

**Verify, live.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked. Ten lanes on `inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. Unlock with the PIN at trunk and head. Save `pin-unlock.png`. Pass when both unlock.
- [ ] Lane 2. Enable biometrics and unlock with `adb -e emu finger touch 1`. Save `finger-ok.png`. Pass when Home shows.
- [ ] Lane 3. Cancel the biometric prompt. Save `finger-cancel.png`. Pass when the PIN pad shows and the app stays open.
- [ ] Lane 4. Unlock with Face ID matching on the iOS simulator. Save `faceid.png`. Pass when Home shows.
- [ ] Lane 5. Boot the dev flavor on the Android emulator from a cold start with `tool/lanes/android.sh launch dev`. Save `android-cold-start.png`. Pass when the first route renders and logcat shows no `E/flutter` line.
- [ ] Lane 6. Boot the dev flavor on the iOS simulator on the macOS runner with `tool/lanes/ios.sh launch dev`. Save `ios-cold-start.png`. Pass when the first route renders and the simulator log shows no Flutter error.
- [ ] Lane 7. Background the app for 40 seconds on Android, then resume. Save `resume.png`. Pass when the app returns to the expected screen with no crash.
- [ ] Lane 8. Install the prod flavor release build on the Android emulator. Save `prod-release.png`. Pass when it starts with the prod app name and no debug banner.
- [ ] Lane 9. Rotate the Android emulator to landscape on the first screen. Save `landscape.png`. Pass when no overflow stripe or exception appears.
- [ ] Lane 10. Install dev, stage and prod side by side on the Android emulator. Save `side-by-side.png`. Pass when the launcher shows three icons with three names.

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] Metric. Cold start time to first frame, `timeToFirstFrameMicros`, for the dev flavor in profile mode on the Android emulator.
- [ ] Probe. Run `flutter run --profile --flavor dev --trace-startup` five times each at trunk and at the head, interleaved, and read `build/start_up_info.json`.
- [ ] Baseline. Record the trunk median first.
- [ ] Rule. Fail when the head median exceeds the trunk median by more than 15 percent.

**Review gate.** The operator reviews before merge.

- [ ] Copy the lane 1 to 4 screenshots into `spec/media/cs-10-review-<slug>.png`.
- [ ] Record a 30 to 60 second video with `adb shell screenrecord`. Save it as `spec/media/cs-10-review.mp4`.
- [ ] Post the screenshots and the video in chat. Stop at merge-ready. Wait for the operator's click.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] Review comment triage done.
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] The root appends it to the stack, and the operator lands it bottom-up.

## Keep FCM on an optional Firebase core (CS-11)

**Depends on.** CS-07.

**Files.**

- [ ] Edit `android/settings.gradle.kts` and `android/app/build.gradle.kts` for the google-services plugin.
- [ ] Edit `ios/Runner.xcodeproj/project.pbxproj` with a build phase that copies `ios/config/<flavor>/GoogleService-Info.plist`.
- [ ] Create `ios/Runner/Runner.entitlements` with `aps-environment`.
- [ ] Create `lib/core/push/push_service.dart`.
- [ ] Create `tool/firebase_config.sh`.
- [ ] Edit `pubspec.yaml` to add `firebase_core`, `firebase_messaging` and `awesome_notifications`.

**Build.**

- [ ] `PushService` initializes Firebase only when the flavor has options, asks permission, shows foreground messages and registers the token with `POST /devices` after sign in and `DELETE /devices` on logout.
- [ ] No other Firebase product is added.

**You see.**

- [ ] A test message from the Firebase console shows on the device in foreground and background.

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] `test/core/push/push_service_test.dart` covers token registration on sign in and removal on logout with a fake messaging. Run `fvm flutter test`.

**Verify, live.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked. Ten lanes on `inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. Trunk has no push. Record that, then build the dev flavor at the head with no Firebase files. Save `no-firebase.png`. Pass when the app starts and logs that push is off.
- [ ] Lane 2. With dev Firebase files, accept the permission prompt. Save `permission.png`. Pass when the server log shows `POST /devices`.
- [ ] Lane 3. Send a test message with the app in foreground. Save `fg-push.png`. Pass when the notification shows.
- [ ] Lane 4. Send a test message with the app killed and tap it. Save `bg-push.png`. Pass when the app opens past the lock to Home.
- [ ] Lane 5. Boot the dev flavor on the Android emulator from a cold start with `tool/lanes/android.sh launch dev`. Save `android-cold-start.png`. Pass when the first route renders and logcat shows no `E/flutter` line.
- [ ] Lane 6. Boot the dev flavor on the iOS simulator on the macOS runner with `tool/lanes/ios.sh launch dev`. Save `ios-cold-start.png`. Pass when the first route renders and the simulator log shows no Flutter error.
- [ ] Lane 7. Background the app for 40 seconds on Android, then resume. Save `resume.png`. Pass when the app returns to the expected screen with no crash.
- [ ] Lane 8. Install the prod flavor release build on the Android emulator. Save `prod-release.png`. Pass when it starts with the prod app name and no debug banner.
- [ ] Lane 9. Rotate the Android emulator to landscape on the first screen. Save `landscape.png`. Pass when no overflow stripe or exception appears.
- [ ] Lane 10. Install dev, stage and prod side by side on the Android emulator. Save `side-by-side.png`. Pass when the launcher shows three icons with three names.

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] Metric. Cold start time to first frame, `timeToFirstFrameMicros`, for the dev flavor in profile mode on the Android emulator.
- [ ] Probe. Run `flutter run --profile --flavor dev --trace-startup` five times each at trunk and at the head, interleaved, and read `build/start_up_info.json`.
- [ ] Baseline. Record the trunk median first.
- [ ] Rule. Fail when the head median exceeds the trunk median by more than 15 percent.

**Review gate.** The operator reviews before merge.

- [ ] Copy the lane 1 to 4 screenshots into `spec/media/cs-11-review-<slug>.png`.
- [ ] Record a 30 to 60 second video with `adb shell screenrecord`. Save it as `spec/media/cs-11-review.mp4`.
- [ ] Post the screenshots and the video in chat. Stop at merge-ready. Wait for the operator's click.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] Review comment triage done.
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] The root appends it to the stack, and the operator lands it bottom-up.

## Port the system screens and the connectivity banner (CS-12)

**Depends on.** CS-06.

**Files.**

- [ ] Create `lib/features/system/no_internet_screen.dart`, `server_error_screen.dart`, `maintenance_screen.dart`, `ssl_failed_screen.dart` from `skelter/lib/presentation`.
- [ ] Create `lib/core/network/connectivity_banner.dart`.
- [ ] Edit `lib/core/network/error_mapper.dart`.

**Build.**

- [ ] Mapped failures route to the matching system screen, and `connectivity_plus` drives a banner instead of pushing a route.

**You see.**

- [ ] Airplane mode shows the offline banner, and a 503 from the mock server shows the maintenance screen.

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] Goldens for each system screen in `en` and `th`. Run `fvm flutter test --tags golden`.

**Verify, live.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked. Ten lanes on `inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. Trunk has no system screens. Record that, then return 500 from the mock server at the head. Save `server-error.png`. Pass when the server error screen shows.
- [ ] Lane 2. Turn on airplane mode. Save `offline-banner.png`. Pass when the banner shows and clears when airplane mode turns off.
- [ ] Lane 3. Return 503 from the mock server. Save `maintenance.png`. Pass when the maintenance screen shows.
- [ ] Lane 4. Boot the dev flavor on the Android emulator from a cold start with `tool/lanes/android.sh launch dev`. Save `android-cold-start.png`. Pass when the first route renders and logcat shows no `E/flutter` line.
- [ ] Lane 5. Boot the dev flavor on the iOS simulator on the macOS runner with `tool/lanes/ios.sh launch dev`. Save `ios-cold-start.png`. Pass when the first route renders and the simulator log shows no Flutter error.
- [ ] Lane 6. Background the app for 40 seconds on Android, then resume. Save `resume.png`. Pass when the app returns to the expected screen with no crash.
- [ ] Lane 7. Install the prod flavor release build on the Android emulator. Save `prod-release.png`. Pass when it starts with the prod app name and no debug banner.
- [ ] Lane 8. Rotate the Android emulator to landscape on the first screen. Save `landscape.png`. Pass when no overflow stripe or exception appears.
- [ ] Lane 9. Install dev, stage and prod side by side on the Android emulator. Save `side-by-side.png`. Pass when the launcher shows three icons with three names.
- [ ] Lane 10. Set the Android font scale to 1.3 with `adb shell settings put system font_scale 1.3` and relaunch. Save `font-scale.png`. Pass when no text clips or overflows.

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] Metric. Cold start time to first frame, `timeToFirstFrameMicros`, for the dev flavor in profile mode on the Android emulator.
- [ ] Probe. Run `flutter run --profile --flavor dev --trace-startup` five times each at trunk and at the head, interleaved, and read `build/start_up_info.json`.
- [ ] Baseline. Record the trunk median first.
- [ ] Rule. Fail when the head median exceeds the trunk median by more than 15 percent.

**Review gate.** The operator reviews before merge.

- [ ] Copy the lane 1 to 4 screenshots into `spec/media/cs-12-review-<slug>.png`.
- [ ] Record a 30 to 60 second video with `adb shell screenrecord`. Save it as `spec/media/cs-12-review.mp4`.
- [ ] Post the screenshots and the video in chat. Stop at merge-ready. Wait for the operator's click.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] Review comment triage done.
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] The root appends it to the stack, and the operator lands it bottom-up.

## Keep deep links behind the session and the lock (CS-16)

**Depends on.** CS-10.

**Files.**

- [ ] Create `lib/core/deep_link/deep_link_service.dart` from `skelter/lib/core/deep_link/app_deep_link_manager.dart` without the product routes.
- [ ] Create `lib/core/deep_link/deep_link_routes.dart`.
- [ ] Edit `android/app/src/main/AndroidManifest.xml` with an App Links intent filter whose host comes from a `deepLinkHost` manifest placeholder per flavor.
- [ ] Edit `ios/Runner/Runner.entitlements` with `applinks:$(DEEP_LINK_HOST)`.
- [ ] Edit `config/dev.json`, `stage.json`, `prod.json` with `DEEP_LINK_HOST`.

**Build.**

- [ ] `DeepLinkTarget` is a sealed class parsed from a `Uri` at the boundary, and an unknown path parses to `DeepLinkTarget.unknown` instead of throwing.
- [ ] A link that arrives signed out or locked is held and replayed after sign in and unlock.

**You see.**

- [ ] `adb shell am start -d https://<host>/settings` opens Settings, after the lock screen when locked.

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] `test/core/deep_link/deep_link_target_test.dart` parses every known path and rejects unknown ones. `test/core/deep_link/pending_link_test.dart` replays a held link after unlock. Run `fvm flutter test test/core/deep_link`.

**Verify, live.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked. Ten lanes on `inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. Trunk has no deep links. Record that, then open the settings link at the head while unlocked. Save `link-settings.png`. Pass when Settings shows.
- [ ] Lane 2. Open the settings link while locked. Save `link-locked.png`. Pass when the lock screen shows first and Settings shows after unlock.
- [ ] Lane 3. Open the settings link while signed out. Save `link-signed-out.png`. Pass when login shows first and Settings shows after sign in and PIN setup.
- [ ] Lane 4. Open an unknown path. Save `link-unknown.png`. Pass when Home shows with no error.
- [ ] Lane 5. Open the link on the stage flavor. Save `link-stage.png`. Pass when the stage app, not dev, handles it.
- [ ] Lane 6. Boot the dev flavor on the Android emulator from a cold start with `tool/lanes/android.sh launch dev`. Save `android-cold-start.png`. Pass when the first route renders and logcat shows no `E/flutter` line.
- [ ] Lane 7. Boot the dev flavor on the iOS simulator on the macOS runner with `tool/lanes/ios.sh launch dev`. Save `ios-cold-start.png`. Pass when the first route renders and the simulator log shows no Flutter error.
- [ ] Lane 8. Background the app for 40 seconds on Android, then resume. Save `resume.png`. Pass when the app returns to the expected screen with no crash.
- [ ] Lane 9. Install the prod flavor release build on the Android emulator. Save `prod-release.png`. Pass when it starts with the prod app name and no debug banner.
- [ ] Lane 10. Rotate the Android emulator to landscape on the first screen. Save `landscape.png`. Pass when no overflow stripe or exception appears.

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] Metric. Cold start time to first frame, `timeToFirstFrameMicros`, for the dev flavor in profile mode on the Android emulator.
- [ ] Probe. Run `flutter run --profile --flavor dev --trace-startup` five times each at trunk and at the head, interleaved, and read `build/start_up_info.json`.
- [ ] Baseline. Record the trunk median first.
- [ ] Rule. Fail when the head median exceeds the trunk median by more than 15 percent.

**Review gate.** The operator reviews before merge.

- [ ] Copy the lane 1 to 4 screenshots into `spec/media/cs-16-review-<slug>.png`.
- [ ] Record a 30 to 60 second video with `adb shell screenrecord`. Save it as `spec/media/cs-16-review.mp4`.
- [ ] Post the screenshots and the video in chat. Stop at merge-ready. Wait for the operator's click.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] Review comment triage done.
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] The root appends it to the stack, and the operator lands it bottom-up.

## Keep feedback on the REST API instead of Firestore (CS-17)

**Depends on.** CS-08 and CS-12.

**Files.**

- [ ] Create `lib/features/feedback/feedback_screen.dart` and `feedback_bloc.dart` from `skelter/lib/presentation/feedback`.
- [ ] Create `lib/features/feedback/data/feedback_repository.dart`.
- [ ] Edit `tool/mock_api/server.dart` to accept `POST /feedback`.
- [ ] Edit `lib/features/settings/settings_screen.dart`.
- [ ] Edit `lib/l10n/app_en.arb` and `app_th.arb`.

**Build.**

- [ ] `FeedbackRepository.send` posts the rating, text and app version with `POST /feedback` through `ApiClient`. No Firestore code is ported.
- [ ] `FeedbackState` is a sealed class with `editing`, `sending`, `sent` and `failed`.

**You see.**

- [ ] Settings then Feedback sends a rating and text, and the mock server logs the body.

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] `test/features/feedback/feedback_bloc_test.dart` covers sent, offline and server error. Feedback golden in `en` and `th`. Run `fvm flutter test test/features/feedback`.

**Verify, live.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked. Ten lanes on `inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. Trunk has no feedback. Record that, then send four stars and a message at the head. Save `feedback-sent.png`. Pass when the success state shows and the server log has the body.
- [ ] Lane 2. Send with the mock server stopped. Save `feedback-offline.png`. Pass when the localized error shows and the text stays.
- [ ] Lane 3. Submit with empty text. Save `feedback-empty.png`. Pass when the validator message shows and nothing is sent.
- [ ] Lane 4. Send in Thai. Save `feedback-th.png`. Pass when every label is Thai and the server log has the Thai text intact.
- [ ] Lane 5. Boot the dev flavor on the Android emulator from a cold start with `tool/lanes/android.sh launch dev`. Save `android-cold-start.png`. Pass when the first route renders and logcat shows no `E/flutter` line.
- [ ] Lane 6. Boot the dev flavor on the iOS simulator on the macOS runner with `tool/lanes/ios.sh launch dev`. Save `ios-cold-start.png`. Pass when the first route renders and the simulator log shows no Flutter error.
- [ ] Lane 7. Background the app for 40 seconds on Android, then resume. Save `resume.png`. Pass when the app returns to the expected screen with no crash.
- [ ] Lane 8. Install the prod flavor release build on the Android emulator. Save `prod-release.png`. Pass when it starts with the prod app name and no debug banner.
- [ ] Lane 9. Rotate the Android emulator to landscape on the first screen. Save `landscape.png`. Pass when no overflow stripe or exception appears.
- [ ] Lane 10. Install dev, stage and prod side by side on the Android emulator. Save `side-by-side.png`. Pass when the launcher shows three icons with three names.

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] Metric. Cold start time to first frame, `timeToFirstFrameMicros`, for the dev flavor in profile mode on the Android emulator.
- [ ] Probe. Run `flutter run --profile --flavor dev --trace-startup` five times each at trunk and at the head, interleaved, and read `build/start_up_info.json`.
- [ ] Baseline. Record the trunk median first.
- [ ] Rule. Fail when the head median exceeds the trunk median by more than 15 percent.

**Review gate.** The operator reviews before merge.

- [ ] Copy the lane 1 to 4 screenshots into `spec/media/cs-17-review-<slug>.png`.
- [ ] Record a 30 to 60 second video with `adb shell screenrecord`. Save it as `spec/media/cs-17-review.mp4`.
- [ ] Post the screenshots and the video in chat. Stop at merge-ready. Wait for the operator's click.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] Review comment triage done.
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] The root appends it to the stack, and the operator lands it bottom-up.

## Adapt the integration tests to Patrol on the new flows (CS-13)

**Depends on.** CS-11, CS-16 and CS-17.

**Files.**

- [ ] Edit `pubspec.yaml` with the `patrol` block for `com.wutstack.corestone.dev`.
- [ ] Edit `android/app/build.gradle.kts` for the Patrol runner and orchestrator.
- [ ] Create `android/app/src/androidTest/java/com/wutstack/corestone/MainActivityTest.java`.
- [ ] Create `integration_test/app_test.dart`.
- [ ] Edit `.github/workflows/ci.yml` to add an emulator job.

**Build.**

- [ ] `app_test.dart` runs sign in, set PIN, background, unlock and logout against the mock server.

**You see.**

- [ ] The emulator job in CI runs the Patrol suite green.

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] The Patrol suite is the test. Run `patrol test --target integration_test/app_test.dart --flavor dev`.

**Verify, live.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked. Ten lanes on `inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. Trunk has no Patrol suite. Record that, then run the suite at the head. Save `patrol-run.png`. Pass when every case passes.
- [ ] Lane 2. Break the PIN check on a scratch branch and rerun. Save `patrol-red.png`. Pass when the suite fails on the unlock case.
- [ ] Lane 3. Read the CI emulator job log. Save `patrol-ci.png`. Pass when it reports the same passing cases.
- [ ] Lane 4. Boot the dev flavor on the Android emulator from a cold start with `tool/lanes/android.sh launch dev`. Save `android-cold-start.png`. Pass when the first route renders and logcat shows no `E/flutter` line.
- [ ] Lane 5. Boot the dev flavor on the iOS simulator on the macOS runner with `tool/lanes/ios.sh launch dev`. Save `ios-cold-start.png`. Pass when the first route renders and the simulator log shows no Flutter error.
- [ ] Lane 6. Background the app for 40 seconds on Android, then resume. Save `resume.png`. Pass when the app returns to the expected screen with no crash.
- [ ] Lane 7. Install the prod flavor release build on the Android emulator. Save `prod-release.png`. Pass when it starts with the prod app name and no debug banner.
- [ ] Lane 8. Rotate the Android emulator to landscape on the first screen. Save `landscape.png`. Pass when no overflow stripe or exception appears.
- [ ] Lane 9. Install dev, stage and prod side by side on the Android emulator. Save `side-by-side.png`. Pass when the launcher shows three icons with three names.
- [ ] Lane 10. Set the Android font scale to 1.3 with `adb shell settings put system font_scale 1.3` and relaunch. Save `font-scale.png`. Pass when no text clips or overflows.

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] Metric. Wall time of the Patrol suite on the CI emulator job. Trunk lacks the suite, so this is an absolute budget.
- [ ] Probe. Read the job duration from three CI runs at the head.
- [ ] Baseline. Record the duration of the existing `test` job on trunk first.
- [ ] Rule. Fail when the Patrol job median exceeds 15 minutes.

**Review gate.** None. CS-13 is not review-gated.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] Review comment triage done.
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] The root appends it to the stack, and the operator lands it bottom-up.

## Build the template generator (CS-14)

**Depends on.** CS-02.

**Files.**

- [ ] Create `tool/new_project.dart`.
- [ ] Create `test/tool/new_project_test.dart`.
- [ ] Create `TEMPLATE.md`.

**Build.**

- [ ] `dart run tool/new_project.dart --name acme_app --org com.acme --display-name Acme` rewrites the pubspec name, every `package:corestone/` import, the Android namespace and `applicationId`, the Kotlin package directory, every iOS `PRODUCT_BUNDLE_IDENTIFIER`, the display names and the Patrol ids.
- [ ] It refuses a dirty tree and running it twice changes nothing.

**You see.**

- [ ] A fresh copy renamed to `acme_app` has no `corestone` string outside `NOTICE` and `TEMPLATE.md`.

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] `new_project_test.dart` renames a temp copy, greps for leftovers and reruns to assert no diff. Run `fvm dart test test/tool`.

**Verify, live.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked. Ten lanes on `inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. Trunk has no generator. Record that, then rename a fresh clone at the head. Save `rename-diff.png`. Pass when `git grep -i corestone` lists only `NOTICE` and `TEMPLATE.md`.
- [ ] Lane 2. Launch the renamed dev flavor on the Android emulator. Save `acme-android.png`. Pass when the launcher shows Acme Dev and it runs.
- [ ] Lane 3. Build the renamed project for iOS on the macOS runner. Save `acme-ios.png`. Pass when the bundle id is `com.acme.acmeApp.dev` or the documented form.
- [ ] Lane 4. Run the generator twice. Save `idempotent.png`. Pass when the second run reports no changes.
- [ ] Lane 5. Boot the dev flavor on the Android emulator from a cold start with `tool/lanes/android.sh launch dev`. Save `android-cold-start.png`. Pass when the first route renders and logcat shows no `E/flutter` line.
- [ ] Lane 6. Boot the dev flavor on the iOS simulator on the macOS runner with `tool/lanes/ios.sh launch dev`. Save `ios-cold-start.png`. Pass when the first route renders and the simulator log shows no Flutter error.
- [ ] Lane 7. Background the app for 40 seconds on Android, then resume. Save `resume.png`. Pass when the app returns to the expected screen with no crash.
- [ ] Lane 8. Install the prod flavor release build on the Android emulator. Save `prod-release.png`. Pass when it starts with the prod app name and no debug banner.
- [ ] Lane 9. Rotate the Android emulator to landscape on the first screen. Save `landscape.png`. Pass when no overflow stripe or exception appears.
- [ ] Lane 10. Install dev, stage and prod side by side on the Android emulator. Save `side-by-side.png`. Pass when the launcher shows three icons with three names.

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] Metric. Cold start time to first frame, `timeToFirstFrameMicros`, for the dev flavor in profile mode on the Android emulator.
- [ ] Probe. Run `flutter run --profile --flavor dev --trace-startup` five times each at trunk and at the head, interleaved, and read `build/start_up_info.json`.
- [ ] Baseline. Record the trunk median first.
- [ ] Rule. Fail when the head median exceeds the trunk median by more than 15 percent.

**Review gate.** None. CS-14 is not review-gated.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] Review comment triage done.
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] The root appends it to the stack, and the operator lands it bottom-up.

## Add App Distribution, release signing and the template smoke job (CS-15)

**Depends on.** CS-13 and CS-14.

**Operator amendment.** The done check is a local script, not a CI job. A project generated from the template passes analyze, test and an Android build, checked by `tool/template_smoke.sh`. GitHub CI is disabled, so PRs show no checks and the evidence is local. iOS is skipped for now and reported as unverified. The App Distribution workflow exists but stays disabled.

**Files.**

- [ ] Edit `android/app/build.gradle.kts` to read `key.properties` for release signing, falling back to the debug key with a Gradle warning.
- [ ] Create `.github/workflows/distribute.yml`, `workflow_dispatch` only, disabled with `gh workflow disable` after merge.
- [ ] Create `tool/template_smoke.sh`.
- [ ] Edit `tool/new_project.dart` to run `dart pub get` and the `directives_ordering` fix after renaming, and to remove `tool/template_smoke.sh` from a generated app.
- [ ] Edit `TEMPLATE.md` with release signing, the secret names and the done check.

**Build.**

- [ ] `distribute-android` builds a signed release APK for the chosen flavor and uploads it with `firebase appdistribution:distribute` using a service account secret and a tester group input.
- [ ] `tool/template_smoke.sh` generates `acme_app` into a temp copy, checks no template identity is left, then runs `pub get`, `analyze`, `test`, a debug dev APK build and a release prod APK build.

**You see.**

- [ ] `tool/template_smoke.sh` prints PASS with per-step timings, and FAIL with a non-zero exit when a step breaks.

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] `tool/template_smoke.sh` is the done check. Run it locally and read every step.
- [ ] `apksigner verify --print-certs` on the prod release APK shows the `key.properties` key when the file is present and the debug key when it is absent.

**Verify, live.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked. Ten lanes on `inherit-parent` at the PR head, per the boot recipe. Lanes 1, 2, 4 and 7 are deferred, because distribution stays disabled and iOS is unverified.

- [ ] Lane 1. Regression lane against trunk. Trunk builds without distribution. Record that, then push to a test branch at the head. Save `distribution.png`. Pass when the App Distribution console lists the new build.
- [ ] Lane 2. Install the distributed build from the tester invite on the emulator. Save `tester-install.png`. Pass when it launches.
- [ ] Lane 3. Read the `template-smoke` Android step. Save `smoke-android.png`. Pass when the renamed APK builds.
- [ ] Lane 4. Read the `template-smoke` iOS step. Save `smoke-ios.png`. Pass when the renamed Runner.app builds.
- [ ] Lane 5. Run `apksigner verify --print-certs` on the release APK. Save `signing.png`. Pass when it shows the release key, not the debug key.
- [ ] Lane 6. Boot the dev flavor on the Android emulator from a cold start with `tool/lanes/android.sh launch dev`. Save `android-cold-start.png`. Pass when the first route renders and logcat shows no `E/flutter` line.
- [ ] Lane 7. Boot the dev flavor on the iOS simulator on the macOS runner with `tool/lanes/ios.sh launch dev`. Save `ios-cold-start.png`. Pass when the first route renders and the simulator log shows no Flutter error.
- [ ] Lane 8. Background the app for 40 seconds on Android, then resume. Save `resume.png`. Pass when the app returns to the expected screen with no crash.
- [ ] Lane 9. Install the prod flavor release build on the Android emulator. Save `prod-release.png`. Pass when it starts with the prod app name and no debug banner.
- [ ] Lane 10. Rotate the Android emulator to landscape on the first screen. Save `landscape.png`. Pass when no overflow stripe or exception appears.

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

- [ ] Metric. Wall time of `tool/template_smoke.sh`, since CI is disabled.
- [ ] Probe. Read the total the script prints at the head.
- [ ] Baseline. Trunk has no smoke script, so there is no baseline.
- [ ] Rule. Fail when the total exceeds 30 minutes.

**Review gate.** None. CS-15 is not review-gated.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] Review comment triage done.
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] The root appends it to the stack, and the operator lands it bottom-up.

## Close the program

- [ ] Every box above is checked with its evidence.
- [ ] The operator marks the GitHub repo as a template repository in Settings.
- [ ] Reply to the operator with the report the execution playbook names.

## Appendix A. Prototype evidence

No prototype ran before this plan. These questions stay unproven, and each owner settles its own by prototype before building.

- The google-services Gradle plugin on AGP 9 with Kotlin DSL fails a flavor whose `google-services.json` is missing. CS-11 needs a per-flavor guard. Unproven.
- `flutter build ios --flavor dev --no-codesign` on Flutter 3.47.9 with nine build configs and the SceneDelegate scaffold. CS-01 proves it on the macOS runner. Unproven.
- The PBKDF2 iteration count that stays under the CS-09 400 ms budget on the emulator. CS-09 measures it. Unproven.
- `awesome_notifications` builds against AGP 9 and Flutter 3.47.9. CS-11 checks it first and falls back to `flutter_local_notifications`. Unproven.

## Appendix B. Alternatives rejected

- Stripping Skelter in place and copying the result. Rejected, because Skelter uses Groovy Gradle with AGP 8.9, hardcodes the SolGuruz Apple team `R4HRZ34ZYE` in every iOS config, and needs about 30 coupled call sites cut before it builds again. Porting into the fresh Kotlin DSL scaffold means REMOVE code never enters.
- A `mason` brick or `very_good_cli` template. Rejected, because a plain repo with `tool/new_project.dart` stays runnable and testable as an app, and adds no tool to learn.
- Keeping `sizer`. Rejected, because only five Skelter files use it and three are e-commerce. Breakpoints from `MediaQuery.sizeOf` need no dependency.
- Keeping `flutter_dotenv` with `.env` as an asset. Rejected, because `--dart-define-from-file` does the same job with no dependency and no file shipped inside the APK.
- Keeping force update and the dynamic icon. Rejected for now, because both read Remote Config, which is a REMOVE row. An API version check can come later.

## Appendix C. Risks

- The operator machine is Windows, so no iOS build or simulator lane runs locally. Every iOS box runs on the GitHub macOS runner. Lands in CS-00. The owner watches macOS minutes.
- The repo has no simulator-driving skill. CS-00 builds `tool/lanes/android.sh` and `tool/lanes/ios.sh` as the control surface. Every live lane depends on them.
- Goldens differ between Windows, macOS and Linux. `flutter_test_config.dart` uses Alchemist CI goldens under `CI=true` and platform goldens locally. Lands in CS-02.
- Inter has no Thai glyphs. CS-04 adds a Noto Sans Thai fallback, and its lane 2 checks for boxes.
- `flutter_secure_storage` data can survive Android auto backup and restore onto a new device without its key. CS-07 sets `android:allowBackup` or excludes the store.
- The session token sits in plain SharedPreferences in Skelter. CS-07 lane 4 proves it no longer does.
- `dartz` is unmaintained. It stays because the error layer is a KEEP row. Swapping to `fpdart` is a later, separate PR.
- The operator confirmed these product calls on 2026-11-04.
  - D1. Auth is a REST backend with access and refresh tokens, email and password only. Phone OTP, Google and Apple sign-in leave with Firebase Auth.
  - D2. Three flavors, dev, stage and prod.
  - D3. Microsoft Clarity, RevenueCat, dynamic icons, the battery channel, speech, rate-my-app, liquid glass, app tour and the demo product data are removed. Deep links stay, in CS-16, without the product routes.
  - D4. The PIN is six digits, locks on cold start and after 30 seconds in background, and five failures log out.
  - D5. Contact us and reminder screens are dropped. Feedback stays on the REST API, in CS-17. Delete account stays, because both stores require it.
  - D6. CI runs on GitHub Actions, and App Distribution covers Android only. iOS still builds unsigned in CI for the done check.

## Appendix D. Links and reading list

- Skelter source at `D:\my_project\skelter`, commit `21f8ba1`, Apache-2.0.
- CS-06, CS-07 and CS-09 get `pstack/skills/how/SKILL.md` before editing and `pstack/skills/interrogate/SKILL.md` before merge-ready, because they carry the security and concurrency weight.
- The decision trail follows `pstack/skills/show-me-your-work/SKILL.md` and lives in `spec/decisions.md`.

## Appendix E. Skelter coupling inventory

Paths are under `D:\my_project\skelter`. Each row is a place tied to the old app and the PR that handles it. Nothing here is copied unless a PR ports it.

| Coupling | Where | Handled by |
|---|---|---|
| Package name `skelter` | `pubspec.yaml` line 1 and 444 Dart files with `package:skelter/` | Not ported, CS-14 renames Corestone |
| App ids `com.solguruz.skelter` | `android/app/build.gradle`, `project.pbxproj`, `lib/constants/constants.dart` line 5, patrol block in `pubspec.yaml` | CS-01, CS-13 |
| Apple team `R4HRZ34ZYE` | every config in `ios/Runner.xcodeproj/project.pbxproj` | Not ported |
| Native package path and battery channel | `MainActivity.kt`, `AppDelegate.swift`, `lib/utils/battery_util.dart` line 7 | Removed, D3 |
| App Links host `skelter.solz.me` | `AndroidManifest.xml` lines 51 to 55, `Runner.entitlements`, `product_detail_constants.dart` line 1 | CS-16 with a per-flavor host |
| Google Sign-In URL schemes | `ios/Runner/Info.plist` lines 32, 40, 48 | Removed, D1 |
| Sign in with Apple entitlement | `ios/Runner/Runner.entitlements` | Removed, D1 |
| Firebase Auth and Google sign-in | `initialize_app.dart`, `main.dart` lines 90 to 96, `injection_container.dart` lines 67 to 82, `services/firebase_auth_services.dart`, login, signup, verify_email blocs | CS-07, CS-08 |
| Firestore and chat users | `injection_container.dart` lines 152 to 174, `signup_bloc.dart` line 10, `delete_account_bloc.dart` line 5 | Removed, feedback moves to REST in CS-17 |
| Gemini AI | `initialize_app.dart` lines 65 to 79, `services/ai/`, `presentation/ai_chat` | Removed |
| Crashlytics, Performance, Remote Config | `initialize_app.dart` lines 44 to 71, `injection_container.dart` lines 128 to 150, `PerformanceMonitoringService` in eight blocs, `initial_screen.dart` lines 37 to 62 | Removed |
| Analytics declared but unused | `pubspec.yaml` line 21 | Removed |
| Clarity analytics | `main.dart`, `core/clarity_analytics/`, about 20 widgets | Removed, D3 |
| RevenueCat | `services/subscription_service.dart`, `main.dart`, `constants.dart` lines 91 to 93, billing permission and dependency | Removed |
| E-commerce | 15 presentation folders, `home/` product data, `injection_container.dart` lines 101 to 142, `demo_dependencies.dart`, notification tap in `main.dart` lines 147 to 164, deep link manager lines 81 to 185 | Removed, home shell rebuilt in CS-02 |
| Plain-text session | `login_bloc.dart` line 703, `signup_bloc.dart` line 446, `verify_email_bloc.dart` lines 90 to 98 | CS-07 |
| 401 handler wipes all prefs | `injection_container.dart` line 220 | CS-07 |
| Cert pin throws when the hash is missing | `injection_container.dart` lines 239 to 257 | CS-06 |
| Cache defaults to `forceCache` | `utils/cache_manager.dart` | CS-06 |
| DI imports `main.dart` | `injection_container.dart` | CS-02 |
| Biometric exits the app on failure | `initial_screen.dart` line 132 | CS-10 |
| No lock on resume | `flutter_fgbg` used only in `verify_email_screen.dart` line 101 | CS-09 |
| Material 2 theme with no ColorScheme | `widgets/styling/app_theme_data.dart` | CS-03 |
| Wrong font weight mapping | `pubspec.yaml` fonts block | CS-03 |
| Strings naming Skelter | `i18n/app_localizations_en.dart` lines 876, 879, 1093, 1097 | CS-04 writes new ARB files |
| Branding images | `assets/images/sg_skelter_logo.png`, `sg_skelter_boilerplate.png`, `ios/Runner/diwali@2x.png` | Not ported |
| Mic, speech and Bluetooth permissions | `AndroidManifest.xml` lines 4 to 7, `Info.plist` lines 56 to 59, Podfile macros | Not ported |
| CI tied to SolGuruz | `.github/workflows/main.yml` with `sonarqube.solz.me`, Flutter 3.41.9, no App Distribution step | CS-00, CS-15 |
| Release signed with the debug key | `android/app/build.gradle` | CS-15 |
| Tests tied to removed features | about 36 test files and 18 Firebase Auth test files, three Patrol tests | Not ported, CS-13 writes new flows |
| SolGuruz contact and branding in docs | `CODE_OF_CONDUCT.md` line 58, `README.md`, `CONTRIBUTING.md` | CS-00 writes new docs and `NOTICE` |

## Appendix F. Execution record

The program finished on 2026-11-05 at main `437662a`. Every PR below was merged by the operator. The done criterion was amended by the operator to analyze, test and an Android build of a generated project, checked by `tool/template_smoke.sh`, which passed 8 of 8 steps in 119 s on main. iOS was skipped and stays unverified.

| Plan id | PR | What landed |
|---|---|---|
| CS-00 | #1 | License, NOTICE, lints, lane scripts |
| CS-01 | #2 | dev, stage and prod flavors on both platforms |
| CS-02 | #3 | Core shell with GetIt, AutoRoute and Prefs |
| CI change | #4 | PR CI cut to analyze and test |
| CS-03 | #5 | Material 3 theme |
| CS-04 | #6 | English and Thai, Noto Sans Thai fallback, golden tool |
| CS-05 | #7, #10 | Responsive layout. #8 reverted it by mistake and #10 restored it |
| CS-06 | #9 | ApiClient, sealed failures, pinning, mock server |
| CS-07 | #11 | Secure session with single-flight token refresh |
| CS-08 | #12 | Login, sign-out, account deletion, demo mode, reinstall wipe |
| CS-09 | #13 | App PIN lock |
| CS-10 | #14 | Biometric shortcut |
| CS-11 | #15 | Optional FCM |
| CS-12 | #16 | System pages and offline banner |
| CS-16 | #17 | Deep links behind session and lock |
| CS-17 | #18 | Feedback on the REST API |
| CS-13 | #19 | Patrol end-to-end suite |
| CS-14 | #20 | Project generator |
| CS-15 | #21 | Release signing, template smoke check, disabled distribution workflow |

Changes from this plan, in order of impact.

- GitHub CI was turned off by the operator. Every verification ran locally, and the ten-lane swarm, perf probes and review videos were run only where a brief asked for them.
- iOS was never built. `spec/open-items.md` lists everything that depends on it.
- The template-smoke CI job became the local script `tool/template_smoke.sh`.
- Stacked PRs caused two merge mistakes, a stale base on #2 and the accidental revert in #8. After #9 the program branched each PR from main.
- Lanes moved from Pixel_5 to Pixel_10_Pro after a biometric lane locked Pixel_5.

`spec/decisions.md` holds the decisions and `spec/open-items.md` the unfinished and unproven items.
