// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'calendar_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CalendarEvent {

 int get rowId; int? get userRowId; String get title; String? get description;// 서버 enum `CalendarEventType` — 'PERSONAL' | 'WORK' | 'BIRTHDAY' | 'HOLIDAY'.
// 목록 밖의 값을 되보내면 저장이 400 으로 끝난다.
 String? get eventType; String? get color; String get startDate;// ISO LocalDateTime
 String get endDate; String? get isAllDay;// 'Y'|'N'
 int? get calendarRowId; String? get calendarColor; int? get labelRowId; String? get labelName; String? get labelColor; String? get location; String? get rrule;// 서버가 늘 채워 내려주는 목록(`CalendarEventApiDto.Response.reminders`).
// 목록·집계·수정 응답 셋 다 실려 온다 — 없으면 빈 목록으로 읽는다.
 List<EventReminder> get reminders;
/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarEventCopyWith<CalendarEvent> get copyWith => _$CalendarEventCopyWithImpl<CalendarEvent>(this as CalendarEvent, _$identity);

  /// Serializes this CalendarEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarEvent&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.color, color) || other.color == color)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.isAllDay, isAllDay) || other.isAllDay == isAllDay)&&(identical(other.calendarRowId, calendarRowId) || other.calendarRowId == calendarRowId)&&(identical(other.calendarColor, calendarColor) || other.calendarColor == calendarColor)&&(identical(other.labelRowId, labelRowId) || other.labelRowId == labelRowId)&&(identical(other.labelName, labelName) || other.labelName == labelName)&&(identical(other.labelColor, labelColor) || other.labelColor == labelColor)&&(identical(other.location, location) || other.location == location)&&(identical(other.rrule, rrule) || other.rrule == rrule)&&const DeepCollectionEquality().equals(other.reminders, reminders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,userRowId,title,description,eventType,color,startDate,endDate,isAllDay,calendarRowId,calendarColor,labelRowId,labelName,labelColor,location,rrule,const DeepCollectionEquality().hash(reminders));

@override
String toString() {
  return 'CalendarEvent(rowId: $rowId, userRowId: $userRowId, title: $title, description: $description, eventType: $eventType, color: $color, startDate: $startDate, endDate: $endDate, isAllDay: $isAllDay, calendarRowId: $calendarRowId, calendarColor: $calendarColor, labelRowId: $labelRowId, labelName: $labelName, labelColor: $labelColor, location: $location, rrule: $rrule, reminders: $reminders)';
}


}

