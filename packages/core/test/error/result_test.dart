import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('pattern-matches Success to its value', () {
      const Result<int, AppFailure> result = Success(42);
      final matched = switch (result) {
        Success(:final value) => value,
        Failure() => -1,
      };
      expect(matched, 42);
    });

    test('pattern-matches Failure to its failure', () {
      const Result<int, AppFailure> result = Failure(StorageFailure());
      final matched = switch (result) {
        Success() => null,
        Failure(:final failure) => failure,
      };
      expect(matched, isA<StorageFailure>());
      expect((matched! as StorageFailure).message, isNotEmpty);
    });
  });
}
