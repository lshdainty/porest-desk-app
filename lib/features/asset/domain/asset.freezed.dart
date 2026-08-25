// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Asset {

 int get rowId; int? get userRowId; String get assetName; String get assetType;// 'CASH' | 'BANK_ACCOUNT' | 'CARD' | 'INVESTMENT' | ...
 int? get balance;/// 예수금·현금 잔액 (투자 계좌의 매수 대기 자금). balance = cashBalance + holdingBalance.
 int? get cashBalance;/// 보유 종목 평가금액. 보유가 없으면 0.
 int? get holdingBalance; String? get currency;/// 원화 환산율 (통화 1단위당 원화). KRW 는 1 — 순자산은 balance × 이 값으로 환산된다.
 double? get exchangeRate; String? get color; String? get institution; String? get memo; int? get sortOrder; String? get isIncludedInTotal;// 'Y' | 'N'
// 신용카드 청구 사이클 (CREDIT_CARD 전용, nullable).
 int? get creditLimit;// 신용 한도
 int? get paymentDay;// 결제일 (1~31)
 int? get paymentAssetRowId;// 결제 출금계좌 자산 rowId
// 연결된 카드 상품 (카드 자산 전용, nullable) — 편집 진입 시 선택 상태 복원용.
 AssetCardCatalog? get cardCatalog;// 토스 연동 (INVESTMENT 전용, nullable). 토스 현재가 × 보유수량으로 평가액 실시간 계산.
// deprecated — holdings(다건)로 대체. 서버 필드 잔존으로 파싱만 유지.
 String? get marketCode;// 종목 마스터 기준 시장코드 — 서버가 확정 못 했으면 없다
 String? get tossSymbol;// 토스 연동 종목코드
 int? get tossQuantity;// 토스 연동 보유수량
// 보유 종목 (INVESTMENT 전용, design tossapi5) — linked(현재가×수량 연동) | manual(평가액 직접).
// 구버전 서버 응답엔 없으므로 기본 빈 리스트로 안전 파싱.
 List<AssetHolding> get holdings;// 이번 달(1일~말일) 사용 합계 — CHECK_CARD 전용, 서버 계산(예정 제외·환불 상계).
// 연결계좌 즉시 차감으로 잔액이 늘 0 이라, 행·상세는 잔액 대신 이 값을 보여준다.
 int? get monthlyUsedAmount;
/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetCopyWith<Asset> get copyWith => _$AssetCopyWithImpl<Asset>(this as Asset, _$identity);

  /// Serializes this Asset to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Asset&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.assetName, assetName) || other.assetName == assetName)&&(identical(other.assetType, assetType) || other.assetType == assetType)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.cashBalance, cashBalance) || other.cashBalance == cashBalance)&&(identical(other.holdingBalance, holdingBalance) || other.holdingBalance == holdingBalance)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.exchangeRate, exchangeRate) || other.exchangeRate == exchangeRate)&&(identical(other.color, color) || other.color == color)&&(identical(other.institution, institution) || other.institution == institution)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isIncludedInTotal, isIncludedInTotal) || other.isIncludedInTotal == isIncludedInTotal)&&(identical(other.creditLimit, creditLimit) || other.creditLimit == creditLimit)&&(identical(other.paymentDay, paymentDay) || other.paymentDay == paymentDay)&&(identical(other.paymentAssetRowId, paymentAssetRowId) || other.paymentAssetRowId == paymentAssetRowId)&&(identical(other.cardCatalog, cardCatalog) || other.cardCatalog == cardCatalog)&&(identical(other.marketCode, marketCode) || other.marketCode == marketCode)&&(identical(other.tossSymbol, tossSymbol) || other.tossSymbol == tossSymbol)&&(identical(other.tossQuantity, tossQuantity) || other.tossQuantity == tossQuantity)&&const DeepCollectionEquality().equals(other.holdings, holdings)&&(identical(other.monthlyUsedAmount, monthlyUsedAmount) || other.monthlyUsedAmount == monthlyUsedAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,rowId,userRowId,assetName,assetType,balance,cashBalance,holdingBalance,currency,exchangeRate,color,institution,memo,sortOrder,isIncludedInTotal,creditLimit,paymentDay,paymentAssetRowId,cardCatalog,marketCode,tossSymbol,tossQuantity,const DeepCollectionEquality().hash(holdings),monthlyUsedAmount]);

@override
String toString() {
  return 'Asset(rowId: $rowId, userRowId: $userRowId, assetName: $assetName, assetType: $assetType, balance: $balance, cashBalance: $cashBalance, holdingBalance: $holdingBalance, currency: $currency, exchangeRate: $exchangeRate, color: $color, institution: $institution, memo: $memo, sortOrder: $sortOrder, isIncludedInTotal: $isIncludedInTotal, creditLimit: $creditLimit, paymentDay: $paymentDay, paymentAssetRowId: $paymentAssetRowId, cardCatalog: $cardCatalog, marketCode: $marketCode, tossSymbol: $tossSymbol, tossQuantity: $tossQuantity, holdings: $holdings, monthlyUsedAmount: $monthlyUsedAmount)';
}


}

