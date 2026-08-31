/// Minimal sealed result type so repositories can return either a value or a
/// typed failure without throwing across the repository boundary. Hand-rolled
/// (no fpdart/dartz dependency) — two variants is all this boilerplate needs.
sealed class Result<T, F> {
  const Result();
}

final class Success<T, F> extends Result<T, F> {
  const Success(this.value);

  final T value;
}

final class Failure<T, F> extends Result<T, F> {
  const Failure(this.failure);

  final F failure;
}
