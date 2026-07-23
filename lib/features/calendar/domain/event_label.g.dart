// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_label.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EventLabel _$EventLabelFromJson(Map<String, dynamic> json) => _EventLabel(
  rowId: (json['rowId'] as num).toInt(),
  userRowId: (json['userRowId'] as num?)?.toInt(),
  labelName: json['labelName'] as String,
  color: json['color'] as String?,
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
  usageCount: (json['usageCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$EventLabelToJson(_EventLabel instance) =>
    <String, dynamic>{
      'rowId': instance.rowId,
      'userRowId': instance.userRowId,
      'labelName': instance.labelName,
      'color': instance.color,
      'sortOrder': instance.sortOrder,
      'usageCount': instance.usageCount,
    };
