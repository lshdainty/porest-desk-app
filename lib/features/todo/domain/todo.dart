import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo.freezed.dart';
part 'todo.g.dart';

/// `TodoApiDto.Response` 매핑.
@freezed
abstract class Todo with _$Todo {
  const factory Todo({
    required int rowId,
    int? userRowId,
    String? type, // 'TASK' | 'NOTE'
    required String title,
    String? content,
    String? priority, // 'HIGH' | 'MEDIUM' | 'LOW'
    String? category,
    String? status, // 'PENDING' | 'IN_PROGRESS' | 'COMPLETED'
    String? dueDate, // 'YYYY-MM-DD'
    String? completedAt,
    int? sortOrder,
    String? isPinned,
    int? parentRowId,
    @Default(0) int subtaskCount,
    @Default(0) int subtaskCompletedCount,
    String? createAt,
    String? modifyAt,
  }) = _Todo;

  factory Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);
}

extension TodoX on Todo {
  bool get pinned => (isPinned ?? 'N') == 'Y';
  bool get done => status == 'COMPLETED';
  DateTime? get due => dueDate == null ? null : DateTime.tryParse(dueDate!);
}