/// @nodoc
abstract mixin class $AssetCopyWith<$Res>  {
  factory $AssetCopyWith(Asset value, $Res Function(Asset) _then) = _$AssetCopyWithImpl;
@useResult
$Res call({
 int rowId, int? userRowId, String assetName, String assetType, int? balance, int? cashBalance, int? holdingBalance, String? currency, double? exchangeRate, String? color, String? institution, String? memo, int? sortOrder, String? isIncludedInTotal, int? creditLimit, int? paymentDay, int? paymentAssetRowId, AssetCardCatalog? cardCatalog, String? marketCode, String? tossSymbol, int? tossQuantity, List<AssetHolding> holdings, int? monthlyUsedAmount
});


$AssetCardCatalogCopyWith<$Res>? get cardCatalog;

}
/// @nodoc
class _$AssetCopyWithImpl<$Res>
    implements $AssetCopyWith<$Res> {
  _$AssetCopyWithImpl(this._self, this._then);

  final Asset _self;
  final $Res Function(Asset) _then;

/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = null,Object? userRowId = freezed,Object? assetName = null,Object? assetType = null,Object? balance = freezed,Object? cashBalance = freezed,Object? holdingBalance = freezed,Object? currency = freezed,Object? exchangeRate = freezed,Object? color = freezed,Object? institution = freezed,Object? memo = freezed,Object? sortOrder = freezed,Object? isIncludedInTotal = freezed,Object? creditLimit = freezed,Object? paymentDay = freezed,Object? paymentAssetRowId = freezed,Object? cardCatalog = freezed,Object? marketCode = freezed,Object? tossSymbol = freezed,Object? tossQuantity = freezed,Object? holdings = null,Object? monthlyUsedAmount = freezed,}) {
  return _then(_self.copyWith(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,assetName: null == assetName ? _self.assetName : assetName // ignore: cast_nullable_to_non_nullable
as String,assetType: null == assetType ? _self.assetType : assetType // ignore: cast_nullable_to_non_nullable
as String,balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as int?,cashBalance: freezed == cashBalance ? _self.cashBalance : cashBalance // ignore: cast_nullable_to_non_nullable
as int?,holdingBalance: freezed == holdingBalance ? _self.holdingBalance : holdingBalance // ignore: cast_nullable_to_non_nullable
as int?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,exchangeRate: freezed == exchangeRate ? _self.exchangeRate : exchangeRate // ignore: cast_nullable_to_non_nullable
as double?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,institution: freezed == institution ? _self.institution : institution // ignore: cast_nullable_to_non_nullable
as String?,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,isIncludedInTotal: freezed == isIncludedInTotal ? _self.isIncludedInTotal : isIncludedInTotal // ignore: cast_nullable_to_non_nullable
as String?,creditLimit: freezed == creditLimit ? _self.creditLimit : creditLimit // ignore: cast_nullable_to_non_nullable
as int?,paymentDay: freezed == paymentDay ? _self.paymentDay : paymentDay // ignore: cast_nullable_to_non_nullable
as int?,paymentAssetRowId: freezed == paymentAssetRowId ? _self.paymentAssetRowId : paymentAssetRowId // ignore: cast_nullable_to_non_nullable
as int?,cardCatalog: freezed == cardCatalog ? _self.cardCatalog : cardCatalog // ignore: cast_nullable_to_non_nullable
as AssetCardCatalog?,marketCode: freezed == marketCode ? _self.marketCode : marketCode // ignore: cast_nullable_to_non_nullable
as String?,tossSymbol: freezed == tossSymbol ? _self.tossSymbol : tossSymbol // ignore: cast_nullable_to_non_nullable
as String?,tossQuantity: freezed == tossQuantity ? _self.tossQuantity : tossQuantity // ignore: cast_nullable_to_non_nullable
as int?,holdings: null == holdings ? _self.holdings : holdings // ignore: cast_nullable_to_non_nullable
as List<AssetHolding>,monthlyUsedAmount: freezed == monthlyUsedAmount ? _self.monthlyUsedAmount : monthlyUsedAmount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AssetCardCatalogCopyWith<$Res>? get cardCatalog {
    if (_self.cardCatalog == null) {
    return null;
  }

  return $AssetCardCatalogCopyWith<$Res>(_self.cardCatalog!, (value) {
    return _then(_self.copyWith(cardCatalog: value));
  });
}
}


/// Adds pattern-matching-related methods to [Asset].
extension AssetPatterns on Asset {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Asset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Asset() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Asset value)  $default,){
final _that = this;
switch (_that) {
case _Asset():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Asset value)?  $default,){
final _that = this;
switch (_that) {
case _Asset() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  String assetName,  String assetType,  int? balance,  int? cashBalance,  int? holdingBalance,  String? currency,  double? exchangeRate,  String? color,  String? institution,  String? memo,  int? sortOrder,  String? isIncludedInTotal,  int? creditLimit,  int? paymentDay,  int? paymentAssetRowId,  AssetCardCatalog? cardCatalog,  String? marketCode,  String? tossSymbol,  int? tossQuantity,  List<AssetHolding> holdings,  int? monthlyUsedAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Asset() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.assetName,_that.assetType,_that.balance,_that.cashBalance,_that.holdingBalance,_that.currency,_that.exchangeRate,_that.color,_that.institution,_that.memo,_that.sortOrder,_that.isIncludedInTotal,_that.creditLimit,_that.paymentDay,_that.paymentAssetRowId,_that.cardCatalog,_that.marketCode,_that.tossSymbol,_that.tossQuantity,_that.holdings,_that.monthlyUsedAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  String assetName,  String assetType,  int? balance,  int? cashBalance,  int? holdingBalance,  String? currency,  double? exchangeRate,  String? color,  String? institution,  String? memo,  int? sortOrder,  String? isIncludedInTotal,  int? creditLimit,  int? paymentDay,  int? paymentAssetRowId,  AssetCardCatalog? cardCatalog,  String? marketCode,  String? tossSymbol,  int? tossQuantity,  List<AssetHolding> holdings,  int? monthlyUsedAmount)  $default,) {final _that = this;
switch (_that) {
case _Asset():
return $default(_that.rowId,_that.userRowId,_that.assetName,_that.assetType,_that.balance,_that.cashBalance,_that.holdingBalance,_that.currency,_that.exchangeRate,_that.color,_that.institution,_that.memo,_that.sortOrder,_that.isIncludedInTotal,_that.creditLimit,_that.paymentDay,_that.paymentAssetRowId,_that.cardCatalog,_that.marketCode,_that.tossSymbol,_that.tossQuantity,_that.holdings,_that.monthlyUsedAmount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowId,  int? userRowId,  String assetName,  String assetType,  int? balance,  int? cashBalance,  int? holdingBalance,  String? currency,  double? exchangeRate,  String? color,  String? institution,  String? memo,  int? sortOrder,  String? isIncludedInTotal,  int? creditLimit,  int? paymentDay,  int? paymentAssetRowId,  AssetCardCatalog? cardCatalog,  String? marketCode,  String? tossSymbol,  int? tossQuantity,  List<AssetHolding> holdings,  int? monthlyUsedAmount)?  $default,) {final _that = this;
switch (_that) {
case _Asset() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.assetName,_that.assetType,_that.balance,_that.cashBalance,_that.holdingBalance,_that.currency,_that.exchangeRate,_that.color,_that.institution,_that.memo,_that.sortOrder,_that.isIncludedInTotal,_that.creditLimit,_that.paymentDay,_that.paymentAssetRowId,_that.cardCatalog,_that.marketCode,_that.tossSymbol,_that.tossQuantity,_that.holdings,_that.monthlyUsedAmount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Asset implements Asset {
  const _Asset({required this.rowId, this.userRowId, required this.assetName, required this.assetType, this.balance, this.cashBalance, this.holdingBalance, this.currency, this.exchangeRate, this.color, this.institution, this.memo, this.sortOrder, this.isIncludedInTotal, this.creditLimit, this.paymentDay, this.paymentAssetRowId, this.cardCatalog, this.marketCode, this.tossSymbol, this.tossQuantity, final  List<AssetHolding> holdings = const <AssetHolding>[], this.monthlyUsedAmount}): _holdings = holdings;
  factory _Asset.fromJson(Map<String, dynamic> json) => _$AssetFromJson(json);

@override final  int rowId;
@override final  int? userRowId;
@override final  String assetName;
@override final  String assetType;
// 'CASH' | 'BANK_ACCOUNT' | 'CARD' | 'INVESTMENT' | ...
@override final  int? balance;
/// 예수금·현금 잔액 (투자 계좌의 매수 대기 자금). balance = cashBalance + holdingBalance.
@override final  int? cashBalance;
/// 보유 종목 평가금액. 보유가 없으면 0.
@override final  int? holdingBalance;
@override final  String? currency;
/// 원화 환산율 (통화 1단위당 원화). KRW 는 1 — 순자산은 balance × 이 값으로 환산된다.
@override final  double? exchangeRate;
@override final  String? color;
@override final  String? institution;
@override final  String? memo;
@override final  int? sortOrder;
@override final  String? isIncludedInTotal;
// 'Y' | 'N'
// 신용카드 청구 사이클 (CREDIT_CARD 전용, nullable).
@override final  int? creditLimit;
// 신용 한도
@override final  int? paymentDay;
// 결제일 (1~31)
@override final  int? paymentAssetRowId;
// 결제 출금계좌 자산 rowId
// 연결된 카드 상품 (카드 자산 전용, nullable) — 편집 진입 시 선택 상태 복원용.
@override final  AssetCardCatalog? cardCatalog;
// 토스 연동 (INVESTMENT 전용, nullable). 토스 현재가 × 보유수량으로 평가액 실시간 계산.
// deprecated — holdings(다건)로 대체. 서버 필드 잔존으로 파싱만 유지.
@override final  String? marketCode;
// 종목 마스터 기준 시장코드 — 서버가 확정 못 했으면 없다
@override final  String? tossSymbol;
// 토스 연동 종목코드
@override final  int? tossQuantity;
// 토스 연동 보유수량
// 보유 종목 (INVESTMENT 전용, design tossapi5) — linked(현재가×수량 연동) | manual(평가액 직접).
// 구버전 서버 응답엔 없으므로 기본 빈 리스트로 안전 파싱.
 final  List<AssetHolding> _holdings;
// 토스 연동 보유수량
// 보유 종목 (INVESTMENT 전용, design tossapi5) — linked(현재가×수량 연동) | manual(평가액 직접).
// 구버전 서버 응답엔 없으므로 기본 빈 리스트로 안전 파싱.
@override@JsonKey() List<AssetHolding> get holdings {
  if (_holdings is EqualUnmodifiableListView) return _holdings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_holdings);
}

// 이번 달(1일~말일) 사용 합계 — CHECK_CARD 전용, 서버 계산(예정 제외·환불 상계).
// 연결계좌 즉시 차감으로 잔액이 늘 0 이라, 행·상세는 잔액 대신 이 값을 보여준다.
@override final  int? monthlyUsedAmount;

/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssetCopyWith<_Asset> get copyWith => __$AssetCopyWithImpl<_Asset>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Asset&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.assetName, assetName) || other.assetName == assetName)&&(identical(other.assetType, assetType) || other.assetType == assetType)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.cashBalance, cashBalance) || other.cashBalance == cashBalance)&&(identical(other.holdingBalance, holdingBalance) || other.holdingBalance == holdingBalance)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.exchangeRate, exchangeRate) || other.exchangeRate == exchangeRate)&&(identical(other.color, color) || other.color == color)&&(identical(other.institution, institution) || other.institution == institution)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isIncludedInTotal, isIncludedInTotal) || other.isIncludedInTotal == isIncludedInTotal)&&(identical(other.creditLimit, creditLimit) || other.creditLimit == creditLimit)&&(identical(other.paymentDay, paymentDay) || other.paymentDay == paymentDay)&&(identical(other.paymentAssetRowId, paymentAssetRowId) || other.paymentAssetRowId == paymentAssetRowId)&&(identical(other.cardCatalog, cardCatalog) || other.cardCatalog == cardCatalog)&&(identical(other.marketCode, marketCode) || other.marketCode == marketCode)&&(identical(other.tossSymbol, tossSymbol) || other.tossSymbol == tossSymbol)&&(identical(other.tossQuantity, tossQuantity) || other.tossQuantity == tossQuantity)&&const DeepCollectionEquality().equals(other._holdings, _holdings)&&(identical(other.monthlyUsedAmount, monthlyUsedAmount) || other.monthlyUsedAmount == monthlyUsedAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,rowId,userRowId,assetName,assetType,balance,cashBalance,holdingBalance,currency,exchangeRate,color,institution,memo,sortOrder,isIncludedInTotal,creditLimit,paymentDay,paymentAssetRowId,cardCatalog,marketCode,tossSymbol,tossQuantity,const DeepCollectionEquality().hash(_holdings),monthlyUsedAmount]);

