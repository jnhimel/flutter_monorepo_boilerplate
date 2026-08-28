import 'package:app/app_widget.dart';
import 'package:app/auth/auth_cubit.dart';
import 'package:app/auth/auth_repository.dart';
import 'package:app/features/login/login_page.dart';
import 'package:app/features/splash/splash_page.dart';
import 'package:app/router/app_router.dart';
import 'package:app/theme_mode_controller.dart';
import 'package:core/core.dart' hide Note;
import 'package:flutter_test/flutter_test.dart';
import 'package:notes/notes.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for the real secure-storage/Drift-backed services so this
/// widget test never touches a platform channel or sqlite — it only needs
/// to prove the app boots to the splash screen, not exercise those
/// services (that's what packages/core and packages/notes' own tests do).
class _FakeSecureStorageService extends SecureStorageService {
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<void> delete(String key) async {}
}

class _FakeNotesRepository implements NotesRepository {
  @override
  Future<Result<List<Note>, AppFailure>> getNotes() async => const Success([]);
  @override
  Future<Result<Note, AppFailure>> getNoteById(int id) async =>
      const Failure(StorageFailure('Note not found.'));
  @override
  Future<Result<Note, AppFailure>> addNote({
    required String title,
    required String body,
  }) => throw UnimplementedError();
  @override
  Future<Result<void, AppFailure>> updateNote(Note note) async =>
      const Success(null);
  @override
  Future<Result<void, AppFailure>> deleteNote(int id) async =>
      const Success(null);
}

void main() {
  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});

    getIt.registerLazySingleton<AppLogger>(ConsoleAppLogger.new);
    getIt.registerLazySingleton<ErrorReporter>(NoopErrorReporter.new);
    getIt.registerLazySingleton<AuthRepository>(FakeAuthRepository.new);
    getIt.registerLazySingleton<SecureStorageService>(
      _FakeSecureStorageService.new,
    );
    getIt.registerLazySingleton(
      () => AuthCubit(getIt<AuthRepository>(), getIt<SecureStorageService>()),
    );

    final prefs = PreferencesService();
    await prefs.init();
    getIt.registerSingleton(prefs);
    getIt.registerLazySingleton(() => ThemeModeController(prefs));

    getIt.registerLazySingleton<NotesRepository>(_FakeNotesRepository.new);
    getIt.registerLazySingleton(() => buildAppRouter(getIt));
  });

  tearDown(() => getIt.reset());

  testWidgets('boots to the splash page', (tester) async {
    await tester.pumpWidget(const AppWidget());

    // First frame: AuthCubit hasn't resolved yet, so the splash page shows.
    expect(find.byType(SplashPage), findsOneWidget);

    // Once the (fake, instant) auth check resolves, the redirect guard sends
    // an unauthenticated user to the login page.
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
