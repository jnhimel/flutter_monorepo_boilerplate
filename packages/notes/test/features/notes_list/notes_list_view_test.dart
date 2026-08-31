import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart' hide Note;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notes/src/domain/entity/note.dart';
import 'package:notes/src/features/notes_list/cubit/notes_list_cubit.dart';
import 'package:notes/src/features/notes_list/cubit/notes_list_state.dart';
import 'package:notes/src/features/notes_list/view/notes_list_view.dart';

class MockNotesListCubit extends MockCubit<NotesListState>
    implements NotesListCubit {}

void main() {
  late MockNotesListCubit cubit;

  Widget wrap() => MaterialApp(
    theme: AppTheme.light,
    home: BlocProvider<NotesListCubit>.value(
      value: cubit,
      child: const NotesListView(),
    ),
  );

  setUp(() {
    cubit = MockNotesListCubit();
  });

  testWidgets('shows a loading indicator while loading', (tester) async {
    when(() => cubit.state).thenReturn(const NotesListState.loading());
    await tester.pumpWidget(wrap());
    expect(find.byType(AppLoadingIndicator), findsOneWidget);
  });

  testWidgets('shows an empty state when loaded with no notes', (tester) async {
    when(() => cubit.state).thenReturn(const NotesListState.loaded([]));
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
    when(() => cubit.state).thenReturn(NotesListState.loaded([note]));
    await tester.pumpWidget(wrap());
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Milk, eggs'), findsOneWidget);
  });
}
