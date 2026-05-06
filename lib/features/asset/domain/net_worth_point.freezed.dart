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

 String get month;// 'YYYY-MM'
 int get totalAssets; int get totalDebt; int get netWorth;
/// Create a copy of NetWorthPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetWorthPointCopyWith<NetWorthPoint> get copyWith => _$NetWorthPointCopyWithImpl<NetWorthPoint>(this as NetWorthPoint, _$identity);

  /// Serializes this NetWorthPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetWorthPoint&&(identical(other.month, month) || other.month == month)&&(identical(other.totalAssets, totalAssets) || other.totalAssets == totalAssets)&&(identical(other.totalDebt, totalDebt) || other.totalDebt == totalDebt)&&(identical(other.netWorth, netWorth) || other.netWorth == netWorth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,totalAssets,totalDebt,netWorth);

@override
String toString() {
  return 'NetWorthPoint(month: $month, totalAssets: $totalAssets, totalDebt: $totalDebt, netWorth: $netWorth)';
}


}

/// @nodoc
abstract mixin class $NetWorthPointCopyWith<$Res>  {
  factory $NetWorthPointCopyWith(NetWorthPoint value, $Res Function(NetWorthPoint) _then) = _$NetWorthPointCopyWithImpl;
@useResult
$Res call({
 String month, int totalAssets, int totalDebt, int netWorth
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
@pragma('vm:prefer-inline') @override $Res call({Object? month = null,Object? totalAssets = null,Object? totalDebt = null,Object? netWorth = null,}) {
  return _then(_self.copyWith(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,totalAssets: null == totalAssets ? _self.totalAssets : totalAssets // ignore: cast_nullable_to_non_nullable
as int,totalDebt: null == totalDebt ? _self.totalDebt : totalDebt // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String month,  int totalAssets,  int totalDebt,  int netWorth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NetWorthPoint() when $default != null:
return $default(_that.month,_that.totalAssets,_that.totalDebt,_that.netWorth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String month,  int totalAssets,  int totalDebt,  int netWorth)  $default,) {final _that = this;
switch (_that) {
case _NetWorthPoint():
return $default(_that.month,_that.totalAssets,_that.totalDebt,_that.netWorth);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String month,  int totalAssets,  int totalDebt,  int netWorth)?  $default,) {final _that = this;
switch (_that) {
case _NetWorthPoint() when $default != null:
return $default(_that.month,_that.totalAssets,_that.totalDebt,_that.netWorth);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NetWorthPoint implements NetWorthPoint {
  const _NetWorthPoint({required this.month, this.totalAssets = 0, this.totalDebt = 0, this.netWorth = 0});
  factory _NetWorthPoint.fromJson(Map<String, dynamic> json) => _$NetWorthPointFromJson(json);

@override final  String month;
// 'YYYY-MM'
@override@JsonKey() final  int totalAssets;
@override@JsonKey() final  int totalDebt;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetWorthPoint&&(identical(other.month, month) || other.month == month)&&(identical(other.totalAssets, totalAssets) || other.totalAssets == totalAssets)&&(identical(other.totalDebt, totalDebt) || other.totalDebt == totalDebt)&&(identical(other.netWorth, netWorth) || other.netWorth == netWorth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,totalAssets,totalDebt,netWorth);

@override
String toString() {
  return 'NetWorthPoint(month: $month, totalAssets: $totalAssets, totalDebt: $totalDebt, netWorth: $netWorth)';
}


}

/// @nodoc
abstract mixin class _$NetWorthPointCopyWith<$Res> implements $NetWorthPointCopyWith<$Res> {
  factory _$NetWorthPointCopyWith(_NetWorthPoint value, $Res Function(_NetWorthPoint) _then) = __$NetWorthPointCopyWithImpl;
@override @useResult
$Res call({
 String month, int totalAssets, int totalDebt, int netWorth
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
@override @pragma('vm:prefer-inline') $Res call({Object? month = null,Object? totalAssets = null,Object? totalDebt = null,Object? netWorth = null,}) {
  return _then(_NetWorthPoint(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,totalAssets: null == totalAssets ? _self.totalAssets : totalAssets // ignore: cast_nullable_to_non_nullable
as int,totalDebt: null == totalDebt ? _self.totalDebt : totalDebt // ignore: cast_nullable_to_non_nullable
as int,netWorth: null == netWorth ? _self.netWorth : netWorth // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
