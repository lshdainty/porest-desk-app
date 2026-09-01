// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'card_billing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BillingItem {

 int get rowId; int get cardAssetRowId; int? get paymentAssetRowId; int get billingAmount; String get periodStart;// 'yyyy-MM-dd'
 String get periodEnd;// 'yyyy-MM-dd'
 String get paymentDate;// 'yyyy-MM-dd'
 String get status;// 'PENDING' | 'COMPLETED' | 'FAILED' | 'SKIPPED'
 int? get transferRowId; String? get failureReason;
/// Create a copy of BillingItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillingItemCopyWith<BillingItem> get copyWith => _$BillingItemCopyWithImpl<BillingItem>(this as BillingItem, _$identity);

  /// Serializes this BillingItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillingItem&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.cardAssetRowId, cardAssetRowId) || other.cardAssetRowId == cardAssetRowId)&&(identical(other.paymentAssetRowId, paymentAssetRowId) || other.paymentAssetRowId == paymentAssetRowId)&&(identical(other.billingAmount, billingAmount) || other.billingAmount == billingAmount)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&(identical(other.paymentDate, paymentDate) || other.paymentDate == paymentDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.transferRowId, transferRowId) || other.transferRowId == transferRowId)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,cardAssetRowId,paymentAssetRowId,billingAmount,periodStart,periodEnd,paymentDate,status,transferRowId,failureReason);

@override
String toString() {
  return 'BillingItem(rowId: $rowId, cardAssetRowId: $cardAssetRowId, paymentAssetRowId: $paymentAssetRowId, billingAmount: $billingAmount, periodStart: $periodStart, periodEnd: $periodEnd, paymentDate: $paymentDate, status: $status, transferRowId: $transferRowId, failureReason: $failureReason)';
}


}

