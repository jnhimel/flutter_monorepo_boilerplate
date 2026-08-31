import 'package:flutter_bloc/flutter_bloc.dart';

/// Shared safety net for every cubit in this app: emitting after the cubit
/// is closed throws `StateError` (happens when the user leaves a screen with
/// an awaited call still in flight), and an exception inside an async cubit
/// method otherwise escapes unhandled and surfaces as a red screen instead of
/// a state the UI can render.
abstract class BaseCubit<S> extends Cubit<S> with SafeEmitMixin<S> {
  BaseCubit(super.initialState);

  /// Runs [action], converting any thrown object into a state via [onError].
  /// [action] is responsible for emitting its own success state(s) — this
  /// only exists to catch what [action] doesn't.
  Future<void> runGuarded(
    Future<void> Function() action, {
    required S Function(Object error, StackTrace stackTrace) onError,
  }) async {
    try {
      await action();
    } on Object catch (error, stackTrace) {
      safeEmit(onError(error, stackTrace));
    }
  }
}

/// Guards against emitting into a closed cubit.
mixin SafeEmitMixin<S> on BlocBase<S> {
  void safeEmit(S state) {
    if (!isClosed) emit(state);
  }
}
