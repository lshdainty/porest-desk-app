// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset_trade.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AssetTrade {

 int get rowId; int get assetRowId; String get tradeType;// 'OPENING' | 'BUY' | 'SELL'
 String? get holdingType;// 'STOCK' | 'GOLD' | 'CRYPTO'
/// 종목 식별자 — 연동은 토스 종목코드, 미연동은 항목명.
 String get holdingKey; bool get linked;/// 소수 허용이라 문자열로 주고받는다(AssetHolding.quantity 와 같은 이유).
 String? get quantity;/// 거래대금 — 수수료 제외.
 int? get amount; int? get fee;/// 실현손익 (매도 전용). 이익 양수 / 손실 음수.
 int? get realizedPl; String? get tradeDate; String? get description;/// 결제 계좌 — 지정하면 증권계좌 예수금 대신 이 계좌에서 오간다.
 int? get settlementAssetRowId;
/// Create a copy of AssetTrade
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetTradeCopyWith<AssetTrade> get copyWith => _$AssetTradeCopyWithImpl<AssetTrade>(this as AssetTrade, _$identity);

  /// Serializes this AssetTrade to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetTrade&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.assetRowId, assetRowId) || other.assetRowId == assetRowId)&&(identical(other.tradeType, tradeType) || other.tradeType == tradeType)&&(identical(other.holdingType, holdingType) || other.holdingType == holdingType)&&(identical(other.holdingKey, holdingKey) || other.holdingKey == holdingKey)&&(identical(other.linked, linked) || other.linked == linked)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.realizedPl, realizedPl) || other.realizedPl == realizedPl)&&(identical(other.tradeDate, tradeDate) || other.tradeDate == tradeDate)&&(identical(other.description, description) || other.description == description)&&(identical(other.settlementAssetRowId, settlementAssetRowId) || other.settlementAssetRowId == settlementAssetRowId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,assetRowId,tradeType,holdingType,holdingKey,linked,quantity,amount,fee,realizedPl,tradeDate,description,settlementAssetRowId);

@override
String toString() {
  return 'AssetTrade(rowId: $rowId, assetRowId: $assetRowId, tradeType: $tradeType, holdingType: $holdingType, holdingKey: $holdingKey, linked: $linked, quantity: $quantity, amount: $amount, fee: $fee, realizedPl: $realizedPl, tradeDate: $tradeDate, description: $description, settlementAssetRowId: $settlementAssetRowId)';
}


}

