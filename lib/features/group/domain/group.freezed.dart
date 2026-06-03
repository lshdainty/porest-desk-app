// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Group {

 int get rowId; String get groupName; String? get description; int? get groupTypeId; String? get groupTypeName; String? get groupTypeColor; String? get color; String? get inviteCode; int get memberCount; String? get createAt;
/// Create a copy of Group
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupCopyWith<Group> get copyWith => _$GroupCopyWithImpl<Group>(this as Group, _$identity);

  /// Serializes this Group to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Group&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.description, description) || other.description == description)&&(identical(other.groupTypeId, groupTypeId) || other.groupTypeId == groupTypeId)&&(identical(other.groupTypeName, groupTypeName) || other.groupTypeName == groupTypeName)&&(identical(other.groupTypeColor, groupTypeColor) || other.groupTypeColor == groupTypeColor)&&(identical(other.color, color) || other.color == color)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&(identical(other.createAt, createAt) || other.createAt == createAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,groupName,description,groupTypeId,groupTypeName,groupTypeColor,color,inviteCode,memberCount,createAt);

@override
String toString() {
  return 'Group(rowId: $rowId, groupName: $groupName, description: $description, groupTypeId: $groupTypeId, groupTypeName: $groupTypeName, groupTypeColor: $groupTypeColor, color: $color, inviteCode: $inviteCode, memberCount: $memberCount, createAt: $createAt)';
}


}

/// @nodoc
abstract mixin class $GroupCopyWith<$Res>  {
  factory $GroupCopyWith(Group value, $Res Function(Group) _then) = _$GroupCopyWithImpl;
@useResult
$Res call({
 int rowId, String groupName, String? description, int? groupTypeId, String? groupTypeName, String? groupTypeColor, String? color, String? inviteCode, int memberCount, String? createAt
});




}
/// @nodoc
class _$GroupCopyWithImpl<$Res>
    implements $GroupCopyWith<$Res> {
  _$GroupCopyWithImpl(this._self, this._then);

  final Group _self;
  final $Res Function(Group) _then;

/// Create a copy of Group
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = null,Object? groupName = null,Object? description = freezed,Object? groupTypeId = freezed,Object? groupTypeName = freezed,Object? groupTypeColor = freezed,Object? color = freezed,Object? inviteCode = freezed,Object? memberCount = null,Object? createAt = freezed,}) {
  return _then(_self.copyWith(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,groupName: null == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,groupTypeId: freezed == groupTypeId ? _self.groupTypeId : groupTypeId // ignore: cast_nullable_to_non_nullable
as int?,groupTypeName: freezed == groupTypeName ? _self.groupTypeName : groupTypeName // ignore: cast_nullable_to_non_nullable
as String?,groupTypeColor: freezed == groupTypeColor ? _self.groupTypeColor : groupTypeColor // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,inviteCode: freezed == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String?,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,createAt: freezed == createAt ? _self.createAt : createAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Group].
extension GroupPatterns on Group {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Group value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Group() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Group value)  $default,){
final _that = this;
switch (_that) {
case _Group():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Group value)?  $default,){
final _that = this;
switch (_that) {
case _Group() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowId,  String groupName,  String? description,  int? groupTypeId,  String? groupTypeName,  String? groupTypeColor,  String? color,  String? inviteCode,  int memberCount,  String? createAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Group() when $default != null:
return $default(_that.rowId,_that.groupName,_that.description,_that.groupTypeId,_that.groupTypeName,_that.groupTypeColor,_that.color,_that.inviteCode,_that.memberCount,_that.createAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowId,  String groupName,  String? description,  int? groupTypeId,  String? groupTypeName,  String? groupTypeColor,  String? color,  String? inviteCode,  int memberCount,  String? createAt)  $default,) {final _that = this;
switch (_that) {
case _Group():
return $default(_that.rowId,_that.groupName,_that.description,_that.groupTypeId,_that.groupTypeName,_that.groupTypeColor,_that.color,_that.inviteCode,_that.memberCount,_that.createAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowId,  String groupName,  String? description,  int? groupTypeId,  String? groupTypeName,  String? groupTypeColor,  String? color,  String? inviteCode,  int memberCount,  String? createAt)?  $default,) {final _that = this;
switch (_that) {
case _Group() when $default != null:
return $default(_that.rowId,_that.groupName,_that.description,_that.groupTypeId,_that.groupTypeName,_that.groupTypeColor,_that.color,_that.inviteCode,_that.memberCount,_that.createAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Group implements Group {
  const _Group({required this.rowId, required this.groupName, this.description, this.groupTypeId, this.groupTypeName, this.groupTypeColor, this.color, this.inviteCode, this.memberCount = 0, this.createAt});
  factory _Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);

@override final  int rowId;
@override final  String groupName;
@override final  String? description;
@override final  int? groupTypeId;
@override final  String? groupTypeName;
@override final  String? groupTypeColor;
@override final  String? color;
@override final  String? inviteCode;
@override@JsonKey() final  int memberCount;
@override final  String? createAt;

/// Create a copy of Group
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupCopyWith<_Group> get copyWith => __$GroupCopyWithImpl<_Group>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Group&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.description, description) || other.description == description)&&(identical(other.groupTypeId, groupTypeId) || other.groupTypeId == groupTypeId)&&(identical(other.groupTypeName, groupTypeName) || other.groupTypeName == groupTypeName)&&(identical(other.groupTypeColor, groupTypeColor) || other.groupTypeColor == groupTypeColor)&&(identical(other.color, color) || other.color == color)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&(identical(other.createAt, createAt) || other.createAt == createAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,groupName,description,groupTypeId,groupTypeName,groupTypeColor,color,inviteCode,memberCount,createAt);

@override
String toString() {
  return 'Group(rowId: $rowId, groupName: $groupName, description: $description, groupTypeId: $groupTypeId, groupTypeName: $groupTypeName, groupTypeColor: $groupTypeColor, color: $color, inviteCode: $inviteCode, memberCount: $memberCount, createAt: $createAt)';
}


}

/// @nodoc
abstract mixin class _$GroupCopyWith<$Res> implements $GroupCopyWith<$Res> {
  factory _$GroupCopyWith(_Group value, $Res Function(_Group) _then) = __$GroupCopyWithImpl;
@override @useResult
$Res call({
 int rowId, String groupName, String? description, int? groupTypeId, String? groupTypeName, String? groupTypeColor, String? color, String? inviteCode, int memberCount, String? createAt
});




}
/// @nodoc
class __$GroupCopyWithImpl<$Res>
    implements _$GroupCopyWith<$Res> {
  __$GroupCopyWithImpl(this._self, this._then);

  final _Group _self;
  final $Res Function(_Group) _then;

/// Create a copy of Group
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = null,Object? groupName = null,Object? description = freezed,Object? groupTypeId = freezed,Object? groupTypeName = freezed,Object? groupTypeColor = freezed,Object? color = freezed,Object? inviteCode = freezed,Object? memberCount = null,Object? createAt = freezed,}) {
  return _then(_Group(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,groupName: null == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,groupTypeId: freezed == groupTypeId ? _self.groupTypeId : groupTypeId // ignore: cast_nullable_to_non_nullable
as int?,groupTypeName: freezed == groupTypeName ? _self.groupTypeName : groupTypeName // ignore: cast_nullable_to_non_nullable
as String?,groupTypeColor: freezed == groupTypeColor ? _self.groupTypeColor : groupTypeColor // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,inviteCode: freezed == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String?,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,createAt: freezed == createAt ? _self.createAt : createAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
