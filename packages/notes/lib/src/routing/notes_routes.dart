import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../cubit/notes_cubit.dart';
import '../repository/notes_repository.dart';
import '../view/note_detail_page.dart';
import '../view/notes_list_page.dart';

/// This feature's `StatefulShellBranch`, for `app` to plug into the Phase 2
/// bottom-nav shell alongside the Home and Settings branches.
///
/// Both routes share one `NotesCubit` (created here, not registered in
/// get_it — see `notes_dependencies.dart`) so navigating from the list to a
/// detail page keeps the same in-memory notes list.
StatefulShellBranch notesShellBranch(GetIt getIt) {
  return StatefulShellBranch(
    routes: [
      // A ShellRoute (not go_router's stateful-shell kind) so the list page
      // and the detail page share one `BlocProvider`/`NotesCubit` instance —
      // nested `GoRoute`s each get their own page in the Navigator stack, so
      // without this wrapper the detail page couldn't see the list's cubit.
      ShellRoute(
        builder: (context, state, child) => BlocProvider(
          create: (_) => NotesCubit(getIt<NotesRepository>())..load(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutePaths.notes,
            builder: (context, state) => const NotesListPage(),
          ),
          GoRoute(
            path: '${AppRoutePaths.notes}/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return NoteDetailPage(noteId: id);
            },
          ),
        ],
      ),
    ],
  );
}