/// @nodoc
abstract mixin class $CalendarEventCopyWith<$Res>  {
  factory $CalendarEventCopyWith(CalendarEvent value, $Res Function(CalendarEvent) _then) = _$CalendarEventCopyWithImpl;
@useResult
$Res call({
 int rowId, int? userRowId, String title, String? description, String? eventType, String? color, String startDate, String endDate, String? isAllDay, int? calendarRowId, String? calendarColor, int? labelRowId, String? labelName, String? labelColor, String? location, String? rrule, List<EventReminder> reminders
});




}
/// @nodoc
class _$CalendarEventCopyWithImpl<$Res>
    implements $CalendarEventCopyWith<$Res> {
  _$CalendarEventCopyWithImpl(this._self, this._then);

  final CalendarEvent _self;
  final $Res Function(CalendarEvent) _then;

/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = null,Object? userRowId = freezed,Object? title = null,Object? description = freezed,Object? eventType = freezed,Object? color = freezed,Object? startDate = null,Object? endDate = null,Object? isAllDay = freezed,Object? calendarRowId = freezed,Object? calendarColor = freezed,Object? labelRowId = freezed,Object? labelName = freezed,Object? labelColor = freezed,Object? location = freezed,Object? rrule = freezed,Object? reminders = null,}) {
  return _then(_self.copyWith(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,eventType: freezed == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String,isAllDay: freezed == isAllDay ? _self.isAllDay : isAllDay // ignore: cast_nullable_to_non_nullable
as String?,calendarRowId: freezed == calendarRowId ? _self.calendarRowId : calendarRowId // ignore: cast_nullable_to_non_nullable
as int?,calendarColor: freezed == calendarColor ? _self.calendarColor : calendarColor // ignore: cast_nullable_to_non_nullable
as String?,labelRowId: freezed == labelRowId ? _self.labelRowId : labelRowId // ignore: cast_nullable_to_non_nullable
as int?,labelName: freezed == labelName ? _self.labelName : labelName // ignore: cast_nullable_to_non_nullable
as String?,labelColor: freezed == labelColor ? _self.labelColor : labelColor // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,rrule: freezed == rrule ? _self.rrule : rrule // ignore: cast_nullable_to_non_nullable
as String?,reminders: null == reminders ? _self.reminders : reminders // ignore: cast_nullable_to_non_nullable
as List<EventReminder>,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarEvent].
extension CalendarEventPatterns on CalendarEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarEvent value)  $default,){
final _that = this;
switch (_that) {
case _CalendarEvent():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarEvent value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  String title,  String? description,  String? eventType,  String? color,  String startDate,  String endDate,  String? isAllDay,  int? calendarRowId,  String? calendarColor,  int? labelRowId,  String? labelName,  String? labelColor,  String? location,  String? rrule,  List<EventReminder> reminders)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.title,_that.description,_that.eventType,_that.color,_that.startDate,_that.endDate,_that.isAllDay,_that.calendarRowId,_that.calendarColor,_that.labelRowId,_that.labelName,_that.labelColor,_that.location,_that.rrule,_that.reminders);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  String title,  String? description,  String? eventType,  String? color,  String startDate,  String endDate,  String? isAllDay,  int? calendarRowId,  String? calendarColor,  int? labelRowId,  String? labelName,  String? labelColor,  String? location,  String? rrule,  List<EventReminder> reminders)  $default,) {final _that = this;
switch (_that) {
case _CalendarEvent():
return $default(_that.rowId,_that.userRowId,_that.title,_that.description,_that.eventType,_that.color,_that.startDate,_that.endDate,_that.isAllDay,_that.calendarRowId,_that.calendarColor,_that.labelRowId,_that.labelName,_that.labelColor,_that.location,_that.rrule,_that.reminders);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowId,  int? userRowId,  String title,  String? description,  String? eventType,  String? color,  String startDate,  String endDate,  String? isAllDay,  int? calendarRowId,  String? calendarColor,  int? labelRowId,  String? labelName,  String? labelColor,  String? location,  String? rrule,  List<EventReminder> reminders)?  $default,) {final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.title,_that.description,_that.eventType,_that.color,_that.startDate,_that.endDate,_that.isAllDay,_that.calendarRowId,_that.calendarColor,_that.labelRowId,_that.labelName,_that.labelColor,_that.location,_that.rrule,_that.reminders);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CalendarEvent implements CalendarEvent {
  const _CalendarEvent({required this.rowId, this.userRowId, required this.title, this.description, this.eventType, this.color, required this.startDate, required this.endDate, this.isAllDay, this.calendarRowId, this.calendarColor, this.labelRowId, this.labelName, this.labelColor, this.location, this.rrule, final  List<EventReminder> reminders = const <EventReminder>[]}): _reminders = reminders;
  factory _CalendarEvent.fromJson(Map<String, dynamic> json) => _$CalendarEventFromJson(json);

@override final  int rowId;
@override final  int? userRowId;
@override final  String title;
@override final  String? description;
// 서버 enum `CalendarEventType` — 'PERSONAL' | 'WORK' | 'BIRTHDAY' | 'HOLIDAY'.
// 목록 밖의 값을 되보내면 저장이 400 으로 끝난다.
@override final  String? eventType;
@override final  String? color;
@override final  String startDate;
// ISO LocalDateTime
@override final  String endDate;
@override final  String? isAllDay;
// 'Y'|'N'
@override final  int? calendarRowId;
@override final  String? calendarColor;
@override final  int? labelRowId;
@override final  String? labelName;
@override final  String? labelColor;
@override final  String? location;
@override final  String? rrule;
// 서버가 늘 채워 내려주는 목록(`CalendarEventApiDto.Response.reminders`).
// 목록·집계·수정 응답 셋 다 실려 온다 — 없으면 빈 목록으로 읽는다.
 final  List<EventReminder> _reminders;
// 서버가 늘 채워 내려주는 목록(`CalendarEventApiDto.Response.reminders`).
// 목록·집계·수정 응답 셋 다 실려 온다 — 없으면 빈 목록으로 읽는다.
@override@JsonKey() List<EventReminder> get reminders {
  if (_reminders is EqualUnmodifiableListView) return _reminders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reminders);
}


/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarEventCopyWith<_CalendarEvent> get copyWith => __$CalendarEventCopyWithImpl<_CalendarEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalendarEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarEvent&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.color, color) || other.color == color)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.isAllDay, isAllDay) || other.isAllDay == isAllDay)&&(identical(other.calendarRowId, calendarRowId) || other.calendarRowId == calendarRowId)&&(identical(other.calendarColor, calendarColor) || other.calendarColor == calendarColor)&&(identical(other.labelRowId, labelRowId) || other.labelRowId == labelRowId)&&(identical(other.labelName, labelName) || other.labelName == labelName)&&(identical(other.labelColor, labelColor) || other.labelColor == labelColor)&&(identical(other.location, location) || other.location == location)&&(identical(other.rrule, rrule) || other.rrule == rrule)&&const DeepCollectionEquality().equals(other._reminders, _reminders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,userRowId,title,description,eventType,color,startDate,endDate,isAllDay,calendarRowId,calendarColor,labelRowId,labelName,labelColor,location,rrule,const DeepCollectionEquality().hash(_reminders));

