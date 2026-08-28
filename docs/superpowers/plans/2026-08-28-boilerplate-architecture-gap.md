# Boilerplate Architecture Gap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring `packages/core` and the `packages/notes` template (and the
generator/docs that copy it) in line with the target architecture: a
domain/data split per feature, shared `BaseCubit`/`BaseView` primitives and a
`Result`/`AppFailure` error type in `core`, `injectable` on top of `get_it`
(including screen-scoped cubits via `@factoryParam`), and a
screen-owns-DI / view-is-pure-UI convention.

**Architecture:** Add core primitives first (error type, base cubit, base
view) since the feature layer depends on them. Then restructure `packages/notes`
into `domain/` + `data/` + `features/<screen>/{cubit,view}`, cutting each
screen over to its own independently-repository-backed cubit (no more
`ShellRoute`-for-shared-state). Finish by updating the generator and docs so
new features get the new shape automatically.

**Tech Stack:** Flutter/Dart ^3.13.0, flutter_bloc (Cubit), go_router,
get_it + injectable, freezed, drift, bloc_test/mocktail.

**Spec:** `docs/superpowers/specs/2026-08-28-boilerplate-architecture-gap-design.md`

## Global Constraints

- Package boundary rule stays as-is: `core` has no local-package
  dependencies; every feature package depends only on `core`; feature
  packages never depend on each other. (Already correct — don't touch.)
- No GetX, no Kiwi — `injectable` sits on top of the existing `get_it`, it
  doesn't replace it.
- No use-case/interactor layer — cubits call the repository interface
  directly.
- No `Skt`-prefixed widgets, no responsive mobile/web screen switching
  (mobile-only).
- No private `Widget _buildX()` helper methods anywhere. Inline a
  sub-widget in `body()` if used once; if reused or non-trivial, extract it
  as a public `Widget` class into its own file under that screen's
  `widgets/` folder.
- Generated files (`*.freezed.dart`, `*.g.dart`, `*.config.dart`) are
  gitignored — never hand-edit; regenerate via
  `dart run build_runner build --delete-conflicting-outputs`.
- Every public DI entry-point function keeps its existing name/signature
  (`registerCoreDependencies`, `registerNotesDependencies`) — only their
  internals change — so `app/lib/bootstrap.dart` needs no edits.

---

## Task 1: Core — `Result` and `AppFailure`

**Files:**
- Create: `packages/core/lib/src/error/result.dart`
- Create: `packages/core/lib/src/error/app_failure.dart`
- Modify: `packages/core/lib/core.dart`
- Test: `packages/core/test/error/result_test.dart`

**Interfaces:**
- Produces: `sealed class Result<T, F>` with `Success<T, F>(T value)` and
  `Failure<T, F>(F failure)` variants; `sealed class AppFailure { String
  message }` with `StorageFailure([String message])` and
  `UnknownFailure([String message])` subclasses. All exported from
  `core.dart`.

- [ ] **Step 1: Write the failing test**

```dart
// packages/core/test/error/result_test.dart
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('pattern-matches Success to its value', () {
      const Result<int, AppFailure> result = Success(42);
      final matched = switch (result) {
        Success(:final value) => value,
        Failure() => -1,
      };
      expect(matched, 42);
    });

    test('pattern-matches Failure to its failure', () {
      const Result<int, AppFailure> result = Failure(StorageFailure());
      final matched = switch (result) {
        Success() => null,
        Failure(:final failure) => failure,
      };
      expect(matched, isA<StorageFailure>());
      expect((matched! as StorageFailure).message, isNotEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run (from `packages/core`): `flutter test test/error/result_test.dart`
Expected: FAIL — `Result`/`Success`/`Failure`/`StorageFailure`/`AppFailure` undefined.

- [ ] **Step 3: Implement `Result` and `AppFailure`**

```dart
// packages/core/lib/src/error/result.dart
/// Minimal sealed result type so repositories can return either a value or a
/// typed failure without throwing across the repository boundary. Hand-rolled
/// (no fpdart/dartz dependency) — two variants is all this boilerplate needs.
sealed class Result<T, F> {
  const Result();
}

final class Success<T, F> extends Result<T, F> {
  const Success(this.value);

  final T value;
}

final class Failure<T, F> extends Result<T, F> {
  const Failure(this.failure);

  final F failure;
}
```

```dart
// packages/core/lib/src/error/app_failure.dart
/// Typed failure payload for [Result]. Repositories catch whatever their
/// backend throws (Drift, Dio, ...) and wrap it into one of these instead of
/// letting the exception cross the repository boundary.
sealed class AppFailure {
  const AppFailure(this.message);

  final String message;
}

class StorageFailure extends AppFailure {
  const StorageFailure([super.message = 'Could not read or write local data.']);
}

class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}
```

- [ ] **Step 4: Export from `core.dart`**

Add, alphabetically among the existing `export` lines in
`packages/core/lib/core.dart`:

```dart
export 'src/error/app_failure.dart';
export 'src/error/result.dart';
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/error/result_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add packages/core/lib/src/error packages/core/lib/core.dart packages/core/test/error
git commit -m "core: add Result/AppFailure error primitives"
```

---

## Task 2: Core — `BaseCubit` + `SafeEmitMixin`

**Files:**
- Modify: `packages/core/pubspec.yaml` (add `flutter_bloc`)
- Create: `packages/core/lib/src/base/base_cubit.dart`
- Modify: `packages/core/lib/core.dart`
- Test: `packages/core/test/base/base_cubit_test.dart`

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: `abstract class BaseCubit<S> extends Cubit<S> with
  SafeEmitMixin<S>`, with `Future<void> runGuarded(Future<void> Function()
  action, {required S Function(Object error, StackTrace stackTrace)
  onError})` and `void safeEmit(S state)` (from the mixin). Later tasks'
  cubits extend `BaseCubit<S>`.

- [ ] **Step 1: Add `flutter_bloc` to core's pubspec**

In `packages/core/pubspec.yaml`, under `dependencies:` (alphabetical,
after `flutter:`):

```yaml
  flutter_bloc: ^9.1.1
```

Run (from repo root): `dart pub get`

- [ ] **Step 2: Write the failing test**

```dart
// packages/core/test/base/base_cubit_test.dart
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterCubit extends BaseCubit<int> {
  _CounterCubit() : super(0);

  Future<void> incrementOrThrow(bool shouldThrow) => runGuarded(() async {
    if (shouldThrow) throw StateError('boom');
    safeEmit(state + 1);
  }, onError: (error, stackTrace) => -1);
}

