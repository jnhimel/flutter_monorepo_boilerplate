import 'package:core/core.dart' hide Note;
import 'package:injectable/injectable.dart';

import '../../../domain/entity/note.dart';
import '../../../domain/repository/notes_repository.dart';
import 'note_detail_state.dart';

@injectable
class NoteDetailCubit extends BaseCubit<NoteDetailState> {
  NoteDetailCubit(@factoryParam this.noteId, this._repository)
    : super(const NoteDetailState.initial());

  final int noteId;
  final NotesRepository _repository;

  Future<void> load() async {
    emit(const NoteDetailState.loading());
    await runGuarded(() async {
      final result = await _repository.getNoteById(noteId);
      switch (result) {
        case Success(:final value):
          safeEmit(NoteDetailState.loaded(value));
        case Failure(:final failure):
          safeEmit(NoteDetailState.error(failure.message));
      }
    }, onError: (error, stackTrace) => NoteDetailState.error(error.toString()));
  }

  /// Returns the updated note on success, so the screen can pop with a
  /// result the notes-list screen uses to know it should refresh.
  ///
  /// Can't route this through `runGuarded` (it needs to return `Note?`,
  /// and `runGuarded`'s `action` is `Future<void> Function()`) — so it
  /// wraps the repository call in the same try/catch + `safeEmit` shape
  /// `runGuarded` uses internally, for the same reason `load()` uses
  /// `runGuarded`: `NoteDetailCubit` is written against the `NotesRepository`
  /// interface, which is documented as never throwing, but an unguarded
  /// call here would still crash if some future implementation did.
  Future<Note?> save({required String title, required String body}) async {
    final current = state;
    if (current is! NoteDetailLoaded) return null;
    final updated = current.note.copyWith(title: title, body: body);
    try {
      final result = await _repository.updateNote(updated);
      switch (result) {
        case Success():
          safeEmit(NoteDetailState.loaded(updated));
          return updated;
        case Failure(:final failure):
          safeEmit(NoteDetailState.error(failure.message));
          return null;
      }
    } on Object catch (error) {
      safeEmit(NoteDetailState.error(error.toString()));
      return null;
    }
  }
}
