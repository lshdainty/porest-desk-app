// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurring_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecurringTransaction {

 int get rowId; int? get userRowId; int get categoryRowId; String? get categoryName; int get assetRowId; String? get assetName; int? get sourceExpenseRowId; String get expenseType; int get amount; String? get description; String? get merchant; String? get paymentMethod; String get frequency; int? get intervalValue; int? get dayOfWeek; int? get dayOfMonth; String? get startDate;// 'YYYY-MM-DD'
 String? get endDate; String? get nextExecutionDate; String? get lastExecutedAt; String? get isActive;// 'Y' | 'N'
 bool get autoLog; bool get notifyDayBefore;
/// Create a copy of RecurringTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurringTransactionCopyWith<RecurringTransaction> get copyWith => _$RecurringTransactionCopyWithImpl<RecurringTransaction>(this as RecurringTransaction, _$identity);

  /// Serializes this RecurringTransaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringTransaction&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.categoryRowId, categoryRowId) || other.categoryRowId == categoryRowId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.assetRowId, assetRowId) || other.assetRowId == assetRowId)&&(identical(other.assetName, assetName) || other.assetName == assetName)&&(identical(other.sourceExpenseRowId, sourceExpenseRowId) || other.sourceExpenseRowId == sourceExpenseRowId)&&(identical(other.expenseType, expenseType) || other.expenseType == expenseType)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.description, description) || other.description == description)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.intervalValue, intervalValue) || other.intervalValue == intervalValue)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.dayOfMonth, dayOfMonth) || other.dayOfMonth == dayOfMonth)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.nextExecutionDate, nextExecutionDate) || other.nextExecutionDate == nextExecutionDate)&&(identical(other.lastExecutedAt, lastExecutedAt) || other.lastExecutedAt == lastExecutedAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.autoLog, autoLog) || other.autoLog == autoLog)&&(identical(other.notifyDayBefore, notifyDayBefore) || other.notifyDayBefore == notifyDayBefore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,rowId,userRowId,categoryRowId,categoryName,assetRowId,assetName,sourceExpenseRowId,expenseType,amount,description,merchant,paymentMethod,frequency,intervalValue,dayOfWeek,dayOfMonth,startDate,endDate,nextExecutionDate,lastExecutedAt,isActive,autoLog,notifyDayBefore]);

@override
String toString() {
  return 'RecurringTransaction(rowId: $rowId, userRowId: $userRowId, categoryRowId: $categoryRowId, categoryName: $categoryName, assetRowId: $assetRowId, assetName: $assetName, sourceExpenseRowId: $sourceExpenseRowId, expenseType: $expenseType, amount: $amount, description: $description, merchant: $merchant, paymentMethod: $paymentMethod, frequency: $frequency, intervalValue: $intervalValue, dayOfWeek: $dayOfWeek, dayOfMonth: $dayOfMonth, startDate: $startDate, endDate: $endDate, nextExecutionDate: $nextExecutionDate, lastExecutedAt: $lastExecutedAt, isActive: $isActive, autoLog: $autoLog, notifyDayBefore: $notifyDayBefore)';
}


}

