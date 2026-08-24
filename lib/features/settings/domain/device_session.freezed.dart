// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeviceSession {

/// 로그아웃 요청에 그대로 쓴다.
 String get sessionId;/// `iPhone · Safari`. 서버가 UA 를 못 알아봤으면 null — 화면이 "알 수 없는 기기" 로 그린다.
 String? get deviceLabel;@JsonKey(unknownEnumValue: DeviceKind.unknown) DeviceKind get deviceKind;/// [UTC] 마지막으로 토큰을 새로 받은 시각. 한 번도 없었으면 null.
 String? get lastUsedAt;/// [UTC] 로그인 시각.
 String? get createAt;/// 지금 이 앱이 쓰고 있는 세션인지.
 bool get current;
/// Create a copy of DeviceSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceSessionCopyWith<DeviceSession> get copyWith => _$DeviceSessionCopyWithImpl<DeviceSession>(this as DeviceSession, _$identity);

  /// Serializes this DeviceSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceSession&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.deviceLabel, deviceLabel) || other.deviceLabel == deviceLabel)&&(identical(other.deviceKind, deviceKind) || other.deviceKind == deviceKind)&&(identical(other.lastUsedAt, lastUsedAt) || other.lastUsedAt == lastUsedAt)&&(identical(other.createAt, createAt) || other.createAt == createAt)&&(identical(other.current, current) || other.current == current));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,deviceLabel,deviceKind,lastUsedAt,createAt,current);

@override
String toString() {
  return 'DeviceSession(sessionId: $sessionId, deviceLabel: $deviceLabel, deviceKind: $deviceKind, lastUsedAt: $lastUsedAt, createAt: $createAt, current: $current)';
}


}

