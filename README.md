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
Sign-in, sign-out, account deletion and feedback then go to an in-memory fake,
and any well-formed email and password sign in. Stage and prod refuse to start
with it.

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
out. Tapping a notification opens its `link` data field as a deep link, or Home
when it has none.

## Deep links

`https://<DEEP_LINK_HOST>/<path>` opens a screen. Each flavor has its own host,
set in three places that `test/core/deep_link/deep_link_host_test.dart` keeps
equal: `DEEP_LINK_HOST` in `config/<flavor>.json`, `deepLinkHost` in the
flavor's block of `android/app/build.gradle.kts`, and `DEEP_LINK_HOST` in
`ios/Flutter/<Config>-<flavor>.xcconfig`. The template ships placeholders
(`dev.links.example.com`, `stage.links.example.com`, `links.example.com`).

| Path | Opens |
| --- | --- |
| `/`, `/home` | Home |
| `/settings` | Settings |
| `/settings/theme` | Theme, over Settings |
| `/settings/language` | Language, over Settings |
| anything else on the host | Home |

Links for another host or scheme, http included, are ignored. A link opens only
after sign in and the PIN lock: one that arrives signed out waits through login
and PIN setup, one that arrives locked waits for unlock. Only the newest waiting
link opens, and signing out drops it. To make a screen linkable, add it to
`lib/core/deep_link/deep_link_routes.dart`.

For the OS to send links to the app instead of the browser, the owner of each
host must serve, over https with no redirect:

1. `https://<host>/.well-known/assetlinks.json`, listing the flavor's
   application id and the SHA-256 fingerprint of its signing certificate (the
   Play App Signing key for Play builds). Check it with
   `adb shell pm get-app-links <application id>`.
2. `https://<host>/.well-known/apple-app-site-association`, JSON with no
   extension, with an `applinks` entry for `<TeamID>.<bundle id>`. Also enable
   the Associated Domains capability for the App ID in your Apple team.
   `ios/Runner/Runner.entitlements` already asks for `applinks:$(DEEP_LINK_HOST)`.

Until then, test on Android by naming the package, which skips verification:
`adb shell am start -a android.intent.action.VIEW -d "https://dev.links.example.com/settings" com.wutstack.corestone.dev`.

## Verification lanes

`tool/lanes/android.sh` and `tool/lanes/ios.sh` drive the app on an emulator or a
simulator and save screenshots. Reviewers and agents use them to check each change
on a real device.

```sh
tool/lanes/android.sh launch dev
tool/lanes/android.sh shot home.png
```

## End-to-end tests (Patrol)

`integration_test/app_test.dart` drives the real app on an Android device with
[Patrol](https://patrol.leancode.co): sign in and set a PIN, the 30 s background
lock and unlock, five wrong PINs signing out, Thai and dark theme, feedback, a
deep link held behind the lock, and sign-out keeping theme and language. Each
test starts from cleared app data and needs the device language set to English.

```sh
fvm dart pub global activate patrol_cli          # once
ANDROID_SERIAL=emulator-5554 tool/run_patrol.sh  # starts and stops the mock API
```

`tool/run_patrol.sh` starts `tool/mock_api/server.dart`, runs `patrol test` on the
dev flavor with `config/dev.json`, stops the server and exits non-zero when a test
fails. Run one file with `tool/run_patrol.sh integration_test/<file>_test.dart`. A
test fails at once with a clear message when the mock API is not reachable. The
two lock tests wait out the real background timeout, so the suite takes a few
minutes.

iOS is not wired yet: it needs a `RunnerUITests` UI test target, which is made in
Xcode on a Mac. Follow "iOS setup" in the Patrol docs: add the target, give it a
`RunnerUITests.m` with `PATROL_INTEGRATION_TEST_IOS_RUNNER(RunnerUITests)`, add
`pod 'patrol'` (or the Swift package) to it, and add the target to the test
action of the existing `dev` scheme. Then run `patrol test --flavor dev` on a
simulator.

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
