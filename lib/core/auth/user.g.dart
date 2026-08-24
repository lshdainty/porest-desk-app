// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  rowId: (json['rowId'] as num).toInt(),
  userId: json['userId'] as String,
  userName: json['userName'] as String,
  userEmail: json['userEmail'] as String,
  timezone: json['timezone'] as String?,
  joinedAt: parseServerUtc(json['joinedAt'] as String?),
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'rowId': instance.rowId,
  'userId': instance.userId,
  'userName': instance.userName,
  'userEmail': instance.userEmail,
  'timezone': instance.timezone,
  'joinedAt': toServerUtc(instance.joinedAt),
};
