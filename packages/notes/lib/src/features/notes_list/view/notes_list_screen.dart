import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/notes_list_cubit.dart';
import 'notes_list_view.dart';

/// Thin: resolves this screen's cubit from `getIt` and wraps it in a
/// `BlocProvider`. All UI lives in [NotesListView].
class NotesListScreen extends StatelessWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NotesListCubit>()..load(),
      child: const NotesListView(),
    );
  }
}
