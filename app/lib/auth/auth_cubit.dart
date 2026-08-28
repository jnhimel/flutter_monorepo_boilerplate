import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'auth_repository.dart';

part 'auth_cubit.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.unknown() = AuthUnknown;
  const factory AuthState.authenticated() = AuthAuthenticated;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
}

/// Drives the splash → login/home redirect in `AppRouter`.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authRepository, this._secureStorage)
    : super(const AuthState.unknown());

  final AuthRepository _authRepository;
  final SecureStorageService _secureStorage;

  /// Called from `SplashPage`: is there already a stored token?
  Future<void> checkAuthStatus() async {
    final token = await _secureStorage.read(SecureStorageService.authTokenKey);
    emit(
      token != null
          ? const AuthState.authenticated()
          : const AuthState.unauthenticated(),
    );
  }

  Future<bool> login({required String email, required String password}) async {
    final token = await _authRepository.login(email: email, password: password);
    if (token == null) return false;
    await _secureStorage.write(SecureStorageService.authTokenKey, token);
    emit(const AuthState.authenticated());
    return true;
  }

  Future<void> logout() async {
    await _secureStorage.delete(SecureStorageService.authTokenKey);
    emit(const AuthState.unauthenticated());
  }
}
