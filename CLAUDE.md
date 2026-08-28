# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A minimal, opinionated Flutter boilerplate: one runnable app
(`app/`), one shared foundation package (`packages/core`), one example
feature package (`packages/notes`) meant to be copied for new features.
Mobile only (iOS + Android) — no web/desktop config. Several pieces are
deliberately stubbed, not production-ready — see "Stubs" below.

Dart/Flutter SDK: `^3.13.0` (Flutter 3.47.0 / Dart 3.13.0).

## Commands

This is a Dart **pub workspace** (root `pubspec.yaml` has a `workspace:`
list and each package has `resolution: workspace`) — a single shared
dependency resolution across `app` + `packages/*`.

```
dart pub get                      # from repo root: resolves + links every workspace package
tool/workspace.sh analyze         # flutter analyze in every package
tool/workspace.sh format          # dart format --set-exit-if-changed everywhere
tool/workspace.sh test            # flutter test in every package with a test/ dir
tool/workspace.sh build_runner    # freezed/json_serializable/drift codegen where needed
```

Or per-package, from `app/`, `packages/core/`, or `packages/notes/`:

```
flutter analyze
flutter test                                              # whole package
flutter test test/cubit/notes_cubit_test.dart              # single file
flutter test test/cubit/notes_cubit_test.dart --plain-name "some test name"
dart run build_runner build --delete-conflicting-outputs
```

Generated files (`*.freezed.dart`, `*.g.dart`, l10n output) are
gitignored — never hand-edit them; re-run `build_runner`/`gen-l10n`.

Run a flavor from `app/`:

```
flutter run --flavor dev     -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor prod    -t lib/main_prod.dart
```

`flutter run` with no args defaults to dev via `lib/main.dart`. Flavor
identity (bundle id / app name) lives in `app/flavorizr.yaml`, generated
into native Android Gradle/iOS xcconfig by `flutter_flavorizr` — after
editing `flavorizr.yaml`, regenerate with
`flutter pub run flutter_flavorizr -f` from `app/` rather than
hand-editing the generated native files.

`tool/rename_app.sh "New Name" com.acme.newapp` — replaces the
placeholder display name/bundle id across flavorizr, Android, iOS.

`tool/new_feature.sh <plural>` — scaffolds `packages/<plural>` from
`packages/notes` and wires it into `app/lib/bootstrap.dart` and
`app/lib/router/app_router.dart` at the `// GENERATOR:` marker
comments. It prints required manual follow-up (path dependency, Drift
table, route constant) — the generated package won't analyze clean
until that's done. Singular is derived by naively stripping a trailing
`s`; irregular plurals need a manual fix.

## Architecture

**Package boundary rule:** only `core` may be depended on by a feature
package. Feature packages never depend on each other; `core` never
depends on a feature package.

**Feature package shape** (`packages/notes` is the template — copy it,
don't build from scratch):

```
lib/<feature>.dart                            # barrel export = public API
lib/src/entity/<thing>.dart                   # freezed + json_serializable model
lib/src/repository/<feature>_repository.dart       # abstract interface — cubits are tested against this
lib/src/repository/<feature>_repository_impl.dart  # real impl, backed by core's AppDatabase (Drift)
lib/src/cubit/<feature>_cubit.dart / _state.dart    # freezed sealed states
lib/src/di/<feature>_dependencies.dart        # register<Feature>Dependencies(GetIt)
lib/src/routing/<feature>_routes.dart         # this feature's StatefulShellBranch/GoRoute list
lib/src/view/*.dart
test/cubit/..., test/view/...                 # bloc_test+mocktail against the repository interface, widget test with mocked cubit
```

**Wiring a feature into the app** happens in exactly two places, both
app-owned and both with `// GENERATOR:` markers `new_feature.sh` edits:
`app/lib/bootstrap.dart` (calls `register<Feature>Dependencies(getIt)`)
and `app/lib/router/app_router.dart` (adds a `StatefulShellBranch` to
the bottom-nav shell). A feature's own cubit is *not* registered in
DI — it's created per-screen via `BlocProvider` in the view layer.

**DI:** plain `get_it` registration functions per package (`core`'s
`registerCoreDependencies`, each feature's `register<Feature>Dependencies`),
not `injectable` codegen. `getIt` is `core`'s single global
`GetIt.instance`.

**Routing:** one `go_router` instance (`buildAppRouter`, built in
`bootstrap.dart` after DI is wired) with a `redirect` driven by
`AuthCubit`'s state (`AuthUnknown` → splash, `AuthUnauthenticated` →
login, `AuthAuthenticated` → out of splash/login) via
`GoRouterRefreshStream`. Authenticated routes live inside a
`StatefulShellRoute.indexedStack` (the bottom-nav shell,
`AppShellScaffold` in `core`); each feature contributes one branch.

**Storage** — four backends wired independently in `core`, pick per
project which of Hive/Drift you actually need:
`flutter_secure_storage` (secrets), `shared_preferences` (flags/prefs
via `PreferencesService`), `hive` (generic KV via `HiveService`),
`drift` (relational — `AppDatabase`, what feature repositories
actually query against).

**State/models:** `freezed` (sealed unions for cubit state, e.g.
`AuthUnknown`/`AuthUnauthenticated`/`AuthAuthenticated`) +
`json_serializable` for entities.

**Startup sequence:** each `main_<flavor>.dart` builds an `EnvConfig`
(flavor name, `baseUrl`, `SecurityConfig`) and calls `bootstrap()`,
which runs everything inside `runZonedGuarded` so uncaught errors reach
`ErrorReporter` — register core deps → register feature deps → build
the router → `runApp`.

## Stubs — not real, don't treat as working

These are marked `// ponytail: <ceiling>, <upgrade path>` in the code;
know about them before assuming behavior they don't have:

- `FakeAuthRepository` (`app/lib/auth/auth_repository.dart`) — accepts
  any non-empty email/password, no real backend.
- `SecurityConfig` (`packages/core`) — `sslPinningEnabled` and
  `rootDetectionEnabled` both default `false`; `DioClient` has a pinning
  hook point but no actual certificate check, and no root/jailbreak
  detection package is included.
- `NoopErrorReporter` (`packages/core`) — the default `ErrorReporter`
  does nothing; `core` deliberately avoids depending on
  Crashlytics/Sentry.
- `EnvConfig.baseUrl` values (`main_dev.dart` etc.) are placeholder
  URLs, not real APIs.

## Localization

Only `en` ships. Adding a locale: create
`app/lib/l10n/app_<locale>.arb` with the same keys as `app_en.arb`,
then run `flutter gen-l10n` (or `tool/workspace.sh build_runner`) —
`supportedLocales` is generated from whichever `.arb` files are
present.
