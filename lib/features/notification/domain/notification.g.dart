// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    _AppNotification(
      rowId: (json['rowId'] as num).toInt(),
      userRowId: (json['userRowId'] as num?)?.toInt(),
      notificationType: json['notificationType'] as String?,
      title: json['title'] as String,
      message: json['message'] as String?,
      referenceType: json['referenceType'] as String?,
      referenceId: (json['referenceId'] as num?)?.toInt(),
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] as String?,
      createAt: json['createAt'] as String?,
    );

Map<String, dynamic> _$AppNotificationToJson(_AppNotification instance) =>
    <String, dynamic>{
      'rowId': instance.rowId,
      'userRowId': instance.userRowId,
      'notificationType': instance.notificationType,
      'title': instance.title,
      'message': instance.message,
      'referenceType': instance.referenceType,
      'referenceId': instance.referenceId,
      'isRead': instance.isRead,
      'readAt': instance.readAt,
      'createAt': instance.createAt,
    };
