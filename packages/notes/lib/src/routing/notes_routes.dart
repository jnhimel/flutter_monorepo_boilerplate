import 'package:core/core.dart';
import 'package:go_router/go_router.dart';

import '../features/note_detail/view/note_detail_screen.dart';
import '../features/notes_list/view/notes_list_screen.dart';

/// This feature's `StatefulShellBranch`, for `app` to plug into the
/// bottom-nav shell alongside the Home and Settings branches.
///
/// Each screen resolves its own cubit from `getIt` (see
/// `notes_list_screen.dart`/`note_detail_screen.dart`) and is independently
/// repository-backed, so — unlike before — this file wires no shared
/// `BlocProvider`/`ShellRoute` of its own.
StatefulShellBranch notesShellBranch() {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: AppRoutePaths.notes,
        builder: (_, _) => const NotesListScreen(),
      ),
      GoRoute(
        path: '${AppRoutePaths.notes}/:id',
        builder: (_, state) =>
            NoteDetailScreen(noteId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
}
