import 'package:core/core.dart' hide Note;
import 'package:injectable/injectable.dart';

import '../../../domain/entity/note.dart';
import '../../../domain/repository/notes_repository.dart';
import 'notes_list_state.dart';

@injectable
class NotesListCubit extends BaseCubit<NotesListState> {
  NotesListCubit(this._repository) : super(const NotesListState.initial());

  final NotesRepository _repository;

  List<Note> get _currentNotes {
    final current = state;
    return current is NotesListLoaded ? current.notes : const <Note>[];
  }

  Future<void> load() async {
    emit(const NotesListState.loading());
    await runGuarded(() async {
      final result = await _repository.getNotes();
      switch (result) {
        case Success(:final value):
          safeEmit(NotesListState.loaded(value));
        case Failure(:final failure):
          safeEmit(NotesListState.error(failure.message));
      }
    }, onError: (error, stackTrace) => NotesListState.error(error.toString()));
  }

  Future<void> addNote({required String title, required String body}) async {
    final result = await _repository.addNote(title: title, body: body);
    switch (result) {
      case Success(:final value):
        safeEmit(NotesListState.loaded([..._currentNotes, value]));
      case Failure(:final failure):
        safeEmit(NotesListState.error(failure.message));
    }
  }

  Future<void> deleteNote(int id) async {
    final result = await _repository.deleteNote(id);
    switch (result) {
      case Success():
        safeEmit(
          NotesListState.loaded(
            _currentNotes.where((n) => n.id != id).toList(),
          ),
        );
      case Failure(:final failure):
        safeEmit(NotesListState.error(failure.message));
    }
  }
}
