import 'package:freezed_annotation/freezed_annotation.dart';

part 'note.freezed.dart';
part 'note.g.dart';

/// The example feature's one domain model. Generic on purpose — no banking
/// language anywhere in this package.
@freezed
abstract class Note with _$Note {
  const factory Note({
    required int id,
    required String title,
    required String body,
    required DateTime createdAt,
  }) = _Note;

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);
}
