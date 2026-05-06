/// 백엔드 `EventCommentApiDto.Response` 매핑 — 캘린더 이벤트 코멘트.
class EventComment {
  const EventComment({
    required this.rowId,
    required this.eventRowId,
    this.userRowId,
    this.userName,
    this.parentRowId,
    required this.content,
    this.createAt,
    this.modifyAt,
  });

  final int rowId;
  final int eventRowId;
  final int? userRowId;
  final String? userName;
  final int? parentRowId; // 답글 대상 코멘트
  final String content;
  final String? createAt;
  final String? modifyAt;

  factory EventComment.fromJson(Map<String, dynamic> json) {
    return EventComment(
      rowId: (json['rowId'] as num).toInt(),
      eventRowId: (json['eventRowId'] as num).toInt(),
      userRowId: (json['userRowId'] as num?)?.toInt(),
      userName: json['userName'] as String?,
      parentRowId: (json['parentRowId'] as num?)?.toInt(),
      content: (json['content'] as String?) ?? '',
      createAt: json['createAt'] as String?,
      modifyAt: json['modifyAt'] as String?,
    );
  }
}
