// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Group _$GroupFromJson(Map<String, dynamic> json) => _Group(
  rowId: (json['rowId'] as num).toInt(),
  groupName: json['groupName'] as String,
  description: json['description'] as String?,
  groupTypeId: (json['groupTypeId'] as num?)?.toInt(),
  groupTypeName: json['groupTypeName'] as String?,
  groupTypeColor: json['groupTypeColor'] as String?,
  color: json['color'] as String?,
  inviteCode: json['inviteCode'] as String?,
  memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
  createAt: json['createAt'] as String?,
);

Map<String, dynamic> _$GroupToJson(_Group instance) => <String, dynamic>{
  'rowId': instance.rowId,
  'groupName': instance.groupName,
  'description': instance.description,
  'groupTypeId': instance.groupTypeId,
  'groupTypeName': instance.groupTypeName,
  'groupTypeColor': instance.groupTypeColor,
  'color': instance.color,
  'inviteCode': instance.inviteCode,
  'memberCount': instance.memberCount,
  'createAt': instance.createAt,
};
