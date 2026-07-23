// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Todo _$TodoFromJson(Map<String, dynamic> json) => _Todo(
  rowId: (json['rowId'] as num).toInt(),
  userRowId: (json['userRowId'] as num?)?.toInt(),
  type: json['type'] as String?,
  title: json['title'] as String,
  content: json['content'] as String?,
  priority: json['priority'] as String?,
  category: json['category'] as String?,
  status: json['status'] as String?,
  dueDate: json['dueDate'] as String?,
  completedAt: json['completedAt'] as String?,
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
  isPinned: json['isPinned'] as String?,
  parentRowId: (json['parentRowId'] as num?)?.toInt(),
  subtaskCount: (json['subtaskCount'] as num?)?.toInt() ?? 0,
  subtaskCompletedCount: (json['subtaskCompletedCount'] as num?)?.toInt() ?? 0,
  createAt: json['createAt'] as String?,
  modifyAt: json['modifyAt'] as String?,
);

Map<String, dynamic> _$TodoToJson(_Todo instance) => <String, dynamic>{
  'rowId': instance.rowId,
  'userRowId': instance.userRowId,
  'type': instance.type,
  'title': instance.title,
  'content': instance.content,
  'priority': instance.priority,
  'category': instance.category,
  'status': instance.status,
  'dueDate': instance.dueDate,
  'completedAt': instance.completedAt,
  'sortOrder': instance.sortOrder,
  'isPinned': instance.isPinned,
  'parentRowId': instance.parentRowId,
  'subtaskCount': instance.subtaskCount,
  'subtaskCompletedCount': instance.subtaskCompletedCount,
  'createAt': instance.createAt,
  'modifyAt': instance.modifyAt,
};