/// @nodoc
abstract mixin class $BillingItemCopyWith<$Res>  {
  factory $BillingItemCopyWith(BillingItem value, $Res Function(BillingItem) _then) = _$BillingItemCopyWithImpl;
@useResult
$Res call({
 int rowId, int cardAssetRowId, int? paymentAssetRowId, int billingAmount, String periodStart, String periodEnd, String paymentDate, String status, int? transferRowId, String? failureReason
});




}
/// @nodoc
class _$BillingItemCopyWithImpl<$Res>
    implements $BillingItemCopyWith<$Res> {
  _$BillingItemCopyWithImpl(this._self, this._then);

  final BillingItem _self;
  final $Res Function(BillingItem) _then;

/// Create a copy of BillingItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = null,Object? cardAssetRowId = null,Object? paymentAssetRowId = freezed,Object? billingAmount = null,Object? periodStart = null,Object? periodEnd = null,Object? paymentDate = null,Object? status = null,Object? transferRowId = freezed,Object? failureReason = freezed,}) {
  return _then(_self.copyWith(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,cardAssetRowId: null == cardAssetRowId ? _self.cardAssetRowId : cardAssetRowId // ignore: cast_nullable_to_non_nullable
as int,paymentAssetRowId: freezed == paymentAssetRowId ? _self.paymentAssetRowId : paymentAssetRowId // ignore: cast_nullable_to_non_nullable
as int?,billingAmount: null == billingAmount ? _self.billingAmount : billingAmount // ignore: cast_nullable_to_non_nullable
as int,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as String,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as String,paymentDate: null == paymentDate ? _self.paymentDate : paymentDate // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,transferRowId: freezed == transferRowId ? _self.transferRowId : transferRowId // ignore: cast_nullable_to_non_nullable
as int?,failureReason: freezed == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BillingItem].
extension BillingItemPatterns on BillingItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BillingItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BillingItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BillingItem value)  $default,){
final _that = this;
switch (_that) {
case _BillingItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BillingItem value)?  $default,){
final _that = this;
switch (_that) {
case _BillingItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowId,  int cardAssetRowId,  int? paymentAssetRowId,  int billingAmount,  String periodStart,  String periodEnd,  String paymentDate,  String status,  int? transferRowId,  String? failureReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BillingItem() when $default != null:
return $default(_that.rowId,_that.cardAssetRowId,_that.paymentAssetRowId,_that.billingAmount,_that.periodStart,_that.periodEnd,_that.paymentDate,_that.status,_that.transferRowId,_that.failureReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowId,  int cardAssetRowId,  int? paymentAssetRowId,  int billingAmount,  String periodStart,  String periodEnd,  String paymentDate,  String status,  int? transferRowId,  String? failureReason)  $default,) {final _that = this;
switch (_that) {
case _BillingItem():
return $default(_that.rowId,_that.cardAssetRowId,_that.paymentAssetRowId,_that.billingAmount,_that.periodStart,_that.periodEnd,_that.paymentDate,_that.status,_that.transferRowId,_that.failureReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowId,  int cardAssetRowId,  int? paymentAssetRowId,  int billingAmount,  String periodStart,  String periodEnd,  String paymentDate,  String status,  int? transferRowId,  String? failureReason)?  $default,) {final _that = this;
switch (_that) {
case _BillingItem() when $default != null:
return $default(_that.rowId,_that.cardAssetRowId,_that.paymentAssetRowId,_that.billingAmount,_that.periodStart,_that.periodEnd,_that.paymentDate,_that.status,_that.transferRowId,_that.failureReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BillingItem implements BillingItem {
  const _BillingItem({required this.rowId, required this.cardAssetRowId, this.paymentAssetRowId, required this.billingAmount, required this.periodStart, required this.periodEnd, required this.paymentDate, required this.status, this.transferRowId, this.failureReason});
  factory _BillingItem.fromJson(Map<String, dynamic> json) => _$BillingItemFromJson(json);

@override final  int rowId;
@override final  int cardAssetRowId;
@override final  int? paymentAssetRowId;
@override final  int billingAmount;
@override final  String periodStart;
// 'yyyy-MM-dd'
@override final  String periodEnd;
// 'yyyy-MM-dd'
@override final  String paymentDate;
// 'yyyy-MM-dd'
@override final  String status;
// 'PENDING' | 'COMPLETED' | 'FAILED' | 'SKIPPED'
@override final  int? transferRowId;
@override final  String? failureReason;

/// Create a copy of BillingItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BillingItemCopyWith<_BillingItem> get copyWith => __$BillingItemCopyWithImpl<_BillingItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BillingItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BillingItem&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.cardAssetRowId, cardAssetRowId) || other.cardAssetRowId == cardAssetRowId)&&(identical(other.paymentAssetRowId, paymentAssetRowId) || other.paymentAssetRowId == paymentAssetRowId)&&(identical(other.billingAmount, billingAmount) || other.billingAmount == billingAmount)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&(identical(other.paymentDate, paymentDate) || other.paymentDate == paymentDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.transferRowId, transferRowId) || other.transferRowId == transferRowId)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,cardAssetRowId,paymentAssetRowId,billingAmount,periodStart,periodEnd,paymentDate,status,transferRowId,failureReason);

@override
String toString() {
  return 'BillingItem(rowId: $rowId, cardAssetRowId: $cardAssetRowId, paymentAssetRowId: $paymentAssetRowId, billingAmount: $billingAmount, periodStart: $periodStart, periodEnd: $periodEnd, paymentDate: $paymentDate, status: $status, transferRowId: $transferRowId, failureReason: $failureReason)';
}


}

/// @nodoc
abstract mixin class _$BillingItemCopyWith<$Res> implements $BillingItemCopyWith<$Res> {
  factory _$BillingItemCopyWith(_BillingItem value, $Res Function(_BillingItem) _then) = __$BillingItemCopyWithImpl;
@override @useResult
$Res call({
 int rowId, int cardAssetRowId, int? paymentAssetRowId, int billingAmount, String periodStart, String periodEnd, String paymentDate, String status, int? transferRowId, String? failureReason
});




}
/// @nodoc
class __$BillingItemCopyWithImpl<$Res>
    implements _$BillingItemCopyWith<$Res> {
  __$BillingItemCopyWithImpl(this._self, this._then);

  final _BillingItem _self;
  final $Res Function(_BillingItem) _then;

/// Create a copy of BillingItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = null,Object? cardAssetRowId = null,Object? paymentAssetRowId = freezed,Object? billingAmount = null,Object? periodStart = null,Object? periodEnd = null,Object? paymentDate = null,Object? status = null,Object? transferRowId = freezed,Object? failureReason = freezed,}) {
  return _then(_BillingItem(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,cardAssetRowId: null == cardAssetRowId ? _self.cardAssetRowId : cardAssetRowId // ignore: cast_nullable_to_non_nullable
as int,paymentAssetRowId: freezed == paymentAssetRowId ? _self.paymentAssetRowId : paymentAssetRowId // ignore: cast_nullable_to_non_nullable
as int?,billingAmount: null == billingAmount ? _self.billingAmount : billingAmount // ignore: cast_nullable_to_non_nullable
as int,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as String,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as String,paymentDate: null == paymentDate ? _self.paymentDate : paymentDate // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,transferRowId: freezed == transferRowId ? _self.transferRowId : transferRowId // ignore: cast_nullable_to_non_nullable
as int?,failureReason: freezed == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$InstallmentDue {

 int get expenseRowId; String? get merchant; String? get description;/// 할부 원금(거래 전액).
 int get principalAmount;/// 총 회차 수(N).
 int get installmentMonths;/// 이번이 몇 회차인지(1-base).
 int get sequence;/// 이번 회차에 빠지는 금액. 나머지는 1회차에 몰린다(카드사 관행).
 int get amount;
/// Create a copy of InstallmentDue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstallmentDueCopyWith<InstallmentDue> get copyWith => _$InstallmentDueCopyWithImpl<InstallmentDue>(this as InstallmentDue, _$identity);

  /// Serializes this InstallmentDue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstallmentDue&&(identical(other.expenseRowId, expenseRowId) || other.expenseRowId == expenseRowId)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.description, description) || other.description == description)&&(identical(other.principalAmount, principalAmount) || other.principalAmount == principalAmount)&&(identical(other.installmentMonths, installmentMonths) || other.installmentMonths == installmentMonths)&&(identical(other.sequence, sequence) || other.sequence == sequence)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,expenseRowId,merchant,description,principalAmount,installmentMonths,sequence,amount);

@override
String toString() {
  return 'InstallmentDue(expenseRowId: $expenseRowId, merchant: $merchant, description: $description, principalAmount: $principalAmount, installmentMonths: $installmentMonths, sequence: $sequence, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $InstallmentDueCopyWith<$Res>  {
  factory $InstallmentDueCopyWith(InstallmentDue value, $Res Function(InstallmentDue) _then) = _$InstallmentDueCopyWithImpl;
@useResult
$Res call({
 int expenseRowId, String? merchant, String? description, int principalAmount, int installmentMonths, int sequence, int amount
});




}
/// @nodoc
class _$InstallmentDueCopyWithImpl<$Res>
    implements $InstallmentDueCopyWith<$Res> {
  _$InstallmentDueCopyWithImpl(this._self, this._then);

  final InstallmentDue _self;
  final $Res Function(InstallmentDue) _then;

/// Create a copy of InstallmentDue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? expenseRowId = null,Object? merchant = freezed,Object? description = freezed,Object? principalAmount = null,Object? installmentMonths = null,Object? sequence = null,Object? amount = null,}) {
  return _then(_self.copyWith(
expenseRowId: null == expenseRowId ? _self.expenseRowId : expenseRowId // ignore: cast_nullable_to_non_nullable
as int,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,principalAmount: null == principalAmount ? _self.principalAmount : principalAmount // ignore: cast_nullable_to_non_nullable
as int,installmentMonths: null == installmentMonths ? _self.installmentMonths : installmentMonths // ignore: cast_nullable_to_non_nullable
as int,sequence: null == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [InstallmentDue].
extension InstallmentDuePatterns on InstallmentDue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstallmentDue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstallmentDue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstallmentDue value)  $default,){
final _that = this;
switch (_that) {
case _InstallmentDue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstallmentDue value)?  $default,){
final _that = this;
switch (_that) {
case _InstallmentDue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int expenseRowId,  String? merchant,  String? description,  int principalAmount,  int installmentMonths,  int sequence,  int amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstallmentDue() when $default != null:
return $default(_that.expenseRowId,_that.merchant,_that.description,_that.principalAmount,_that.installmentMonths,_that.sequence,_that.amount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int expenseRowId,  String? merchant,  String? description,  int principalAmount,  int installmentMonths,  int sequence,  int amount)  $default,) {final _that = this;
switch (_that) {
case _InstallmentDue():
return $default(_that.expenseRowId,_that.merchant,_that.description,_that.principalAmount,_that.installmentMonths,_that.sequence,_that.amount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int expenseRowId,  String? merchant,  String? description,  int principalAmount,  int installmentMonths,  int sequence,  int amount)?  $default,) {final _that = this;
switch (_that) {
case _InstallmentDue() when $default != null:
return $default(_that.expenseRowId,_that.merchant,_that.description,_that.principalAmount,_that.installmentMonths,_that.sequence,_that.amount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstallmentDue implements InstallmentDue {
  const _InstallmentDue({required this.expenseRowId, this.merchant, this.description, required this.principalAmount, required this.installmentMonths, required this.sequence, required this.amount});
  factory _InstallmentDue.fromJson(Map<String, dynamic> json) => _$InstallmentDueFromJson(json);

@override final  int expenseRowId;
@override final  String? merchant;
@override final  String? description;
/// 할부 원금(거래 전액).
@override final  int principalAmount;
/// 총 회차 수(N).
@override final  int installmentMonths;
/// 이번이 몇 회차인지(1-base).
@override final  int sequence;
/// 이번 회차에 빠지는 금액. 나머지는 1회차에 몰린다(카드사 관행).
@override final  int amount;

/// Create a copy of InstallmentDue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstallmentDueCopyWith<_InstallmentDue> get copyWith => __$InstallmentDueCopyWithImpl<_InstallmentDue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstallmentDueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstallmentDue&&(identical(other.expenseRowId, expenseRowId) || other.expenseRowId == expenseRowId)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.description, description) || other.description == description)&&(identical(other.principalAmount, principalAmount) || other.principalAmount == principalAmount)&&(identical(other.installmentMonths, installmentMonths) || other.installmentMonths == installmentMonths)&&(identical(other.sequence, sequence) || other.sequence == sequence)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,expenseRowId,merchant,description,principalAmount,installmentMonths,sequence,amount);

@override
String toString() {
  return 'InstallmentDue(expenseRowId: $expenseRowId, merchant: $merchant, description: $description, principalAmount: $principalAmount, installmentMonths: $installmentMonths, sequence: $sequence, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$InstallmentDueCopyWith<$Res> implements $InstallmentDueCopyWith<$Res> {
  factory _$InstallmentDueCopyWith(_InstallmentDue value, $Res Function(_InstallmentDue) _then) = __$InstallmentDueCopyWithImpl;
@override @useResult
$Res call({
 int expenseRowId, String? merchant, String? description, int principalAmount, int installmentMonths, int sequence, int amount
});




}
/// @nodoc
class __$InstallmentDueCopyWithImpl<$Res>
    implements _$InstallmentDueCopyWith<$Res> {
  __$InstallmentDueCopyWithImpl(this._self, this._then);

  final _InstallmentDue _self;
  final $Res Function(_InstallmentDue) _then;

/// Create a copy of InstallmentDue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? expenseRowId = null,Object? merchant = freezed,Object? description = freezed,Object? principalAmount = null,Object? installmentMonths = null,Object? sequence = null,Object? amount = null,}) {
  return _then(_InstallmentDue(
expenseRowId: null == expenseRowId ? _self.expenseRowId : expenseRowId // ignore: cast_nullable_to_non_nullable
as int,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,principalAmount: null == principalAmount ? _self.principalAmount : principalAmount // ignore: cast_nullable_to_non_nullable
as int,installmentMonths: null == installmentMonths ? _self.installmentMonths : installmentMonths // ignore: cast_nullable_to_non_nullable
as int,sequence: null == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CardBilling {

 int get cardAssetRowId;// 다가오는 결제 회차의 결제예정액 = 청구 기간(결제일의 전월 1일~말일)
// 순사용액 − 같은 회차 기결제액(선결제 차감). 결제일 미설정 시 잔액 전액.
 int get upcomingAmount;/// 회차 내 일시불 순사용액(환불 상계, 음수 가능). 옛 서버 호환으로 옵셔널.
 int? get upcomingLumpSumAmount;/// 같은 회차에 이미 낸 금액(선결제 차감분).
 int? get upcomingAlreadyPaidAmount;/// 이 회차에 빠지는 할부 구성. 예정액이 이용 내역 합과 다를 때 그 차이를 설명한다.
 List<InstallmentDue> get upcomingInstallments; String? get upcomingPeriodStart;// 회차 청구 기간 'yyyy-MM-dd' | null
 String? get upcomingPeriodEnd; String? get nextPaymentDate;// 'yyyy-MM-dd' | null
 int? get paymentDay;// 1~31 | null
 int? get paymentAssetRowId; List<BillingItem> get history;
/// Create a copy of CardBilling
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardBillingCopyWith<CardBilling> get copyWith => _$CardBillingCopyWithImpl<CardBilling>(this as CardBilling, _$identity);

  /// Serializes this CardBilling to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardBilling&&(identical(other.cardAssetRowId, cardAssetRowId) || other.cardAssetRowId == cardAssetRowId)&&(identical(other.upcomingAmount, upcomingAmount) || other.upcomingAmount == upcomingAmount)&&(identical(other.upcomingLumpSumAmount, upcomingLumpSumAmount) || other.upcomingLumpSumAmount == upcomingLumpSumAmount)&&(identical(other.upcomingAlreadyPaidAmount, upcomingAlreadyPaidAmount) || other.upcomingAlreadyPaidAmount == upcomingAlreadyPaidAmount)&&const DeepCollectionEquality().equals(other.upcomingInstallments, upcomingInstallments)&&(identical(other.upcomingPeriodStart, upcomingPeriodStart) || other.upcomingPeriodStart == upcomingPeriodStart)&&(identical(other.upcomingPeriodEnd, upcomingPeriodEnd) || other.upcomingPeriodEnd == upcomingPeriodEnd)&&(identical(other.nextPaymentDate, nextPaymentDate) || other.nextPaymentDate == nextPaymentDate)&&(identical(other.paymentDay, paymentDay) || other.paymentDay == paymentDay)&&(identical(other.paymentAssetRowId, paymentAssetRowId) || other.paymentAssetRowId == paymentAssetRowId)&&const DeepCollectionEquality().equals(other.history, history));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cardAssetRowId,upcomingAmount,upcomingLumpSumAmount,upcomingAlreadyPaidAmount,const DeepCollectionEquality().hash(upcomingInstallments),upcomingPeriodStart,upcomingPeriodEnd,nextPaymentDate,paymentDay,paymentAssetRowId,const DeepCollectionEquality().hash(history));

@override
String toString() {
  return 'CardBilling(cardAssetRowId: $cardAssetRowId, upcomingAmount: $upcomingAmount, upcomingLumpSumAmount: $upcomingLumpSumAmount, upcomingAlreadyPaidAmount: $upcomingAlreadyPaidAmount, upcomingInstallments: $upcomingInstallments, upcomingPeriodStart: $upcomingPeriodStart, upcomingPeriodEnd: $upcomingPeriodEnd, nextPaymentDate: $nextPaymentDate, paymentDay: $paymentDay, paymentAssetRowId: $paymentAssetRowId, history: $history)';
}


}

/// @nodoc
abstract mixin class $CardBillingCopyWith<$Res>  {
  factory $CardBillingCopyWith(CardBilling value, $Res Function(CardBilling) _then) = _$CardBillingCopyWithImpl;
@useResult
$Res call({
 int cardAssetRowId, int upcomingAmount, int? upcomingLumpSumAmount, int? upcomingAlreadyPaidAmount, List<InstallmentDue> upcomingInstallments, String? upcomingPeriodStart, String? upcomingPeriodEnd, String? nextPaymentDate, int? paymentDay, int? paymentAssetRowId, List<BillingItem> history
});




}
/// @nodoc
class _$CardBillingCopyWithImpl<$Res>
    implements $CardBillingCopyWith<$Res> {
  _$CardBillingCopyWithImpl(this._self, this._then);

  final CardBilling _self;
  final $Res Function(CardBilling) _then;

/// Create a copy of CardBilling
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cardAssetRowId = null,Object? upcomingAmount = null,Object? upcomingLumpSumAmount = freezed,Object? upcomingAlreadyPaidAmount = freezed,Object? upcomingInstallments = null,Object? upcomingPeriodStart = freezed,Object? upcomingPeriodEnd = freezed,Object? nextPaymentDate = freezed,Object? paymentDay = freezed,Object? paymentAssetRowId = freezed,Object? history = null,}) {
  return _then(_self.copyWith(
cardAssetRowId: null == cardAssetRowId ? _self.cardAssetRowId : cardAssetRowId // ignore: cast_nullable_to_non_nullable
as int,upcomingAmount: null == upcomingAmount ? _self.upcomingAmount : upcomingAmount // ignore: cast_nullable_to_non_nullable
as int,upcomingLumpSumAmount: freezed == upcomingLumpSumAmount ? _self.upcomingLumpSumAmount : upcomingLumpSumAmount // ignore: cast_nullable_to_non_nullable
as int?,upcomingAlreadyPaidAmount: freezed == upcomingAlreadyPaidAmount ? _self.upcomingAlreadyPaidAmount : upcomingAlreadyPaidAmount // ignore: cast_nullable_to_non_nullable
as int?,upcomingInstallments: null == upcomingInstallments ? _self.upcomingInstallments : upcomingInstallments // ignore: cast_nullable_to_non_nullable
as List<InstallmentDue>,upcomingPeriodStart: freezed == upcomingPeriodStart ? _self.upcomingPeriodStart : upcomingPeriodStart // ignore: cast_nullable_to_non_nullable
as String?,upcomingPeriodEnd: freezed == upcomingPeriodEnd ? _self.upcomingPeriodEnd : upcomingPeriodEnd // ignore: cast_nullable_to_non_nullable
as String?,nextPaymentDate: freezed == nextPaymentDate ? _self.nextPaymentDate : nextPaymentDate // ignore: cast_nullable_to_non_nullable
as String?,paymentDay: freezed == paymentDay ? _self.paymentDay : paymentDay // ignore: cast_nullable_to_non_nullable
as int?,paymentAssetRowId: freezed == paymentAssetRowId ? _self.paymentAssetRowId : paymentAssetRowId // ignore: cast_nullable_to_non_nullable
as int?,history: null == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as List<BillingItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [CardBilling].
extension CardBillingPatterns on CardBilling {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardBilling value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardBilling() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardBilling value)  $default,){
final _that = this;
switch (_that) {
case _CardBilling():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardBilling value)?  $default,){
final _that = this;
switch (_that) {
case _CardBilling() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int cardAssetRowId,  int upcomingAmount,  int? upcomingLumpSumAmount,  int? upcomingAlreadyPaidAmount,  List<InstallmentDue> upcomingInstallments,  String? upcomingPeriodStart,  String? upcomingPeriodEnd,  String? nextPaymentDate,  int? paymentDay,  int? paymentAssetRowId,  List<BillingItem> history)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardBilling() when $default != null:
return $default(_that.cardAssetRowId,_that.upcomingAmount,_that.upcomingLumpSumAmount,_that.upcomingAlreadyPaidAmount,_that.upcomingInstallments,_that.upcomingPeriodStart,_that.upcomingPeriodEnd,_that.nextPaymentDate,_that.paymentDay,_that.paymentAssetRowId,_that.history);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int cardAssetRowId,  int upcomingAmount,  int? upcomingLumpSumAmount,  int? upcomingAlreadyPaidAmount,  List<InstallmentDue> upcomingInstallments,  String? upcomingPeriodStart,  String? upcomingPeriodEnd,  String? nextPaymentDate,  int? paymentDay,  int? paymentAssetRowId,  List<BillingItem> history)  $default,) {final _that = this;
switch (_that) {
case _CardBilling():
return $default(_that.cardAssetRowId,_that.upcomingAmount,_that.upcomingLumpSumAmount,_that.upcomingAlreadyPaidAmount,_that.upcomingInstallments,_that.upcomingPeriodStart,_that.upcomingPeriodEnd,_that.nextPaymentDate,_that.paymentDay,_that.paymentAssetRowId,_that.history);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int cardAssetRowId,  int upcomingAmount,  int? upcomingLumpSumAmount,  int? upcomingAlreadyPaidAmount,  List<InstallmentDue> upcomingInstallments,  String? upcomingPeriodStart,  String? upcomingPeriodEnd,  String? nextPaymentDate,  int? paymentDay,  int? paymentAssetRowId,  List<BillingItem> history)?  $default,) {final _that = this;
switch (_that) {
case _CardBilling() when $default != null:
return $default(_that.cardAssetRowId,_that.upcomingAmount,_that.upcomingLumpSumAmount,_that.upcomingAlreadyPaidAmount,_that.upcomingInstallments,_that.upcomingPeriodStart,_that.upcomingPeriodEnd,_that.nextPaymentDate,_that.paymentDay,_that.paymentAssetRowId,_that.history);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CardBilling implements CardBilling {
  const _CardBilling({required this.cardAssetRowId, required this.upcomingAmount, this.upcomingLumpSumAmount, this.upcomingAlreadyPaidAmount, final  List<InstallmentDue> upcomingInstallments = const <InstallmentDue>[], this.upcomingPeriodStart, this.upcomingPeriodEnd, this.nextPaymentDate, this.paymentDay, this.paymentAssetRowId, final  List<BillingItem> history = const <BillingItem>[]}): _upcomingInstallments = upcomingInstallments,_history = history;
  factory _CardBilling.fromJson(Map<String, dynamic> json) => _$CardBillingFromJson(json);

@override final  int cardAssetRowId;
// 다가오는 결제 회차의 결제예정액 = 청구 기간(결제일의 전월 1일~말일)
// 순사용액 − 같은 회차 기결제액(선결제 차감). 결제일 미설정 시 잔액 전액.
@override final  int upcomingAmount;
/// 회차 내 일시불 순사용액(환불 상계, 음수 가능). 옛 서버 호환으로 옵셔널.
@override final  int? upcomingLumpSumAmount;
/// 같은 회차에 이미 낸 금액(선결제 차감분).
@override final  int? upcomingAlreadyPaidAmount;
/// 이 회차에 빠지는 할부 구성. 예정액이 이용 내역 합과 다를 때 그 차이를 설명한다.
 final  List<InstallmentDue> _upcomingInstallments;
/// 이 회차에 빠지는 할부 구성. 예정액이 이용 내역 합과 다를 때 그 차이를 설명한다.
@override@JsonKey() List<InstallmentDue> get upcomingInstallments {
  if (_upcomingInstallments is EqualUnmodifiableListView) return _upcomingInstallments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_upcomingInstallments);
}

@override final  String? upcomingPeriodStart;
// 회차 청구 기간 'yyyy-MM-dd' | null
@override final  String? upcomingPeriodEnd;
@override final  String? nextPaymentDate;
// 'yyyy-MM-dd' | null
@override final  int? paymentDay;
// 1~31 | null
@override final  int? paymentAssetRowId;
 final  List<BillingItem> _history;
@override@JsonKey() List<BillingItem> get history {
  if (_history is EqualUnmodifiableListView) return _history;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_history);
}


/// Create a copy of CardBilling
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardBillingCopyWith<_CardBilling> get copyWith => __$CardBillingCopyWithImpl<_CardBilling>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CardBillingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardBilling&&(identical(other.cardAssetRowId, cardAssetRowId) || other.cardAssetRowId == cardAssetRowId)&&(identical(other.upcomingAmount, upcomingAmount) || other.upcomingAmount == upcomingAmount)&&(identical(other.upcomingLumpSumAmount, upcomingLumpSumAmount) || other.upcomingLumpSumAmount == upcomingLumpSumAmount)&&(identical(other.upcomingAlreadyPaidAmount, upcomingAlreadyPaidAmount) || other.upcomingAlreadyPaidAmount == upcomingAlreadyPaidAmount)&&const DeepCollectionEquality().equals(other._upcomingInstallments, _upcomingInstallments)&&(identical(other.upcomingPeriodStart, upcomingPeriodStart) || other.upcomingPeriodStart == upcomingPeriodStart)&&(identical(other.upcomingPeriodEnd, upcomingPeriodEnd) || other.upcomingPeriodEnd == upcomingPeriodEnd)&&(identical(other.nextPaymentDate, nextPaymentDate) || other.nextPaymentDate == nextPaymentDate)&&(identical(other.paymentDay, paymentDay) || other.paymentDay == paymentDay)&&(identical(other.paymentAssetRowId, paymentAssetRowId) || other.paymentAssetRowId == paymentAssetRowId)&&const DeepCollectionEquality().equals(other._history, _history));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cardAssetRowId,upcomingAmount,upcomingLumpSumAmount,upcomingAlreadyPaidAmount,const DeepCollectionEquality().hash(_upcomingInstallments),upcomingPeriodStart,upcomingPeriodEnd,nextPaymentDate,paymentDay,paymentAssetRowId,const DeepCollectionEquality().hash(_history));

@override
String toString() {
  return 'CardBilling(cardAssetRowId: $cardAssetRowId, upcomingAmount: $upcomingAmount, upcomingLumpSumAmount: $upcomingLumpSumAmount, upcomingAlreadyPaidAmount: $upcomingAlreadyPaidAmount, upcomingInstallments: $upcomingInstallments, upcomingPeriodStart: $upcomingPeriodStart, upcomingPeriodEnd: $upcomingPeriodEnd, nextPaymentDate: $nextPaymentDate, paymentDay: $paymentDay, paymentAssetRowId: $paymentAssetRowId, history: $history)';
}


}

/// @nodoc
abstract mixin class _$CardBillingCopyWith<$Res> implements $CardBillingCopyWith<$Res> {
  factory _$CardBillingCopyWith(_CardBilling value, $Res Function(_CardBilling) _then) = __$CardBillingCopyWithImpl;
@override @useResult
$Res call({
 int cardAssetRowId, int upcomingAmount, int? upcomingLumpSumAmount, int? upcomingAlreadyPaidAmount, List<InstallmentDue> upcomingInstallments, String? upcomingPeriodStart, String? upcomingPeriodEnd, String? nextPaymentDate, int? paymentDay, int? paymentAssetRowId, List<BillingItem> history
});




}
/// @nodoc
class __$CardBillingCopyWithImpl<$Res>
    implements _$CardBillingCopyWith<$Res> {
  __$CardBillingCopyWithImpl(this._self, this._then);

  final _CardBilling _self;
  final $Res Function(_CardBilling) _then;

/// Create a copy of CardBilling
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cardAssetRowId = null,Object? upcomingAmount = null,Object? upcomingLumpSumAmount = freezed,Object? upcomingAlreadyPaidAmount = freezed,Object? upcomingInstallments = null,Object? upcomingPeriodStart = freezed,Object? upcomingPeriodEnd = freezed,Object? nextPaymentDate = freezed,Object? paymentDay = freezed,Object? paymentAssetRowId = freezed,Object? history = null,}) {
  return _then(_CardBilling(
cardAssetRowId: null == cardAssetRowId ? _self.cardAssetRowId : cardAssetRowId // ignore: cast_nullable_to_non_nullable
as int,upcomingAmount: null == upcomingAmount ? _self.upcomingAmount : upcomingAmount // ignore: cast_nullable_to_non_nullable
as int,upcomingLumpSumAmount: freezed == upcomingLumpSumAmount ? _self.upcomingLumpSumAmount : upcomingLumpSumAmount // ignore: cast_nullable_to_non_nullable
as int?,upcomingAlreadyPaidAmount: freezed == upcomingAlreadyPaidAmount ? _self.upcomingAlreadyPaidAmount : upcomingAlreadyPaidAmount // ignore: cast_nullable_to_non_nullable
as int?,upcomingInstallments: null == upcomingInstallments ? _self._upcomingInstallments : upcomingInstallments // ignore: cast_nullable_to_non_nullable
as List<InstallmentDue>,upcomingPeriodStart: freezed == upcomingPeriodStart ? _self.upcomingPeriodStart : upcomingPeriodStart // ignore: cast_nullable_to_non_nullable
as String?,upcomingPeriodEnd: freezed == upcomingPeriodEnd ? _self.upcomingPeriodEnd : upcomingPeriodEnd // ignore: cast_nullable_to_non_nullable
as String?,nextPaymentDate: freezed == nextPaymentDate ? _self.nextPaymentDate : nextPaymentDate // ignore: cast_nullable_to_non_nullable
as String?,paymentDay: freezed == paymentDay ? _self.paymentDay : paymentDay // ignore: cast_nullable_to_non_nullable
as int?,paymentAssetRowId: freezed == paymentAssetRowId ? _self.paymentAssetRowId : paymentAssetRowId // ignore: cast_nullable_to_non_nullable
as int?,history: null == history ? _self._history : history // ignore: cast_nullable_to_non_nullable
as List<BillingItem>,
  ));
}


}

// dart format on