/// @nodoc
abstract mixin class $AssetTradeCopyWith<$Res>  {
  factory $AssetTradeCopyWith(AssetTrade value, $Res Function(AssetTrade) _then) = _$AssetTradeCopyWithImpl;
@useResult
$Res call({
 int rowId, int assetRowId, String tradeType, String? holdingType, String holdingKey, bool linked, String? quantity, int? amount, int? fee, int? realizedPl, String? tradeDate, String? description, int? settlementAssetRowId
});




}
/// @nodoc
class _$AssetTradeCopyWithImpl<$Res>
    implements $AssetTradeCopyWith<$Res> {
  _$AssetTradeCopyWithImpl(this._self, this._then);

  final AssetTrade _self;
  final $Res Function(AssetTrade) _then;

/// Create a copy of AssetTrade
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = null,Object? assetRowId = null,Object? tradeType = null,Object? holdingType = freezed,Object? holdingKey = null,Object? linked = null,Object? quantity = freezed,Object? amount = freezed,Object? fee = freezed,Object? realizedPl = freezed,Object? tradeDate = freezed,Object? description = freezed,Object? settlementAssetRowId = freezed,}) {
  return _then(_self.copyWith(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,assetRowId: null == assetRowId ? _self.assetRowId : assetRowId // ignore: cast_nullable_to_non_nullable
as int,tradeType: null == tradeType ? _self.tradeType : tradeType // ignore: cast_nullable_to_non_nullable
as String,holdingType: freezed == holdingType ? _self.holdingType : holdingType // ignore: cast_nullable_to_non_nullable
as String?,holdingKey: null == holdingKey ? _self.holdingKey : holdingKey // ignore: cast_nullable_to_non_nullable
as String,linked: null == linked ? _self.linked : linked // ignore: cast_nullable_to_non_nullable
as bool,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int?,fee: freezed == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as int?,realizedPl: freezed == realizedPl ? _self.realizedPl : realizedPl // ignore: cast_nullable_to_non_nullable
as int?,tradeDate: freezed == tradeDate ? _self.tradeDate : tradeDate // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,settlementAssetRowId: freezed == settlementAssetRowId ? _self.settlementAssetRowId : settlementAssetRowId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [AssetTrade].
extension AssetTradePatterns on AssetTrade {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssetTrade value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssetTrade() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssetTrade value)  $default,){
final _that = this;
switch (_that) {
case _AssetTrade():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssetTrade value)?  $default,){
final _that = this;
switch (_that) {
case _AssetTrade() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowId,  int assetRowId,  String tradeType,  String? holdingType,  String holdingKey,  bool linked,  String? quantity,  int? amount,  int? fee,  int? realizedPl,  String? tradeDate,  String? description,  int? settlementAssetRowId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssetTrade() when $default != null:
return $default(_that.rowId,_that.assetRowId,_that.tradeType,_that.holdingType,_that.holdingKey,_that.linked,_that.quantity,_that.amount,_that.fee,_that.realizedPl,_that.tradeDate,_that.description,_that.settlementAssetRowId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowId,  int assetRowId,  String tradeType,  String? holdingType,  String holdingKey,  bool linked,  String? quantity,  int? amount,  int? fee,  int? realizedPl,  String? tradeDate,  String? description,  int? settlementAssetRowId)  $default,) {final _that = this;
switch (_that) {
case _AssetTrade():
return $default(_that.rowId,_that.assetRowId,_that.tradeType,_that.holdingType,_that.holdingKey,_that.linked,_that.quantity,_that.amount,_that.fee,_that.realizedPl,_that.tradeDate,_that.description,_that.settlementAssetRowId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowId,  int assetRowId,  String tradeType,  String? holdingType,  String holdingKey,  bool linked,  String? quantity,  int? amount,  int? fee,  int? realizedPl,  String? tradeDate,  String? description,  int? settlementAssetRowId)?  $default,) {final _that = this;
switch (_that) {
case _AssetTrade() when $default != null:
return $default(_that.rowId,_that.assetRowId,_that.tradeType,_that.holdingType,_that.holdingKey,_that.linked,_that.quantity,_that.amount,_that.fee,_that.realizedPl,_that.tradeDate,_that.description,_that.settlementAssetRowId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssetTrade implements AssetTrade {
  const _AssetTrade({required this.rowId, required this.assetRowId, required this.tradeType, this.holdingType, required this.holdingKey, this.linked = false, this.quantity, this.amount, this.fee, this.realizedPl, this.tradeDate, this.description, this.settlementAssetRowId});
  factory _AssetTrade.fromJson(Map<String, dynamic> json) => _$AssetTradeFromJson(json);

@override final  int rowId;
@override final  int assetRowId;
@override final  String tradeType;
// 'OPENING' | 'BUY' | 'SELL'
@override final  String? holdingType;
// 'STOCK' | 'GOLD' | 'CRYPTO'
/// 종목 식별자 — 연동은 토스 종목코드, 미연동은 항목명.
@override final  String holdingKey;
@override@JsonKey() final  bool linked;
/// 소수 허용이라 문자열로 주고받는다(AssetHolding.quantity 와 같은 이유).
@override final  String? quantity;
/// 거래대금 — 수수료 제외.
@override final  int? amount;
@override final  int? fee;
/// 실현손익 (매도 전용). 이익 양수 / 손실 음수.
@override final  int? realizedPl;
@override final  String? tradeDate;
@override final  String? description;
/// 결제 계좌 — 지정하면 증권계좌 예수금 대신 이 계좌에서 오간다.
@override final  int? settlementAssetRowId;

/// Create a copy of AssetTrade
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssetTradeCopyWith<_AssetTrade> get copyWith => __$AssetTradeCopyWithImpl<_AssetTrade>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssetTradeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssetTrade&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.assetRowId, assetRowId) || other.assetRowId == assetRowId)&&(identical(other.tradeType, tradeType) || other.tradeType == tradeType)&&(identical(other.holdingType, holdingType) || other.holdingType == holdingType)&&(identical(other.holdingKey, holdingKey) || other.holdingKey == holdingKey)&&(identical(other.linked, linked) || other.linked == linked)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.realizedPl, realizedPl) || other.realizedPl == realizedPl)&&(identical(other.tradeDate, tradeDate) || other.tradeDate == tradeDate)&&(identical(other.description, description) || other.description == description)&&(identical(other.settlementAssetRowId, settlementAssetRowId) || other.settlementAssetRowId == settlementAssetRowId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,assetRowId,tradeType,holdingType,holdingKey,linked,quantity,amount,fee,realizedPl,tradeDate,description,settlementAssetRowId);

@override
String toString() {
  return 'AssetTrade(rowId: $rowId, assetRowId: $assetRowId, tradeType: $tradeType, holdingType: $holdingType, holdingKey: $holdingKey, linked: $linked, quantity: $quantity, amount: $amount, fee: $fee, realizedPl: $realizedPl, tradeDate: $tradeDate, description: $description, settlementAssetRowId: $settlementAssetRowId)';
}


}

/// @nodoc
abstract mixin class _$AssetTradeCopyWith<$Res> implements $AssetTradeCopyWith<$Res> {
  factory _$AssetTradeCopyWith(_AssetTrade value, $Res Function(_AssetTrade) _then) = __$AssetTradeCopyWithImpl;
@override @useResult
$Res call({
 int rowId, int assetRowId, String tradeType, String? holdingType, String holdingKey, bool linked, String? quantity, int? amount, int? fee, int? realizedPl, String? tradeDate, String? description, int? settlementAssetRowId
});




}
/// @nodoc
class __$AssetTradeCopyWithImpl<$Res>
    implements _$AssetTradeCopyWith<$Res> {
  __$AssetTradeCopyWithImpl(this._self, this._then);

  final _AssetTrade _self;
  final $Res Function(_AssetTrade) _then;

/// Create a copy of AssetTrade
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = null,Object? assetRowId = null,Object? tradeType = null,Object? holdingType = freezed,Object? holdingKey = null,Object? linked = null,Object? quantity = freezed,Object? amount = freezed,Object? fee = freezed,Object? realizedPl = freezed,Object? tradeDate = freezed,Object? description = freezed,Object? settlementAssetRowId = freezed,}) {
  return _then(_AssetTrade(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,assetRowId: null == assetRowId ? _self.assetRowId : assetRowId // ignore: cast_nullable_to_non_nullable
as int,tradeType: null == tradeType ? _self.tradeType : tradeType // ignore: cast_nullable_to_non_nullable
as String,holdingType: freezed == holdingType ? _self.holdingType : holdingType // ignore: cast_nullable_to_non_nullable
as String?,holdingKey: null == holdingKey ? _self.holdingKey : holdingKey // ignore: cast_nullable_to_non_nullable
as String,linked: null == linked ? _self.linked : linked // ignore: cast_nullable_to_non_nullable
as bool,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int?,fee: freezed == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as int?,realizedPl: freezed == realizedPl ? _self.realizedPl : realizedPl // ignore: cast_nullable_to_non_nullable
as int?,tradeDate: freezed == tradeDate ? _self.tradeDate : tradeDate // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,settlementAssetRowId: freezed == settlementAssetRowId ? _self.settlementAssetRowId : settlementAssetRowId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
