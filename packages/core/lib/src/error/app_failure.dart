/// Typed failure payload for [Result]. Repositories catch whatever their
/// backend throws (Drift, Dio, ...) and wrap it into one of these instead of
/// letting the exception cross the repository boundary.
sealed class AppFailure {
  const AppFailure(this.message);

  final String message;
}

class StorageFailure extends AppFailure {
  const StorageFailure([super.message = 'Could not read or write local data.']);
}

class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}
