import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// The one real Drift table in this boilerplate — demonstrates query
/// generation (`packages/notes` persists through this, not a mock).
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get body => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Notes])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'app.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }

  Stream<List<Note>> watchAllNotes() =>
      (select(notes)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Future<Note> createNote({required String title, required String body}) async {
    final id = await into(notes)
        .insert(NotesCompanion.insert(title: title, body: Value(body)));
    return (select(notes)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> updateNote(Note note) => update(notes).replace(note);

  Future<void> deleteNote(int id) =>
      (delete(notes)..where((t) => t.id.equals(id))).go();
}
