// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AssetSummary {

 int get totalBalance; int get totalAssets; int get totalDebt; int get netWorth; int get lastMonthNetWorth; int get changeAmount; double get changePercent;
/// Create a copy of AssetSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetSummaryCopyWith<AssetSummary> get copyWith => _$AssetSummaryCopyWithImpl<AssetSummary>(this as AssetSummary, _$identity);

  /// Serializes this AssetSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetSummary&&(identical(other.totalBalance, totalBalance) || other.totalBalance == totalBalance)&&(identical(other.totalAssets, totalAssets) || other.totalAssets == totalAssets)&&(identical(other.totalDebt, totalDebt) || other.totalDebt == totalDebt)&&(identical(other.netWorth, netWorth) || other.netWorth == netWorth)&&(identical(other.lastMonthNetWorth, lastMonthNetWorth) || other.lastMonthNetWorth == lastMonthNetWorth)&&(identical(other.changeAmount, changeAmount) || other.changeAmount == changeAmount)&&(identical(other.changePercent, changePercent) || other.changePercent == changePercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalBalance,totalAssets,totalDebt,netWorth,lastMonthNetWorth,changeAmount,changePercent);

@override
String toString() {
  return 'AssetSummary(totalBalance: $totalBalance, totalAssets: $totalAssets, totalDebt: $totalDebt, netWorth: $netWorth, lastMonthNetWorth: $lastMonthNetWorth, changeAmount: $changeAmount, changePercent: $changePercent)';
}


}

