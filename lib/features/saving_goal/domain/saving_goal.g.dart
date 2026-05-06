// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saving_goal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SavingGoal _$SavingGoalFromJson(Map<String, dynamic> json) => _SavingGoal(
  rowId: (json['rowId'] as num).toInt(),
  userRowId: (json['userRowId'] as num?)?.toInt(),
  title: json['title'] as String,
  description: json['description'] as String?,
  targetAmount: (json['targetAmount'] as num).toInt(),
  currentAmount: (json['currentAmount'] as num?)?.toInt() ?? 0,
  currency: json['currency'] as String?,
  deadlineDate: json['deadlineDate'] as String?,
  icon: json['icon'] as String?,
  color: json['color'] as String?,
  linkedAssetRowId: (json['linkedAssetRowId'] as num?)?.toInt(),
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
  isAchieved: json['isAchieved'] as String?,
  achievedAt: json['achievedAt'] as String?,
);

Map<String, dynamic> _$SavingGoalToJson(_SavingGoal instance) =>
    <String, dynamic>{
      'rowId': instance.rowId,
      'userRowId': instance.userRowId,
      'title': instance.title,
      'description': instance.description,
      'targetAmount': instance.targetAmount,
      'currentAmount': instance.currentAmount,
      'currency': instance.currency,
      'deadlineDate': instance.deadlineDate,
      'icon': instance.icon,
      'color': instance.color,
      'linkedAssetRowId': instance.linkedAssetRowId,
      'sortOrder': instance.sortOrder,
      'isAchieved': instance.isAchieved,
      'achievedAt': instance.achievedAt,
    };
