// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'net_worth_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NetWorthPoint {

 int get year; int get month;// 1~12
 int get netWorth;
/// Create a copy of NetWorthPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetWorthPointCopyWith<NetWorthPoint> get copyWith => _$NetWorthPointCopyWithImpl<NetWorthPoint>(this as NetWorthPoint, _$identity);

  /// Serializes this NetWorthPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetWorthPoint&&(identical(other.year, year) || other.year == year)&&(identical(other.month, month) || other.month == month)&&(identical(other.netWorth, netWorth) || other.netWorth == netWorth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,year,month,netWorth);

@override
String toString() {
  return 'NetWorthPoint(year: $year, month: $month, netWorth: $netWorth)';
}


}

/// @nodoc
abstract mixin class $NetWorthPointCopyWith<$Res>  {
  factory $NetWorthPointCopyWith(NetWorthPoint value, $Res Function(NetWorthPoint) _then) = _$NetWorthPointCopyWithImpl;
@useResult
$Res call({
 int year, int month, int netWorth
});




}
/// @nodoc
class _$NetWorthPointCopyWithImpl<$Res>
    implements $NetWorthPointCopyWith<$Res> {
  _$NetWorthPointCopyWithImpl(this._self, this._then);

  final NetWorthPoint _self;
  final $Res Function(NetWorthPoint) _then;

/// Create a copy of NetWorthPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? year = null,Object? month = null,Object? netWorth = null,}) {
  return _then(_self.copyWith(
year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,netWorth: null == netWorth ? _self.netWorth : netWorth // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [NetWorthPoint].
extension NetWorthPointPatterns on NetWorthPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NetWorthPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NetWorthPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NetWorthPoint value)  $default,){
final _that = this;
switch (_that) {
case _NetWorthPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NetWorthPoint value)?  $default,){
final _that = this;
switch (_that) {
case _NetWorthPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int year,  int month,  int netWorth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NetWorthPoint() when $default != null:
return $default(_that.year,_that.month,_that.netWorth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int year,  int month,  int netWorth)  $default,) {final _that = this;
switch (_that) {
case _NetWorthPoint():
return $default(_that.year,_that.month,_that.netWorth);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int year,  int month,  int netWorth)?  $default,) {final _that = this;
switch (_that) {
case _NetWorthPoint() when $default != null:
return $default(_that.year,_that.month,_that.netWorth);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NetWorthPoint extends NetWorthPoint {
  const _NetWorthPoint({required this.year, required this.month, this.netWorth = 0}): super._();
  factory _NetWorthPoint.fromJson(Map<String, dynamic> json) => _$NetWorthPointFromJson(json);

@override final  int year;
@override final  int month;
// 1~12
@override@JsonKey() final  int netWorth;

/// Create a copy of NetWorthPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetWorthPointCopyWith<_NetWorthPoint> get copyWith => __$NetWorthPointCopyWithImpl<_NetWorthPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NetWorthPointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetWorthPoint&&(identical(other.year, year) || other.year == year)&&(identical(other.month, month) || other.month == month)&&(identical(other.netWorth, netWorth) || other.netWorth == netWorth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,year,month,netWorth);

@override
String toString() {
  return 'NetWorthPoint(year: $year, month: $month, netWorth: $netWorth)';
}


}

/// @nodoc
abstract mixin class _$NetWorthPointCopyWith<$Res> implements $NetWorthPointCopyWith<$Res> {
  factory _$NetWorthPointCopyWith(_NetWorthPoint value, $Res Function(_NetWorthPoint) _then) = __$NetWorthPointCopyWithImpl;
@override @useResult
$Res call({
 int year, int month, int netWorth
});




}
/// @nodoc
class __$NetWorthPointCopyWithImpl<$Res>
    implements _$NetWorthPointCopyWith<$Res> {
  __$NetWorthPointCopyWithImpl(this._self, this._then);

  final _NetWorthPoint _self;
  final $Res Function(_NetWorthPoint) _then;

/// Create a copy of NetWorthPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? year = null,Object? month = null,Object? netWorth = null,}) {
  return _then(_NetWorthPoint(
year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,netWorth: null == netWorth ? _self.netWorth : netWorth // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
