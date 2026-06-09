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
    String? tag, // 분류 태그 (가계부/자산/업무/개인/건강/결제/고정비 등)
    String? color, // 카드 색 — chart palette base hex (#2c70bf 등). null=blue
    String? isPinned, // 'Y' | 'N'
    String? createAt,
    String? modifyAt,
  }) = _Memo;

  factory Memo.fromJson(Map<String, dynamic> json) => _$MemoFromJson(json);
}

extension MemoX on Memo {
  bool get pinned => (isPinned ?? 'N') == 'Y';
}
