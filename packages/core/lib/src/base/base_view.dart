import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'base_view_mixin.dart';

/// Base class for a stateless screen bound to a cubit.
///
/// Override [BaseViewMixin.appBar] and [BaseViewMixin.body]. Use
/// [BaseViewState] instead when the screen needs `initState`/local
/// controllers.
abstract class BaseView<C extends StateStreamable<S>, S> extends StatelessWidget
    with BaseViewMixin<C, S> {
  const BaseView({super.key});

  @override
  Widget build(BuildContext context) => buildView(context);
}