/// @nodoc
abstract mixin class $RecurringTransactionCopyWith<$Res>  {
  factory $RecurringTransactionCopyWith(RecurringTransaction value, $Res Function(RecurringTransaction) _then) = _$RecurringTransactionCopyWithImpl;
@useResult
$Res call({
 int rowId, int? userRowId, int categoryRowId, String? categoryName, int assetRowId, String? assetName, int? sourceExpenseRowId, String expenseType, int amount, String? description, String? merchant, String? paymentMethod, String frequency, int? intervalValue, int? dayOfWeek, int? dayOfMonth, String? startDate, String? endDate, String? nextExecutionDate, String? lastExecutedAt, String? isActive, bool autoLog, bool notifyDayBefore
});




}
/// @nodoc
class _$RecurringTransactionCopyWithImpl<$Res>
    implements $RecurringTransactionCopyWith<$Res> {
  _$RecurringTransactionCopyWithImpl(this._self, this._then);

  final RecurringTransaction _self;
  final $Res Function(RecurringTransaction) _then;

/// Create a copy of RecurringTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = null,Object? userRowId = freezed,Object? categoryRowId = null,Object? categoryName = freezed,Object? assetRowId = null,Object? assetName = freezed,Object? sourceExpenseRowId = freezed,Object? expenseType = null,Object? amount = null,Object? description = freezed,Object? merchant = freezed,Object? paymentMethod = freezed,Object? frequency = null,Object? intervalValue = freezed,Object? dayOfWeek = freezed,Object? dayOfMonth = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? nextExecutionDate = freezed,Object? lastExecutedAt = freezed,Object? isActive = freezed,Object? autoLog = null,Object? notifyDayBefore = null,}) {
  return _then(_self.copyWith(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,categoryRowId: null == categoryRowId ? _self.categoryRowId : categoryRowId // ignore: cast_nullable_to_non_nullable
as int,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,assetRowId: null == assetRowId ? _self.assetRowId : assetRowId // ignore: cast_nullable_to_non_nullable
as int,assetName: freezed == assetName ? _self.assetName : assetName // ignore: cast_nullable_to_non_nullable
as String?,sourceExpenseRowId: freezed == sourceExpenseRowId ? _self.sourceExpenseRowId : sourceExpenseRowId // ignore: cast_nullable_to_non_nullable
as int?,expenseType: null == expenseType ? _self.expenseType : expenseType // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String,intervalValue: freezed == intervalValue ? _self.intervalValue : intervalValue // ignore: cast_nullable_to_non_nullable
as int?,dayOfWeek: freezed == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int?,dayOfMonth: freezed == dayOfMonth ? _self.dayOfMonth : dayOfMonth // ignore: cast_nullable_to_non_nullable
as int?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,nextExecutionDate: freezed == nextExecutionDate ? _self.nextExecutionDate : nextExecutionDate // ignore: cast_nullable_to_non_nullable
as String?,lastExecutedAt: freezed == lastExecutedAt ? _self.lastExecutedAt : lastExecutedAt // ignore: cast_nullable_to_non_nullable
as String?,isActive: freezed == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as String?,autoLog: null == autoLog ? _self.autoLog : autoLog // ignore: cast_nullable_to_non_nullable
as bool,notifyDayBefore: null == notifyDayBefore ? _self.notifyDayBefore : notifyDayBefore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RecurringTransaction].
extension RecurringTransactionPatterns on RecurringTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecurringTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecurringTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecurringTransaction value)  $default,){
final _that = this;
switch (_that) {
case _RecurringTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecurringTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _RecurringTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  int categoryRowId,  String? categoryName,  int assetRowId,  String? assetName,  int? sourceExpenseRowId,  String expenseType,  int amount,  String? description,  String? merchant,  String? paymentMethod,  String frequency,  int? intervalValue,  int? dayOfWeek,  int? dayOfMonth,  String? startDate,  String? endDate,  String? nextExecutionDate,  String? lastExecutedAt,  String? isActive,  bool autoLog,  bool notifyDayBefore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurringTransaction() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.categoryRowId,_that.categoryName,_that.assetRowId,_that.assetName,_that.sourceExpenseRowId,_that.expenseType,_that.amount,_that.description,_that.merchant,_that.paymentMethod,_that.frequency,_that.intervalValue,_that.dayOfWeek,_that.dayOfMonth,_that.startDate,_that.endDate,_that.nextExecutionDate,_that.lastExecutedAt,_that.isActive,_that.autoLog,_that.notifyDayBefore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  int categoryRowId,  String? categoryName,  int assetRowId,  String? assetName,  int? sourceExpenseRowId,  String expenseType,  int amount,  String? description,  String? merchant,  String? paymentMethod,  String frequency,  int? intervalValue,  int? dayOfWeek,  int? dayOfMonth,  String? startDate,  String? endDate,  String? nextExecutionDate,  String? lastExecutedAt,  String? isActive,  bool autoLog,  bool notifyDayBefore)  $default,) {final _that = this;
switch (_that) {
case _RecurringTransaction():
return $default(_that.rowId,_that.userRowId,_that.categoryRowId,_that.categoryName,_that.assetRowId,_that.assetName,_that.sourceExpenseRowId,_that.expenseType,_that.amount,_that.description,_that.merchant,_that.paymentMethod,_that.frequency,_that.intervalValue,_that.dayOfWeek,_that.dayOfMonth,_that.startDate,_that.endDate,_that.nextExecutionDate,_that.lastExecutedAt,_that.isActive,_that.autoLog,_that.notifyDayBefore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowId,  int? userRowId,  int categoryRowId,  String? categoryName,  int assetRowId,  String? assetName,  int? sourceExpenseRowId,  String expenseType,  int amount,  String? description,  String? merchant,  String? paymentMethod,  String frequency,  int? intervalValue,  int? dayOfWeek,  int? dayOfMonth,  String? startDate,  String? endDate,  String? nextExecutionDate,  String? lastExecutedAt,  String? isActive,  bool autoLog,  bool notifyDayBefore)?  $default,) {final _that = this;
switch (_that) {
case _RecurringTransaction() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.categoryRowId,_that.categoryName,_that.assetRowId,_that.assetName,_that.sourceExpenseRowId,_that.expenseType,_that.amount,_that.description,_that.merchant,_that.paymentMethod,_that.frequency,_that.intervalValue,_that.dayOfWeek,_that.dayOfMonth,_that.startDate,_that.endDate,_that.nextExecutionDate,_that.lastExecutedAt,_that.isActive,_that.autoLog,_that.notifyDayBefore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecurringTransaction implements RecurringTransaction {
  const _RecurringTransaction({required this.rowId, this.userRowId, required this.categoryRowId, this.categoryName, required this.assetRowId, this.assetName, this.sourceExpenseRowId, required this.expenseType, required this.amount, this.description, this.merchant, this.paymentMethod, required this.frequency, this.intervalValue, this.dayOfWeek, this.dayOfMonth, this.startDate, this.endDate, this.nextExecutionDate, this.lastExecutedAt, this.isActive, this.autoLog = false, this.notifyDayBefore = false});
  factory _RecurringTransaction.fromJson(Map<String, dynamic> json) => _$RecurringTransactionFromJson(json);

@override final  int rowId;
@override final  int? userRowId;
@override final  int categoryRowId;
@override final  String? categoryName;
@override final  int assetRowId;
@override final  String? assetName;
@override final  int? sourceExpenseRowId;
@override final  String expenseType;
@override final  int amount;
@override final  String? description;
@override final  String? merchant;
@override final  String? paymentMethod;
@override final  String frequency;
@override final  int? intervalValue;
@override final  int? dayOfWeek;
@override final  int? dayOfMonth;
@override final  String? startDate;
// 'YYYY-MM-DD'
@override final  String? endDate;
@override final  String? nextExecutionDate;
@override final  String? lastExecutedAt;
@override final  String? isActive;
// 'Y' | 'N'
@override@JsonKey() final  bool autoLog;
@override@JsonKey() final  bool notifyDayBefore;

/// Create a copy of RecurringTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurringTransactionCopyWith<_RecurringTransaction> get copyWith => __$RecurringTransactionCopyWithImpl<_RecurringTransaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecurringTransactionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurringTransaction&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.categoryRowId, categoryRowId) || other.categoryRowId == categoryRowId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.assetRowId, assetRowId) || other.assetRowId == assetRowId)&&(identical(other.assetName, assetName) || other.assetName == assetName)&&(identical(other.sourceExpenseRowId, sourceExpenseRowId) || other.sourceExpenseRowId == sourceExpenseRowId)&&(identical(other.expenseType, expenseType) || other.expenseType == expenseType)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.description, description) || other.description == description)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.intervalValue, intervalValue) || other.intervalValue == intervalValue)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.dayOfMonth, dayOfMonth) || other.dayOfMonth == dayOfMonth)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.nextExecutionDate, nextExecutionDate) || other.nextExecutionDate == nextExecutionDate)&&(identical(other.lastExecutedAt, lastExecutedAt) || other.lastExecutedAt == lastExecutedAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.autoLog, autoLog) || other.autoLog == autoLog)&&(identical(other.notifyDayBefore, notifyDayBefore) || other.notifyDayBefore == notifyDayBefore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,rowId,userRowId,categoryRowId,categoryName,assetRowId,assetName,sourceExpenseRowId,expenseType,amount,description,merchant,paymentMethod,frequency,intervalValue,dayOfWeek,dayOfMonth,startDate,endDate,nextExecutionDate,lastExecutedAt,isActive,autoLog,notifyDayBefore]);

@override
String toString() {
  return 'RecurringTransaction(rowId: $rowId, userRowId: $userRowId, categoryRowId: $categoryRowId, categoryName: $categoryName, assetRowId: $assetRowId, assetName: $assetName, sourceExpenseRowId: $sourceExpenseRowId, expenseType: $expenseType, amount: $amount, description: $description, merchant: $merchant, paymentMethod: $paymentMethod, frequency: $frequency, intervalValue: $intervalValue, dayOfWeek: $dayOfWeek, dayOfMonth: $dayOfMonth, startDate: $startDate, endDate: $endDate, nextExecutionDate: $nextExecutionDate, lastExecutedAt: $lastExecutedAt, isActive: $isActive, autoLog: $autoLog, notifyDayBefore: $notifyDayBefore)';
}


}

/// @nodoc
abstract mixin class _$RecurringTransactionCopyWith<$Res> implements $RecurringTransactionCopyWith<$Res> {
  factory _$RecurringTransactionCopyWith(_RecurringTransaction value, $Res Function(_RecurringTransaction) _then) = __$RecurringTransactionCopyWithImpl;
@override @useResult
$Res call({
 int rowId, int? userRowId, int categoryRowId, String? categoryName, int assetRowId, String? assetName, int? sourceExpenseRowId, String expenseType, int amount, String? description, String? merchant, String? paymentMethod, String frequency, int? intervalValue, int? dayOfWeek, int? dayOfMonth, String? startDate, String? endDate, String? nextExecutionDate, String? lastExecutedAt, String? isActive, bool autoLog, bool notifyDayBefore
});




}
/// @nodoc
class __$RecurringTransactionCopyWithImpl<$Res>
    implements _$RecurringTransactionCopyWith<$Res> {
  __$RecurringTransactionCopyWithImpl(this._self, this._then);

  final _RecurringTransaction _self;
  final $Res Function(_RecurringTransaction) _then;

/// Create a copy of RecurringTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = null,Object? userRowId = freezed,Object? categoryRowId = null,Object? categoryName = freezed,Object? assetRowId = null,Object? assetName = freezed,Object? sourceExpenseRowId = freezed,Object? expenseType = null,Object? amount = null,Object? description = freezed,Object? merchant = freezed,Object? paymentMethod = freezed,Object? frequency = null,Object? intervalValue = freezed,Object? dayOfWeek = freezed,Object? dayOfMonth = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? nextExecutionDate = freezed,Object? lastExecutedAt = freezed,Object? isActive = freezed,Object? autoLog = null,Object? notifyDayBefore = null,}) {
  return _then(_RecurringTransaction(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,categoryRowId: null == categoryRowId ? _self.categoryRowId : categoryRowId // ignore: cast_nullable_to_non_nullable
as int,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,assetRowId: null == assetRowId ? _self.assetRowId : assetRowId // ignore: cast_nullable_to_non_nullable
as int,assetName: freezed == assetName ? _self.assetName : assetName // ignore: cast_nullable_to_non_nullable
as String?,sourceExpenseRowId: freezed == sourceExpenseRowId ? _self.sourceExpenseRowId : sourceExpenseRowId // ignore: cast_nullable_to_non_nullable
as int?,expenseType: null == expenseType ? _self.expenseType : expenseType // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String,intervalValue: freezed == intervalValue ? _self.intervalValue : intervalValue // ignore: cast_nullable_to_non_nullable
as int?,dayOfWeek: freezed == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int?,dayOfMonth: freezed == dayOfMonth ? _self.dayOfMonth : dayOfMonth // ignore: cast_nullable_to_non_nullable
as int?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,nextExecutionDate: freezed == nextExecutionDate ? _self.nextExecutionDate : nextExecutionDate // ignore: cast_nullable_to_non_nullable
as String?,lastExecutedAt: freezed == lastExecutedAt ? _self.lastExecutedAt : lastExecutedAt // ignore: cast_nullable_to_non_nullable
as String?,isActive: freezed == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as String?,autoLog: null == autoLog ? _self.autoLog : autoLog // ignore: cast_nullable_to_non_nullable
as bool,notifyDayBefore: null == notifyDayBefore ? _self.notifyDayBefore : notifyDayBefore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
