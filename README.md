# Corestone

Corestone is the company Flutter template for new Android and iOS apps.
It ports the kept parts of [Skelter by SolGuruz](https://github.com/solguruz/skelter)
into a fresh Flutter scaffold. See `NOTICE` for attribution.

## Requirements

- [FVM](https://fvm.app) with Flutter 3.47.9 (`fvm install` reads `.fvmrc`).
- Android Studio with an emulator for Android work.
- A Mac with Xcode for local iOS work. Without one, CI builds iOS on a macOS runner.

## Daily commands

```sh
fvm flutter pub get
fvm flutter analyze
fvm flutter test
fvm flutter run --flavor dev --dart-define-from-file=config/dev.json
```

## Verification lanes

`tool/lanes/android.sh` and `tool/lanes/ios.sh` drive the app on an emulator or a
simulator and save screenshots. Reviewers and agents use them to check each change
on a real device.

```sh
tool/lanes/android.sh launch dev
tool/lanes/android.sh shot home.png
```

## Plan

`spec/template-plan.md` lists the PRs that build the template, in order.

## CI

Pull requests run `analyze` and `test` only (`.github/workflows/ci.yml`).
Android and iOS builds live in `.github/workflows/build.yml` and run only when
started by hand: `gh workflow run build.yml --ref <branch>`.
