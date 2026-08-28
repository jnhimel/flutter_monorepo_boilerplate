/// Auth backend seam. [FakeAuthRepository] is a stub — replace it with a
/// real API-backed implementation before shipping.
abstract class AuthRepository {
  /// Returns an auth token on success, `null` on failure.
  Future<String?> login({required String email, required String password});
}

/// ponytail: in-memory fake, not a real API client. Accepts any non-empty
/// email/password after a fake delay. Replace with a real `DioClient`-backed
/// implementation before shipping.
class FakeAuthRepository implements AuthRepository {
  @override
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (email.trim().isEmpty || password.trim().isEmpty) return null;
    return 'fake-token-${email.hashCode}';
  }
}
