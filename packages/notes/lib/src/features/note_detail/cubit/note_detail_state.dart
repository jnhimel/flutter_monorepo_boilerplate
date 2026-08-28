import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/entity/note.dart';

part 'note_detail_state.freezed.dart';

@freezed
sealed class NoteDetailState with _$NoteDetailState {
  const factory NoteDetailState.initial() = NoteDetailInitial;
  const factory NoteDetailState.loading() = NoteDetailLoading;
  const factory NoteDetailState.loaded(Note note) = NoteDetailLoaded;
  const factory NoteDetailState.error(String message) = NoteDetailError;
}
