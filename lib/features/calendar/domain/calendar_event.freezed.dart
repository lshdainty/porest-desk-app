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

 int get rowId; int? get userRowId; String get title; String? get description; String? get eventType;// 'NORMAL' | 'BIRTHDAY' | 'ANNIVERSARY' ...
 String? get color; String get startDate;// ISO LocalDateTime
 String get endDate; String? get isAllDay;// 'Y'|'N'
 int? get calendarRowId; String? get calendarColor; int? get labelRowId; String? get labelName; String? get labelColor; String? get location; String? get rrule; int? get groupRowId; String? get groupName;
/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarEventCopyWith<CalendarEvent> get copyWith => _$CalendarEventCopyWithImpl<CalendarEvent>(this as CalendarEvent, _$identity);

  /// Serializes this CalendarEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarEvent&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.color, color) || other.color == color)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.isAllDay, isAllDay) || other.isAllDay == isAllDay)&&(identical(other.calendarRowId, calendarRowId) || other.calendarRowId == calendarRowId)&&(identical(other.calendarColor, calendarColor) || other.calendarColor == calendarColor)&&(identical(other.labelRowId, labelRowId) || other.labelRowId == labelRowId)&&(identical(other.labelName, labelName) || other.labelName == labelName)&&(identical(other.labelColor, labelColor) || other.labelColor == labelColor)&&(identical(other.location, location) || other.location == location)&&(identical(other.rrule, rrule) || other.rrule == rrule)&&(identical(other.groupRowId, groupRowId) || other.groupRowId == groupRowId)&&(identical(other.groupName, groupName) || other.groupName == groupName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,userRowId,title,description,eventType,color,startDate,endDate,isAllDay,calendarRowId,calendarColor,labelRowId,labelName,labelColor,location,rrule,groupRowId,groupName);

@override
String toString() {
  return 'CalendarEvent(rowId: $rowId, userRowId: $userRowId, title: $title, description: $description, eventType: $eventType, color: $color, startDate: $startDate, endDate: $endDate, isAllDay: $isAllDay, calendarRowId: $calendarRowId, calendarColor: $calendarColor, labelRowId: $labelRowId, labelName: $labelName, labelColor: $labelColor, location: $location, rrule: $rrule, groupRowId: $groupRowId, groupName: $groupName)';
}


}

