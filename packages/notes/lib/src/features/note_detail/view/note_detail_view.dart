import 'package:core/core.dart' hide Note;
import 'package:flutter/material.dart';

import '../../../domain/entity/note.dart';
import '../cubit/note_detail_cubit.dart';
import '../cubit/note_detail_state.dart';

class NoteDetailView extends StatefulWidget {
  const NoteDetailView({super.key});

  @override
  State<NoteDetailView> createState() => _NoteDetailViewState();
}

class _NoteDetailViewState
    extends BaseViewState<NoteDetailView, NoteDetailCubit, NoteDetailState> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  int? _loadedNoteId;

  // ponytail: `onStateChanged` (BlocConsumer's listener) only fires for
  // state *transitions* — flutter_bloc's `_BlocBuilderBaseState.initState`
  // seeds its first build straight from `bloc.state` without ever calling
  // listenWhen/listener. That's fine for the real screen (starts at
  // `initial`, `load()` emits real transitions), but a widget test that
  // pre-seeds the mock cubit's state to `loaded` before the first pump
  // never triggers `onStateChanged`. Guarding here too — rather than only
  // in `onStateChanged` — makes the seeding correct regardless of whether
  // the loaded state arrived via a transition or was already current on
  // first build. Upgrade path: seed from `bloc.state` in
  // `core`'s `BaseViewMixin.buildView` too, if more screens hit this.
  void _syncControllers(Note note) {
    if (_loadedNoteId == note.id) return;
    _loadedNoteId = note.id;
    _titleController = TextEditingController(text: note.title);
    _bodyController = TextEditingController(text: note.body);
  }

  @override
  void onStateChanged(BuildContext context, NoteDetailState state) {
    if (state is NoteDetailLoaded) _syncControllers(state.note);
  }

  @override
  PreferredSizeWidget appBar(BuildContext context, NoteDetailState state) =>
      const AppAppBar(title: 'Edit note');

  @override
  Widget body(BuildContext context, NoteDetailState state) {
    switch (state) {
      case NoteDetailInitial():
      case NoteDetailLoading():
        return const AppLoadingIndicator();
      case NoteDetailError(:final message):
        return AppErrorView(message: message);
      case NoteDetailLoaded(:final note):
        _syncControllers(note);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AppTextField(controller: _titleController, label: 'Title'),
              const SizedBox(height: 12),
              AppTextField(controller: _bodyController, label: 'Body'),
              const SizedBox(height: 16),
              AppButton(
                label: 'Save',
                onPressed: () async {
                  final updated = await cubitOf(context).save(
                    title: _titleController.text,
                    body: _bodyController.text,
                  );
                  if (updated != null && context.mounted) {
                    Navigator.of(context).pop(updated);
                  }
                },
              ),
            ],
          ),
        );
    }
  }
}
