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
        when(() => repository.getNoteById(1))
            .thenAnswer((_) async => Success(note));
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
        when(() => repository.getNoteById(1))
            .thenAnswer((_) async => Success(note));
        when(() => repository.updateNote(any()))
            .thenAnswer((_) async => const Success(null));
        return NoteDetailCubit(1, repository);
      },
      act: (cubit) => cubit.load().then(
        (_) => cubit.save(title: 'Updated', body: 'New body'),
      ),
      expect: () => [
        const NoteDetailState.loading(),
        NoteDetailState.loaded(note),
        NoteDetailState.loaded(
          note.copyWith(title: 'Updated', body: 'New body'),
        ),
      ],
    );

    blocTest<NoteDetailCubit, NoteDetailState>(
      'save emits an error state when the repository reports a failure',
      build: () {
        when(() => repository.getNoteById(1))
            .thenAnswer((_) async => Success(note));
        when(() => repository.updateNote(any()))
            .thenAnswer((_) async => const Failure(StorageFailure()));
        return NoteDetailCubit(1, repository);
      },
      act: (cubit) => cubit.load().then(
        (_) => cubit.save(title: 'Updated', body: 'New body'),
      ),
      expect: () => [
        const NoteDetailState.loading(),
        NoteDetailState.loaded(note),
        isA<NoteDetailError>(),
      ],
    );
  });
}