/// @nodoc
abstract mixin class $AssetSummaryCopyWith<$Res>  {
  factory $AssetSummaryCopyWith(AssetSummary value, $Res Function(AssetSummary) _then) = _$AssetSummaryCopyWithImpl;
@useResult
$Res call({
 int totalBalance, int totalAssets, int totalDebt, int netWorth, int lastMonthNetWorth, int changeAmount, double changePercent
});




}
/// @nodoc
class _$AssetSummaryCopyWithImpl<$Res>
    implements $AssetSummaryCopyWith<$Res> {
  _$AssetSummaryCopyWithImpl(this._self, this._then);

  final AssetSummary _self;
  final $Res Function(AssetSummary) _then;

/// Create a copy of AssetSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalBalance = null,Object? totalAssets = null,Object? totalDebt = null,Object? netWorth = null,Object? lastMonthNetWorth = null,Object? changeAmount = null,Object? changePercent = null,}) {
  return _then(_self.copyWith(
totalBalance: null == totalBalance ? _self.totalBalance : totalBalance // ignore: cast_nullable_to_non_nullable
as int,totalAssets: null == totalAssets ? _self.totalAssets : totalAssets // ignore: cast_nullable_to_non_nullable
as int,totalDebt: null == totalDebt ? _self.totalDebt : totalDebt // ignore: cast_nullable_to_non_nullable
as int,netWorth: null == netWorth ? _self.netWorth : netWorth // ignore: cast_nullable_to_non_nullable
as int,lastMonthNetWorth: null == lastMonthNetWorth ? _self.lastMonthNetWorth : lastMonthNetWorth // ignore: cast_nullable_to_non_nullable
as int,changeAmount: null == changeAmount ? _self.changeAmount : changeAmount // ignore: cast_nullable_to_non_nullable
as int,changePercent: null == changePercent ? _self.changePercent : changePercent // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [AssetSummary].
extension AssetSummaryPatterns on AssetSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssetSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssetSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssetSummary value)  $default,){
final _that = this;
switch (_that) {
case _AssetSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssetSummary value)?  $default,){
final _that = this;
switch (_that) {
case _AssetSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalBalance,  int totalAssets,  int totalDebt,  int netWorth,  int lastMonthNetWorth,  int changeAmount,  double changePercent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssetSummary() when $default != null:
return $default(_that.totalBalance,_that.totalAssets,_that.totalDebt,_that.netWorth,_that.lastMonthNetWorth,_that.changeAmount,_that.changePercent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalBalance,  int totalAssets,  int totalDebt,  int netWorth,  int lastMonthNetWorth,  int changeAmount,  double changePercent)  $default,) {final _that = this;
switch (_that) {
case _AssetSummary():
return $default(_that.totalBalance,_that.totalAssets,_that.totalDebt,_that.netWorth,_that.lastMonthNetWorth,_that.changeAmount,_that.changePercent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalBalance,  int totalAssets,  int totalDebt,  int netWorth,  int lastMonthNetWorth,  int changeAmount,  double changePercent)?  $default,) {final _that = this;
switch (_that) {
case _AssetSummary() when $default != null:
return $default(_that.totalBalance,_that.totalAssets,_that.totalDebt,_that.netWorth,_that.lastMonthNetWorth,_that.changeAmount,_that.changePercent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssetSummary implements AssetSummary {
  const _AssetSummary({this.totalBalance = 0, this.totalAssets = 0, this.totalDebt = 0, this.netWorth = 0, this.lastMonthNetWorth = 0, this.changeAmount = 0, this.changePercent = 0.0});
  factory _AssetSummary.fromJson(Map<String, dynamic> json) => _$AssetSummaryFromJson(json);

@override@JsonKey() final  int totalBalance;
@override@JsonKey() final  int totalAssets;
@override@JsonKey() final  int totalDebt;
@override@JsonKey() final  int netWorth;
@override@JsonKey() final  int lastMonthNetWorth;
@override@JsonKey() final  int changeAmount;
@override@JsonKey() final  double changePercent;

/// Create a copy of AssetSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssetSummaryCopyWith<_AssetSummary> get copyWith => __$AssetSummaryCopyWithImpl<_AssetSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssetSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssetSummary&&(identical(other.totalBalance, totalBalance) || other.totalBalance == totalBalance)&&(identical(other.totalAssets, totalAssets) || other.totalAssets == totalAssets)&&(identical(other.totalDebt, totalDebt) || other.totalDebt == totalDebt)&&(identical(other.netWorth, netWorth) || other.netWorth == netWorth)&&(identical(other.lastMonthNetWorth, lastMonthNetWorth) || other.lastMonthNetWorth == lastMonthNetWorth)&&(identical(other.changeAmount, changeAmount) || other.changeAmount == changeAmount)&&(identical(other.changePercent, changePercent) || other.changePercent == changePercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalBalance,totalAssets,totalDebt,netWorth,lastMonthNetWorth,changeAmount,changePercent);

@override
String toString() {
  return 'AssetSummary(totalBalance: $totalBalance, totalAssets: $totalAssets, totalDebt: $totalDebt, netWorth: $netWorth, lastMonthNetWorth: $lastMonthNetWorth, changeAmount: $changeAmount, changePercent: $changePercent)';
}


}

/// @nodoc
abstract mixin class _$AssetSummaryCopyWith<$Res> implements $AssetSummaryCopyWith<$Res> {
  factory _$AssetSummaryCopyWith(_AssetSummary value, $Res Function(_AssetSummary) _then) = __$AssetSummaryCopyWithImpl;
@override @useResult
$Res call({
 int totalBalance, int totalAssets, int totalDebt, int netWorth, int lastMonthNetWorth, int changeAmount, double changePercent
});




}
/// @nodoc
class __$AssetSummaryCopyWithImpl<$Res>
    implements _$AssetSummaryCopyWith<$Res> {
  __$AssetSummaryCopyWithImpl(this._self, this._then);

  final _AssetSummary _self;
  final $Res Function(_AssetSummary) _then;

/// Create a copy of AssetSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalBalance = null,Object? totalAssets = null,Object? totalDebt = null,Object? netWorth = null,Object? lastMonthNetWorth = null,Object? changeAmount = null,Object? changePercent = null,}) {
  return _then(_AssetSummary(
totalBalance: null == totalBalance ? _self.totalBalance : totalBalance // ignore: cast_nullable_to_non_nullable
as int,totalAssets: null == totalAssets ? _self.totalAssets : totalAssets // ignore: cast_nullable_to_non_nullable
as int,totalDebt: null == totalDebt ? _self.totalDebt : totalDebt // ignore: cast_nullable_to_non_nullable
as int,netWorth: null == netWorth ? _self.netWorth : netWorth // ignore: cast_nullable_to_non_nullable
as int,lastMonthNetWorth: null == lastMonthNetWorth ? _self.lastMonthNetWorth : lastMonthNetWorth // ignore: cast_nullable_to_non_nullable
as int,changeAmount: null == changeAmount ? _self.changeAmount : changeAmount // ignore: cast_nullable_to_non_nullable
as int,changePercent: null == changePercent ? _self.changePercent : changePercent // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
