import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'base_view_mixin.dart';

/// Base class for a stateful screen bound to a cubit — for screens that need
/// `initState`/`dispose` or local controllers (e.g. `TextEditingController`s
/// seeded from a just-loaded state in [BaseViewMixin.onStateChanged]).
abstract class BaseViewState<
  W extends StatefulWidget,
  C extends StateStreamable<S>,
  S
>
    extends State<W>
    with BaseViewMixin<C, S> {
  @override
  Widget build(BuildContext context) => buildView(context);
}