@override
String toString() {
  return 'Asset(rowId: $rowId, userRowId: $userRowId, assetName: $assetName, assetType: $assetType, balance: $balance, cashBalance: $cashBalance, holdingBalance: $holdingBalance, currency: $currency, exchangeRate: $exchangeRate, color: $color, institution: $institution, memo: $memo, sortOrder: $sortOrder, isIncludedInTotal: $isIncludedInTotal, creditLimit: $creditLimit, paymentDay: $paymentDay, paymentAssetRowId: $paymentAssetRowId, cardCatalog: $cardCatalog, marketCode: $marketCode, tossSymbol: $tossSymbol, tossQuantity: $tossQuantity, holdings: $holdings, monthlyUsedAmount: $monthlyUsedAmount)';
}


}

/// @nodoc
abstract mixin class _$AssetCopyWith<$Res> implements $AssetCopyWith<$Res> {
  factory _$AssetCopyWith(_Asset value, $Res Function(_Asset) _then) = __$AssetCopyWithImpl;
@override @useResult
$Res call({
 int rowId, int? userRowId, String assetName, String assetType, int? balance, int? cashBalance, int? holdingBalance, String? currency, double? exchangeRate, String? color, String? institution, String? memo, int? sortOrder, String? isIncludedInTotal, int? creditLimit, int? paymentDay, int? paymentAssetRowId, AssetCardCatalog? cardCatalog, String? marketCode, String? tossSymbol, int? tossQuantity, List<AssetHolding> holdings, int? monthlyUsedAmount
});


@override $AssetCardCatalogCopyWith<$Res>? get cardCatalog;

}
/// @nodoc
class __$AssetCopyWithImpl<$Res>
    implements _$AssetCopyWith<$Res> {
  __$AssetCopyWithImpl(this._self, this._then);

  final _Asset _self;
  final $Res Function(_Asset) _then;

/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = null,Object? userRowId = freezed,Object? assetName = null,Object? assetType = null,Object? balance = freezed,Object? cashBalance = freezed,Object? holdingBalance = freezed,Object? currency = freezed,Object? exchangeRate = freezed,Object? color = freezed,Object? institution = freezed,Object? memo = freezed,Object? sortOrder = freezed,Object? isIncludedInTotal = freezed,Object? creditLimit = freezed,Object? paymentDay = freezed,Object? paymentAssetRowId = freezed,Object? cardCatalog = freezed,Object? marketCode = freezed,Object? tossSymbol = freezed,Object? tossQuantity = freezed,Object? holdings = null,Object? monthlyUsedAmount = freezed,}) {
  return _then(_Asset(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,assetName: null == assetName ? _self.assetName : assetName // ignore: cast_nullable_to_non_nullable
as String,assetType: null == assetType ? _self.assetType : assetType // ignore: cast_nullable_to_non_nullable
as String,balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as int?,cashBalance: freezed == cashBalance ? _self.cashBalance : cashBalance // ignore: cast_nullable_to_non_nullable
as int?,holdingBalance: freezed == holdingBalance ? _self.holdingBalance : holdingBalance // ignore: cast_nullable_to_non_nullable
as int?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,exchangeRate: freezed == exchangeRate ? _self.exchangeRate : exchangeRate // ignore: cast_nullable_to_non_nullable
as double?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,institution: freezed == institution ? _self.institution : institution // ignore: cast_nullable_to_non_nullable
as String?,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,isIncludedInTotal: freezed == isIncludedInTotal ? _self.isIncludedInTotal : isIncludedInTotal // ignore: cast_nullable_to_non_nullable
as String?,creditLimit: freezed == creditLimit ? _self.creditLimit : creditLimit // ignore: cast_nullable_to_non_nullable
as int?,paymentDay: freezed == paymentDay ? _self.paymentDay : paymentDay // ignore: cast_nullable_to_non_nullable
as int?,paymentAssetRowId: freezed == paymentAssetRowId ? _self.paymentAssetRowId : paymentAssetRowId // ignore: cast_nullable_to_non_nullable
as int?,cardCatalog: freezed == cardCatalog ? _self.cardCatalog : cardCatalog // ignore: cast_nullable_to_non_nullable
as AssetCardCatalog?,marketCode: freezed == marketCode ? _self.marketCode : marketCode // ignore: cast_nullable_to_non_nullable
as String?,tossSymbol: freezed == tossSymbol ? _self.tossSymbol : tossSymbol // ignore: cast_nullable_to_non_nullable
as String?,tossQuantity: freezed == tossQuantity ? _self.tossQuantity : tossQuantity // ignore: cast_nullable_to_non_nullable
as int?,holdings: null == holdings ? _self._holdings : holdings // ignore: cast_nullable_to_non_nullable
as List<AssetHolding>,monthlyUsedAmount: freezed == monthlyUsedAmount ? _self.monthlyUsedAmount : monthlyUsedAmount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AssetCardCatalogCopyWith<$Res>? get cardCatalog {
    if (_self.cardCatalog == null) {
    return null;
  }

  return $AssetCardCatalogCopyWith<$Res>(_self.cardCatalog!, (value) {
    return _then(_self.copyWith(cardCatalog: value));
  });
}
}


/// @nodoc
mixin _$AssetCardCatalog {

 int get rowId; String get cardName; String? get imgUrl; String? get companyName; String? get companyLogoUrl;
/// Create a copy of AssetCardCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetCardCatalogCopyWith<AssetCardCatalog> get copyWith => _$AssetCardCatalogCopyWithImpl<AssetCardCatalog>(this as AssetCardCatalog, _$identity);

  /// Serializes this AssetCardCatalog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetCardCatalog&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.cardName, cardName) || other.cardName == cardName)&&(identical(other.imgUrl, imgUrl) || other.imgUrl == imgUrl)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.companyLogoUrl, companyLogoUrl) || other.companyLogoUrl == companyLogoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,cardName,imgUrl,companyName,companyLogoUrl);

@override
String toString() {
  return 'AssetCardCatalog(rowId: $rowId, cardName: $cardName, imgUrl: $imgUrl, companyName: $companyName, companyLogoUrl: $companyLogoUrl)';
}


}

/// @nodoc
abstract mixin class $AssetCardCatalogCopyWith<$Res>  {
  factory $AssetCardCatalogCopyWith(AssetCardCatalog value, $Res Function(AssetCardCatalog) _then) = _$AssetCardCatalogCopyWithImpl;
@useResult
$Res call({
 int rowId, String cardName, String? imgUrl, String? companyName, String? companyLogoUrl
});




}
/// @nodoc
class _$AssetCardCatalogCopyWithImpl<$Res>
    implements $AssetCardCatalogCopyWith<$Res> {
  _$AssetCardCatalogCopyWithImpl(this._self, this._then);

  final AssetCardCatalog _self;
  final $Res Function(AssetCardCatalog) _then;

/// Create a copy of AssetCardCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = null,Object? cardName = null,Object? imgUrl = freezed,Object? companyName = freezed,Object? companyLogoUrl = freezed,}) {
  return _then(_self.copyWith(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,cardName: null == cardName ? _self.cardName : cardName // ignore: cast_nullable_to_non_nullable
as String,imgUrl: freezed == imgUrl ? _self.imgUrl : imgUrl // ignore: cast_nullable_to_non_nullable
as String?,companyName: freezed == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String?,companyLogoUrl: freezed == companyLogoUrl ? _self.companyLogoUrl : companyLogoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AssetCardCatalog].
extension AssetCardCatalogPatterns on AssetCardCatalog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssetCardCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssetCardCatalog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssetCardCatalog value)  $default,){
final _that = this;
switch (_that) {
case _AssetCardCatalog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssetCardCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _AssetCardCatalog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowId,  String cardName,  String? imgUrl,  String? companyName,  String? companyLogoUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssetCardCatalog() when $default != null:
return $default(_that.rowId,_that.cardName,_that.imgUrl,_that.companyName,_that.companyLogoUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowId,  String cardName,  String? imgUrl,  String? companyName,  String? companyLogoUrl)  $default,) {final _that = this;
switch (_that) {
case _AssetCardCatalog():
return $default(_that.rowId,_that.cardName,_that.imgUrl,_that.companyName,_that.companyLogoUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowId,  String cardName,  String? imgUrl,  String? companyName,  String? companyLogoUrl)?  $default,) {final _that = this;
switch (_that) {
case _AssetCardCatalog() when $default != null:
return $default(_that.rowId,_that.cardName,_that.imgUrl,_that.companyName,_that.companyLogoUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssetCardCatalog implements AssetCardCatalog {
  const _AssetCardCatalog({required this.rowId, required this.cardName, this.imgUrl, this.companyName, this.companyLogoUrl});
  factory _AssetCardCatalog.fromJson(Map<String, dynamic> json) => _$AssetCardCatalogFromJson(json);

@override final  int rowId;
@override final  String cardName;
@override final  String? imgUrl;
@override final  String? companyName;
@override final  String? companyLogoUrl;

/// Create a copy of AssetCardCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssetCardCatalogCopyWith<_AssetCardCatalog> get copyWith => __$AssetCardCatalogCopyWithImpl<_AssetCardCatalog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssetCardCatalogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssetCardCatalog&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.cardName, cardName) || other.cardName == cardName)&&(identical(other.imgUrl, imgUrl) || other.imgUrl == imgUrl)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.companyLogoUrl, companyLogoUrl) || other.companyLogoUrl == companyLogoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,cardName,imgUrl,companyName,companyLogoUrl);

@override
String toString() {
  return 'AssetCardCatalog(rowId: $rowId, cardName: $cardName, imgUrl: $imgUrl, companyName: $companyName, companyLogoUrl: $companyLogoUrl)';
}


}

/// @nodoc
abstract mixin class _$AssetCardCatalogCopyWith<$Res> implements $AssetCardCatalogCopyWith<$Res> {
  factory _$AssetCardCatalogCopyWith(_AssetCardCatalog value, $Res Function(_AssetCardCatalog) _then) = __$AssetCardCatalogCopyWithImpl;
@override @useResult
$Res call({
 int rowId, String cardName, String? imgUrl, String? companyName, String? companyLogoUrl
});




}
/// @nodoc
class __$AssetCardCatalogCopyWithImpl<$Res>
    implements _$AssetCardCatalogCopyWith<$Res> {
  __$AssetCardCatalogCopyWithImpl(this._self, this._then);

  final _AssetCardCatalog _self;
  final $Res Function(_AssetCardCatalog) _then;

/// Create a copy of AssetCardCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = null,Object? cardName = null,Object? imgUrl = freezed,Object? companyName = freezed,Object? companyLogoUrl = freezed,}) {
  return _then(_AssetCardCatalog(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,cardName: null == cardName ? _self.cardName : cardName // ignore: cast_nullable_to_non_nullable
as String,imgUrl: freezed == imgUrl ? _self.imgUrl : imgUrl // ignore: cast_nullable_to_non_nullable
as String?,companyName: freezed == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String?,companyLogoUrl: freezed == companyLogoUrl ? _self.companyLogoUrl : companyLogoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AssetHolding {

 int? get rowId;// 구버전 응답엔 없음 — 없거나 모르는 값이면 주식으로 본다(하위호환).
@JsonKey(unknownEnumValue: AssetHoldingType.stock) AssetHoldingType get holdingType; bool get linked;/// 종목 마스터 기준 시장코드(NAS·KOSPI …) — 선택.
///
/// 같은 티커가 여러 시장에 걸린다(SPY·IVV·JEPI·SOXL). 종목 검색 응답이 이미 들고
/// 있으니 저장할 때 그대로 돌려보내면 서버가 종목을 확정한다. 안 보내면 서버가
/// 심볼로 해석하고, 여러 시장에 걸리면 비워 둔다.
 String? get marketCode; String? get tossSymbol;// 코인 0.05·금 3.75g 등 소수 허용. 미연동도 기록 가능(선택).
// 서버 계약은 BigDecimal(decimal(28,8)) — double 로 담으면 십진 소수가 깎이므로
// 클라이언트는 문자열로 들고 다닌다. 전송도 문자열 그대로(Jackson 이 BigDecimal 로 받는다).
@JsonKey(fromJson: decimalStringFromJson) String? get quantity; String? get holdingName; int? get holdingValue;/// 총 매수원가 (원화, 수수료 포함). 평가액과의 차이가 평가손익이다.
 int? get totalCost;/// 평단가 — 총원가 / 수량. 서버 파생값이라 읽기 전용, 정밀도 때문에 문자열.
/// 서버 계약이 BigDecimal 이라 JSON 숫자로 온다 — 컨버터 없이 캐스트하면 터진다.
@JsonKey(fromJson: decimalStringFromJson) String? get avgPrice; int? get sortOrder;
/// Create a copy of AssetHolding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetHoldingCopyWith<AssetHolding> get copyWith => _$AssetHoldingCopyWithImpl<AssetHolding>(this as AssetHolding, _$identity);

  /// Serializes this AssetHolding to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetHolding&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.holdingType, holdingType) || other.holdingType == holdingType)&&(identical(other.linked, linked) || other.linked == linked)&&(identical(other.marketCode, marketCode) || other.marketCode == marketCode)&&(identical(other.tossSymbol, tossSymbol) || other.tossSymbol == tossSymbol)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.holdingName, holdingName) || other.holdingName == holdingName)&&(identical(other.holdingValue, holdingValue) || other.holdingValue == holdingValue)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.avgPrice, avgPrice) || other.avgPrice == avgPrice)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,holdingType,linked,marketCode,tossSymbol,quantity,holdingName,holdingValue,totalCost,avgPrice,sortOrder);

@override
String toString() {
  return 'AssetHolding(rowId: $rowId, holdingType: $holdingType, linked: $linked, marketCode: $marketCode, tossSymbol: $tossSymbol, quantity: $quantity, holdingName: $holdingName, holdingValue: $holdingValue, totalCost: $totalCost, avgPrice: $avgPrice, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $AssetHoldingCopyWith<$Res>  {
  factory $AssetHoldingCopyWith(AssetHolding value, $Res Function(AssetHolding) _then) = _$AssetHoldingCopyWithImpl;
@useResult
$Res call({
 int? rowId,@JsonKey(unknownEnumValue: AssetHoldingType.stock) AssetHoldingType holdingType, bool linked, String? marketCode, String? tossSymbol,@JsonKey(fromJson: decimalStringFromJson) String? quantity, String? holdingName, int? holdingValue, int? totalCost,@JsonKey(fromJson: decimalStringFromJson) String? avgPrice, int? sortOrder
});




}
/// @nodoc
class _$AssetHoldingCopyWithImpl<$Res>
    implements $AssetHoldingCopyWith<$Res> {
  _$AssetHoldingCopyWithImpl(this._self, this._then);

  final AssetHolding _self;
  final $Res Function(AssetHolding) _then;

/// Create a copy of AssetHolding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = freezed,Object? holdingType = null,Object? linked = null,Object? marketCode = freezed,Object? tossSymbol = freezed,Object? quantity = freezed,Object? holdingName = freezed,Object? holdingValue = freezed,Object? totalCost = freezed,Object? avgPrice = freezed,Object? sortOrder = freezed,}) {
  return _then(_self.copyWith(
rowId: freezed == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int?,holdingType: null == holdingType ? _self.holdingType : holdingType // ignore: cast_nullable_to_non_nullable
as AssetHoldingType,linked: null == linked ? _self.linked : linked // ignore: cast_nullable_to_non_nullable
as bool,marketCode: freezed == marketCode ? _self.marketCode : marketCode // ignore: cast_nullable_to_non_nullable
as String?,tossSymbol: freezed == tossSymbol ? _self.tossSymbol : tossSymbol // ignore: cast_nullable_to_non_nullable
as String?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String?,holdingName: freezed == holdingName ? _self.holdingName : holdingName // ignore: cast_nullable_to_non_nullable
as String?,holdingValue: freezed == holdingValue ? _self.holdingValue : holdingValue // ignore: cast_nullable_to_non_nullable
as int?,totalCost: freezed == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as int?,avgPrice: freezed == avgPrice ? _self.avgPrice : avgPrice // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [AssetHolding].
extension AssetHoldingPatterns on AssetHolding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssetHolding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssetHolding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssetHolding value)  $default,){
final _that = this;
switch (_that) {
case _AssetHolding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssetHolding value)?  $default,){
final _that = this;
switch (_that) {
case _AssetHolding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? rowId, @JsonKey(unknownEnumValue: AssetHoldingType.stock)  AssetHoldingType holdingType,  bool linked,  String? marketCode,  String? tossSymbol, @JsonKey(fromJson: decimalStringFromJson)  String? quantity,  String? holdingName,  int? holdingValue,  int? totalCost, @JsonKey(fromJson: decimalStringFromJson)  String? avgPrice,  int? sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssetHolding() when $default != null:
return $default(_that.rowId,_that.holdingType,_that.linked,_that.marketCode,_that.tossSymbol,_that.quantity,_that.holdingName,_that.holdingValue,_that.totalCost,_that.avgPrice,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? rowId, @JsonKey(unknownEnumValue: AssetHoldingType.stock)  AssetHoldingType holdingType,  bool linked,  String? marketCode,  String? tossSymbol, @JsonKey(fromJson: decimalStringFromJson)  String? quantity,  String? holdingName,  int? holdingValue,  int? totalCost, @JsonKey(fromJson: decimalStringFromJson)  String? avgPrice,  int? sortOrder)  $default,) {final _that = this;
switch (_that) {
case _AssetHolding():
return $default(_that.rowId,_that.holdingType,_that.linked,_that.marketCode,_that.tossSymbol,_that.quantity,_that.holdingName,_that.holdingValue,_that.totalCost,_that.avgPrice,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? rowId, @JsonKey(unknownEnumValue: AssetHoldingType.stock)  AssetHoldingType holdingType,  bool linked,  String? marketCode,  String? tossSymbol, @JsonKey(fromJson: decimalStringFromJson)  String? quantity,  String? holdingName,  int? holdingValue,  int? totalCost, @JsonKey(fromJson: decimalStringFromJson)  String? avgPrice,  int? sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _AssetHolding() when $default != null:
return $default(_that.rowId,_that.holdingType,_that.linked,_that.marketCode,_that.tossSymbol,_that.quantity,_that.holdingName,_that.holdingValue,_that.totalCost,_that.avgPrice,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssetHolding implements AssetHolding {
  const _AssetHolding({this.rowId, @JsonKey(unknownEnumValue: AssetHoldingType.stock) this.holdingType = AssetHoldingType.stock, this.linked = false, this.marketCode, this.tossSymbol, @JsonKey(fromJson: decimalStringFromJson) this.quantity, this.holdingName, this.holdingValue, this.totalCost, @JsonKey(fromJson: decimalStringFromJson) this.avgPrice, this.sortOrder});
  factory _AssetHolding.fromJson(Map<String, dynamic> json) => _$AssetHoldingFromJson(json);

@override final  int? rowId;
// 구버전 응답엔 없음 — 없거나 모르는 값이면 주식으로 본다(하위호환).
@override@JsonKey(unknownEnumValue: AssetHoldingType.stock) final  AssetHoldingType holdingType;
@override@JsonKey() final  bool linked;
/// 종목 마스터 기준 시장코드(NAS·KOSPI …) — 선택.
///
/// 같은 티커가 여러 시장에 걸린다(SPY·IVV·JEPI·SOXL). 종목 검색 응답이 이미 들고
/// 있으니 저장할 때 그대로 돌려보내면 서버가 종목을 확정한다. 안 보내면 서버가
/// 심볼로 해석하고, 여러 시장에 걸리면 비워 둔다.
@override final  String? marketCode;
@override final  String? tossSymbol;
// 코인 0.05·금 3.75g 등 소수 허용. 미연동도 기록 가능(선택).
// 서버 계약은 BigDecimal(decimal(28,8)) — double 로 담으면 십진 소수가 깎이므로
// 클라이언트는 문자열로 들고 다닌다. 전송도 문자열 그대로(Jackson 이 BigDecimal 로 받는다).
@override@JsonKey(fromJson: decimalStringFromJson) final  String? quantity;
@override final  String? holdingName;
@override final  int? holdingValue;
/// 총 매수원가 (원화, 수수료 포함). 평가액과의 차이가 평가손익이다.
@override final  int? totalCost;
/// 평단가 — 총원가 / 수량. 서버 파생값이라 읽기 전용, 정밀도 때문에 문자열.
/// 서버 계약이 BigDecimal 이라 JSON 숫자로 온다 — 컨버터 없이 캐스트하면 터진다.
@override@JsonKey(fromJson: decimalStringFromJson) final  String? avgPrice;
@override final  int? sortOrder;

/// Create a copy of AssetHolding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssetHoldingCopyWith<_AssetHolding> get copyWith => __$AssetHoldingCopyWithImpl<_AssetHolding>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssetHoldingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssetHolding&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.holdingType, holdingType) || other.holdingType == holdingType)&&(identical(other.linked, linked) || other.linked == linked)&&(identical(other.marketCode, marketCode) || other.marketCode == marketCode)&&(identical(other.tossSymbol, tossSymbol) || other.tossSymbol == tossSymbol)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.holdingName, holdingName) || other.holdingName == holdingName)&&(identical(other.holdingValue, holdingValue) || other.holdingValue == holdingValue)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.avgPrice, avgPrice) || other.avgPrice == avgPrice)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,holdingType,linked,marketCode,tossSymbol,quantity,holdingName,holdingValue,totalCost,avgPrice,sortOrder);

@override
String toString() {
  return 'AssetHolding(rowId: $rowId, holdingType: $holdingType, linked: $linked, marketCode: $marketCode, tossSymbol: $tossSymbol, quantity: $quantity, holdingName: $holdingName, holdingValue: $holdingValue, totalCost: $totalCost, avgPrice: $avgPrice, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$AssetHoldingCopyWith<$Res> implements $AssetHoldingCopyWith<$Res> {
  factory _$AssetHoldingCopyWith(_AssetHolding value, $Res Function(_AssetHolding) _then) = __$AssetHoldingCopyWithImpl;
@override @useResult
$Res call({
 int? rowId,@JsonKey(unknownEnumValue: AssetHoldingType.stock) AssetHoldingType holdingType, bool linked, String? marketCode, String? tossSymbol,@JsonKey(fromJson: decimalStringFromJson) String? quantity, String? holdingName, int? holdingValue, int? totalCost,@JsonKey(fromJson: decimalStringFromJson) String? avgPrice, int? sortOrder
});




}
/// @nodoc
class __$AssetHoldingCopyWithImpl<$Res>
    implements _$AssetHoldingCopyWith<$Res> {
  __$AssetHoldingCopyWithImpl(this._self, this._then);

  final _AssetHolding _self;
  final $Res Function(_AssetHolding) _then;

/// Create a copy of AssetHolding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = freezed,Object? holdingType = null,Object? linked = null,Object? marketCode = freezed,Object? tossSymbol = freezed,Object? quantity = freezed,Object? holdingName = freezed,Object? holdingValue = freezed,Object? totalCost = freezed,Object? avgPrice = freezed,Object? sortOrder = freezed,}) {
  return _then(_AssetHolding(
rowId: freezed == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int?,holdingType: null == holdingType ? _self.holdingType : holdingType // ignore: cast_nullable_to_non_nullable
as AssetHoldingType,linked: null == linked ? _self.linked : linked // ignore: cast_nullable_to_non_nullable
as bool,marketCode: freezed == marketCode ? _self.marketCode : marketCode // ignore: cast_nullable_to_non_nullable
as String?,tossSymbol: freezed == tossSymbol ? _self.tossSymbol : tossSymbol // ignore: cast_nullable_to_non_nullable
as String?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String?,holdingName: freezed == holdingName ? _self.holdingName : holdingName // ignore: cast_nullable_to_non_nullable
as String?,holdingValue: freezed == holdingValue ? _self.holdingValue : holdingValue // ignore: cast_nullable_to_non_nullable
as int?,totalCost: freezed == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as int?,avgPrice: freezed == avgPrice ? _self.avgPrice : avgPrice // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
