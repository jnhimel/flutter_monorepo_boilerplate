# Contributing

## Layout & naming conventions

This is a Dart [pub workspace](https://dart.dev/tools/pub/workspaces) monorepo:

```
app/                    # the runnable Flutter app (mobile only: iOS + Android)
packages/
  core/                 # shared foundation: theme, widgets, network, storage, DI, routing base
  notes/                # the one example feature package — copy this for new features
```

A feature package mirrors `packages/notes`' internal layout:

```
lib/
  <feature>.dart                       # barrel export — this is the package's public API
  src/
    entity/<thing>.dart                # freezed + json_serializable model(s)
    repository/<feature>_repository.dart       # abstract interface (this is what cubits are tested against)
    repository/<feature>_repository_impl.dart  # real implementation, backed by core's AppDatabase
    cubit/<feature>_cubit.dart
    cubit/<feature>_state.dart         # freezed sealed states
    di/<feature>_dependencies.dart     # register<Feature>Dependencies(GetIt getIt)
    routing/<feature>_routes.dart      # this feature's StatefulShellBranch/GoRoute list
    view/<feature>_list_page.dart
    view/<thing>_detail_page.dart
test/
  cubit/<feature>_cubit_test.dart      # bloc_test + mocktail against the repository interface
  view/<feature>_list_page_test.dart   # widget test with a mocked cubit
```

Only `core` may be a dependency of a feature package. Feature packages don't
depend on each other, and `core` never depends on a feature package.

## Running things locally

All from the repo root:

```
dart pub get                    # resolves + links every workspace package
tool/workspace.sh analyze       # flutter analyze in every package
tool/workspace.sh format        # dart format --set-exit-if-changed everywhere
tool/workspace.sh test          # flutter test in every package that has a test/ dir
tool/workspace.sh build_runner  # codegen (freezed/json_serializable/drift) where needed
```

Or per-package with plain `flutter analyze` / `flutter test` / `dart run
build_runner build --delete-conflicting-outputs` from inside `app/`,
`packages/core/`, or `packages/notes/`.

## Adding a feature package

```
tool/new_feature.sh todos
```

This copies `packages/notes`, renames `notes`→`todos`/`Notes`→`Todos`
(and the singular `note`→`todo`/`Note`→`Todo`), and wires
`registerTodosDependencies` and `todosShellBranch` into `app/lib/bootstrap.dart`
and `app/lib/router/app_router.dart` at their `// GENERATOR:` marker
comments. It prints the remaining manual steps (add the path dependency in
`app/pubspec.yaml`, give the feature its own Drift table in `packages/core`
if it needs one, add a route-path constant, run `dart pub get` and
`build_runner`) — read them, the new package won't analyze clean until
you've done them.

## PR expectations

- Tests for anything with a branch: cubits, repositories, non-trivial
  widgets. See `packages/notes/test/` for the pattern (TDD against the
  repository interface, not against Drift directly).
- `tool/workspace.sh analyze` and `tool/workspace.sh test` clean before
  requesting review.
- Generated files (`*.freezed.dart`, `*.g.dart`, l10n output) are gitignored
  — don't hand-edit or commit them; re-run `build_runner`/`gen-l10n` instead.
