import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart' hide Note;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notes/notes.dart';

class MockNotesRepository extends Mock implements NotesRepository {}

class MockNotesCubit extends MockCubit<NotesState> implements NotesCubit {}

void main() {
  late MockNotesCubit cubit;

  Widget wrap() => MaterialApp(
    theme: AppTheme.light,
    home: BlocProvider<NotesCubit>.value(
      value: cubit,
      child: const NotesListPage(),
    ),
  );

  setUp(() {
    cubit = MockNotesCubit();
  });

  testWidgets('shows a loading indicator while loading', (tester) async {
    when(() => cubit.state).thenReturn(const NotesState.loading());
    await tester.pumpWidget(wrap());
    expect(find.byType(AppLoadingIndicator), findsOneWidget);
  });

  testWidgets('shows an empty state when loaded with no notes', (tester) async {
    when(() => cubit.state).thenReturn(const NotesState.loaded([]));
    await tester.pumpWidget(wrap());
    expect(find.byType(AppEmptyState), findsOneWidget);
  });

  testWidgets('shows a list tile per note when loaded', (tester) async {
    final note = Note(
      id: 1,
      title: 'Groceries',
      body: 'Milk, eggs',
      createdAt: DateTime(2026, 1, 1),
    );
    when(() => cubit.state).thenReturn(NotesState.loaded([note]));
    await tester.pumpWidget(wrap());
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Milk, eggs'), findsOneWidget);
  });
}
