import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/note_detail_cubit.dart';
import 'note_detail_view.dart';

/// Thin: resolves this screen's cubit (keyed by [noteId]) from `getIt` and
/// wraps it in a `BlocProvider`. All UI lives in [NoteDetailView].
class NoteDetailScreen extends StatelessWidget {
  const NoteDetailScreen({super.key, required this.noteId});

  final int noteId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NoteDetailCubit>(param1: noteId)..load(),
      child: const NoteDetailView(),
    );
  }
}
