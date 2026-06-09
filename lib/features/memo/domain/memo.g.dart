// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Memo _$MemoFromJson(Map<String, dynamic> json) => _Memo(
  rowId: (json['rowId'] as num).toInt(),
  userRowId: (json['userRowId'] as num?)?.toInt(),
  folderId: (json['folderId'] as num?)?.toInt(),
  title: json['title'] as String?,
  content: json['content'] as String?,
  tag: json['tag'] as String?,
  color: json['color'] as String?,
  isPinned: json['isPinned'] as String?,
  createAt: json['createAt'] as String?,
  modifyAt: json['modifyAt'] as String?,
);

Map<String, dynamic> _$MemoToJson(_Memo instance) => <String, dynamic>{
  'rowId': instance.rowId,
  'userRowId': instance.userRowId,
  'folderId': instance.folderId,
  'title': instance.title,
  'content': instance.content,
  'tag': instance.tag,
  'color': instance.color,
  'isPinned': instance.isPinned,
  'createAt': instance.createAt,
  'modifyAt': instance.modifyAt,
};