void main() {
  group('BaseCubit', () {
    test('runGuarded emits the action\'s result on success', () async {
      final cubit = _CounterCubit();
      await cubit.incrementOrThrow(false);
      expect(cubit.state, 1);
      await cubit.close();
    });

    test('runGuarded emits onError\'s state when the action throws', () async {
      final cubit = _CounterCubit();
      await cubit.incrementOrThrow(true);
      expect(cubit.state, -1);
      await cubit.close();
    });

    test('safeEmit is a no-op after the cubit is closed', () async {
      final cubit = _CounterCubit();
      await cubit.close();
      cubit.safeEmit(99);
      expect(cubit.state, 0);
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/base/base_cubit_test.dart`
Expected: FAIL — `BaseCubit` undefined.

- [ ] **Step 4: Implement `BaseCubit`**

```dart
// packages/core/lib/src/base/base_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shared safety net for every cubit in this app: emitting after the cubit
/// is closed throws `StateError` (happens when the user leaves a screen with
/// an awaited call still in flight), and an exception inside an async cubit
/// method otherwise escapes unhandled and surfaces as a red screen instead of
/// a state the UI can render.
abstract class BaseCubit<S> extends Cubit<S> with SafeEmitMixin<S> {
  BaseCubit(super.initialState);

  /// Runs [action], converting any thrown object into a state via [onError].
  /// [action] is responsible for emitting its own success state(s) — this
  /// only exists to catch what [action] doesn't.
  Future<void> runGuarded(
    Future<void> Function() action, {
    required S Function(Object error, StackTrace stackTrace) onError,
  }) async {
    try {
      await action();
    } on Object catch (error, stackTrace) {
      safeEmit(onError(error, stackTrace));
    }
  }
}

/// Guards against emitting into a closed cubit.
mixin SafeEmitMixin<S> on BlocBase<S> {
  void safeEmit(S state) {
    if (!isClosed) emit(state);
  }
}
```

- [ ] **Step 5: Export from `core.dart`**

```dart
export 'src/base/base_cubit.dart';
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/base/base_cubit_test.dart`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add packages/core/pubspec.yaml packages/core/pubspec.lock packages/core/lib/src/base packages/core/lib/core.dart packages/core/test/base
git commit -m "core: add BaseCubit safe-emit + runGuarded helper"
```

---

## Task 3: Core — `BaseView` / `BaseViewState` / `BaseViewMixin`

**Files:**
- Create: `packages/core/lib/src/base/base_view_mixin.dart`
- Create: `packages/core/lib/src/base/base_view.dart`
- Create: `packages/core/lib/src/base/base_view_state.dart`
- Modify: `packages/core/lib/core.dart`
- Test: `packages/core/test/base/base_view_test.dart`

**Interfaces:**
- Consumes: nothing from Tasks 1-2.
- Produces: `mixin BaseViewMixin<C extends StateStreamable<S>, S>` with
  overridable `appBar(context, state)`, `body(context, state)` (required),
  `floatingActionButton(context, state)`, `onStateChanged(context, state)`,
  `listenWhen`, `buildWhen`, `useSafeArea`, and `C cubitOf(BuildContext)`.
  `abstract class BaseView<C, S> extends StatelessWidget with
  BaseViewMixin<C, S>` and `abstract class BaseViewState<W extends
  StatefulWidget, C, S> extends State<W> with BaseViewMixin<C, S>`. Later
  tasks' screens extend one of these two.

- [ ] **Step 1: Write the failing test**

```dart
// packages/core/test/base/base_view_test.dart
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterCubit extends Cubit<int> {
  _CounterCubit() : super(0);
}

class _CounterView extends BaseView<_CounterCubit, int> {
  const _CounterView();

  @override
  PreferredSizeWidget appBar(BuildContext context, int state) =>
      AppBar(title: const Text('Counter'));

  @override
  Widget body(BuildContext context, int state) => Text('Count: $state');

  @override
  Widget? floatingActionButton(BuildContext context, int state) =>
      FloatingActionButton(onPressed: () => cubitOf(context).emit(state + 1));
}

void main() {
  testWidgets('BaseView renders appBar, body, and floatingActionButton', (
    tester,
  ) async {
    final cubit = _CounterCubit();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<_CounterCubit>.value(
          value: cubit,
          child: const _CounterView(),
        ),
      ),
    );

    expect(find.text('Counter'), findsOneWidget);
    expect(find.text('Count: 0'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(find.text('Count: 1'), findsOneWidget);
    await cubit.close();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/base/base_view_test.dart`
Expected: FAIL — `BaseView` undefined.

- [ ] **Step 3: Implement the mixin and the two base classes**

```dart
// packages/core/lib/src/base/base_view_mixin.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The screen contract shared by [BaseView] and [BaseViewState].
///
/// Holds the `BlocConsumer -> Scaffold -> SafeArea` shell so the stateless
/// and stateful bases stay a delegation each, and so no screen hand-rolls
/// this shell itself.
mixin BaseViewMixin<C extends StateStreamable<S>, S> {
  /// The screen's app bar. Null for screens that supply their own, or none.
  PreferredSizeWidget? appBar(BuildContext context, S state) => null;

  /// The screen's content, below the app bar.
  Widget body(BuildContext context, S state);

  /// The screen's floating action button, if any.
  Widget? floatingActionButton(BuildContext context, S state) => null;

  /// Reacts to state changes that are effects, not rendering — navigation,
  /// snack bars, seeding local controllers from a just-loaded state. Runs
  /// before [body] for the same state change.
  void onStateChanged(BuildContext context, S state) {}

  bool listenWhen(S previous, S current) => true;

  bool buildWhen(S previous, S current) => true;

  /// Set false for screens that manage their own insets.
  bool get useSafeArea => true;

  /// The cubit driving this screen.
  C cubitOf(BuildContext context) => context.read<C>();

  Widget buildView(BuildContext context) {
    return BlocConsumer<C, S>(
      listenWhen: listenWhen,
      buildWhen: buildWhen,
      listener: onStateChanged,
      builder: (context, state) {
        final content = body(context, state);
        return Scaffold(
          appBar: appBar(context, state),
          body: useSafeArea ? SafeArea(child: content) : content,
          floatingActionButton: floatingActionButton(context, state),
        );
      },
    );
  }
}
```

```dart
// packages/core/lib/src/base/base_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'base_view_mixin.dart';

/// Base class for a stateless screen bound to a cubit.
///
/// Override [BaseViewMixin.appBar] and [BaseViewMixin.body]. Use
/// [BaseViewState] instead when the screen needs `initState`/local
/// controllers.
abstract class BaseView<C extends StateStreamable<S>, S> extends StatelessWidget
    with BaseViewMixin<C, S> {
  const BaseView({super.key});

  @override
  Widget build(BuildContext context) => buildView(context);
}
```

```dart
// packages/core/lib/src/base/base_view_state.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'base_view_mixin.dart';

/// Base class for a stateful screen bound to a cubit — for screens that need
/// `initState`/`dispose` or local controllers (e.g. `TextEditingController`s
/// seeded from a just-loaded state in [BaseViewMixin.onStateChanged]).
abstract class BaseViewState<
  W extends StatefulWidget,
  C extends StateStreamable<S>,
  S
>
    extends State<W>
    with BaseViewMixin<C, S> {
  @override
  Widget build(BuildContext context) => buildView(context);
}
```

- [ ] **Step 4: Export from `core.dart`**

```dart
export 'src/base/base_view.dart';
export 'src/base/base_view_mixin.dart';
export 'src/base/base_view_state.dart';
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/base/base_view_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add packages/core/lib/src/base packages/core/lib/core.dart packages/core/test/base
git commit -m "core: add BaseView/BaseViewState/BaseViewMixin"
```

---

## Task 4: Core — `AppDatabase.getNoteById`

**Files:**
- Modify: `packages/core/lib/src/storage/database/app_database.dart`
- Test: `packages/core/test/storage/app_database_test.dart`

**Interfaces:**
- Produces: `Future<Note?> getNoteById(int id)` on `AppDatabase`, used by
  `packages/notes`' datasource in Task 6.

- [ ] **Step 1: Write the failing test**

```dart
// packages/core/test/storage/app_database_test.dart
import 'package:core/core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  group('AppDatabase.getNoteById', () {
    test('returns the matching note', () async {
      final created = await database.createNote(
        title: 'Groceries',
        body: 'Milk',
      );
      final found = await database.getNoteById(created.id);
      expect(found?.title, 'Groceries');
    });

    test('returns null for an unknown id', () async {
      final found = await database.getNoteById(999);
      expect(found, isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/storage/app_database_test.dart`
Expected: FAIL — `getNoteById` undefined on `AppDatabase`.

- [ ] **Step 3: Add the query method**

In `packages/core/lib/src/storage/database/app_database.dart`, add inside
`class AppDatabase`, after `deleteNote`:

```dart
  Future<Note?> getNoteById(int id) =>
      (select(notes)..where((t) => t.id.equals(id))).getSingleOrNull();
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/storage/app_database_test.dart`
Expected: PASS

(No `build_runner` step needed — this method only adds a query against the
already-generated `notes` table accessor, it doesn't change the table shape.)

- [ ] **Step 5: Commit**

```bash
git add packages/core/lib/src/storage/database/app_database.dart packages/core/test/storage
git commit -m "core: add AppDatabase.getNoteById"
```

---

## Task 5: Core — adopt `injectable` on top of `get_it`

**Files:**
- Modify: `packages/core/pubspec.yaml` (add `injectable`, `injectable_generator`)
- Modify: `packages/core/lib/src/logging/app_logger.dart`
- Modify: `packages/core/lib/src/logging/error_reporter.dart`
- Create: `packages/core/lib/src/di/core_module.dart`
- Modify: `packages/core/lib/src/di/service_locator.dart`
- Test: `packages/core/test/di/core_module_test.dart`

**Interfaces:**
- Produces: `registerCoreDependencies(GetIt getIt, {required String
  baseUrl, SecurityConfig securityConfig})` — same name/signature as
  before, called unchanged from `app/lib/bootstrap.dart`. After this task,
  `getIt<AppLogger>()`, `getIt<ErrorReporter>()`, `getIt<AppDatabase>()`,
  `getIt<SecureStorageService>()`, `getIt<PreferencesService>()`,
  `getIt<HiveService>()`, and `getIt<DioClient>()` are all resolvable.

- [ ] **Step 1: Add injectable to core's pubspec**

In `packages/core/pubspec.yaml`, under `dependencies:`:

```yaml
  injectable: ^2.5.0
```

Under `dev_dependencies:`:

```yaml
  injectable_generator: ^2.6.2
```

Run (from repo root): `dart pub get`

- [ ] **Step 2: Write the failing test for the module's synchronous providers**

```dart
// packages/core/test/di/core_module_test.dart
import 'package:core/src/di/core_module.dart';
import 'package:core/src/storage/database/app_database.dart';
import 'package:core/src/storage/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final module = CoreModule();

  test('appDatabase provides an AppDatabase instance', () {
    expect(module.appDatabase, isA<AppDatabase>());
  });

  test('secureStorageService provides a SecureStorageService instance', () {
    expect(module.secureStorageService, isA<SecureStorageService>());
  });

  test('preferencesService initializes SharedPreferences before returning', () async {
    SharedPreferences.setMockInitialValues({});
    final service = await module.preferencesService;
    expect(service.getBool('missing_key'), isFalse);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/di/core_module_test.dart`
Expected: FAIL — `package:core/src/di/core_module.dart` doesn't exist.

- [ ] **Step 4: Annotate the simple concrete classes**

In `packages/core/lib/src/logging/app_logger.dart`, add the import and
annotate `ConsoleAppLogger` (leave its body unchanged):

```dart
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart' as pkg;

abstract class AppLogger {
  ...
}

@LazySingleton(as: AppLogger)
class ConsoleAppLogger implements AppLogger {
  ...
}
```

In `packages/core/lib/src/logging/error_reporter.dart`:

```dart
import 'package:injectable/injectable.dart';

abstract class ErrorReporter {
  ...
}

@LazySingleton(as: ErrorReporter)
class NoopErrorReporter implements ErrorReporter {
  ...
}
```

- [ ] **Step 5: Add the module for services injectable can't construct directly**

```dart
// packages/core/lib/src/di/core_module.dart
import 'package:injectable/injectable.dart';

import '../storage/database/app_database.dart';
import '../storage/hive_service.dart';
import '../storage/preferences_service.dart';
import '../storage/secure_storage_service.dart';

/// Provides the core services injectable can't generate a registration for
/// directly: [AppDatabase] and [SecureStorageService] both take an optional
/// test-only constructor parameter injectable can't resolve, and
/// [PreferencesService]/[HiveService] need an async `init()` step before
/// they're usable.
@module
abstract class CoreModule {
  @lazySingleton
  AppDatabase get appDatabase => AppDatabase();

  @lazySingleton
  SecureStorageService get secureStorageService => SecureStorageService();

  @preResolve
  Future<PreferencesService> get preferencesService async {
    final service = PreferencesService();
    await service.init();
    return service;
  }

  @preResolve
  Future<HiveService> get hiveService async {
    final service = HiveService();
    await service.init();
    return service;
  }
}
```

- [ ] **Step 6: Rewrite `service_locator.dart`**

```dart
// packages/core/lib/src/di/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../logging/app_logger.dart';
import '../network/dio_client.dart';
import '../security/security_config.dart';
import 'service_locator.config.dart';

final GetIt getIt = GetIt.instance;

/// Registers everything `core` owns. Call once from the app's `bootstrap()`
/// before `registerNotesDependencies` (or any other feature package's
/// registration function).
///
/// Most registrations are generated from `@LazySingleton`/`@module`
/// annotations across this package (see `core_module.dart`,
/// `app_logger.dart`, `error_reporter.dart`). `DioClient` stays manual
/// because it needs a flavor's runtime `baseUrl`/`SecurityConfig`, which
/// injectable can't see at compile time.
@InjectableInit()
Future<void> registerCoreDependencies(
  GetIt getIt, {
  required String baseUrl,
  SecurityConfig securityConfig = const SecurityConfig(),
}) async {
  await getIt.init();

  getIt.registerLazySingleton(
    () => DioClient(
      baseUrl: baseUrl,
      logger: getIt<AppLogger>(),
      securityConfig: securityConfig,
    ),
  );
}
```

- [ ] **Step 7: Generate the injectable config**

Run (from `packages/core`):
`dart run build_runner build --delete-conflicting-outputs`

Expected: generates `packages/core/lib/src/di/service_locator.config.dart`
(gitignored). If generation fails on an unresolvable constructor parameter,
re-check step 5 — every class injectable auto-wires (as opposed to the
`@module` getters) must have a zero-arg or fully DI-resolvable constructor.

- [ ] **Step 8: Run tests to verify they pass**

Run: `flutter test test/di/core_module_test.dart`
Expected: PASS

Run (whole package, confirms nothing else broke): `flutter analyze && flutter test`
Expected: no analyzer errors, all tests pass (including the existing
`test/widgets/state_widgets_golden_test.dart`).

- [ ] **Step 9: Commit**

```bash
git add packages/core/pubspec.yaml packages/core/pubspec.lock packages/core/lib/src/logging packages/core/lib/src/di packages/core/test/di
git commit -m "core: adopt injectable codegen on top of get_it"
```

---

## Task 6: Notes — domain + data layers

**Files:**
- Create: `packages/notes/lib/src/domain/entity/note.dart` (moved from `lib/src/entity/note.dart`, unchanged)
- Create: `packages/notes/lib/src/domain/repository/notes_repository.dart`
- Create: `packages/notes/lib/src/data/datasource/notes_local_data_source.dart`
- Create: `packages/notes/lib/src/data/repository_impl/notes_repository_impl.dart`
- Modify: `packages/notes/pubspec.yaml` (add `injectable`)
- Test: `packages/notes/test/data/notes_repository_impl_test.dart`

The old `lib/src/entity/`, `lib/src/repository/` and their consumers
(`lib/src/cubit/notes_cubit.dart`, the view/routing/DI files, the barrel,
and the two old test files) are **not touched or deleted yet** — they still
reference the old shape and keep the package analyzing clean until Task 9's
cutover. The new files in this task are exercised directly via
`package:notes/src/...` imports, not yet re-exported from `lib/notes.dart`.

**Interfaces:**
- Consumes: `Result<T, F>`, `Success`, `Failure`, `AppFailure`,
  `StorageFailure` (Task 1); `AppDatabase.getNoteById` (Task 4).
- Produces: `NotesRepository` interface (`getNotes`, `getNoteById`,
  `addNote`, `updateNote`, `deleteNote`, all `Result`-returning) and its
  `NotesRepositoryImpl`, used by Tasks 7-8's cubits.

- [ ] **Step 1: Add injectable to notes' pubspec**

In `packages/notes/pubspec.yaml`, under `dependencies:`:

```yaml
  injectable: ^2.5.0
```

Under `dev_dependencies:`:

```yaml
  injectable_generator: ^2.6.2
```

Run (from repo root): `dart pub get`

- [ ] **Step 2: Move the entity, unchanged**

```bash
mkdir -p packages/notes/lib/src/domain/entity
git mv packages/notes/lib/src/entity/note.dart packages/notes/lib/src/domain/entity/note.dart
git mv packages/notes/lib/src/entity/note.g.dart packages/notes/lib/src/domain/entity/note.g.dart 2>/dev/null || true
```

(`note.g.dart`/`note.freezed.dart` are gitignored — if `git mv` reports them
as not tracked, that's expected; just move the file yourself with `mv`, or
let the next `build_runner` regenerate it in the new location and delete the
stale copy from the old `lib/src/entity/` directory.)

- [ ] **Step 3: Write the failing test for the data layer**

```dart
// packages/notes/test/data/notes_repository_impl_test.dart
import 'package:core/core.dart' as core;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes/src/data/datasource/notes_local_data_source.dart';
import 'package:notes/src/data/repository_impl/notes_repository_impl.dart';

void main() {
  late core.AppDatabase database;
  late NotesRepositoryImpl repository;

  setUp(() {
    database = core.AppDatabase(NativeDatabase.memory());
    repository = NotesRepositoryImpl(DriftNotesLocalDataSource(database));
  });

  tearDown(() => database.close());

  test('addNote then getNotes round-trips through Drift', () async {
    final added = await repository.addNote(title: 'Groceries', body: 'Milk');
    expect(added, isA<core.Success<dynamic, dynamic>>());

    final all = await repository.getNotes();
    final notes = (all as core.Success).value;
    expect(notes, hasLength(1));
    expect(notes.first.title, 'Groceries');
  });

  test('getNoteById returns a StorageFailure for an unknown id', () async {
    final result = await repository.getNoteById(999);
    expect(result, isA<core.Failure<dynamic, dynamic>>());
    expect((result as core.Failure).failure, isA<core.StorageFailure>());
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

Run (from `packages/notes`): `flutter test test/data/notes_repository_impl_test.dart`
Expected: FAIL — the imported files don't exist yet.

- [ ] **Step 5: Write the domain repository interface**

```dart
// packages/notes/lib/src/domain/repository/notes_repository.dart
import 'package:core/core.dart' hide Note;

import '../entity/note.dart';

/// The seam feature cubits are tested against — a mocktail fake in cubit
/// tests stands in for [NotesRepositoryImpl] so those tests never touch
/// Drift directly.
abstract interface class NotesRepository {
  Future<Result<List<Note>, AppFailure>> getNotes();
  Future<Result<Note, AppFailure>> getNoteById(int id);
  Future<Result<Note, AppFailure>> addNote({
    required String title,
    required String body,
  });
  Future<Result<void, AppFailure>> updateNote(Note note);
  Future<Result<void, AppFailure>> deleteNote(int id);
}
```

- [ ] **Step 6: Write the local datasource**

```dart
// packages/notes/lib/src/data/datasource/notes_local_data_source.dart
import 'package:core/core.dart' as core;
import 'package:injectable/injectable.dart';

/// The only file in this package that touches `AppDatabase` (Drift)
/// directly — [NotesRepositoryImpl] is tested against [NotesLocalDataSource]
/// through this seam instead.
abstract interface class NotesLocalDataSource {
  Future<List<core.Note>> getAllNotes();
  Future<core.Note?> getNoteById(int id);
  Future<core.Note> createNote({required String title, required String body});
  Future<void> updateNote(core.Note note);
  Future<void> deleteNote(int id);
}

@LazySingleton(as: NotesLocalDataSource)
class DriftNotesLocalDataSource implements NotesLocalDataSource {
  DriftNotesLocalDataSource(this._database);

  final core.AppDatabase _database;

  @override
  Future<List<core.Note>> getAllNotes() => _database.watchAllNotes().first;

  @override
  Future<core.Note?> getNoteById(int id) => _database.getNoteById(id);

  @override
  Future<core.Note> createNote({required String title, required String body}) =>
      _database.createNote(title: title, body: body);

  @override
  Future<void> updateNote(core.Note note) => _database.updateNote(note);

  @override
  Future<void> deleteNote(int id) => _database.deleteNote(id);
}
```

- [ ] **Step 7: Write the repository implementation**

```dart
// packages/notes/lib/src/data/repository_impl/notes_repository_impl.dart
import 'package:core/core.dart' as core;
import 'package:injectable/injectable.dart';

import '../../domain/entity/note.dart';
import '../../domain/repository/notes_repository.dart';
import '../datasource/notes_local_data_source.dart';

@LazySingleton(as: NotesRepository)
class NotesRepositoryImpl implements NotesRepository {
  NotesRepositoryImpl(this._dataSource);

  final NotesLocalDataSource _dataSource;

  Note _fromRow(core.Note row) => Note(
    id: row.id,
    title: row.title,
    body: row.body,
    createdAt: row.createdAt,
  );

  @override
  Future<core.Result<List<Note>, core.AppFailure>> getNotes() async {
    try {
      final rows = await _dataSource.getAllNotes();
      return core.Success(rows.map(_fromRow).toList());
    } catch (_) {
      return const core.Failure(core.StorageFailure());
    }
  }

  @override
  Future<core.Result<Note, core.AppFailure>> getNoteById(int id) async {
    try {
      final row = await _dataSource.getNoteById(id);
      if (row == null) {
        return const core.Failure(core.StorageFailure('Note not found.'));
      }
      return core.Success(_fromRow(row));
    } catch (_) {
      return const core.Failure(core.StorageFailure());
    }
  }

  @override
  Future<core.Result<Note, core.AppFailure>> addNote({
    required String title,
    required String body,
  }) async {
    try {
      final row = await _dataSource.createNote(title: title, body: body);
      return core.Success(_fromRow(row));
    } catch (_) {
      return const core.Failure(core.StorageFailure());
    }
  }

  @override
  Future<core.Result<void, core.AppFailure>> updateNote(Note note) async {
    try {
      await _dataSource.updateNote(
        core.Note(
          id: note.id,
          title: note.title,
          body: note.body,
          createdAt: note.createdAt,
        ),
      );
      return const core.Success(null);
    } catch (_) {
      return const core.Failure(core.StorageFailure());
    }
  }

  @override
  Future<core.Result<void, core.AppFailure>> deleteNote(int id) async {
    try {
      await _dataSource.deleteNote(id);
      return const core.Success(null);
    } catch (_) {
      return const core.Failure(core.StorageFailure());
    }
  }
}
```

- [ ] **Step 8: Run test to verify it passes**

Run: `flutter test test/data/notes_repository_impl_test.dart`
Expected: PASS

- [ ] **Step 9: Commit**

```bash
git add packages/notes/pubspec.yaml packages/notes/pubspec.lock packages/notes/lib/src/domain packages/notes/lib/src/data packages/notes/test/data
git commit -m "notes: add domain+data layers (Result-based repository, datasource seam)"
```

---

## Task 7: Notes — `notes_list` feature

**Files:**
- Create: `packages/notes/lib/src/features/notes_list/cubit/notes_list_state.dart`
- Create: `packages/notes/lib/src/features/notes_list/cubit/notes_list_cubit.dart`
- Create: `packages/notes/lib/src/features/notes_list/view/notes_list_screen.dart`
- Create: `packages/notes/lib/src/features/notes_list/view/notes_list_view.dart`
- Create: `packages/notes/lib/src/features/notes_list/view/widgets/add_note_dialog.dart`
- Test: `packages/notes/test/features/notes_list/notes_list_cubit_test.dart`
- Test: `packages/notes/test/features/notes_list/notes_list_view_test.dart`

**Interfaces:**
- Consumes: `NotesRepository`, `Note` (Task 6); `BaseCubit`, `BaseView`
  (Tasks 2-3); `Result`/`Success`/`Failure` (Task 1).
- Produces: `NotesListCubit` (`@injectable`, methods `load()`,
  `addNote({title, body})`, `deleteNote(id)`), `NotesListState`
  (`initial`/`loading`/`loaded(List<Note>)`/`error(String)`),
  `NotesListScreen` (the `GoRoute` target — resolves `NotesListCubit` from
  `getIt`), `NotesListView` (pure UI). Task 9's routing wiring references
  `NotesListScreen`.

- [ ] **Step 1: Write the failing cubit test**

```dart
// packages/notes/test/features/notes_list/notes_list_cubit_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart' hide Note;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notes/src/domain/entity/note.dart';
import 'package:notes/src/domain/repository/notes_repository.dart';
import 'package:notes/src/features/notes_list/cubit/notes_list_cubit.dart';
import 'package:notes/src/features/notes_list/cubit/notes_list_state.dart';

class MockNotesRepository extends Mock implements NotesRepository {}

void main() {
  late MockNotesRepository repository;

  final note = Note(
    id: 1,
    title: 'Groceries',
    body: 'Milk, eggs',
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    repository = MockNotesRepository();
  });

  group('NotesListCubit', () {
    blocTest<NotesListCubit, NotesListState>(
      'emits [loading, loaded] when load succeeds',
      build: () {
        when(() => repository.getNotes()).thenAnswer((_) async => Success([note]));
        return NotesListCubit(repository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const NotesListState.loading(),
        NotesListState.loaded([note]),
      ],
    );

    blocTest<NotesListCubit, NotesListState>(
      'emits [loading, error] when load fails',
      build: () {
        when(
          () => repository.getNotes(),
        ).thenAnswer((_) async => const Failure(StorageFailure()));
        return NotesListCubit(repository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [const NotesListState.loading(), isA<NotesListError>()],
    );

    blocTest<NotesListCubit, NotesListState>(
      'addNote appends the created note and re-emits loaded',
      build: () {
        when(
          () => repository.getNotes(),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => repository.addNote(title: 'New', body: 'Body'),
        ).thenAnswer((_) async => Success(note));
        return NotesListCubit(repository);
      },
      act: (cubit) =>
          cubit.load().then((_) => cubit.addNote(title: 'New', body: 'Body')),
      expect: () => [
        const NotesListState.loading(),
        const NotesListState.loaded([]),
        NotesListState.loaded([note]),
      ],
    );

    blocTest<NotesListCubit, NotesListState>(
      'deleteNote removes the note and re-emits loaded',
      build: () {
        when(
          () => repository.getNotes(),
        ).thenAnswer((_) async => Success([note]));
        when(
          () => repository.deleteNote(1),
        ).thenAnswer((_) async => const Success(null));
        return NotesListCubit(repository);
      },
      act: (cubit) => cubit.load().then((_) => cubit.deleteNote(1)),
      expect: () => [
        const NotesListState.loading(),
        NotesListState.loaded([note]),
        const NotesListState.loaded([]),
      ],
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/notes_list/notes_list_cubit_test.dart`
Expected: FAIL — none of the imported files exist yet.

- [ ] **Step 3: Write the state**

```dart
// packages/notes/lib/src/features/notes_list/cubit/notes_list_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/entity/note.dart';

part 'notes_list_state.freezed.dart';

@freezed
sealed class NotesListState with _$NotesListState {
  const factory NotesListState.initial() = NotesListInitial;
  const factory NotesListState.loading() = NotesListLoading;
  const factory NotesListState.loaded(List<Note> notes) = NotesListLoaded;
  const factory NotesListState.error(String message) = NotesListError;
}
```

- [ ] **Step 4: Write the cubit**

```dart
// packages/notes/lib/src/features/notes_list/cubit/notes_list_cubit.dart
import 'package:core/core.dart' hide Note;
import 'package:injectable/injectable.dart';

import '../../../domain/entity/note.dart';
import '../../../domain/repository/notes_repository.dart';
import 'notes_list_state.dart';

@injectable
class NotesListCubit extends BaseCubit<NotesListState> {
  NotesListCubit(this._repository) : super(const NotesListState.initial());

  final NotesRepository _repository;

  List<Note> get _currentNotes {
    final current = state;
    return current is NotesListLoaded ? current.notes : const <Note>[];
  }

  Future<void> load() async {
    emit(const NotesListState.loading());
    await runGuarded(() async {
      final result = await _repository.getNotes();
      switch (result) {
        case Success(:final value):
          safeEmit(NotesListState.loaded(value));
        case Failure(:final failure):
          safeEmit(NotesListState.error(failure.message));
      }
    }, onError: (error, stackTrace) => NotesListState.error(error.toString()));
  }

  Future<void> addNote({required String title, required String body}) async {
    final result = await _repository.addNote(title: title, body: body);
    switch (result) {
      case Success(:final value):
        safeEmit(NotesListState.loaded([..._currentNotes, value]));
      case Failure(:final failure):
        safeEmit(NotesListState.error(failure.message));
    }
  }

  Future<void> deleteNote(int id) async {
    final result = await _repository.deleteNote(id);
    switch (result) {
      case Success():
        safeEmit(
          NotesListState.loaded(
            _currentNotes.where((n) => n.id != id).toList(),
          ),
        );
      case Failure(:final failure):
        safeEmit(NotesListState.error(failure.message));
    }
  }
}
```

- [ ] **Step 5: Generate freezed code and run the cubit test**

Run (from `packages/notes`): `dart run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/features/notes_list/notes_list_cubit_test.dart`
Expected: PASS

- [ ] **Step 6: Write the extracted dialog widget**

```dart
// packages/notes/lib/src/features/notes_list/view/widgets/add_note_dialog.dart
import 'package:core/core.dart';
import 'package:flutter/material.dart';

/// A public widget (not a `_buildX()` helper) so it can be tested and reused
/// on its own. Takes [onSave] instead of a cubit so it doesn't need a
/// `BlocProvider` in scope — `showDialog` opens on the root navigator, which
/// sits above this screen's `BlocProvider<NotesListCubit>`.
class AddNoteDialog extends StatelessWidget {
  const AddNoteDialog({super.key, required this.onSave});

  final void Function({required String title, required String body}) onSave;

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    return AlertDialog(
      title: const Text('New note'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(controller: titleController, label: 'Title'),
          const SizedBox(height: 8),
          AppTextField(controller: bodyController, label: 'Body'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Save',
          onPressed: () {
            if (titleController.text.trim().isEmpty) return;
            onSave(title: titleController.text, body: bodyController.text);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
```

- [ ] **Step 7: Write the view**

```dart
// packages/notes/lib/src/features/notes_list/view/notes_list_view.dart
import 'package:core/core.dart' hide Note;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entity/note.dart';
import '../cubit/notes_list_cubit.dart';
import '../cubit/notes_list_state.dart';
import 'widgets/add_note_dialog.dart';

class NotesListView extends BaseView<NotesListCubit, NotesListState> {
  const NotesListView({super.key});

  @override
  PreferredSizeWidget appBar(BuildContext context, NotesListState state) =>
      const AppAppBar(title: 'Notes');

  @override
  Widget body(BuildContext context, NotesListState state) {
    return switch (state) {
      NotesListInitial() || NotesListLoading() => const AppLoadingIndicator(),
      NotesListError(:final message) => AppErrorView(
        message: message,
        onRetry: () => cubitOf(context).load(),
      ),
      NotesListLoaded(:final notes) when notes.isEmpty => const AppEmptyState(
        message: 'No notes yet. Tap + to add one.',
      ),
      NotesListLoaded(:final notes) => ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) => _NoteListTile(note: notes[index]),
      ),
    };
  }

  @override
  Widget? floatingActionButton(BuildContext context, NotesListState state) {
    final cubit = cubitOf(context);
    return FloatingActionButton(
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => AddNoteDialog(
          onSave: ({required title, required body}) =>
              cubit.addNote(title: title, body: body),
        ),
      ),
      child: const Icon(Icons.add),
    );
  }
}

/// Single-use inside [NotesListView.body] but extracted anyway so the tap
/// handler's `await` doesn't get buried inside a `ListView.builder` callback.
class _NoteListTile extends StatelessWidget {
  const _NoteListTile({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.title),
      subtitle: Text(note.body),
      onTap: () async {
        final updated = await context.push<Note>(
          '${AppRoutePaths.notes}/${note.id}',
        );
        if (updated != null && context.mounted) {
          context.read<NotesListCubit>().load();
        }
      },
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => context.read<NotesListCubit>().deleteNote(note.id),
      ),
    );
  }
}
```

Note: `_NoteListTile` is private despite the "extract to a public widget"
rule — it's private because it's a single-file, single-use helper for
`NotesListView` specifically (not reused, not meant to be imported
elsewhere), which is exactly the "inline if single-use" half of that rule.
`AddNoteDialog` is public because it's reusable/testable on its own.

- [ ] **Step 8: Write the screen**

```dart
// packages/notes/lib/src/features/notes_list/view/notes_list_screen.dart
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/notes_list_cubit.dart';
import 'notes_list_view.dart';

/// Thin: resolves this screen's cubit from `getIt` and wraps it in a
/// `BlocProvider`. All UI lives in [NotesListView].
class NotesListScreen extends StatelessWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NotesListCubit>()..load(),
      child: const NotesListView(),
    );
  }
}
```

- [ ] **Step 9: Write the failing widget test, then make it pass**

```dart
// packages/notes/test/features/notes_list/notes_list_view_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart' hide Note;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notes/src/domain/entity/note.dart';
import 'package:notes/src/features/notes_list/cubit/notes_list_cubit.dart';
import 'package:notes/src/features/notes_list/cubit/notes_list_state.dart';
import 'package:notes/src/features/notes_list/view/notes_list_view.dart';

class MockNotesListCubit extends MockCubit<NotesListState>
    implements NotesListCubit {}

void main() {
  late MockNotesListCubit cubit;

  Widget wrap() => MaterialApp(
    theme: AppTheme.light,
    home: BlocProvider<NotesListCubit>.value(
      value: cubit,
      child: const NotesListView(),
    ),
  );

  setUp(() {
    cubit = MockNotesListCubit();
  });

  testWidgets('shows a loading indicator while loading', (tester) async {
    when(() => cubit.state).thenReturn(const NotesListState.loading());
    await tester.pumpWidget(wrap());
    expect(find.byType(AppLoadingIndicator), findsOneWidget);
  });

  testWidgets('shows an empty state when loaded with no notes', (
    tester,
  ) async {
    when(() => cubit.state).thenReturn(const NotesListState.loaded([]));
    await tester.pumpWidget(wrap());
    expect(find.byType(AppEmptyState), findsOneWidget);
  });

  testWidgets('shows a list tile per note when loaded', (tester) async {
    final note = Note(
      id: 1,
      title: 'Groceries',
      body: 'Milk, eggs',
      createdAt: DateTime(2026, 1, 1),
    );
    when(() => cubit.state).thenReturn(NotesListState.loaded([note]));
    await tester.pumpWidget(wrap());
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Milk, eggs'), findsOneWidget);
  });
}
```

Run: `flutter test test/features/notes_list/notes_list_view_test.dart`
Expected: FAIL, then PASS once the files from steps 6-8 are saved.

- [ ] **Step 10: Commit**

```bash
git add packages/notes/lib/src/features/notes_list packages/notes/test/features/notes_list
git commit -m "notes: add notes_list feature (cubit, screen, view, add-note dialog)"
```

---

## Task 8: Notes — `note_detail` feature

**Files:**
- Create: `packages/notes/lib/src/features/note_detail/cubit/note_detail_state.dart`
- Create: `packages/notes/lib/src/features/note_detail/cubit/note_detail_cubit.dart`
- Create: `packages/notes/lib/src/features/note_detail/view/note_detail_screen.dart`
- Create: `packages/notes/lib/src/features/note_detail/view/note_detail_view.dart`
- Test: `packages/notes/test/features/note_detail/note_detail_cubit_test.dart`
- Test: `packages/notes/test/features/note_detail/note_detail_view_test.dart`

**Interfaces:**
- Consumes: `NotesRepository`, `Note` (Task 6); `BaseCubit`, `BaseViewState`
  (Tasks 2-3).
- Produces: `NoteDetailCubit` (`@injectable`, `@factoryParam` on `noteId`;
  methods `load()`, `Future<Note?> save({title, body})`),
  `NoteDetailState` (`initial`/`loading`/`loaded(Note)`/`error(String)`),
  `NoteDetailScreen({required int noteId})` (resolves
  `getIt<NoteDetailCubit>(param1: noteId)`). Task 9's routing wiring
  references `NoteDetailScreen`.

- [ ] **Step 1: Write the failing cubit test**

```dart
// packages/notes/test/features/note_detail/note_detail_cubit_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart' hide Note;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notes/src/domain/entity/note.dart';
import 'package:notes/src/domain/repository/notes_repository.dart';
import 'package:notes/src/features/note_detail/cubit/note_detail_cubit.dart';
import 'package:notes/src/features/note_detail/cubit/note_detail_state.dart';

class MockNotesRepository extends Mock implements NotesRepository {}

void main() {
  late MockNotesRepository repository;

  final note = Note(
    id: 1,
    title: 'Groceries',
    body: 'Milk, eggs',
    createdAt: DateTime(2026, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(
      Note(id: 0, title: '', body: '', createdAt: DateTime(2000)),
    );
  });

  setUp(() {
    repository = MockNotesRepository();
  });

  group('NoteDetailCubit', () {
    blocTest<NoteDetailCubit, NoteDetailState>(
      'emits [loading, loaded] when load succeeds',
      build: () {
        when(
          () => repository.getNoteById(1),
        ).thenAnswer((_) async => Success(note));
        return NoteDetailCubit(1, repository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const NoteDetailState.loading(),
        NoteDetailState.loaded(note),
      ],
    );

    blocTest<NoteDetailCubit, NoteDetailState>(
      'emits [loading, error] when the note is not found',
      build: () {
        when(() => repository.getNoteById(1)).thenAnswer(
          (_) async => const Failure(StorageFailure('Note not found.')),
        );
        return NoteDetailCubit(1, repository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [const NoteDetailState.loading(), isA<NoteDetailError>()],
    );

    blocTest<NoteDetailCubit, NoteDetailState>(
      'save updates the note and re-emits loaded',
      build: () {
        when(
          () => repository.getNoteById(1),
        ).thenAnswer((_) async => Success(note));
        when(
          () => repository.updateNote(any()),
        ).thenAnswer((_) async => const Success(null));
        return NoteDetailCubit(1, repository);
      },
      act: (cubit) => cubit
          .load()
          .then((_) => cubit.save(title: 'Updated', body: 'New body')),
      expect: () => [
        const NoteDetailState.loading(),
        NoteDetailState.loaded(note),
        NoteDetailState.loaded(
          note.copyWith(title: 'Updated', body: 'New body'),
        ),
      ],
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/note_detail/note_detail_cubit_test.dart`
Expected: FAIL — none of the imported files exist yet.

- [ ] **Step 3: Write the state**

```dart
// packages/notes/lib/src/features/note_detail/cubit/note_detail_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/entity/note.dart';

part 'note_detail_state.freezed.dart';

@freezed
sealed class NoteDetailState with _$NoteDetailState {
  const factory NoteDetailState.initial() = NoteDetailInitial;
  const factory NoteDetailState.loading() = NoteDetailLoading;
  const factory NoteDetailState.loaded(Note note) = NoteDetailLoaded;
  const factory NoteDetailState.error(String message) = NoteDetailError;
}
```

- [ ] **Step 4: Write the cubit**

```dart
// packages/notes/lib/src/features/note_detail/cubit/note_detail_cubit.dart
import 'package:core/core.dart' hide Note;
import 'package:injectable/injectable.dart';

import '../../../domain/entity/note.dart';
import '../../../domain/repository/notes_repository.dart';
import 'note_detail_state.dart';

@injectable
class NoteDetailCubit extends BaseCubit<NoteDetailState> {
  NoteDetailCubit(@factoryParam this.noteId, this._repository)
    : super(const NoteDetailState.initial());

  final int noteId;
  final NotesRepository _repository;

  Future<void> load() async {
    emit(const NoteDetailState.loading());
    await runGuarded(() async {
      final result = await _repository.getNoteById(noteId);
      switch (result) {
        case Success(:final value):
          safeEmit(NoteDetailState.loaded(value));
        case Failure(:final failure):
          safeEmit(NoteDetailState.error(failure.message));
      }
    }, onError: (error, stackTrace) => NoteDetailState.error(error.toString()));
  }

  /// Returns the updated note on success, so the screen can pop with a
  /// result the notes-list screen uses to know it should refresh.
  Future<Note?> save({required String title, required String body}) async {
    final current = state;
    if (current is! NoteDetailLoaded) return null;
    final updated = current.note.copyWith(title: title, body: body);
    final result = await _repository.updateNote(updated);
    switch (result) {
      case Success():
        safeEmit(NoteDetailState.loaded(updated));
        return updated;
      case Failure(:final failure):
        safeEmit(NoteDetailState.error(failure.message));
        return null;
    }
  }
}
```

- [ ] **Step 5: Generate freezed code and run the cubit test**

Run (from `packages/notes`): `dart run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/features/note_detail/note_detail_cubit_test.dart`
Expected: PASS

- [ ] **Step 6: Write the view**

```dart
// packages/notes/lib/src/features/note_detail/view/note_detail_view.dart
import 'package:core/core.dart' hide Note;
import 'package:flutter/material.dart';

import '../cubit/note_detail_cubit.dart';
import '../cubit/note_detail_state.dart';

class NoteDetailView extends StatefulWidget {
  const NoteDetailView({super.key});

  @override
  State<NoteDetailView> createState() => _NoteDetailViewState();
}

class _NoteDetailViewState
    extends BaseViewState<NoteDetailView, NoteDetailCubit, NoteDetailState> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  int? _loadedNoteId;

  @override
  void onStateChanged(BuildContext context, NoteDetailState state) {
    if (state is NoteDetailLoaded && _loadedNoteId != state.note.id) {
      _loadedNoteId = state.note.id;
      _titleController = TextEditingController(text: state.note.title);
      _bodyController = TextEditingController(text: state.note.body);
    }
  }

  @override
  PreferredSizeWidget appBar(BuildContext context, NoteDetailState state) =>
      const AppAppBar(title: 'Edit note');

  @override
  Widget body(BuildContext context, NoteDetailState state) {
    return switch (state) {
      NoteDetailInitial() || NoteDetailLoading() => const AppLoadingIndicator(),
      NoteDetailError(:final message) => AppErrorView(message: message),
      NoteDetailLoaded() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppTextField(controller: _titleController, label: 'Title'),
            const SizedBox(height: 12),
            AppTextField(controller: _bodyController, label: 'Body'),
            const SizedBox(height: 16),
            AppButton(
              label: 'Save',
              onPressed: () async {
                final updated = await cubitOf(context).save(
                  title: _titleController.text,
                  body: _bodyController.text,
                );
                if (updated != null && context.mounted) {
                  Navigator.of(context).pop(updated);
                }
              },
            ),
          ],
        ),
      ),
    };
  }
}
```

- [ ] **Step 7: Write the screen**

```dart
// packages/notes/lib/src/features/note_detail/view/note_detail_screen.dart
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/note_detail_cubit.dart';
import 'note_detail_view.dart';

/// Thin: resolves this screen's cubit (keyed by [noteId]) from `getIt` and
/// wraps it in a `BlocProvider`. All UI lives in [NoteDetailView].
class NoteDetailScreen extends StatelessWidget {
  const NoteDetailScreen({super.key, required this.noteId});

  final int noteId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NoteDetailCubit>(param1: noteId)..load(),
      child: const NoteDetailView(),
    );
  }
}
```

- [ ] **Step 8: Write the failing widget test, then make it pass**

```dart
// packages/notes/test/features/note_detail/note_detail_view_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart' hide Note;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notes/src/domain/entity/note.dart';
import 'package:notes/src/features/note_detail/cubit/note_detail_cubit.dart';
import 'package:notes/src/features/note_detail/cubit/note_detail_state.dart';
import 'package:notes/src/features/note_detail/view/note_detail_view.dart';

class MockNoteDetailCubit extends MockCubit<NoteDetailState>
    implements NoteDetailCubit {}

void main() {
  late MockNoteDetailCubit cubit;

  Widget wrap() => MaterialApp(
    theme: AppTheme.light,
    home: BlocProvider<NoteDetailCubit>.value(
      value: cubit,
      child: const NoteDetailView(),
    ),
  );

  setUp(() {
    cubit = MockNoteDetailCubit();
  });

  testWidgets('shows a loading indicator while loading', (tester) async {
    when(() => cubit.state).thenReturn(const NoteDetailState.loading());
    await tester.pumpWidget(wrap());
    expect(find.byType(AppLoadingIndicator), findsOneWidget);
  });

  testWidgets('shows the note fields once loaded', (tester) async {
    final note = Note(
      id: 1,
      title: 'Groceries',
      body: 'Milk, eggs',
      createdAt: DateTime(2026, 1, 1),
    );
    when(() => cubit.state).thenReturn(NoteDetailState.loaded(note));
    await tester.pumpWidget(wrap());
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Milk, eggs'), findsOneWidget);
  });
}
```

Run: `flutter test test/features/note_detail/note_detail_view_test.dart`
Expected: FAIL, then PASS once the files from steps 6-7 are saved.

- [ ] **Step 9: Commit**

```bash
git add packages/notes/lib/src/features/note_detail packages/notes/test/features/note_detail
git commit -m "notes: add note_detail feature (cubit, screen, view)"
```

---

## Task 9: Notes — DI + routing cutover, delete the old shape

**Files:**
- Create: `packages/notes/lib/src/di/notes_dependencies.dart` (rewritten)
- Create: `packages/notes/lib/src/routing/notes_routes.dart` (rewritten)
- Modify: `packages/notes/lib/notes.dart` (barrel)
- Modify: `app/lib/router/app_router.dart` (call-site: `notesShellBranch(getIt)` -> `notesShellBranch()`)
- Modify: `app/test/app_smoke_test.dart` (`_FakeNotesRepository` matches the new `Result`-based interface)
- Delete: `packages/notes/lib/src/entity/`, `packages/notes/lib/src/repository/`, `packages/notes/lib/src/cubit/`, `packages/notes/lib/src/view/`
- Delete: `packages/notes/test/cubit/notes_cubit_test.dart`, `packages/notes/test/view/notes_list_page_test.dart`

**Interfaces:**
- Consumes: everything from Tasks 6-8.
- Produces: the fully cut-over `packages/notes` public API
  (`lib/notes.dart` exports the new domain/data/features/di/routing tree);
  `notesShellBranch()` (no-arg, unlike the old `notesShellBranch(GetIt)`).

This task has no new business logic to TDD — it's a rewire-and-delete.
Verification is `flutter analyze`/`flutter test` passing across both
`packages/notes` and `app` at the end.

- [ ] **Step 1: Rewrite the DI entry point**

```dart
// packages/notes/lib/src/di/notes_dependencies.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'notes_dependencies.config.dart';

/// Generated init, covers every `@injectable`/`@LazySingleton` registration
/// in this package (the repository, the datasource, and both feature
/// cubits). `NoteDetailCubit` is a `@factoryParam` factory — resolve it with
/// `getIt<NoteDetailCubit>(param1: noteId)`.
@InjectableInit()
void registerNotesDependencies(GetIt getIt) => getIt.init();
```

- [ ] **Step 2: Rewrite routing**

```dart
// packages/notes/lib/src/routing/notes_routes.dart
import 'package:core/core.dart';
import 'package:go_router/go_router.dart';

import '../features/note_detail/view/note_detail_screen.dart';
import '../features/notes_list/view/notes_list_screen.dart';

/// This feature's `StatefulShellBranch`, for `app` to plug into the
/// bottom-nav shell alongside the Home and Settings branches.
///
/// Each screen resolves its own cubit from `getIt` (see
/// `notes_list_screen.dart`/`note_detail_screen.dart`) and is independently
/// repository-backed, so — unlike before — this file wires no shared
/// `BlocProvider`/`ShellRoute` of its own.
StatefulShellBranch notesShellBranch() {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: AppRoutePaths.notes,
        builder: (_, _) => const NotesListScreen(),
      ),
      GoRoute(
        path: '${AppRoutePaths.notes}/:id',
        builder: (_, state) =>
            NoteDetailScreen(noteId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
}
```

- [ ] **Step 3: Delete the old files**

```bash
cd packages/notes
git rm -r lib/src/entity lib/src/repository lib/src/cubit lib/src/view
git rm test/cubit/notes_cubit_test.dart test/view/notes_list_page_test.dart
```

- [ ] **Step 4: Rewrite the barrel**

```dart
// packages/notes/lib/notes.dart
/// The one example feature package: generic CRUD notes, backed by core's
/// Drift `AppDatabase`. `domain/`+`data/` are feature-wide; `cubit/`+`view/`
/// nest per screen under `features/` since each screen owns its own state
/// independently.
library;

export 'src/data/datasource/notes_local_data_source.dart';
export 'src/data/repository_impl/notes_repository_impl.dart';
export 'src/di/notes_dependencies.dart';
export 'src/domain/entity/note.dart';
export 'src/domain/repository/notes_repository.dart';
export 'src/features/note_detail/cubit/note_detail_cubit.dart';
export 'src/features/note_detail/cubit/note_detail_state.dart';
export 'src/features/note_detail/view/note_detail_screen.dart';
export 'src/features/note_detail/view/note_detail_view.dart';
export 'src/features/notes_list/cubit/notes_list_cubit.dart';
export 'src/features/notes_list/cubit/notes_list_state.dart';
export 'src/features/notes_list/view/notes_list_screen.dart';
export 'src/features/notes_list/view/notes_list_view.dart';
export 'src/routing/notes_routes.dart';
```

- [ ] **Step 5: Update the app router call site**

In `app/lib/router/app_router.dart`, change:

```dart
          notesShellBranch(getIt),
```

to:

```dart
          notesShellBranch(),
```

- [ ] **Step 6: Update the app smoke test's fake repository**

In `app/test/app_smoke_test.dart`, replace the `_FakeNotesRepository` class
with one matching the new interface:

```dart
class _FakeNotesRepository implements NotesRepository {
  @override
  Future<Result<List<Note>, AppFailure>> getNotes() async => const Success([]);
  @override
  Future<Result<Note, AppFailure>> getNoteById(int id) async =>
      const Failure(StorageFailure('Note not found.'));
  @override
  Future<Result<Note, AppFailure>> addNote({
    required String title,
    required String body,
  }) => throw UnimplementedError();
  @override
  Future<Result<void, AppFailure>> updateNote(Note note) async =>
      const Success(null);
  @override
  Future<Result<void, AppFailure>> deleteNote(int id) async =>
      const Success(null);
}
```

(`Result`, `Success`, `Failure`, `AppFailure`, `StorageFailure` are already
in scope via the file's existing `import 'package:core/core.dart' hide
Note;`.)

- [ ] **Step 7: Regenerate and run the full suite**

Run (from `packages/notes`): `dart run build_runner build --delete-conflicting-outputs`
Run (from repo root): `dart pub get`

Run (from `packages/notes`): `flutter analyze && flutter test`
Expected: no analyzer errors; every test under `packages/notes/test`
(Tasks 6-8's new tests) passes; no leftover references to the deleted files.

Run (from `app`): `flutter analyze && flutter test`
Expected: no analyzer errors; `app_smoke_test.dart` passes.

- [ ] **Step 8: Commit**

```bash
git add -A packages/notes app/lib/router/app_router.dart app/test/app_smoke_test.dart
git commit -m "notes: cut over DI/routing to the new domain/data/features shape"
```

---

## Task 10: `tool/new_feature.sh` — scaffold the new shape

**Files:**
- Modify: `tool/new_feature.sh`

**Interfaces:**
- Consumes: nothing (shell script). Its output is whatever
  `packages/notes` looks like after Task 9 — no template-shape logic to
  change, since the script works by `rsync`-copying `packages/notes`
  verbatim and substituting names in file contents/paths.

- [ ] **Step 1: Update the route-branch insertion line**

In `tool/new_feature.sh`, change:

```bash
  insert_before_marker "$ROUTER" "$ROUTE_MARKER" "${PLURAL_LOWER}ShellBranch(getIt),"
  if grep -qF "${PLURAL_LOWER}ShellBranch(getIt)," "$ROUTER"; then
    echo "Wired ${PLURAL_LOWER}ShellBranch(getIt) into app/lib/router/app_router.dart"
```

to:

```bash
  insert_before_marker "$ROUTER" "$ROUTE_MARKER" "${PLURAL_LOWER}ShellBranch(),"
  if grep -qF "${PLURAL_LOWER}ShellBranch()," "$ROUTER"; then
    echo "Wired ${PLURAL_LOWER}ShellBranch() into app/lib/router/app_router.dart"
```

(The DI-wiring insertion — `register${PLURAL_UPPER}Dependencies(getIt);` —
needs no change: `registerNotesDependencies`'s name and signature didn't
change in Task 9.)

- [ ] **Step 2: Update the "next manual steps" message**

In the `cat <<EOF ... EOF` block at the end of the script, change the
repository_impl path reference from:

```
       $PLURAL_LOWER/lib/src/repository/${PLURAL_LOWER}_repository_impl.dart
```

to:

```
       $PLURAL_LOWER/lib/src/data/repository_impl/${PLURAL_LOWER}_repository_impl.dart
```

and the mention of what still calls the notes-specific database methods:

```
  2. Add a "$PLURAL_LOWER" table + DAO methods to packages/core's AppDatabase
     (Notes/watchAllNotes/createNote/etc. were copied by name, not
     regenerated — packages/$PLURAL_LOWER/lib/src/data/repository_impl/${PLURAL_LOWER}_repository_impl.dart
     still calls the notes ones).
```

- [ ] **Step 3: Verify by dry-running the scaffold**

Run (from repo root): `tool/new_feature.sh todos`

Expected: `packages/todos` is created with a `lib/src/{domain,data,features,di,routing}`
tree (mirroring the now-restructured `packages/notes`), and the printed
"Next manual steps" reference the `data/repository_impl/` path. Inspect
`packages/todos/lib/src/routing/todos_routes.dart` — it should define
`StatefulShellBranch todosShellBranch()` (no `GetIt` parameter) and
`app/lib/router/app_router.dart` should now contain `todosShellBranch(),`.

Then remove the dry-run scaffold and revert the router/bootstrap edits it made:

```bash
rm -rf packages/todos
git checkout -- app/lib/bootstrap.dart app/lib/router/app_router.dart
```

- [ ] **Step 4: Commit**

```bash
git add tool/new_feature.sh
git commit -m "tool: update new_feature.sh for the domain/data/features scaffold"
```

---

## Task 11: `CLAUDE.md` — document the new conventions

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Replace the "Feature package shape" section**

Replace the existing code block under `**Feature package shape**...` with:

````markdown
**Feature package shape** (`packages/notes` is the template — copy it,
don't build from scratch):

```
lib/<feature>.dart                                    # barrel export = public API
lib/src/domain/entity/<thing>.dart                    # freezed + json_serializable model
lib/src/domain/repository/<feature>_repository.dart   # interface — returns Result<T, AppFailure>
lib/src/data/datasource/<feature>_local_data_source.dart  # wraps core's AppDatabase/Hive/etc. — the
                                                           # only file touching that storage directly
lib/src/data/repository_impl/<feature>_repository_impl.dart  # implements the domain repository,
                                                               # delegates to the datasource
lib/src/features/<screen>/cubit/<screen>_cubit.dart / _state.dart  # one cubit per screen — no
                                                                    # cross-screen shared cubit;
                                                                    # a screen needing another
                                                                    # screen's data goes through the
                                                                    # repository, not a shared cubit
lib/src/features/<screen>/view/<screen>_screen.dart   # resolves this screen's cubit from `getIt`
                                                       # (getIt<Cubit>() or getIt<Cubit>(param1: x)
                                                       # for one needing a route param) and wraps it
                                                       # in a BlocProvider — the GoRoute target
lib/src/features/<screen>/view/<screen>_view.dart     # pure UI, extends core's BaseView/BaseViewState
lib/src/features/<screen>/view/widgets/*.dart         # sub-widgets extracted out of that screen's
                                                       # body() — see the widget-composition rule below
lib/src/di/<feature>_dependencies.dart        # @InjectableInit() entry point (see DI below)
lib/src/routing/<feature>_routes.dart         # this feature's StatefulShellBranch/GoRoute list
test/features/<screen>/..., test/data/...     # bloc_test+mocktail against the repository interface,
                                               # widget test with a mocked cubit
```
````

- [ ] **Step 2: Update the DI paragraph**

Replace the existing `**DI:**` paragraph with:

```markdown
**DI:** `get_it` + `injectable` codegen. Repositories, datasources, and
core services carry `@LazySingleton(as: ...)`/`@lazySingleton`/`@injectable`
annotations (or an `@module` provider in `core_module.dart` for a class
injectable can't construct directly — an optional test-only constructor
param, or an async `init()` step); each package's `di/<feature>_dependencies.dart`
carries a single `@InjectableInit()` entry point that the generated
`getIt.init()` implements. `getIt` is `core`'s single global `GetIt.instance`.
Cubits are `@injectable` too — a cubit needing a route parameter (e.g.
`NoteDetailCubit`'s `noteId`) takes it via `@factoryParam`; screens resolve
with `getIt<Cubit>()` or `getIt<Cubit>(param1: ...)` rather than
constructing the cubit and its dependencies by hand.
```

- [ ] **Step 3: Add the screen/view/widget-composition convention**

Add a new subsection after "Wiring a feature into the app" and before
"Storage":

```markdown
**Screen/view split and widget composition:** a screen has two files.
`<screen>_screen.dart` is thin — it only resolves the screen's cubit from
`getIt` and wraps it in a `BlocProvider`; it's the `GoRoute`/`ShellRoute`
builder target. `<screen>_view.dart` holds the actual UI — `extends
BaseView<Cubit, State>` (or `BaseViewState` for a screen needing
`initState`/local controllers, from `core`'s `base/` — overrides `appBar()`
and `body()`; `BaseViewMixin` owns the `BlocConsumer -> Scaffold -> SafeArea`
shell so no screen hand-rolls it. No private `Widget _buildX()` helper
methods: inline a sub-widget in `body()` if it's used once; if it's reused,
non-trivial, or needed to keep `body()` readable, extract it as a public
`Widget` class into its own file under that screen's `view/widgets/`
folder.
```

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md for the domain/data/features convention"
```
