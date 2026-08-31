import 'package:core/core.dart' as core;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:notes/notes.dart';

void main() {
  test(
    'registerNotesDependencies wires the repository and both feature cubits',
    () {
      final getIt = GetIt.asNewInstance();
      getIt.registerLazySingleton<core.AppDatabase>(
        () => core.AppDatabase(NativeDatabase.memory()),
      );

      registerNotesDependencies(getIt);

      expect(getIt<NotesRepository>(), isA<NotesRepositoryImpl>());
      expect(getIt<NotesListCubit>(), isA<NotesListCubit>());
      expect(getIt<NoteDetailCubit>(param1: 7).noteId, 7);

      getIt.reset();
    },
  );
}
