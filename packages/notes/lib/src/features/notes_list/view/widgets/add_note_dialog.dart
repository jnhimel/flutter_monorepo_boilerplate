import 'package:core/core.dart';
import 'package:flutter/material.dart';

/// A public widget (not a `_buildX()` helper) so it can be tested and reused
/// on its own. Takes [onSave] instead of a cubit so it doesn't need a
/// `BlocProvider` in scope — `showDialog` opens on the root navigator, which
/// sits above this screen's `BlocProvider<NotesListCubit>`.
class AddNoteDialog extends StatefulWidget {
  const AddNoteDialog({super.key, required this.onSave});

  final void Function({required String title, required String body}) onSave;

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New note'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(controller: _titleController, label: 'Title'),
          const SizedBox(height: 8),
          AppTextField(controller: _bodyController, label: 'Body'),
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
            if (_titleController.text.trim().isEmpty) return;
            widget.onSave(
              title: _titleController.text,
              body: _bodyController.text,
            );
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
