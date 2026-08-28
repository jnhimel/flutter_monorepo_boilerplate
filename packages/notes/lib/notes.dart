/// The one example feature package: generic CRUD notes, backed by core's
/// Drift `AppDatabase`.
library;

export 'src/cubit/notes_cubit.dart';
export 'src/cubit/notes_state.dart';
export 'src/di/notes_dependencies.dart';
export 'src/entity/note.dart';
export 'src/repository/notes_repository.dart';
export 'src/repository/notes_repository_impl.dart';
export 'src/routing/notes_routes.dart';
export 'src/view/note_detail_page.dart';
export 'src/view/notes_list_page.dart';
