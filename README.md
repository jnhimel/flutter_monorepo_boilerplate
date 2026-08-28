# flutter_monorepo_boilerplate

A minimal, opinionated Flutter starting point: one runnable app, one shared
foundation package, one example feature package — enough working plumbing to
delete and replace per project, not a framework to learn.

Mobile only (iOS + Android). No web/desktop config.

## Stack

- **State management:** `flutter_bloc` (Cubit)
- **DI:** `get_it`, manual registration functions (no codegen)
- **Routing:** `go_router`, `StatefulShellRoute.indexedStack` bottom-nav shell
- **Network:** `dio`, typed exception hierarchy
- **Storage:** `flutter_secure_storage` (secrets), `shared_preferences` (flags),
  `hive` (generic key-value), `drift` (real relational queries) — all four
  wired independently; pick which of Hive/Drift you actually need per project
- **Models/state:** `freezed` + `json_serializable`
- **Flavors:** `flutter_flavorizr` — `dev` / `staging` / `prod`
- **i18n:** `flutter_localizations` + `intl`, one locale (`en`) shipped

## Layout

```
flutter_monorepo_boilerplate/
  pubspec.yaml                      # Dart pub workspace (workspace: list)
  analysis_options.yaml             # shared flutter_lints include
  tool/
    rename_app.sh                   # rename bundle id / display name
    new_feature.sh                  # scaffold a new feature package
    workspace.sh                    # run analyze/format/test/build_runner across every package
  app/                              # the runnable Flutter app
  packages/
    core/                           # shared foundation, no feature knowledge
    notes/                          # the one example feature (generic CRUD notes)
```

See `CONTRIBUTING.md` for the feature-package layout convention and local
dev commands.

## Running a flavor

From `app/`:

```
flutter run --flavor dev     -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor prod    -t lib/main_prod.dart
```

`flutter run` with no arguments defaults to the dev flavor via `lib/main.dart`
(a thin convenience wrapper around `main_dev.dart`).

Flavor identity (bundle id / app name / applicationId per flavor) is
configured in `app/flavorizr.yaml` and was generated into the native Android
Gradle config and iOS xcconfig/schemes by `flutter_flavorizr`. Re-run
`flutter pub run flutter_flavorizr -f` from `app/` after editing
`flavorizr.yaml` to regenerate them, rather than hand-editing the generated
Gradle/xcconfig files directly.

## Renaming for a new project

```
tool/rename_app.sh "My New App" com.acme.mynewapp
```

Replaces the placeholder display name (`Boilerplate`) and bundle id
(`com.yourcompany.app`) across `flavorizr.yaml`, the Android Gradle files,
and the iOS project/xcconfig files. See the script for exactly what it
touches — it's a plain sed script, not a templating engine.

## Adding a feature

```
tool/new_feature.sh todos
```

Copies `packages/notes`'s structure into `packages/todos` with a
`notes`→`todos`/`Notes`→`Todos` substitution, and wires DI + routes into
`app/lib/bootstrap.dart` and `app/lib/router/app_router.dart` automatically.
It prints the remaining manual steps — read them; a package generated this
way won't `flutter analyze` clean until you give it its own Drift table and
route-path constant (see `CONTRIBUTING.md`).

## Adding another locale

Only `en` ships. To add one: create `app/lib/l10n/app_<locale>.arb` with the
same keys as `app_en.arb`, add the locale to `supportedLocales` (generated
automatically by `flutter gen-l10n` from the arb files present), and provide
translated values. Run `flutter gen-l10n` (or `tool/workspace.sh build_runner`) to
regenerate.

## What's a stub, not production-ready

This is a boilerplate — several pieces are intentionally unfinished
scaffolding, marked `// ponytail: <ceiling>, <upgrade path>` in the code:

- **`FakeAuthRepository`** (`app/lib/auth/auth_repository.dart`) — accepts
  any non-empty email/password after a fake delay. There is no real backend.
  Replace with an API-backed implementation before shipping.
- **`SecurityConfig`** (`packages/core`) — `sslPinningEnabled` and
  `rootDetectionEnabled` both default to `false`. `DioClient` has a hook
  point for pinning but no actual certificate check. No root/jailbreak
  detection package is included. Both are stub flags, not working security
  features — see the comments in `packages/core/lib/src/security/security_config.dart`
  and `packages/core/lib/src/network/dio_client.dart`.
- **`NoopErrorReporter`** (`packages/core`) — the default `ErrorReporter` does
  nothing. Wire a real Crashlytics/Sentry implementation per project; `core`
  deliberately doesn't depend on either SDK.
- **DI** is plain `get_it` registration functions per package, not
  `injectable` codegen — fine at boilerplate scale, revisit if registration
  count grows unwieldy.
- **`tool/new_feature.sh`**'s singular/plural substitution is a naive
  trailing-`s` strip (`todos` → `todo`); irregular plurals need a manual fix
  afterward.

## A note on tooling versions

Built against Flutter 3.47.0 / Dart 3.13.0. The workspace uses Dart's
native [pub workspaces](https://dart.dev/tools/pub/workspaces) — a single
shared dependency resolution across `app` + `packages/*`, declared via the
root `pubspec.yaml`'s `workspace:` list and each package's
`resolution: workspace`. `dart pub get` at the root handles linking, and
`tool/workspace.sh` covers running a command across every package.
`freezed` is unified on the stable `^4.0.0` line across every package —
no more per-package pre-release pinning.
