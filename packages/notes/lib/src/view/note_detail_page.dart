import 'package:core/core.dart' hide Note;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/notes_cubit.dart';
import '../cubit/notes_state.dart';
import '../entity/note.dart';

/// Edits a single note found by [noteId] in the current `NotesCubit` state.
/// Reached via `/notes/:id`, wrapped in the same `BlocProvider` as
/// `NotesListPage` so both share one cubit instance.
class NoteDetailPage extends StatefulWidget {
  const NoteDetailPage({super.key, required this.noteId});

  final int noteId;

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  Note? _note;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NotesCubit>().state;
    final notes = state is NotesLoaded ? state.notes : const <Note>[];
    Note? note;
    for (final n in notes) {
      if (n.id == widget.noteId) note = n;
    }

    if (note == null) {
      return const Scaffold(body: AppErrorView(message: 'Note not found.'));
    }
    if (_note?.id != note.id) {
      _note = note;
      _titleController = TextEditingController(text: note.title);
      _bodyController = TextEditingController(text: note.body);
    }

    return Scaffold(
      appBar: const AppAppBar(title: 'Edit note'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppTextField(controller: _titleController, label: 'Title'),
            const SizedBox(height: 12),
            AppTextField(controller: _bodyController, label: 'Body'),
            const SizedBox(height: 16),
            AppButton(
              label: 'Save',
              onPressed: () {
                context.read<NotesCubit>().updateNote(
                  note!.copyWith(
                    title: _titleController.text,
                    body: _bodyController.text,
                  ),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
