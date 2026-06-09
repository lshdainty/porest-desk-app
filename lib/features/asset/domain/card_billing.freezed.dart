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
mixin _$CardBilling {

 int get cardAssetRowId; int get upcomingAmount;// = abs(카드 balance), 이번 결제예정액
 String? get nextPaymentDate;// 'yyyy-MM-dd' | null
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardBilling&&(identical(other.cardAssetRowId, cardAssetRowId) || other.cardAssetRowId == cardAssetRowId)&&(identical(other.upcomingAmount, upcomingAmount) || other.upcomingAmount == upcomingAmount)&&(identical(other.nextPaymentDate, nextPaymentDate) || other.nextPaymentDate == nextPaymentDate)&&(identical(other.paymentDay, paymentDay) || other.paymentDay == paymentDay)&&(identical(other.paymentAssetRowId, paymentAssetRowId) || other.paymentAssetRowId == paymentAssetRowId)&&const DeepCollectionEquality().equals(other.history, history));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cardAssetRowId,upcomingAmount,nextPaymentDate,paymentDay,paymentAssetRowId,const DeepCollectionEquality().hash(history));

@override
String toString() {
  return 'CardBilling(cardAssetRowId: $cardAssetRowId, upcomingAmount: $upcomingAmount, nextPaymentDate: $nextPaymentDate, paymentDay: $paymentDay, paymentAssetRowId: $paymentAssetRowId, history: $history)';
}


}

/// @nodoc
abstract mixin class $CardBillingCopyWith<$Res>  {
  factory $CardBillingCopyWith(CardBilling value, $Res Function(CardBilling) _then) = _$CardBillingCopyWithImpl;
@useResult
$Res call({
 int cardAssetRowId, int upcomingAmount, String? nextPaymentDate, int? paymentDay, int? paymentAssetRowId, List<BillingItem> history
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
@pragma('vm:prefer-inline') @override $Res call({Object? cardAssetRowId = null,Object? upcomingAmount = null,Object? nextPaymentDate = freezed,Object? paymentDay = freezed,Object? paymentAssetRowId = freezed,Object? history = null,}) {
  return _then(_self.copyWith(
cardAssetRowId: null == cardAssetRowId ? _self.cardAssetRowId : cardAssetRowId // ignore: cast_nullable_to_non_nullable
as int,upcomingAmount: null == upcomingAmount ? _self.upcomingAmount : upcomingAmount // ignore: cast_nullable_to_non_nullable
as int,nextPaymentDate: freezed == nextPaymentDate ? _self.nextPaymentDate : nextPaymentDate // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int cardAssetRowId,  int upcomingAmount,  String? nextPaymentDate,  int? paymentDay,  int? paymentAssetRowId,  List<BillingItem> history)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardBilling() when $default != null:
return $default(_that.cardAssetRowId,_that.upcomingAmount,_that.nextPaymentDate,_that.paymentDay,_that.paymentAssetRowId,_that.history);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int cardAssetRowId,  int upcomingAmount,  String? nextPaymentDate,  int? paymentDay,  int? paymentAssetRowId,  List<BillingItem> history)  $default,) {final _that = this;
switch (_that) {
case _CardBilling():
return $default(_that.cardAssetRowId,_that.upcomingAmount,_that.nextPaymentDate,_that.paymentDay,_that.paymentAssetRowId,_that.history);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int cardAssetRowId,  int upcomingAmount,  String? nextPaymentDate,  int? paymentDay,  int? paymentAssetRowId,  List<BillingItem> history)?  $default,) {final _that = this;
switch (_that) {
case _CardBilling() when $default != null:
return $default(_that.cardAssetRowId,_that.upcomingAmount,_that.nextPaymentDate,_that.paymentDay,_that.paymentAssetRowId,_that.history);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CardBilling implements CardBilling {
  const _CardBilling({required this.cardAssetRowId, required this.upcomingAmount, this.nextPaymentDate, this.paymentDay, this.paymentAssetRowId, final  List<BillingItem> history = const <BillingItem>[]}): _history = history;
  factory _CardBilling.fromJson(Map<String, dynamic> json) => _$CardBillingFromJson(json);

@override final  int cardAssetRowId;
@override final  int upcomingAmount;
// = abs(카드 balance), 이번 결제예정액
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardBilling&&(identical(other.cardAssetRowId, cardAssetRowId) || other.cardAssetRowId == cardAssetRowId)&&(identical(other.upcomingAmount, upcomingAmount) || other.upcomingAmount == upcomingAmount)&&(identical(other.nextPaymentDate, nextPaymentDate) || other.nextPaymentDate == nextPaymentDate)&&(identical(other.paymentDay, paymentDay) || other.paymentDay == paymentDay)&&(identical(other.paymentAssetRowId, paymentAssetRowId) || other.paymentAssetRowId == paymentAssetRowId)&&const DeepCollectionEquality().equals(other._history, _history));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cardAssetRowId,upcomingAmount,nextPaymentDate,paymentDay,paymentAssetRowId,const DeepCollectionEquality().hash(_history));

@override
String toString() {
  return 'CardBilling(cardAssetRowId: $cardAssetRowId, upcomingAmount: $upcomingAmount, nextPaymentDate: $nextPaymentDate, paymentDay: $paymentDay, paymentAssetRowId: $paymentAssetRowId, history: $history)';
}


}

/// @nodoc
abstract mixin class _$CardBillingCopyWith<$Res> implements $CardBillingCopyWith<$Res> {
  factory _$CardBillingCopyWith(_CardBilling value, $Res Function(_CardBilling) _then) = __$CardBillingCopyWithImpl;
@override @useResult
$Res call({
 int cardAssetRowId, int upcomingAmount, String? nextPaymentDate, int? paymentDay, int? paymentAssetRowId, List<BillingItem> history
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
@override @pragma('vm:prefer-inline') $Res call({Object? cardAssetRowId = null,Object? upcomingAmount = null,Object? nextPaymentDate = freezed,Object? paymentDay = freezed,Object? paymentAssetRowId = freezed,Object? history = null,}) {
  return _then(_CardBilling(
cardAssetRowId: null == cardAssetRowId ? _self.cardAssetRowId : cardAssetRowId // ignore: cast_nullable_to_non_nullable
as int,upcomingAmount: null == upcomingAmount ? _self.upcomingAmount : upcomingAmount // ignore: cast_nullable_to_non_nullable
as int,nextPaymentDate: freezed == nextPaymentDate ? _self.nextPaymentDate : nextPaymentDate // ignore: cast_nullable_to_non_nullable
as String?,paymentDay: freezed == paymentDay ? _self.paymentDay : paymentDay // ignore: cast_nullable_to_non_nullable
as int?,paymentAssetRowId: freezed == paymentAssetRowId ? _self.paymentAssetRowId : paymentAssetRowId // ignore: cast_nullable_to_non_nullable
as int?,history: null == history ? _self._history : history // ignore: cast_nullable_to_non_nullable
as List<BillingItem>,
  ));
}


}

// dart format on
