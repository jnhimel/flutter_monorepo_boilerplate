import 'package:freezed_annotation/freezed_annotation.dart';

import '../entity/note.dart';

part 'notes_state.freezed.dart';

@freezed
sealed class NotesState with _$NotesState {
  const factory NotesState.initial() = NotesInitial;
  const factory NotesState.loading() = NotesLoading;
  const factory NotesState.loaded(List<Note> notes) = NotesLoaded;
  const factory NotesState.error(String message) = NotesError;
}
