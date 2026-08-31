import 'package:core/core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  group('AppDatabase.getNoteById', () {
    test('returns the matching note', () async {
      final created = await database.createNote(
        title: 'Groceries',
        body: 'Milk',
      );
      final found = await database.getNoteById(created.id);
      expect(found?.title, 'Groceries');
    });

    test('returns null for an unknown id', () async {
      final found = await database.getNoteById(999);
      expect(found, isNull);
    });
  });
}
