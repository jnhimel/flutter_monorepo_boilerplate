import 'package:core/core.dart' as core;

import '../entity/note.dart';
import 'notes_repository.dart';

/// Persists notes through core's `AppDatabase` (Drift). This is the only
/// file in this package that touches Drift directly — `NotesCubit` is
/// tested against the [NotesRepository] interface instead.
class NotesRepositoryImpl implements NotesRepository {
  NotesRepositoryImpl(this._database);

  final core.AppDatabase _database;

  Note _fromRow(core.Note row) => Note(
    id: row.id,
    title: row.title,
    body: row.body,
    createdAt: row.createdAt,
  );

  @override
  Future<List<Note>> getNotes() async {
    final rows = await _database.watchAllNotes().first;
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Note> addNote({required String title, required String body}) async {
    final row = await _database.createNote(title: title, body: body);
    return _fromRow(row);
  }

  @override
  Future<void> updateNote(Note note) => _database.updateNote(
    core.Note(
      id: note.id,
      title: note.title,
      body: note.body,
      createdAt: note.createdAt,
    ),
  );

  @override
  Future<void> deleteNote(int id) => _database.deleteNote(id);
}
