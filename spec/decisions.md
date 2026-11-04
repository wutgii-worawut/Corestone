# Decisions

The product and process decisions Corestone follows. The operator made each
one on 2026-11-04 or 2026-11-05. Change a decision here first, then the code.

## Product

| Id | Decision | Where it lives |
|---|---|---|
| Strategy | Port the kept parts of Skelter into a fresh Flutter scaffold, rather than strip Skelter in place. | Whole repo; NOTICE credits Skelter (Apache-2.0). |
| D1 | REST auth with access and refresh tokens, email and password only. No phone OTP, Google or Apple sign-in. | `lib/features/auth/`, `lib/core/network/auth_interceptor.dart` |
| D2 | Three flavors: dev, stage, prod. | `android/app/build.gradle.kts`, iOS build configs, `config/*.json` |
| D3 | Removed: Clarity, RevenueCat, dynamic icons, battery channel, speech, rate-my-app, liquid glass, app tour, demo product data, every Firebase product except FCM. Kept: deep links, without product routes. | `lib/core/deep_link/` |
| D4 | Six-digit app PIN. Locks on cold start and after 30 s in the background. Five wrong PINs sign out. | `lib/features/app_lock/` |
| D5 | Feedback stays, sent with `POST /feedback`. Contact us and reminder screens dropped. Delete account kept, because both stores require it. | `lib/features/feedback/`, `lib/features/settings/` |
| D6 | App Distribution for Android only, as a manual workflow that stays disabled. | `.github/workflows/distribute.yml` |
| Done | The template is done when a generated project passes analyze, test and an Android build (`tool/template_smoke.sh`). iOS is skipped for now. | `tool/template_smoke.sh` |

## Process

| Decision | Detail |
|---|---|
| The operator merges | Agents open PRs and stop. They never merge, force-push or change a PR base. |
| Stacked PRs are allowed | The operator retargets bases to `main`. Deleting a merged branch makes GitHub retarget the next PR. |
| No GitHub CI | `ci`, `build` and `distribute` are disabled because they slowed work. Verify locally: `fvm flutter analyze`, `fvm flutter test`, `tool/update_goldens.sh verify`, emulator lanes, `tool/run_patrol.sh`, `tool/template_smoke.sh`. |
| No platform builds on GitHub | Not even the manual `build.yml`, unless the operator asks. |
| Emulators belong to the operator | Use Pixel_10_Pro. Do not touch Pixel_5. Never guess a device PIN or fingerprint. After one failed device-auth attempt, stop and ask. |
| Do not use the host clipboard | Lanes type text with adb or set it in code. |
| Mock server | Run it with `fvm dart tool/mock_api/server.dart`, because `dart run` fails a native-assets check here. Stop only the process you started; `/__mock/quit` stops it cleanly. |
