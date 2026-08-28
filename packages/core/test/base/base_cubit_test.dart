import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterCubit extends BaseCubit<int> {
  _CounterCubit() : super(0);

  Future<void> incrementOrThrow(bool shouldThrow) => runGuarded(() async {
    if (shouldThrow) throw StateError('boom');
    safeEmit(state + 1);
  }, onError: (error, stackTrace) => -1);
}

void main() {
  group('BaseCubit', () {
    test('runGuarded emits the action\'s result on success', () async {
      final cubit = _CounterCubit();
      await cubit.incrementOrThrow(false);
      expect(cubit.state, 1);
      await cubit.close();
    });

    test('runGuarded emits onError\'s state when the action throws', () async {
      final cubit = _CounterCubit();
      await cubit.incrementOrThrow(true);
      expect(cubit.state, -1);
      await cubit.close();
    });

    test('safeEmit is a no-op after the cubit is closed', () async {
      final cubit = _CounterCubit();
      await cubit.close();
      cubit.safeEmit(99);
      expect(cubit.state, 0);
    });
  });
}
