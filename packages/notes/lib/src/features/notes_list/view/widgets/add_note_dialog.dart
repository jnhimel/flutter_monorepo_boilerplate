import 'package:core/core.dart';
import 'package:flutter/material.dart';

/// A public widget (not a `_buildX()` helper) so it can be tested and reused
/// on its own. Takes [onSave] instead of a cubit so it doesn't need a
/// `BlocProvider` in scope — `showDialog` opens on the root navigator, which
/// sits above this screen's `BlocProvider<NotesListCubit>`.
class AddNoteDialog extends StatelessWidget {
  const AddNoteDialog({super.key, required this.onSave});

  final void Function({required String title, required String body}) onSave;

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    return AlertDialog(
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Save',
          onPressed: () {
            if (titleController.text.trim().isEmpty) return;
            onSave(title: titleController.text, body: bodyController.text);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
