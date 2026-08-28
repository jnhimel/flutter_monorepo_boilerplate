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
