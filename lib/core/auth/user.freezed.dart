// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$User {

 int get rowId; String get userId; String get userName; String get userEmail; String? get timezone;// 가입일시 — 백엔드 /auth/check 의 joinedAt(User.createAt). 미조회 시 null.
//
// 생성기 기본값인 DateTime.parse 는 시간대 표시가 없는 값을 로컬로 읽어 UTC 를
// 9시간(KST) 당겨 버린다 — 월초·월말 가입이면 "가입 2026년 8월" 이 7월로 보인다.
// user.g.dart 는 build_runner 가 덮어쓰므로 보정은 여기 fromJson 으로만 걸 수 있다.
//
// toJson 도 같이 지정해 왕복을 닫는다. parseServerUtc 는 isUtc=false 인 로컬
// DateTime 을 주는데 생성기 기본값 toIso8601String() 은 로컬이면 오프셋을 안 붙인다
// — 그 문자열을 다시 fromJson 으로 읽으면 UTC 로 오해해 왕복마다 +9 씩 밀린다.
// 지금은 User.toJson() 호출부가 없지만, 캐시·로그로 한 번 쓰는 순간 조용히 틀린다.
@JsonKey(fromJson: parseServerUtc, toJson: toServerUtc) DateTime? get joinedAt;
/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCopyWith<User> get copyWith => _$UserCopyWithImpl<User>(this as User, _$identity);

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is User&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userEmail, userEmail) || other.userEmail == userEmail)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,userId,userName,userEmail,timezone,joinedAt);

@override
String toString() {
  return 'User(rowId: $rowId, userId: $userId, userName: $userName, userEmail: $userEmail, timezone: $timezone, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class $UserCopyWith<$Res>  {
  factory $UserCopyWith(User value, $Res Function(User) _then) = _$UserCopyWithImpl;
@useResult
$Res call({
 int rowId, String userId, String userName, String userEmail, String? timezone,@JsonKey(fromJson: parseServerUtc, toJson: toServerUtc) DateTime? joinedAt
});




}
/// @nodoc
class _$UserCopyWithImpl<$Res>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._self, this._then);

  final User _self;
  final $Res Function(User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = null,Object? userId = null,Object? userName = null,Object? userEmail = null,Object? timezone = freezed,Object? joinedAt = freezed,}) {
  return _then(_self.copyWith(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,userEmail: null == userEmail ? _self.userEmail : userEmail // ignore: cast_nullable_to_non_nullable
as String,timezone: freezed == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String?,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [User].
extension UserPatterns on User {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _User value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _User() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _User value)  $default,){
final _that = this;
switch (_that) {
case _User():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _User value)?  $default,){
final _that = this;
switch (_that) {
case _User() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowId,  String userId,  String userName,  String userEmail,  String? timezone, @JsonKey(fromJson: parseServerUtc, toJson: toServerUtc)  DateTime? joinedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that.rowId,_that.userId,_that.userName,_that.userEmail,_that.timezone,_that.joinedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowId,  String userId,  String userName,  String userEmail,  String? timezone, @JsonKey(fromJson: parseServerUtc, toJson: toServerUtc)  DateTime? joinedAt)  $default,) {final _that = this;
switch (_that) {
case _User():
return $default(_that.rowId,_that.userId,_that.userName,_that.userEmail,_that.timezone,_that.joinedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowId,  String userId,  String userName,  String userEmail,  String? timezone, @JsonKey(fromJson: parseServerUtc, toJson: toServerUtc)  DateTime? joinedAt)?  $default,) {final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that.rowId,_that.userId,_that.userName,_that.userEmail,_that.timezone,_that.joinedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _User implements User {
  const _User({required this.rowId, required this.userId, required this.userName, required this.userEmail, this.timezone, @JsonKey(fromJson: parseServerUtc, toJson: toServerUtc) this.joinedAt});
  factory _User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

@override final  int rowId;
@override final  String userId;
@override final  String userName;
@override final  String userEmail;
@override final  String? timezone;
// 가입일시 — 백엔드 /auth/check 의 joinedAt(User.createAt). 미조회 시 null.
//
// 생성기 기본값인 DateTime.parse 는 시간대 표시가 없는 값을 로컬로 읽어 UTC 를
// 9시간(KST) 당겨 버린다 — 월초·월말 가입이면 "가입 2026년 8월" 이 7월로 보인다.
// user.g.dart 는 build_runner 가 덮어쓰므로 보정은 여기 fromJson 으로만 걸 수 있다.
//
// toJson 도 같이 지정해 왕복을 닫는다. parseServerUtc 는 isUtc=false 인 로컬
// DateTime 을 주는데 생성기 기본값 toIso8601String() 은 로컬이면 오프셋을 안 붙인다
// — 그 문자열을 다시 fromJson 으로 읽으면 UTC 로 오해해 왕복마다 +9 씩 밀린다.
// 지금은 User.toJson() 호출부가 없지만, 캐시·로그로 한 번 쓰는 순간 조용히 틀린다.
@override@JsonKey(fromJson: parseServerUtc, toJson: toServerUtc) final  DateTime? joinedAt;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCopyWith<_User> get copyWith => __$UserCopyWithImpl<_User>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _User&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userEmail, userEmail) || other.userEmail == userEmail)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,userId,userName,userEmail,timezone,joinedAt);

@override
String toString() {
  return 'User(rowId: $rowId, userId: $userId, userName: $userName, userEmail: $userEmail, timezone: $timezone, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class _$UserCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$UserCopyWith(_User value, $Res Function(_User) _then) = __$UserCopyWithImpl;
@override @useResult
$Res call({
 int rowId, String userId, String userName, String userEmail, String? timezone,@JsonKey(fromJson: parseServerUtc, toJson: toServerUtc) DateTime? joinedAt
});




}
/// @nodoc
class __$UserCopyWithImpl<$Res>
    implements _$UserCopyWith<$Res> {
  __$UserCopyWithImpl(this._self, this._then);

  final _User _self;
  final $Res Function(_User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = null,Object? userId = null,Object? userName = null,Object? userEmail = null,Object? timezone = freezed,Object? joinedAt = freezed,}) {
  return _then(_User(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,userEmail: null == userEmail ? _self.userEmail : userEmail // ignore: cast_nullable_to_non_nullable
as String,timezone: freezed == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String?,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
