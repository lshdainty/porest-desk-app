/// 백엔드 `MemoTagApiDto.Response` 매핑.
///
/// 메모 태그는 **사용자별 서버 마스터**다(desk-back #323). 앱은 이 목록을 읽어
/// 고르게만 하고 만들거나 지우지 않는다 — 태그 관리는 설정 화면(웹)의 몫이다.
class MemoTag {
  const MemoTag({
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

  /// 이 태그를 쓰는 메모 수 — 서버 GROUP BY 집계.
  final int usageCount;

  factory MemoTag.fromJson(Map<String, dynamic> json) {
    return MemoTag(
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
