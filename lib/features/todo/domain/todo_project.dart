/// 백엔드 `TodoProjectApiDto.Response` 매핑.
class TodoProject {
  const TodoProject({
    required this.rowId,
    this.userRowId,
    required this.projectName,
    this.description,
    this.color,
    this.icon,
    this.sortOrder,
    this.createAt,
    this.modifyAt,
  });

  final int rowId;
  final int? userRowId;
  final String projectName;
  final String? description;
  final String? color;
  final String? icon;
  final int? sortOrder;
  final String? createAt;
  final String? modifyAt;

  factory TodoProject.fromJson(Map<String, dynamic> json) {
    return TodoProject(
      rowId: (json['rowId'] as num).toInt(),
      userRowId: (json['userRowId'] as num?)?.toInt(),
      projectName: (json['projectName'] as String?) ?? '',
      description: json['description'] as String?,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt(),
      createAt: json['createAt'] as String?,
      modifyAt: json['modifyAt'] as String?,
    );
  }
}
