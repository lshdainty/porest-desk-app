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
      calendarRowId: (json['calendarRowId'] as num?)?.toInt(),
      calendarColor: json['calendarColor'] as String?,
      labelRowId: (json['labelRowId'] as num?)?.toInt(),
      labelName: json['labelName'] as String?,
      labelColor: json['labelColor'] as String?,
      location: json['location'] as String?,
      rrule: json['rrule'] as String?,
      reminders:
          (json['reminders'] as List<dynamic>?)
              ?.map((e) => EventReminder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <EventReminder>[],
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
      'calendarRowId': instance.calendarRowId,
      'calendarColor': instance.calendarColor,
      'labelRowId': instance.labelRowId,
      'labelName': instance.labelName,
      'labelColor': instance.labelColor,
      'location': instance.location,
      'rrule': instance.rrule,
      'reminders': instance.reminders,
    };

_EventReminder _$EventReminderFromJson(Map<String, dynamic> json) =>
    _EventReminder(
      rowId: (json['rowId'] as num?)?.toInt(),
      eventRowId: (json['eventRowId'] as num?)?.toInt(),
      reminderType: json['reminderType'] as String?,
      minutesBefore: (json['minutesBefore'] as num?)?.toInt(),
      isSent: json['isSent'] as String?,
    );

Map<String, dynamic> _$EventReminderToJson(_EventReminder instance) =>
    <String, dynamic>{
      'rowId': instance.rowId,
      'eventRowId': instance.eventRowId,
      'reminderType': instance.reminderType,
      'minutesBefore': instance.minutesBefore,
      'isSent': instance.isSent,
    };
