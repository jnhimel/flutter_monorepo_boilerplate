import '../entity/note.dart';

/// The seam `NotesCubit` is tested against — a mocktail fake in
/// `notes_cubit_test.dart` stands in for [NotesRepositoryImpl] so the cubit
/// test never touches Drift directly.
abstract class NotesRepository {
  Future<List<Note>> getNotes();
  Future<Note> addNote({required String title, required String body});
  Future<void> updateNote(Note note);
  Future<void> deleteNote(int id);
}
