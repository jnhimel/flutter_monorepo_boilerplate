/// The one example feature package: generic CRUD notes, backed by core's
/// Drift `AppDatabase`. `domain/`+`data/` are feature-wide; `cubit/`+`view/`
/// nest per screen under `features/` since each screen owns its own state
/// independently.
library;

export 'src/data/datasource/notes_local_data_source.dart';
export 'src/data/repository_impl/notes_repository_impl.dart';
export 'src/di/notes_dependencies.dart';
export 'src/domain/entity/note.dart';
export 'src/domain/repository/notes_repository.dart';
export 'src/features/note_detail/cubit/note_detail_cubit.dart';
export 'src/features/note_detail/cubit/note_detail_state.dart';
export 'src/features/note_detail/view/note_detail_screen.dart';
export 'src/features/note_detail/view/note_detail_view.dart';
export 'src/features/notes_list/cubit/notes_list_cubit.dart';
export 'src/features/notes_list/cubit/notes_list_state.dart';
export 'src/features/notes_list/view/notes_list_screen.dart';
export 'src/features/notes_list/view/notes_list_view.dart';
export 'src/routing/notes_routes.dart';
