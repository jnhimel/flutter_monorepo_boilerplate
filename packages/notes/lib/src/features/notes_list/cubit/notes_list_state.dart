import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/entity/note.dart';

part 'notes_list_state.freezed.dart';

@freezed
sealed class NotesListState with _$NotesListState {
  const factory NotesListState.initial() = NotesListInitial;
  const factory NotesListState.loading() = NotesListLoading;
  const factory NotesListState.loaded(List<Note> notes) = NotesListLoaded;
  const factory NotesListState.error(String message) = NotesListError;
}
