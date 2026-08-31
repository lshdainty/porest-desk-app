/// 백엔드 `FileApiDto.Response` 매핑.
///
/// `referenceType` enum: EXPENSE / TODO / MEMO / CALENDAR_EVENT 등.
/// `referenceRowId` 가 null 이면 사용자에게 직접 귀속된 파일.
class FileAttachment {
  const FileAttachment({
    required this.rowId,
    required this.originalName,
    this.contentType,
    this.fileSize,
    this.referenceType,
    this.referenceRowId,
    this.createAt,
  });

  final int rowId;
  final String originalName;
  final String? contentType;
  final int? fileSize;
  final String? referenceType;
  final int? referenceRowId;
  final String? createAt;

  bool get isImage => (contentType ?? '').startsWith('image/');

  factory FileAttachment.fromJson(Map<String, dynamic> json) {
    return FileAttachment(
      rowId: (json['rowId'] as num).toInt(),
      originalName: (json['originalName'] as String?) ?? '',
      contentType: json['contentType'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      referenceType: json['referenceType'] as String?,
      referenceRowId: (json['referenceRowId'] as num?)?.toInt(),
      createAt: json['createAt'] as String?,
    );
  }
}
