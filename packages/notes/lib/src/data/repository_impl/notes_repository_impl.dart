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
