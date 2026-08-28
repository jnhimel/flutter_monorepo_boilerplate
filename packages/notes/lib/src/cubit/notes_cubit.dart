import 'package:flutter_bloc/flutter_bloc.dart';

import '../entity/note.dart';
import '../repository/notes_repository.dart';
import 'notes_state.dart';

class NotesCubit extends Cubit<NotesState> {
  NotesCubit(this._repository) : super(const NotesState.initial());

  final NotesRepository _repository;

  List<Note> get _currentNotes {
    final current = state;
    return current is NotesLoaded ? current.notes : const <Note>[];
  }

  Future<void> load() async {
    emit(const NotesState.loading());
    try {
      final notes = await _repository.getNotes();
      emit(NotesState.loaded(notes));
    } catch (e) {
      emit(NotesState.error(e.toString()));
    }
  }

  Future<void> addNote({required String title, required String body}) async {
    final created = await _repository.addNote(title: title, body: body);
    emit(NotesState.loaded([..._currentNotes, created]));
  }

  Future<void> updateNote(Note note) async {
    await _repository.updateNote(note);
    emit(
      NotesState.loaded([
        for (final n in _currentNotes) n.id == note.id ? note : n,
      ]),
    );
  }

  Future<void> deleteNote(int id) async {
    await _repository.deleteNote(id);
    emit(NotesState.loaded(_currentNotes.where((n) => n.id != id).toList()));
  }
}