/// @nodoc
abstract mixin class $CalendarEventCopyWith<$Res>  {
  factory $CalendarEventCopyWith(CalendarEvent value, $Res Function(CalendarEvent) _then) = _$CalendarEventCopyWithImpl;
@useResult
$Res call({
 int rowId, int? userRowId, String title, String? description, String? eventType, String? color, String startDate, String endDate, String? isAllDay, int? calendarRowId, String? calendarColor, int? labelRowId, String? labelName, String? labelColor, String? location, String? rrule, int? groupRowId, String? groupName
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
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = null,Object? userRowId = freezed,Object? title = null,Object? description = freezed,Object? eventType = freezed,Object? color = freezed,Object? startDate = null,Object? endDate = null,Object? isAllDay = freezed,Object? calendarRowId = freezed,Object? calendarColor = freezed,Object? labelRowId = freezed,Object? labelName = freezed,Object? labelColor = freezed,Object? location = freezed,Object? rrule = freezed,Object? groupRowId = freezed,Object? groupName = freezed,}) {
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
as String?,groupRowId: freezed == groupRowId ? _self.groupRowId : groupRowId // ignore: cast_nullable_to_non_nullable
as int?,groupName: freezed == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  String title,  String? description,  String? eventType,  String? color,  String startDate,  String endDate,  String? isAllDay,  int? calendarRowId,  String? calendarColor,  int? labelRowId,  String? labelName,  String? labelColor,  String? location,  String? rrule,  int? groupRowId,  String? groupName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.title,_that.description,_that.eventType,_that.color,_that.startDate,_that.endDate,_that.isAllDay,_that.calendarRowId,_that.calendarColor,_that.labelRowId,_that.labelName,_that.labelColor,_that.location,_that.rrule,_that.groupRowId,_that.groupName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  String title,  String? description,  String? eventType,  String? color,  String startDate,  String endDate,  String? isAllDay,  int? calendarRowId,  String? calendarColor,  int? labelRowId,  String? labelName,  String? labelColor,  String? location,  String? rrule,  int? groupRowId,  String? groupName)  $default,) {final _that = this;
switch (_that) {
case _CalendarEvent():
return $default(_that.rowId,_that.userRowId,_that.title,_that.description,_that.eventType,_that.color,_that.startDate,_that.endDate,_that.isAllDay,_that.calendarRowId,_that.calendarColor,_that.labelRowId,_that.labelName,_that.labelColor,_that.location,_that.rrule,_that.groupRowId,_that.groupName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowId,  int? userRowId,  String title,  String? description,  String? eventType,  String? color,  String startDate,  String endDate,  String? isAllDay,  int? calendarRowId,  String? calendarColor,  int? labelRowId,  String? labelName,  String? labelColor,  String? location,  String? rrule,  int? groupRowId,  String? groupName)?  $default,) {final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.title,_that.description,_that.eventType,_that.color,_that.startDate,_that.endDate,_that.isAllDay,_that.calendarRowId,_that.calendarColor,_that.labelRowId,_that.labelName,_that.labelColor,_that.location,_that.rrule,_that.groupRowId,_that.groupName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CalendarEvent implements CalendarEvent {
  const _CalendarEvent({required this.rowId, this.userRowId, required this.title, this.description, this.eventType, this.color, required this.startDate, required this.endDate, this.isAllDay, this.calendarRowId, this.calendarColor, this.labelRowId, this.labelName, this.labelColor, this.location, this.rrule, this.groupRowId, this.groupName});
  factory _CalendarEvent.fromJson(Map<String, dynamic> json) => _$CalendarEventFromJson(json);

@override final  int rowId;
@override final  int? userRowId;
@override final  String title;
@override final  String? description;
@override final  String? eventType;
// 'NORMAL' | 'BIRTHDAY' | 'ANNIVERSARY' ...
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
@override final  int? groupRowId;
@override final  String? groupName;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarEvent&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.color, color) || other.color == color)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.isAllDay, isAllDay) || other.isAllDay == isAllDay)&&(identical(other.calendarRowId, calendarRowId) || other.calendarRowId == calendarRowId)&&(identical(other.calendarColor, calendarColor) || other.calendarColor == calendarColor)&&(identical(other.labelRowId, labelRowId) || other.labelRowId == labelRowId)&&(identical(other.labelName, labelName) || other.labelName == labelName)&&(identical(other.labelColor, labelColor) || other.labelColor == labelColor)&&(identical(other.location, location) || other.location == location)&&(identical(other.rrule, rrule) || other.rrule == rrule)&&(identical(other.groupRowId, groupRowId) || other.groupRowId == groupRowId)&&(identical(other.groupName, groupName) || other.groupName == groupName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,userRowId,title,description,eventType,color,startDate,endDate,isAllDay,calendarRowId,calendarColor,labelRowId,labelName,labelColor,location,rrule,groupRowId,groupName);

@override
String toString() {
  return 'CalendarEvent(rowId: $rowId, userRowId: $userRowId, title: $title, description: $description, eventType: $eventType, color: $color, startDate: $startDate, endDate: $endDate, isAllDay: $isAllDay, calendarRowId: $calendarRowId, calendarColor: $calendarColor, labelRowId: $labelRowId, labelName: $labelName, labelColor: $labelColor, location: $location, rrule: $rrule, groupRowId: $groupRowId, groupName: $groupName)';
}


}

/// @nodoc
abstract mixin class _$CalendarEventCopyWith<$Res> implements $CalendarEventCopyWith<$Res> {
  factory _$CalendarEventCopyWith(_CalendarEvent value, $Res Function(_CalendarEvent) _then) = __$CalendarEventCopyWithImpl;
@override @useResult
$Res call({
 int rowId, int? userRowId, String title, String? description, String? eventType, String? color, String startDate, String endDate, String? isAllDay, int? calendarRowId, String? calendarColor, int? labelRowId, String? labelName, String? labelColor, String? location, String? rrule, int? groupRowId, String? groupName
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
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = null,Object? userRowId = freezed,Object? title = null,Object? description = freezed,Object? eventType = freezed,Object? color = freezed,Object? startDate = null,Object? endDate = null,Object? isAllDay = freezed,Object? calendarRowId = freezed,Object? calendarColor = freezed,Object? labelRowId = freezed,Object? labelName = freezed,Object? labelColor = freezed,Object? location = freezed,Object? rrule = freezed,Object? groupRowId = freezed,Object? groupName = freezed,}) {
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
as String?,groupRowId: freezed == groupRowId ? _self.groupRowId : groupRowId // ignore: cast_nullable_to_non_nullable
as int?,groupName: freezed == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
