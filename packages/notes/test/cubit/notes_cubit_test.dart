import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notes/notes.dart';

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

  group('NotesCubit', () {
    blocTest<NotesCubit, NotesState>(
      'emits [loading, loaded] when load succeeds',
      build: () {
        when(() => repository.getNotes()).thenAnswer((_) async => [note]);
        return NotesCubit(repository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const NotesState.loading(),
        NotesState.loaded([note]),
      ],
    );

    blocTest<NotesCubit, NotesState>(
      'emits [loading, error] when load fails',
      build: () {
        when(() => repository.getNotes()).thenThrow(Exception('boom'));
        return NotesCubit(repository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [const NotesState.loading(), isA<NotesError>()],
    );

    blocTest<NotesCubit, NotesState>(
      'addNote appends the created note and re-emits loaded',
      build: () {
        when(() => repository.getNotes()).thenAnswer((_) async => []);
        when(() => repository.addNote(title: 'New', body: 'Body'))
            .thenAnswer((_) async => note);
        return NotesCubit(repository);
      },
      act: (cubit) =>
          cubit.load().then((_) => cubit.addNote(title: 'New', body: 'Body')),
      expect: () => [
        const NotesState.loading(),
        const NotesState.loaded([]),
        NotesState.loaded([note]),
      ],
    );

    blocTest<NotesCubit, NotesState>(
      'deleteNote removes the note and re-emits loaded',
      build: () {
        when(() => repository.getNotes()).thenAnswer((_) async => [note]);
        when(() => repository.deleteNote(1)).thenAnswer((_) async {});
        return NotesCubit(repository);
      },
      act: (cubit) => cubit.load().then((_) => cubit.deleteNote(1)),
      expect: () => [
        const NotesState.loading(),
        NotesState.loaded([note]),
        const NotesState.loaded([]),
      ],
    );
  });
}
