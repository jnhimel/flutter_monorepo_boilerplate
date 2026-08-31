import 'package:core/core.dart' hide Note;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entity/note.dart';
import '../cubit/notes_list_cubit.dart';
import '../cubit/notes_list_state.dart';
import 'widgets/add_note_dialog.dart';

class NotesListView extends BaseView<NotesListCubit, NotesListState> {
  const NotesListView({super.key});

  @override
  PreferredSizeWidget appBar(BuildContext context, NotesListState state) =>
      const AppAppBar(title: 'Notes');

  @override
  Widget body(BuildContext context, NotesListState state) {
    return switch (state) {
      NotesListInitial() || NotesListLoading() => const AppLoadingIndicator(),
      NotesListError(:final message) => AppErrorView(
        message: message,
        onRetry: () => cubitOf(context).load(),
      ),
      NotesListLoaded(:final notes) when notes.isEmpty => const AppEmptyState(
        message: 'No notes yet. Tap + to add one.',
      ),
      NotesListLoaded(:final notes) => ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) => _NoteListTile(note: notes[index]),
      ),
    };
  }

  @override
  Widget? floatingActionButton(BuildContext context, NotesListState state) {
    final cubit = cubitOf(context);
    return FloatingActionButton(
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => AddNoteDialog(
          onSave: ({required title, required body}) =>
              cubit.addNote(title: title, body: body),
        ),
      ),
      child: const Icon(Icons.add),
    );
  }
}

/// Single-use inside [NotesListView.body] but extracted anyway so the tap
/// handler's `await` doesn't get buried inside a `ListView.builder` callback.
class _NoteListTile extends StatelessWidget {
  const _NoteListTile({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.title),
      subtitle: Text(note.body),
      onTap: () async {
        final updated = await context.push<Note>(
          '${AppRoutePaths.notes}/${note.id}',
        );
        if (updated != null && context.mounted) {
          context.read<NotesListCubit>().load();
        }
      },
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => context.read<NotesListCubit>().deleteNote(note.id),
      ),
    );
  }
}
