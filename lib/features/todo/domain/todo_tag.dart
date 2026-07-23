/// 백엔드 `TodoTagApiDto.Response` 매핑.
class TodoTag {
  const TodoTag({
    required this.rowId,
    this.userRowId,
    required this.tagName,
    this.color,
    this.createAt,
    this.modifyAt,
    this.usageCount = 0,
  });

  final int rowId;
  final int? userRowId;
  final String tagName;
  final String? color;
  final String? createAt;
  final String? modifyAt;

  /// 사용 중 할일 수 — 서버 GROUP BY 집계.
  final int usageCount;

  factory TodoTag.fromJson(Map<String, dynamic> json) {
    return TodoTag(
      rowId: (json['rowId'] as num).toInt(),
      userRowId: (json['userRowId'] as num?)?.toInt(),
      tagName: (json['tagName'] as String?) ?? '',
      color: json['color'] as String?,
      createAt: json['createAt'] as String?,
      modifyAt: json['modifyAt'] as String?,
      usageCount: (json['usageCount'] as num?)?.toInt() ?? 0,
    );
  }
}
