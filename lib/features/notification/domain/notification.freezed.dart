// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppNotification {

 int get rowId; int? get userRowId; String? get notificationType; String get title; String? get message; String? get referenceType; int? get referenceId; bool get isRead; String? get readAt; String? get createAt;
/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppNotificationCopyWith<AppNotification> get copyWith => _$AppNotificationCopyWithImpl<AppNotification>(this as AppNotification, _$identity);

  /// Serializes this AppNotification to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppNotification&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.notificationType, notificationType) || other.notificationType == notificationType)&&(identical(other.title, title) || other.title == title)&&(identical(other.message, message) || other.message == message)&&(identical(other.referenceType, referenceType) || other.referenceType == referenceType)&&(identical(other.referenceId, referenceId) || other.referenceId == referenceId)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.createAt, createAt) || other.createAt == createAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,userRowId,notificationType,title,message,referenceType,referenceId,isRead,readAt,createAt);

@override
String toString() {
  return 'AppNotification(rowId: $rowId, userRowId: $userRowId, notificationType: $notificationType, title: $title, message: $message, referenceType: $referenceType, referenceId: $referenceId, isRead: $isRead, readAt: $readAt, createAt: $createAt)';
}


}

/// @nodoc
abstract mixin class $AppNotificationCopyWith<$Res>  {
  factory $AppNotificationCopyWith(AppNotification value, $Res Function(AppNotification) _then) = _$AppNotificationCopyWithImpl;
@useResult
$Res call({
 int rowId, int? userRowId, String? notificationType, String title, String? message, String? referenceType, int? referenceId, bool isRead, String? readAt, String? createAt
});




}
/// @nodoc
class _$AppNotificationCopyWithImpl<$Res>
    implements $AppNotificationCopyWith<$Res> {
  _$AppNotificationCopyWithImpl(this._self, this._then);

  final AppNotification _self;
  final $Res Function(AppNotification) _then;

/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = null,Object? userRowId = freezed,Object? notificationType = freezed,Object? title = null,Object? message = freezed,Object? referenceType = freezed,Object? referenceId = freezed,Object? isRead = null,Object? readAt = freezed,Object? createAt = freezed,}) {
  return _then(_self.copyWith(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,notificationType: freezed == notificationType ? _self.notificationType : notificationType // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,referenceType: freezed == referenceType ? _self.referenceType : referenceType // ignore: cast_nullable_to_non_nullable
as String?,referenceId: freezed == referenceId ? _self.referenceId : referenceId // ignore: cast_nullable_to_non_nullable
as int?,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as String?,createAt: freezed == createAt ? _self.createAt : createAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppNotification].
extension AppNotificationPatterns on AppNotification {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppNotification value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppNotification value)  $default,){
final _that = this;
switch (_that) {
case _AppNotification():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppNotification value)?  $default,){
final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  String? notificationType,  String title,  String? message,  String? referenceType,  int? referenceId,  bool isRead,  String? readAt,  String? createAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.notificationType,_that.title,_that.message,_that.referenceType,_that.referenceId,_that.isRead,_that.readAt,_that.createAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  String? notificationType,  String title,  String? message,  String? referenceType,  int? referenceId,  bool isRead,  String? readAt,  String? createAt)  $default,) {final _that = this;
switch (_that) {
case _AppNotification():
return $default(_that.rowId,_that.userRowId,_that.notificationType,_that.title,_that.message,_that.referenceType,_that.referenceId,_that.isRead,_that.readAt,_that.createAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowId,  int? userRowId,  String? notificationType,  String title,  String? message,  String? referenceType,  int? referenceId,  bool isRead,  String? readAt,  String? createAt)?  $default,) {final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.notificationType,_that.title,_that.message,_that.referenceType,_that.referenceId,_that.isRead,_that.readAt,_that.createAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppNotification implements AppNotification {
  const _AppNotification({required this.rowId, this.userRowId, this.notificationType, required this.title, this.message, this.referenceType, this.referenceId, this.isRead = false, this.readAt, this.createAt});
  factory _AppNotification.fromJson(Map<String, dynamic> json) => _$AppNotificationFromJson(json);

@override final  int rowId;
@override final  int? userRowId;
@override final  String? notificationType;
@override final  String title;
@override final  String? message;
@override final  String? referenceType;
@override final  int? referenceId;
@override@JsonKey() final  bool isRead;
@override final  String? readAt;
@override final  String? createAt;

/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppNotificationCopyWith<_AppNotification> get copyWith => __$AppNotificationCopyWithImpl<_AppNotification>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppNotificationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppNotification&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.notificationType, notificationType) || other.notificationType == notificationType)&&(identical(other.title, title) || other.title == title)&&(identical(other.message, message) || other.message == message)&&(identical(other.referenceType, referenceType) || other.referenceType == referenceType)&&(identical(other.referenceId, referenceId) || other.referenceId == referenceId)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.createAt, createAt) || other.createAt == createAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,userRowId,notificationType,title,message,referenceType,referenceId,isRead,readAt,createAt);

@override
String toString() {
  return 'AppNotification(rowId: $rowId, userRowId: $userRowId, notificationType: $notificationType, title: $title, message: $message, referenceType: $referenceType, referenceId: $referenceId, isRead: $isRead, readAt: $readAt, createAt: $createAt)';
}


}

/// @nodoc
abstract mixin class _$AppNotificationCopyWith<$Res> implements $AppNotificationCopyWith<$Res> {
  factory _$AppNotificationCopyWith(_AppNotification value, $Res Function(_AppNotification) _then) = __$AppNotificationCopyWithImpl;
@override @useResult
$Res call({
 int rowId, int? userRowId, String? notificationType, String title, String? message, String? referenceType, int? referenceId, bool isRead, String? readAt, String? createAt
});




}
/// @nodoc
class __$AppNotificationCopyWithImpl<$Res>
    implements _$AppNotificationCopyWith<$Res> {
  __$AppNotificationCopyWithImpl(this._self, this._then);

  final _AppNotification _self;
  final $Res Function(_AppNotification) _then;

/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = null,Object? userRowId = freezed,Object? notificationType = freezed,Object? title = null,Object? message = freezed,Object? referenceType = freezed,Object? referenceId = freezed,Object? isRead = null,Object? readAt = freezed,Object? createAt = freezed,}) {
  return _then(_AppNotification(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,notificationType: freezed == notificationType ? _self.notificationType : notificationType // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,referenceType: freezed == referenceType ? _self.referenceType : referenceType // ignore: cast_nullable_to_non_nullable
as String?,referenceId: freezed == referenceId ? _self.referenceId : referenceId // ignore: cast_nullable_to_non_nullable
as int?,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as String?,createAt: freezed == createAt ? _self.createAt : createAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
