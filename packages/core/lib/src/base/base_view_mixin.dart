import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The screen contract shared by [BaseView] and [BaseViewState].
///
/// Holds the `BlocConsumer -> Scaffold -> SafeArea` shell so the stateless
/// and stateful bases stay a delegation each, and so no screen hand-rolls
/// this shell itself.
mixin BaseViewMixin<C extends StateStreamable<S>, S> {
  /// The screen's app bar. Null for screens that supply their own, or none.
  PreferredSizeWidget? appBar(BuildContext context, S state) => null;

  /// The screen's content, below the app bar.
  Widget body(BuildContext context, S state);

  /// The screen's floating action button, if any.
  Widget? floatingActionButton(BuildContext context, S state) => null;

  /// Reacts to state changes that are effects, not rendering — navigation,
  /// snack bars, seeding local controllers from a just-loaded state. Runs
  /// before [body] for the same state change.
  void onStateChanged(BuildContext context, S state) {}

  bool listenWhen(S previous, S current) => true;

  bool buildWhen(S previous, S current) => true;

  /// Set false for screens that manage their own insets.
  bool get useSafeArea => true;

  /// The cubit driving this screen.
  C cubitOf(BuildContext context) => context.read<C>();

  Widget buildView(BuildContext context) {
    return BlocConsumer<C, S>(
      listenWhen: listenWhen,
      buildWhen: buildWhen,
      listener: onStateChanged,
      builder: (context, state) {
        final content = body(context, state);
        return Scaffold(
          appBar: appBar(context, state),
          body: useSafeArea ? SafeArea(child: content) : content,
          floatingActionButton: floatingActionButton(context, state),
        );
      },
    );
  }
}