@override
String toString() {
  return 'CalendarEvent(rowId: $rowId, userRowId: $userRowId, title: $title, description: $description, eventType: $eventType, color: $color, startDate: $startDate, endDate: $endDate, isAllDay: $isAllDay, calendarRowId: $calendarRowId, calendarColor: $calendarColor, labelRowId: $labelRowId, labelName: $labelName, labelColor: $labelColor, location: $location, rrule: $rrule, reminders: $reminders)';
}


}

/// @nodoc
abstract mixin class _$CalendarEventCopyWith<$Res> implements $CalendarEventCopyWith<$Res> {
  factory _$CalendarEventCopyWith(_CalendarEvent value, $Res Function(_CalendarEvent) _then) = __$CalendarEventCopyWithImpl;
@override @useResult
$Res call({
 int rowId, int? userRowId, String title, String? description, String? eventType, String? color, String startDate, String endDate, String? isAllDay, int? calendarRowId, String? calendarColor, int? labelRowId, String? labelName, String? labelColor, String? location, String? rrule, List<EventReminder> reminders
});




}
/// @nodoc
class __$CalendarEventCopyWithImpl<$Res>
    implements _$CalendarEventCopyWith<$Res> {
  __$CalendarEventCopyWithImpl(this._self, this._then);

  final _CalendarEvent _self;
  final $Res Function(_CalendarEvent) _then;

/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = null,Object? userRowId = freezed,Object? title = null,Object? description = freezed,Object? eventType = freezed,Object? color = freezed,Object? startDate = null,Object? endDate = null,Object? isAllDay = freezed,Object? calendarRowId = freezed,Object? calendarColor = freezed,Object? labelRowId = freezed,Object? labelName = freezed,Object? labelColor = freezed,Object? location = freezed,Object? rrule = freezed,Object? reminders = null,}) {
  return _then(_CalendarEvent(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,eventType: freezed == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String,isAllDay: freezed == isAllDay ? _self.isAllDay : isAllDay // ignore: cast_nullable_to_non_nullable
as String?,calendarRowId: freezed == calendarRowId ? _self.calendarRowId : calendarRowId // ignore: cast_nullable_to_non_nullable
as int?,calendarColor: freezed == calendarColor ? _self.calendarColor : calendarColor // ignore: cast_nullable_to_non_nullable
as String?,labelRowId: freezed == labelRowId ? _self.labelRowId : labelRowId // ignore: cast_nullable_to_non_nullable
as int?,labelName: freezed == labelName ? _self.labelName : labelName // ignore: cast_nullable_to_non_nullable
as String?,labelColor: freezed == labelColor ? _self.labelColor : labelColor // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,rrule: freezed == rrule ? _self.rrule : rrule // ignore: cast_nullable_to_non_nullable
as String?,reminders: null == reminders ? _self._reminders : reminders // ignore: cast_nullable_to_non_nullable
as List<EventReminder>,
  ));
}


}


/// @nodoc
mixin _$EventReminder {

 int? get rowId; int? get eventRowId; String? get reminderType; int? get minutesBefore; String? get isSent;
/// Create a copy of EventReminder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventReminderCopyWith<EventReminder> get copyWith => _$EventReminderCopyWithImpl<EventReminder>(this as EventReminder, _$identity);

  /// Serializes this EventReminder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventReminder&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.eventRowId, eventRowId) || other.eventRowId == eventRowId)&&(identical(other.reminderType, reminderType) || other.reminderType == reminderType)&&(identical(other.minutesBefore, minutesBefore) || other.minutesBefore == minutesBefore)&&(identical(other.isSent, isSent) || other.isSent == isSent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,eventRowId,reminderType,minutesBefore,isSent);

@override
String toString() {
  return 'EventReminder(rowId: $rowId, eventRowId: $eventRowId, reminderType: $reminderType, minutesBefore: $minutesBefore, isSent: $isSent)';
}


}

