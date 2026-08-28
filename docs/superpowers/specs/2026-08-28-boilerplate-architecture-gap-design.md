# Boilerplate architecture gap analysis & target design

Date: 2026-08-28

## Context

This boilerplate (`flutter_monorepo_boilerplate`) was bootstrapped from
`FinTech-Internet-Banking`. A sibling project, `token_tap`, applies
clean-architecture layering more consistently than either the boilerplate
or FinTech. This spec identifies where the boilerplate's conventions fall
short and defines the target shape to bring it in line — using
`packages/notes` as the reference feature (everything here is what
`tool/new_feature.sh` scaffolds going forward) and `packages/core` as the
shared foundation.

Reference projects consulted:
- `/Users/bs01706/Documents/projects/flutter-projects/boilerplate/FinTech-Internet-Banking`
- `/Users/bs01706/Documents/projects/flutter-projects/boilerplate/token_tap`

## Gap analysis

| Area | Current boilerplate | FinTech | token_tap | Gap |
|---|---|---|---|---|
| Package boundary rule | `core` has no local deps; every feature package depends only on `core`; features never depend on each other | Same rule, verified via pubspec deps (one documented exception: `dashboard`→`ekyc`) | N/A (single-domain app, no per-feature packages) | **None.** Already correct — not a gap. |
| Feature-internal layering | Flat `lib/src/{entity,repository,cubit,di,routing,view}`; `NotesRepositoryImpl` touches `AppDatabase` (Drift) directly | `data/{api,entity,remote,repository,repositoryImpl}` — remote data source behind repository, but folder naming inconsistent per package | Top-level `domain/{entity,repository,usecase}` + `data/{local,mapper,repository_impl}`, features hold presentation only | No domain/data split; no datasource seam between repository and storage. |
| Business logic layer | None — cubit calls repository directly | None — controller calls repository directly | `domain/usecase/*.dart`, one class per operation | Resolved: boilerplate intentionally skips a use-case layer (matches FinTech's actual practice), cubit → repository directly. |
| Error handling | Cubits hand-roll `try/catch` → `emit(State.error(e.toString()))`; repositories throw | Controllers wrap calls in `callService`; no typed failure type surfaced in the explored sample | `core/error/{result.dart,failures.dart}` — repositories return `Result<T, Failure>`, no throwing across the repository boundary | No shared `Result`/`Failure` primitive; error handling is ad hoc per cubit. |
| Cubit lifecycle safety | Plain `Cubit<State>` | `BaseController extends GetxController` | `BaseCubit<S> extends Cubit<S>` with safe-emit + `runGuarded()` | No shared base cubit — every feature reimplements the same try/catch shape. |
| Screen shell | Each page hand-rolls `Scaffold` + `BlocBuilder` + state switch | `BaseView`/`BaseViewState` (GetX-bound) | `BaseView`/`BaseViewState` delegating to `BaseViewMixin` (`BlocConsumer → Scaffold → SafeArea`) | No shared view base — every screen repeats the same shell. |
| Screen/view split | One file per page (`notes_list_page.dart`) doing routing-target + DI + UI in one class | `_screen.dart` (thin, responsive picker) + `_screen_builder.dart` (actual UI) | Screens are the `BaseView` directly; no separate builder file | No separation between "who wires this screen's dependencies" and "how it renders." |
| Widget composition | No private `_build*()` methods today (by accident, not convention) | Explicit documented rule: no `_build*()` helper methods; inline or extract to a named widget | Per-screen `widgets/` subfolder holding extracted public widget classes | Convention isn't documented, so nothing stops it from drifting. |
| Multi-screen shared state | `ShellRoute` in the routing file wraps a `BlocProvider` so list+detail share one `NotesCubit` instance | N/A in sample | Screen-scoped cubits are independent, created via `get_it` factory params inline in the router | Routing owns a DI/state concern it shouldn't; the "shared cubit" workaround is unnecessary once each screen is independently repository-backed. |
| DI mechanism | Hand-written `register<Feature>Dependencies(GetIt)` functions (flagged in-code: `// ponytail: manual get_it registration ... switch to injectable codegen if registration count grows unwieldy`) | Kiwi codegen (`@Register.singleton/.factory`) *and* GetIt, dual mechanism, inconsistent injector file naming per package | Plain manual `get_it`, explicitly no codegen | Boilerplate's own flagged debt: registration is manual with no compile-time safety; the flagged upgrade path (`injectable`) hasn't been taken. |
| Screen-scoped DI params | N/A — cubits aren't in DI at all | N/A in sample | `registerFactoryParam` for screen cubits (e.g. `TokenEntryCubit` keyed by `transactionId`) | No equivalent — this design adopts it via `injectable`'s `@factoryParam`. |

## Target design

### 1. Core additions (`packages/core/lib/src/`)

```
base/
  base_cubit.dart        # BaseCubit<S> extends Cubit<S> — safeEmit (guards emit-after-close)
                          # + runGuarded(Future<S> Function(), S Function(Failure) onError)
  base_view_mixin.dart    # mixin BaseViewMixin<C extends StateStreamable<S>, S>
                          # owns BlocConsumer -> Scaffold -> SafeArea; overrides: appBar(), body(),
                          # onStateChanged(), listenWhen(), buildWhen(), useSafeArea
  base_view.dart          # abstract class BaseView<C, S> extends StatelessWidget with BaseViewMixin<C, S>
  base_view_state.dart    # abstract class BaseViewState<W extends StatefulWidget, C, S> extends State<W>
                           #   with BaseViewMixin<C, S> — for screens needing initState/dispose
error/
  failure.dart            # sealed class Failure — StorageFailure, NetworkFailure, UnknownFailure, ...
                           # AppException (already exists) is what DioClient/Drift throw; it gets
                           # caught and mapped to a Failure at the repository boundary, never
                           # propagated past it.
  result.dart             # sealed class Result<T, F> = Success<T, F>(T value) | Error<T, F>(F failure)
                           # hand-rolled (no fpdart/dartz dependency — matches token_tap's choice)
```

These are direct, near-literal ports of token_tap's `core/base` and
`core/error` (already small, well-isolated files) — not FinTech's
GetX-flavored `BaseController`/`BaseView`, since the boilerplate keeps
Bloc/Cubit.

### 2. DI: adopt `injectable` on top of `get_it`

This closes the boilerplate's own flagged debt
(`packages/core/lib/src/di/service_locator.dart:14`). Scope:

- **Domain/data layer + core services** (repositories, datasources,
  loggers, `AppDatabase`, etc.) move to `@LazySingleton(as: ...)` /
  `@singleton` / `@injectable` annotations. Each package keeps one
  `@InjectableInit()`-annotated entry point (same call-site shape as
  today's `register<Feature>Dependencies(getIt)` — `app/lib/bootstrap.dart`
  doesn't change how it calls in) that delegates to a generated
  `getIt.init()`.
- **Runtime-config-dependent registrations** that injectable can't express
  at compile time (`DioClient`, which needs the flavor's `baseUrl` and
  `SecurityConfig` from `EnvConfig`) stay manually registered inside the
  same entry-point function, alongside the generated `getIt.init()` call
  — mixed manual + generated registration in one package is a supported,
  ordinary injectable pattern.
- **Cubits move into DI too** (a change from today's documented "cubits
  are never in DI" rule): `@injectable` on cubit classes; a cubit needing
  a route parameter (e.g. `NoteDetailCubit`'s `noteId`) takes it via
  `@factoryParam`. Screens resolve with
  `getIt<NoteDetailCubit>(param1: noteId)` instead of constructing the
  cubit and its repository dependency by hand. This matches token_tap's
  `registerFactoryParam` pattern for screen-scoped cubits.
- `tool/workspace.sh build_runner` already runs `build_runner build`
  across every package — no new command, `injectable_generator` just adds
  another generator to the existing pipeline. Generated `*.config.dart`
  files are gitignored like the existing generated files.

### 3. Feature package layout (`packages/notes` as the template)

```
lib/src/
  domain/
    entity/note.dart                        # freezed model, unchanged in shape from today
    repository/notes_repository.dart        # interface; methods return Future<Result<T, Failure>>;
                                             # gains getNoteById(int id) — each screen is now
                                             # independently repository-backed (see §5)
  data/
    datasource/notes_local_data_source.dart # abstract interface + Drift-backed impl — the only
                                             # file touching AppDatabase directly
    repository_impl/notes_repository_impl.dart  # implements the domain repository, delegates to
                                                 # the datasource, maps row -> entity, wraps thrown
                                                 # exceptions into a Failure
  features/
    notes_list/
      cubit/
        notes_list_cubit.dart               # @injectable, extends BaseCubit<NotesListState>
        notes_list_state.dart
      view/
        notes_list_screen.dart              # BlocProvider(create: (_) => getIt<NotesListCubit>()..load())
        notes_list_view.dart                # extends BaseView<NotesListCubit, NotesListState>
        widgets/
          add_note_dialog.dart              # was the _showAddNoteDialog() method; now a public
                                             # AddNoteDialog widget class
    note_detail/
      cubit/
        note_detail_cubit.dart              # @injectable, @factoryParam on noteId
        note_detail_state.dart
      view/
        note_detail_screen.dart             # BlocProvider(create: (_) => getIt<NoteDetailCubit>(param1: noteId)..load())
        note_detail_view.dart               # extends BaseViewState<..., NoteDetailCubit, NoteDetailState>
                                             # (needs local TextEditingControllers)
  di/notes_dependencies.dart                # @InjectableInit() entry point
  routing/notes_routes.dart                 # plain sibling GoRoutes — no ShellRoute-for-shared-state hack
```

`domain/` and `data/` stay feature-wide (one package = one bounded
feature, so there's exactly one of each); `cubit/` and `view/` nest per
screen under `features/<sub-feature>/` since each screen now owns its own
state independently.

### 4. Screen/view/widgets convention (applies repo-wide, documented in CLAUDE.md)

- `<screen>_screen.dart`: thin, owns dependency resolution — resolves its
  cubit from `getIt` (with `param1:` for route-scoped ones) and wraps it
  in `BlocProvider`. This is the `GoRoute`/`ShellRoute` builder target.
  No UI beyond that.
- `<screen>_view.dart`: the actual UI, `extends BaseView<Cubit, State>` (or
  `BaseViewState` if it needs `initState`/local controllers). Overrides
  `appBar()`/`body()`. Reads the cubit via the ambient `BlocProvider` from
  its `_screen.dart`.
- No private `Widget _buildX()` helper methods anywhere. Inline a
  sub-widget in `body()` if it's used once; if it's reused, non-trivial,
  or needed to keep `body()` readable, extract it as a public `Widget`
  class into its own file under that screen's `widgets/` folder. Enforced
  by convention/review, not the analyzer (same as FinTech — there's no
  off-the-shelf lint rule for this).

### 5. Routing simplification

Today's `notes_routes.dart` wraps both routes in a `ShellRoute` purely so
list and detail can share one `NotesCubit` instance. Once each screen is
independently repository-backed (`NoteDetailCubit` fetches its own note
via `NotesRepository.getNoteById(id)`), that wrapper is unnecessary:

```dart
StatefulShellBranch notesShellBranch(GetIt getIt) => StatefulShellBranch(
  routes: [
    GoRoute(path: AppRoutePaths.notes, builder: (_, __) => const NotesListScreen()),
    GoRoute(
      path: '${AppRoutePaths.notes}/:id',
      builder: (_, state) => NoteDetailScreen(noteId: int.parse(state.pathParameters['id']!)),
    ),
  ],
);
```

Cross-screen refresh (list should reflect an edit made in detail) uses the
ordinary go_router pop-with-result pattern: `NoteDetailScreen` pops with
`context.pop(updatedNote)`; `NotesListView`'s tap handler awaits the
pushed route and calls `context.read<NotesListCubit>().load()` (or
replaces the entry in place) when a non-null result comes back. No shared
cubit instance required.

### 6. Explicitly not adopted (scope guardrail)

- No GetX, no Kiwi — `injectable` sits on top of the existing `get_it`,
  it doesn't replace it or add a second DI container.
- No use-case/interactor layer — cubits call the repository interface
  directly (matches FinTech's actual practice, not token_tap's).
- No `Skt`-prefixed widget renaming, no per-package folder-naming
  variance (FinTech's own inconsistency across packages — not a
  convention worth copying).
- No responsive mobile/web screen switching in `_screen.dart` — this
  boilerplate is mobile-only per CLAUDE.md.

## Rollout scope

Files/packages touched when this is implemented:

- `packages/core/pubspec.yaml` — add `injectable`, `injectable_generator`.
- `packages/core/lib/src/base/*.dart`, `packages/core/lib/src/error/*.dart` — new.
- `packages/core/lib/src/di/service_locator.dart` — becomes the
  `@InjectableInit()` entry point + manual `DioClient` registration.
- `packages/core/lib/core.dart` — export the new base/error files.
- `packages/notes/` — restructured end-to-end per §3; `notes_cubit_test.dart`
  splits into `notes_list_cubit_test.dart` + `note_detail_cubit_test.dart`;
  widget tests split per screen; mocked `NotesRepository` returns
  `Success`/`Error(Failure)` instead of raw values/throws.
- `tool/new_feature.sh` — scaffold generator updated to emit the new tree.
- `tool/workspace.sh` — no command changes; `build_runner` step now also
  runs `injectable_generator`.
- `CLAUDE.md` — rewrite "Feature package shape", the DI paragraph, and add
  the screen/view/widgets convention as a documented rule.

## Non-goals / follow-ups

- Migrating any *other* storage backend (Hive/secure storage/prefs) to
  the same datasource-seam pattern is out of scope here — this spec only
  restructures what `notes` (Drift) demonstrates; the same shape applies
  when a future feature uses a different backend.
- No change to `app/lib/features/{home,login,settings,splash}` — those
  are app-owned scaffolding pages, not a feature-package template, and
  weren't in scope for this comparison.
