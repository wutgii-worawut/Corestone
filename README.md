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

The dev flavor talks to the local mock API. Start it first with
`dart run tool/mock_api/server.dart`, then sign in as `demo@corestone.dev` with
the password `demo-password`.

To run with no backend at all, add `--dart-define=DEMO_MODE=true` to a dev build.
Sign-in, sign-out and account deletion then go to an in-memory fake, and any
well-formed email and password sign in. Stage and prod refuse to start with it.

```sh
fvm flutter run --flavor dev --dart-define-from-file=config/dev.json --dart-define=DEMO_MODE=true
```

## Push notifications

Push uses Firebase Cloud Messaging and is off until a flavor has Firebase config
files. With none, every flavor builds and runs, and the app logs
`push off: no Firebase config for <flavor>`. No other Firebase product is used.

To turn push on for a flavor:

1. In the Firebase console, add an Android app with the flavor's application id
   (`com.wutstack.corestone.dev`, `.stage`, or no suffix for prod) and an iOS app
   with the bundle id from `ios/Flutter/<Config>-<flavor>.xcconfig`.
2. Put `google-services.json` at `android/app/src/<flavor>/` and
   `GoogleService-Info.plist` at `ios/config/<flavor>/`. Both are gitignored, so
   never commit them. In CI, store each file base64-encoded in the secrets
   `GOOGLE_SERVICES_JSON_<FLAVOR>` and `GOOGLE_SERVICE_INFO_PLIST_<FLAVOR>` and
   run `tool/firebase_config.sh` before the build.
3. For iOS, enable the Push Notifications capability for the App ID in your Apple
   team, upload an APNs auth key to the Firebase project, and set your
   `DEVELOPMENT_TEAM`. `ios/Runner/Runner.entitlements` already asks for
   `aps-environment`.

The app asks for notification permission after sign in, registers the token with
`POST /devices`, re-registers on token refresh, and sends `DELETE /devices` on sign
out. Tapping a notification opens the app to Home.

## Verification lanes

`tool/lanes/android.sh` and `tool/lanes/ios.sh` drive the app on an emulator or a
simulator and save screenshots. Reviewers and agents use them to check each change
on a real device.

```sh
tool/lanes/android.sh launch dev
tool/lanes/android.sh shot home.png
```

## Localization

Strings live in `lib/l10n/app_en.arb` (template) and `lib/l10n/app_th.arb`.
`flutter pub get` regenerates `AppLocalizations`. Read strings with `context.l10n`.
Add a key to every ARB file: `test/l10n/untranslated_test.dart` fails when any
locale misses one.

## Goldens

Golden tests carry the `golden` tag. Each has a platform golden for local runs
and a CI golden that must be rendered on Linux to match the ubuntu runner.
`tool/update_goldens.sh` regenerates both. On Windows it renders the CI goldens
inside WSL Ubuntu, which needs Flutter 3.47.9 at `~/flutter-3.47.9`
(override with `WSL_FLUTTER`).

```sh
tool/update_goldens.sh          # platform goldens, then CI goldens
tool/update_goldens.sh ci       # CI goldens only
tool/update_goldens.sh verify   # run the golden tests as CI does
```

## Plan

`spec/template-plan.md` lists the PRs that build the template, in order.

## CI

Pull requests run `analyze` and `test` only (`.github/workflows/ci.yml`).
Android and iOS builds live in `.github/workflows/build.yml` and run only when
started by hand: `gh workflow run build.yml --ref <branch>`.
