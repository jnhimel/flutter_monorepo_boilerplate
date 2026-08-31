import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'notes_dependencies.config.dart';

/// Generated init, covers every `@injectable`/`@LazySingleton` registration
/// in this package (the repository, the datasource, and both feature
/// cubits). `NoteDetailCubit` is a `@factoryParam` factory — resolve it with
/// `getIt<NoteDetailCubit>(param1: noteId)`.
@InjectableInit()
void registerNotesDependencies(GetIt getIt) => getIt.init();
