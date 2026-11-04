# Open items

What Corestone has not done or not proven, as of 2026-11-05 (main `437662a`).
Nothing on this list has been started. Each item says why it matters and what
closes it.

## Not proven

| Item | Why it matters | What closes it |
|---|---|---|
| iOS build and run | No iOS build has run since CI was turned off. The flavors, SwiftPM setup, entitlements, the Firebase plist copy phase, Face ID text and `applinks` are only checked by grep. | Build and run on a Mac (`flutter build ios --flavor dev --no-codesign`, then a simulator run), or enable `build.yml` once and dispatch it. |
| iOS Keychain wipe on reinstall | CS-08 clears SecureStore on the first launch after install, because iOS Keychain survives uninstall. Android deletes app data anyway, so the lane never exercised it. | On an iOS device: sign in, set a PIN, delete the app, reinstall. It must open on login. |
| iOS lifecycle, app switcher cover, Face ID | The PIN lock, its blank app-switcher cover and the biometric shortcut were proven on Android only. | Run the CS-09 and CS-10 lanes on iOS. |
| Push delivery | No Firebase project exists, so no real token was registered and no message was delivered. | Steps 1 to 4 in README "Push notifications", then send a test message. |
| App Distribution | `distribute.yml` has never run. | Create the Firebase project and secrets listed in TEMPLATE.md, enable the workflow, dispatch it once. |
| App Links and Universal Links | Hosts in `config/*.json` are placeholders, so links never verify. Lanes sent links straight to the app. | Host `assetlinks.json` and `apple-app-site-association` on a real domain and set `DEEP_LINK_HOST`. |
| Real backend | Every flow ran against `tool/mock_api/server.dart` or demo mode. | Point `API_BASE_URL` at the real API and rerun the auth, feedback and device-registration lanes. |
| Real-device performance | PIN unlock was 337 ms median on an x86 emulator (budget 400 ms). PBKDF2 uses 150k iterations. | Measure on a low-end Android phone and on iOS; lower the iterations only if the budget fails. |
| Android 7 and 8 biometric prompt | `local_auth` may need an AppCompat launch theme below Android 9. `styles.xml` still uses `@android:style/Theme.Light.NoTitleBar`. minSdk is 24. | Test on an API 24 to 27 emulator, then either switch to an AppCompat theme or raise minSdk (a product decision). |
| Patrol on iOS | `RunnerUITests` needs an Xcode target. | Create it on a Mac as README "End-to-end tests" describes. |

## Not done

| Item | Note |
|---|---|
| GitHub CI | `ci`, `build` and `distribute` are disabled at the operator's request. Re-enable with `gh workflow enable <file>`. |
| "Template repository" setting | Needed for GitHub's "Use this template" button. Repo settings, admin only. |
| Offline banner debounce | The banner can flicker while the phone switches between Wi-Fi and mobile data. |
| Background data-message handler | Push has no handler for data-only messages while the app is in the background. |
| Cancelled-request failure | `error_mapper.dart` has a `shortcut:` note. Nothing cancels requests yet. |
| Keystore passwords with `\` | They break `key.properties`. Not documented in TEMPLATE.md. |
| `kotlin.incremental=false` | In `android/gradle.properties` as a workaround for this Windows machine (pub cache on C:, project on D:). It slows Kotlin builds for every app made from the template. The operator has not decided whether to move it to `~/.gradle/gradle.properties`. |
| Debug-only Settings rows | "Throw test error" and "Call /me" show only in debug builds. Generated apps may want to remove them. |
| Pixel_5 emulator | Locked by its device credential after a biometric lane. The operator unlocks it. |

## Find the remaining shortcuts

`grep -rn "shortcut:" lib tool test integration_test` lists every known limit
the code marks in place.
