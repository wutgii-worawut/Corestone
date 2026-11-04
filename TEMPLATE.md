# Start a new app from Corestone

Corestone is the company Flutter template for Android and iOS. One command
renames it to your app, so nobody edits identifiers by hand.

## Create the app

1. Create a repository from the template. On GitHub, use "Use this template",
   or clone it and point `origin` at your new repository.
2. In a clean checkout, rename it:

   ```sh
   fvm dart run tool/new_project.dart --name acme_app --org com.acme --display-name "Acme"
   ```

   The generator refuses a dirty git tree, so every change it makes shows up
   in one diff you can review or throw away. It prints each changed, moved
   and removed file.
   After renaming, it runs `dart pub get` and
   `dart fix --apply --code=directives_ordering`, because the new package
   name changes the import order the lints require.
3. Check the app:

   ```sh
   fvm dart run build_runner build --delete-conflicting-outputs
   fvm flutter gen-l10n
   fvm flutter analyze
   fvm flutter test
   fvm flutter build apk --debug --flavor dev --dart-define-from-file=config/dev.json
   ```

   `build_runner` and `gen-l10n` only matter once you add annotated code or
   change `.arb` files. The committed generated files already use the new
   name.
4. Commit. Running the generator again with the same identity reports
   `no changes`.

## The identity

| Flag | Rule | Example |
| --- | --- | --- |
| `--name` | Dart package name: lower_snake_case, a letter first, single underscores, no trailing underscore | `acme_app` |
| `--org` | Reverse-DNS, two or more segments, each a lowercase letter then lowercase letters or digits | `com.acme` |
| `--display-name` | Letters, digits, spaces, dots and hyphens; starts with a letter or digit | `Acme` |

Dart reserved words, Java and Kotlin keywords, `flutter`, `test` and `patrol`
are rejected, because the name and each org segment become a Dart package and
a Kotlin package. Names containing `corestone` or `wutstack` are rejected too.

Every platform id comes from those three values:

| Value | Rule | Example |
| --- | --- | --- |
| Android `applicationId`, namespace and Kotlin package | `<org>.<name>` | `com.acme.acme_app` |
| iOS bundle id | `<org>.<name in camelCase>`, since iOS bundle ids allow no underscore. This matches `flutter create`. | `com.acme.acmeApp` |
| Flavor suffix | `.dev` and `.stage`, none for prod, on both platforms | `com.acme.acme_app.dev` |
| Launcher names | `<display> Dev`, `<display> Stage`, `<display>` | `Acme Dev` |
| Demo email domain and custom URI scheme in tests | `<name>` with `-` for `_` | `demo@acme-app.dev` |

## What the generator changes

`tool/new_project.dart` holds one table of rules, each a set of file globs and
a from/to pair. It rewrites the pubspec `name:` and `patrol:` block, every
`package:corestone/` import, the Android namespace, `applicationId` and
launcher names, the Kotlin and Java package declarations, every iOS
`PRODUCT_BUNDLE_IDENTIFIER` and `APP_DISPLAY_NAME`, `CFBundleName`, the app
title and the test expectations that name the app. It moves
`MainActivity.kt` and `MainActivityTest.java` to the new package directory and
removes `spec/template-plan.md`, the template's own build plan.

It also removes `tool/template_smoke.sh`, the template's done check.
It leaves `NOTICE`, `LICENSE`, this file and the generator with its test as
they are. Those are the only files where `corestone` or `wutstack` may stay:

```sh
git grep -n -i -e corestone -e wutstack
```

## What the owner still does by hand

- Firebase. Register Android apps for `<applicationId>.dev`, `.stage` and the
  prod id, and iOS apps for the matching bundle ids. Supply the config files
  per flavor with `tool/firebase_config.sh`. They stay out of git. See
  README "Push notifications".
- Deep links. Set `DEEP_LINK_HOST` and `CERT_SHA256` in `config/*.json`, then
  host `assetlinks.json` for the Android ids and the
  `apple-app-site-association` file for `<TeamID>.<bundle id>`, as the README
  describes.
- Signing. Add an Android release keystore, as "Release signing" below
  describes. Until then release builds sign with the debug key.
- Apple. Set your development team in Xcode, register the bundle ids, and
  enable Push Notifications and Associated Domains for each App ID.
- The README. It still describes the template, and its Plan section points
  at the removed plan. Rewrite it for your app.

## Release signing

`android/app/build.gradle.kts` signs release builds with the key that
`android/key.properties` names. Without that file, release builds sign with
the debug key and Gradle prints a warning, so local and template builds still
work. Never commit the keystore or `key.properties`; `.gitignore` already
excludes `key.properties`, `*.jks` and `*.keystore`.

Create an upload keystore once, outside the repository, and keep it and its
passwords in your password manager:

```sh
keytool -genkey -v -keystore ~/upload-keystore.jks -storetype JKS   -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then write `android/key.properties`. A relative `storeFile` resolves against
`android/app/`:

```properties
storePassword=<keystore password>
keyPassword=<key password>
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

Check the signature with `apksigner verify --print-certs` from the Android SDK
build-tools on `build/app/outputs/flutter-apk/app-prod-release.apk`.

## App Distribution

`.github/workflows/distribute.yml` builds a signed release APK for one flavor
and uploads it to Firebase App Distribution. It runs only when started by
hand, and the template keeps it disabled. To use it, add these repository
secrets, run `gh workflow enable distribute.yml`, then
`gh workflow run distribute.yml -f flavor=dev -f testers=<group alias>`.

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | The upload keystore, base64-encoded |
| `ANDROID_KEYSTORE_PASSWORD` | Its store password |
| `ANDROID_KEY_ALIAS` | Its key alias |
| `ANDROID_KEY_PASSWORD` | Its key password |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | A service account key with the Firebase App Distribution Admin role |
| `FIREBASE_APP_ID_ANDROID_DEV`, `_STAGE`, `_PROD` | Each flavor's Firebase Android app id, `1:<number>:android:<hash>` |
| `GOOGLE_SERVICES_JSON_DEV`, `_STAGE`, `_PROD` | Each flavor's `google-services.json`, base64-encoded, as `tool/firebase_config.sh` reads them |

Only the secrets for the flavor you distribute need values.

## Template done check

`tool/template_smoke.sh` is the template's done check. It copies the checkout
(HEAD plus uncommitted edits to tracked files) to a temp directory, renames it
to `acme_app`, checks no template identity is left, then runs `pub get`,
`analyze`, `test`, a debug dev APK build and a release prod APK build. It
prints a PASS or FAIL line per step with timings and exits non-zero on any
failure. Run it from Git Bash on Windows, or a shell on macOS or Linux.
GitHub CI is disabled for now, so this local run is the evidence. iOS is not
built anywhere yet and stays unverified.
