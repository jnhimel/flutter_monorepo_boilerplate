import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart' hide Note;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notes/src/domain/entity/note.dart';
import 'package:notes/src/features/note_detail/cubit/note_detail_cubit.dart';
import 'package:notes/src/features/note_detail/cubit/note_detail_state.dart';
import 'package:notes/src/features/note_detail/view/note_detail_view.dart';

class MockNoteDetailCubit extends MockCubit<NoteDetailState>
    implements NoteDetailCubit {}

void main() {
  late MockNoteDetailCubit cubit;

  Widget wrap() => MaterialApp(
    theme: AppTheme.light,
    home: BlocProvider<NoteDetailCubit>.value(
      value: cubit,
      child: const NoteDetailView(),
    ),
  );

  setUp(() {
    cubit = MockNoteDetailCubit();
  });

  testWidgets('shows a loading indicator while loading', (tester) async {
    when(() => cubit.state).thenReturn(const NoteDetailState.loading());
    await tester.pumpWidget(wrap());
    expect(find.byType(AppLoadingIndicator), findsOneWidget);
  });

  testWidgets('shows the note fields once loaded', (tester) async {
    final note = Note(
      id: 1,
      title: 'Groceries',
      body: 'Milk, eggs',
      createdAt: DateTime(2026, 1, 1),
    );
    when(() => cubit.state).thenReturn(NoteDetailState.loaded(note));
    await tester.pumpWidget(wrap());
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Milk, eggs'), findsOneWidget);
  });
}
