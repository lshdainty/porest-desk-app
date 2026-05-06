// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_label.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EventLabel {

 int get rowId; int? get userRowId; String get labelName; String? get color; int? get sortOrder;
/// Create a copy of EventLabel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventLabelCopyWith<EventLabel> get copyWith => _$EventLabelCopyWithImpl<EventLabel>(this as EventLabel, _$identity);

  /// Serializes this EventLabel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventLabel&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.labelName, labelName) || other.labelName == labelName)&&(identical(other.color, color) || other.color == color)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,userRowId,labelName,color,sortOrder);

@override
String toString() {
  return 'EventLabel(rowId: $rowId, userRowId: $userRowId, labelName: $labelName, color: $color, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $EventLabelCopyWith<$Res>  {
  factory $EventLabelCopyWith(EventLabel value, $Res Function(EventLabel) _then) = _$EventLabelCopyWithImpl;
@useResult
$Res call({
 int rowId, int? userRowId, String labelName, String? color, int? sortOrder
});




}
/// @nodoc
class _$EventLabelCopyWithImpl<$Res>
    implements $EventLabelCopyWith<$Res> {
  _$EventLabelCopyWithImpl(this._self, this._then);

  final EventLabel _self;
  final $Res Function(EventLabel) _then;

/// Create a copy of EventLabel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = null,Object? userRowId = freezed,Object? labelName = null,Object? color = freezed,Object? sortOrder = freezed,}) {
  return _then(_self.copyWith(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,labelName: null == labelName ? _self.labelName : labelName // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [EventLabel].
extension EventLabelPatterns on EventLabel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventLabel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventLabel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventLabel value)  $default,){
final _that = this;
switch (_that) {
case _EventLabel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventLabel value)?  $default,){
final _that = this;
switch (_that) {
case _EventLabel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  String labelName,  String? color,  int? sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventLabel() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.labelName,_that.color,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  String labelName,  String? color,  int? sortOrder)  $default,) {final _that = this;
switch (_that) {
case _EventLabel():
return $default(_that.rowId,_that.userRowId,_that.labelName,_that.color,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowId,  int? userRowId,  String labelName,  String? color,  int? sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _EventLabel() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.labelName,_that.color,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventLabel implements EventLabel {
  const _EventLabel({required this.rowId, this.userRowId, required this.labelName, this.color, this.sortOrder});
  factory _EventLabel.fromJson(Map<String, dynamic> json) => _$EventLabelFromJson(json);

@override final  int rowId;
@override final  int? userRowId;
@override final  String labelName;
@override final  String? color;
@override final  int? sortOrder;

/// Create a copy of EventLabel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventLabelCopyWith<_EventLabel> get copyWith => __$EventLabelCopyWithImpl<_EventLabel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventLabelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventLabel&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.labelName, labelName) || other.labelName == labelName)&&(identical(other.color, color) || other.color == color)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,userRowId,labelName,color,sortOrder);

@override
String toString() {
  return 'EventLabel(rowId: $rowId, userRowId: $userRowId, labelName: $labelName, color: $color, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$EventLabelCopyWith<$Res> implements $EventLabelCopyWith<$Res> {
  factory _$EventLabelCopyWith(_EventLabel value, $Res Function(_EventLabel) _then) = __$EventLabelCopyWithImpl;
@override @useResult
$Res call({
 int rowId, int? userRowId, String labelName, String? color, int? sortOrder
});




}
/// @nodoc
class __$EventLabelCopyWithImpl<$Res>
    implements _$EventLabelCopyWith<$Res> {
  __$EventLabelCopyWithImpl(this._self, this._then);

  final _EventLabel _self;
  final $Res Function(_EventLabel) _then;

/// Create a copy of EventLabel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = null,Object? userRowId = freezed,Object? labelName = null,Object? color = freezed,Object? sortOrder = freezed,}) {
  return _then(_EventLabel(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,labelName: null == labelName ? _self.labelName : labelName // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