/// @nodoc
abstract mixin class $EventReminderCopyWith<$Res>  {
  factory $EventReminderCopyWith(EventReminder value, $Res Function(EventReminder) _then) = _$EventReminderCopyWithImpl;
@useResult
$Res call({
 int? rowId, int? eventRowId, String? reminderType, int? minutesBefore, String? isSent
});




}
/// @nodoc
class _$EventReminderCopyWithImpl<$Res>
    implements $EventReminderCopyWith<$Res> {
  _$EventReminderCopyWithImpl(this._self, this._then);

  final EventReminder _self;
  final $Res Function(EventReminder) _then;

/// Create a copy of EventReminder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = freezed,Object? eventRowId = freezed,Object? reminderType = freezed,Object? minutesBefore = freezed,Object? isSent = freezed,}) {
  return _then(_self.copyWith(
rowId: freezed == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int?,eventRowId: freezed == eventRowId ? _self.eventRowId : eventRowId // ignore: cast_nullable_to_non_nullable
as int?,reminderType: freezed == reminderType ? _self.reminderType : reminderType // ignore: cast_nullable_to_non_nullable
as String?,minutesBefore: freezed == minutesBefore ? _self.minutesBefore : minutesBefore // ignore: cast_nullable_to_non_nullable
as int?,isSent: freezed == isSent ? _self.isSent : isSent // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EventReminder].
extension EventReminderPatterns on EventReminder {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventReminder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventReminder() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventReminder value)  $default,){
final _that = this;
switch (_that) {
case _EventReminder():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventReminder value)?  $default,){
final _that = this;
switch (_that) {
case _EventReminder() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? rowId,  int? eventRowId,  String? reminderType,  int? minutesBefore,  String? isSent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventReminder() when $default != null:
return $default(_that.rowId,_that.eventRowId,_that.reminderType,_that.minutesBefore,_that.isSent);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? rowId,  int? eventRowId,  String? reminderType,  int? minutesBefore,  String? isSent)  $default,) {final _that = this;
switch (_that) {
case _EventReminder():
return $default(_that.rowId,_that.eventRowId,_that.reminderType,_that.minutesBefore,_that.isSent);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? rowId,  int? eventRowId,  String? reminderType,  int? minutesBefore,  String? isSent)?  $default,) {final _that = this;
switch (_that) {
case _EventReminder() when $default != null:
return $default(_that.rowId,_that.eventRowId,_that.reminderType,_that.minutesBefore,_that.isSent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventReminder implements EventReminder {
  const _EventReminder({this.rowId, this.eventRowId, this.reminderType, this.minutesBefore, this.isSent});
  factory _EventReminder.fromJson(Map<String, dynamic> json) => _$EventReminderFromJson(json);

@override final  int? rowId;
@override final  int? eventRowId;
@override final  String? reminderType;
@override final  int? minutesBefore;
@override final  String? isSent;

/// Create a copy of EventReminder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventReminderCopyWith<_EventReminder> get copyWith => __$EventReminderCopyWithImpl<_EventReminder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventReminderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventReminder&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.eventRowId, eventRowId) || other.eventRowId == eventRowId)&&(identical(other.reminderType, reminderType) || other.reminderType == reminderType)&&(identical(other.minutesBefore, minutesBefore) || other.minutesBefore == minutesBefore)&&(identical(other.isSent, isSent) || other.isSent == isSent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,eventRowId,reminderType,minutesBefore,isSent);

@override
String toString() {
  return 'EventReminder(rowId: $rowId, eventRowId: $eventRowId, reminderType: $reminderType, minutesBefore: $minutesBefore, isSent: $isSent)';
}


}

/// @nodoc
abstract mixin class _$EventReminderCopyWith<$Res> implements $EventReminderCopyWith<$Res> {
  factory _$EventReminderCopyWith(_EventReminder value, $Res Function(_EventReminder) _then) = __$EventReminderCopyWithImpl;
@override @useResult
$Res call({
 int? rowId, int? eventRowId, String? reminderType, int? minutesBefore, String? isSent
});




}
/// @nodoc
class __$EventReminderCopyWithImpl<$Res>
    implements _$EventReminderCopyWith<$Res> {
  __$EventReminderCopyWithImpl(this._self, this._then);

  final _EventReminder _self;
  final $Res Function(_EventReminder) _then;

/// Create a copy of EventReminder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = freezed,Object? eventRowId = freezed,Object? reminderType = freezed,Object? minutesBefore = freezed,Object? isSent = freezed,}) {
  return _then(_EventReminder(
rowId: freezed == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int?,eventRowId: freezed == eventRowId ? _self.eventRowId : eventRowId // ignore: cast_nullable_to_non_nullable
as int?,reminderType: freezed == reminderType ? _self.reminderType : reminderType // ignore: cast_nullable_to_non_nullable
as String?,minutesBefore: freezed == minutesBefore ? _self.minutesBefore : minutesBefore // ignore: cast_nullable_to_non_nullable
as int?,isSent: freezed == isSent ? _self.isSent : isSent // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
