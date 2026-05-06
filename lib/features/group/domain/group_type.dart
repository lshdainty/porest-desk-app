/// 백엔드 `GroupTypeApiDto.Response` 매핑.
class GroupType {
  const GroupType({
    required this.rowId,
    required this.typeName,
    this.color,
    required this.sortOrder,
  });

  final int rowId;
  final String typeName;
  final String? color;
  final int sortOrder;

  factory GroupType.fromJson(Map<String, dynamic> json) {
    return GroupType(
      rowId: (json['rowId'] as num).toInt(),
      typeName: (json['typeName'] as String?) ?? '',
      color: json['color'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}
