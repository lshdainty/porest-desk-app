import 'package:freezed_annotation/freezed_annotation.dart';

part 'memo.freezed.dart';
part 'memo.g.dart';

@freezed
abstract class Memo with _$Memo {
  const factory Memo({
    required int rowId,
    int? userRowId,
    int? folderId,
    String? title,
    String? content,
    String? isPinned, // 'Y' | 'N'
    String? createAt,
    String? modifyAt,
  }) = _Memo;

  factory Memo.fromJson(Map<String, dynamic> json) => _$MemoFromJson(json);
}

extension MemoX on Memo {
  bool get pinned => (isPinned ?? 'N') == 'Y';
}
