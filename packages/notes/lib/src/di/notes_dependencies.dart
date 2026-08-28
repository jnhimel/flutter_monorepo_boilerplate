import 'package:core/core.dart';
import 'package:get_it/get_it.dart';

import '../repository/notes_repository.dart';
import '../repository/notes_repository_impl.dart';

// ponytail: manual get_it registration, matching core's pattern — see
// core's service_locator.dart for the rationale.

/// Registers this feature's dependencies. `NotesCubit` is deliberately NOT
/// registered here — it's created per-screen via `BlocProvider` in the view
/// layer instead.
void registerNotesDependencies(GetIt getIt) {
  getIt.registerLazySingleton<NotesRepository>(
    () => NotesRepositoryImpl(getIt<AppDatabase>()),
  );
}
