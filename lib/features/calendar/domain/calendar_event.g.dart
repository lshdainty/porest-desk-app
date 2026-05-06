// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CalendarEvent _$CalendarEventFromJson(Map<String, dynamic> json) =>
    _CalendarEvent(
      rowId: (json['rowId'] as num).toInt(),
      userRowId: (json['userRowId'] as num?)?.toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      eventType: json['eventType'] as String?,
      color: json['color'] as String?,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      isAllDay: json['isAllDay'] as String?,
      labelRowId: (json['labelRowId'] as num?)?.toInt(),
      labelName: json['labelName'] as String?,
      labelColor: json['labelColor'] as String?,
      location: json['location'] as String?,
      rrule: json['rrule'] as String?,
      groupRowId: (json['groupRowId'] as num?)?.toInt(),
      groupName: json['groupName'] as String?,
    );

Map<String, dynamic> _$CalendarEventToJson(_CalendarEvent instance) =>
    <String, dynamic>{
      'rowId': instance.rowId,
      'userRowId': instance.userRowId,
      'title': instance.title,
      'description': instance.description,
      'eventType': instance.eventType,
      'color': instance.color,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'isAllDay': instance.isAllDay,
      'labelRowId': instance.labelRowId,
      'labelName': instance.labelName,
      'labelColor': instance.labelColor,
      'location': instance.location,
      'rrule': instance.rrule,
      'groupRowId': instance.groupRowId,
      'groupName': instance.groupName,
    };
