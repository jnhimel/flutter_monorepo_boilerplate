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
        when(() => repository.getNotes())
            .thenAnswer((_) async => Success([note]));
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
        when(() => repository.getNotes())
            .thenAnswer((_) async => const Failure(StorageFailure()));
        return NotesListCubit(repository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [const NotesListState.loading(), isA<NotesListError>()],
    );

    blocTest<NotesListCubit, NotesListState>(
      'addNote appends the created note and re-emits loaded',
      build: () {
        when(() => repository.getNotes())
            .thenAnswer((_) async => const Success([]));
        when(() => repository.addNote(title: 'New', body: 'Body'))
            .thenAnswer((_) async => Success(note));
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
        when(() => repository.getNotes())
            .thenAnswer((_) async => Success([note]));
        when(() => repository.deleteNote(1))
            .thenAnswer((_) async => const Success(null));
        return NotesListCubit(repository);
      },
      act: (cubit) => cubit.load().then((_) => cubit.deleteNote(1)),
      expect: () => [
        const NotesListState.loading(),
        NotesListState.loaded([note]),
        const NotesListState.loaded([]),
      ],
    );

    blocTest<NotesListCubit, NotesListState>(
      'addNote emits an error state when the repository reports a failure',
      build: () {
        when(() => repository.getNotes())
            .thenAnswer((_) async => const Success([]));
        when(() => repository.addNote(title: 'New', body: 'Body'))
            .thenAnswer((_) async => const Failure(StorageFailure()));
        return NotesListCubit(repository);
      },
      act: (cubit) =>
          cubit.load().then((_) => cubit.addNote(title: 'New', body: 'Body')),
      expect: () => [
        const NotesListState.loading(),
        const NotesListState.loaded([]),
        isA<NotesListError>(),
      ],
    );

    blocTest<NotesListCubit, NotesListState>(
      'deleteNote emits an error state when the repository reports a failure',
      build: () {
        when(() => repository.getNotes())
            .thenAnswer((_) async => Success([note]));
        when(() => repository.deleteNote(1))
            .thenAnswer((_) async => const Failure(StorageFailure()));
        return NotesListCubit(repository);
      },
      act: (cubit) => cubit.load().then((_) => cubit.deleteNote(1)),
      expect: () => [
        const NotesListState.loading(),
        NotesListState.loaded([note]),
        isA<NotesListError>(),
      ],
    );
  });
}
