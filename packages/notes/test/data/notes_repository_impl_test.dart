import 'package:core/core.dart' as core;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes/src/data/datasource/notes_local_data_source.dart';
import 'package:notes/src/data/repository_impl/notes_repository_impl.dart';

void main() {
  late core.AppDatabase database;
  late NotesRepositoryImpl repository;

  setUp(() {
    database = core.AppDatabase(NativeDatabase.memory());
    repository = NotesRepositoryImpl(DriftNotesLocalDataSource(database));
  });

  tearDown(() => database.close());

  test('addNote then getNotes round-trips through Drift', () async {
    final added = await repository.addNote(title: 'Groceries', body: 'Milk');
    expect(added, isA<core.Success<dynamic, dynamic>>());

    final all = await repository.getNotes();
    final notes = (all as core.Success).value;
    expect(notes, hasLength(1));
    expect(notes.first.title, 'Groceries');
  });

  test('getNoteById returns a StorageFailure for an unknown id', () async {
    final result = await repository.getNoteById(999);
    expect(result, isA<core.Failure<dynamic, dynamic>>());
    expect((result as core.Failure).failure, isA<core.StorageFailure>());
  });
}
