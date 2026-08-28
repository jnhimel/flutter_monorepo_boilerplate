import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/notes_cubit.dart';
import '../cubit/notes_state.dart';

class NotesListPage extends StatelessWidget {
  const NotesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: 'Notes'),
      body: BlocBuilder<NotesCubit, NotesState>(
        builder: (context, state) {
          return switch (state) {
            NotesInitial() || NotesLoading() => const AppLoadingIndicator(),
            NotesError(:final message) => AppErrorView(
              message: message,
              onRetry: () => context.read<NotesCubit>().load(),
            ),
            NotesLoaded(:final notes) when notes.isEmpty => const AppEmptyState(
              message: 'No notes yet. Tap + to add one.',
            ),
            NotesLoaded(:final notes) => ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return ListTile(
                  title: Text(note.title),
                  subtitle: Text(note.body),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        context.read<NotesCubit>().deleteNote(note.id),
                  ),
                );
              },
            ),
          };
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddNoteDialog(BuildContext context) async {
    final cubit = context.read<NotesCubit>();
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(controller: titleController, label: 'Title'),
            const SizedBox(height: 8),
            AppTextField(controller: bodyController, label: 'Body'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Save',
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              cubit.addNote(
                title: titleController.text,
                body: bodyController.text,
              );
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    );
  }
}
