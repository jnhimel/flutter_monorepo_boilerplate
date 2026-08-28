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