/// @nodoc
abstract mixin class $DeviceSessionCopyWith<$Res>  {
  factory $DeviceSessionCopyWith(DeviceSession value, $Res Function(DeviceSession) _then) = _$DeviceSessionCopyWithImpl;
@useResult
$Res call({
 String sessionId, String? deviceLabel,@JsonKey(unknownEnumValue: DeviceKind.unknown) DeviceKind deviceKind, String? lastUsedAt, String? createAt, bool current
});




}
/// @nodoc
class _$DeviceSessionCopyWithImpl<$Res>
    implements $DeviceSessionCopyWith<$Res> {
  _$DeviceSessionCopyWithImpl(this._self, this._then);

  final DeviceSession _self;
  final $Res Function(DeviceSession) _then;

/// Create a copy of DeviceSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? deviceLabel = freezed,Object? deviceKind = null,Object? lastUsedAt = freezed,Object? createAt = freezed,Object? current = null,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,deviceLabel: freezed == deviceLabel ? _self.deviceLabel : deviceLabel // ignore: cast_nullable_to_non_nullable
as String?,deviceKind: null == deviceKind ? _self.deviceKind : deviceKind // ignore: cast_nullable_to_non_nullable
as DeviceKind,lastUsedAt: freezed == lastUsedAt ? _self.lastUsedAt : lastUsedAt // ignore: cast_nullable_to_non_nullable
as String?,createAt: freezed == createAt ? _self.createAt : createAt // ignore: cast_nullable_to_non_nullable
as String?,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceSession].
extension DeviceSessionPatterns on DeviceSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceSession value)  $default,){
final _that = this;
switch (_that) {
case _DeviceSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceSession value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId,  String? deviceLabel, @JsonKey(unknownEnumValue: DeviceKind.unknown)  DeviceKind deviceKind,  String? lastUsedAt,  String? createAt,  bool current)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceSession() when $default != null:
return $default(_that.sessionId,_that.deviceLabel,_that.deviceKind,_that.lastUsedAt,_that.createAt,_that.current);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId,  String? deviceLabel, @JsonKey(unknownEnumValue: DeviceKind.unknown)  DeviceKind deviceKind,  String? lastUsedAt,  String? createAt,  bool current)  $default,) {final _that = this;
switch (_that) {
case _DeviceSession():
return $default(_that.sessionId,_that.deviceLabel,_that.deviceKind,_that.lastUsedAt,_that.createAt,_that.current);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId,  String? deviceLabel, @JsonKey(unknownEnumValue: DeviceKind.unknown)  DeviceKind deviceKind,  String? lastUsedAt,  String? createAt,  bool current)?  $default,) {final _that = this;
switch (_that) {
case _DeviceSession() when $default != null:
return $default(_that.sessionId,_that.deviceLabel,_that.deviceKind,_that.lastUsedAt,_that.createAt,_that.current);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceSession implements DeviceSession {
  const _DeviceSession({required this.sessionId, this.deviceLabel, @JsonKey(unknownEnumValue: DeviceKind.unknown) this.deviceKind = DeviceKind.unknown, this.lastUsedAt, this.createAt, this.current = false});
  factory _DeviceSession.fromJson(Map<String, dynamic> json) => _$DeviceSessionFromJson(json);

/// 로그아웃 요청에 그대로 쓴다.
@override final  String sessionId;
/// `iPhone · Safari`. 서버가 UA 를 못 알아봤으면 null — 화면이 "알 수 없는 기기" 로 그린다.
@override final  String? deviceLabel;
@override@JsonKey(unknownEnumValue: DeviceKind.unknown) final  DeviceKind deviceKind;
/// [UTC] 마지막으로 토큰을 새로 받은 시각. 한 번도 없었으면 null.
@override final  String? lastUsedAt;
/// [UTC] 로그인 시각.
@override final  String? createAt;
/// 지금 이 앱이 쓰고 있는 세션인지.
@override@JsonKey() final  bool current;

/// Create a copy of DeviceSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceSessionCopyWith<_DeviceSession> get copyWith => __$DeviceSessionCopyWithImpl<_DeviceSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceSession&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.deviceLabel, deviceLabel) || other.deviceLabel == deviceLabel)&&(identical(other.deviceKind, deviceKind) || other.deviceKind == deviceKind)&&(identical(other.lastUsedAt, lastUsedAt) || other.lastUsedAt == lastUsedAt)&&(identical(other.createAt, createAt) || other.createAt == createAt)&&(identical(other.current, current) || other.current == current));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,deviceLabel,deviceKind,lastUsedAt,createAt,current);

@override
String toString() {
  return 'DeviceSession(sessionId: $sessionId, deviceLabel: $deviceLabel, deviceKind: $deviceKind, lastUsedAt: $lastUsedAt, createAt: $createAt, current: $current)';
}


}

/// @nodoc
abstract mixin class _$DeviceSessionCopyWith<$Res> implements $DeviceSessionCopyWith<$Res> {
  factory _$DeviceSessionCopyWith(_DeviceSession value, $Res Function(_DeviceSession) _then) = __$DeviceSessionCopyWithImpl;
@override @useResult
$Res call({
 String sessionId, String? deviceLabel,@JsonKey(unknownEnumValue: DeviceKind.unknown) DeviceKind deviceKind, String? lastUsedAt, String? createAt, bool current
});




}
/// @nodoc
class __$DeviceSessionCopyWithImpl<$Res>
    implements _$DeviceSessionCopyWith<$Res> {
  __$DeviceSessionCopyWithImpl(this._self, this._then);

  final _DeviceSession _self;
  final $Res Function(_DeviceSession) _then;

/// Create a copy of DeviceSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? deviceLabel = freezed,Object? deviceKind = null,Object? lastUsedAt = freezed,Object? createAt = freezed,Object? current = null,}) {
  return _then(_DeviceSession(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,deviceLabel: freezed == deviceLabel ? _self.deviceLabel : deviceLabel // ignore: cast_nullable_to_non_nullable
as String?,deviceKind: null == deviceKind ? _self.deviceKind : deviceKind // ignore: cast_nullable_to_non_nullable
as DeviceKind,lastUsedAt: freezed == lastUsedAt ? _self.lastUsedAt : lastUsedAt // ignore: cast_nullable_to_non_nullable
as String?,createAt: freezed == createAt ? _self.createAt : createAt // ignore: cast_nullable_to_non_nullable
as String?,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
