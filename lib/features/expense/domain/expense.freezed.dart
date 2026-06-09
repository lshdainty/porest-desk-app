// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expense.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Expense {

 int get rowId; int? get userRowId; int? get categoryRowId; String? get categoryName; String? get categoryIcon; String? get categoryColor; int? get assetRowId; String? get assetName; String get expenseType;// 'EXPENSE' | 'INCOME'
 int get amount; String? get description; String? get expenseDate;// ISO LocalDateTime ('YYYY-MM-DDTHH:mm:ss')
 String? get merchant; String? get paymentMethod; int? get calendarEventRowId; int? get todoRowId; String? get createAt; String? get modifyAt;
/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseCopyWith<Expense> get copyWith => _$ExpenseCopyWithImpl<Expense>(this as Expense, _$identity);

  /// Serializes this Expense to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Expense&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.categoryRowId, categoryRowId) || other.categoryRowId == categoryRowId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.categoryIcon, categoryIcon) || other.categoryIcon == categoryIcon)&&(identical(other.categoryColor, categoryColor) || other.categoryColor == categoryColor)&&(identical(other.assetRowId, assetRowId) || other.assetRowId == assetRowId)&&(identical(other.assetName, assetName) || other.assetName == assetName)&&(identical(other.expenseType, expenseType) || other.expenseType == expenseType)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.description, description) || other.description == description)&&(identical(other.expenseDate, expenseDate) || other.expenseDate == expenseDate)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.calendarEventRowId, calendarEventRowId) || other.calendarEventRowId == calendarEventRowId)&&(identical(other.todoRowId, todoRowId) || other.todoRowId == todoRowId)&&(identical(other.createAt, createAt) || other.createAt == createAt)&&(identical(other.modifyAt, modifyAt) || other.modifyAt == modifyAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,userRowId,categoryRowId,categoryName,categoryIcon,categoryColor,assetRowId,assetName,expenseType,amount,description,expenseDate,merchant,paymentMethod,calendarEventRowId,todoRowId,createAt,modifyAt);

@override
String toString() {
  return 'Expense(rowId: $rowId, userRowId: $userRowId, categoryRowId: $categoryRowId, categoryName: $categoryName, categoryIcon: $categoryIcon, categoryColor: $categoryColor, assetRowId: $assetRowId, assetName: $assetName, expenseType: $expenseType, amount: $amount, description: $description, expenseDate: $expenseDate, merchant: $merchant, paymentMethod: $paymentMethod, calendarEventRowId: $calendarEventRowId, todoRowId: $todoRowId, createAt: $createAt, modifyAt: $modifyAt)';
}


}

/// @nodoc
abstract mixin class $ExpenseCopyWith<$Res>  {
  factory $ExpenseCopyWith(Expense value, $Res Function(Expense) _then) = _$ExpenseCopyWithImpl;
@useResult
$Res call({
 int rowId, int? userRowId, int? categoryRowId, String? categoryName, String? categoryIcon, String? categoryColor, int? assetRowId, String? assetName, String expenseType, int amount, String? description, String? expenseDate, String? merchant, String? paymentMethod, int? calendarEventRowId, int? todoRowId, String? createAt, String? modifyAt
});




}
/// @nodoc
class _$ExpenseCopyWithImpl<$Res>
    implements $ExpenseCopyWith<$Res> {
  _$ExpenseCopyWithImpl(this._self, this._then);

  final Expense _self;
  final $Res Function(Expense) _then;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = null,Object? userRowId = freezed,Object? categoryRowId = freezed,Object? categoryName = freezed,Object? categoryIcon = freezed,Object? categoryColor = freezed,Object? assetRowId = freezed,Object? assetName = freezed,Object? expenseType = null,Object? amount = null,Object? description = freezed,Object? expenseDate = freezed,Object? merchant = freezed,Object? paymentMethod = freezed,Object? calendarEventRowId = freezed,Object? todoRowId = freezed,Object? createAt = freezed,Object? modifyAt = freezed,}) {
  return _then(_self.copyWith(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,categoryRowId: freezed == categoryRowId ? _self.categoryRowId : categoryRowId // ignore: cast_nullable_to_non_nullable
as int?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,categoryIcon: freezed == categoryIcon ? _self.categoryIcon : categoryIcon // ignore: cast_nullable_to_non_nullable
as String?,categoryColor: freezed == categoryColor ? _self.categoryColor : categoryColor // ignore: cast_nullable_to_non_nullable
as String?,assetRowId: freezed == assetRowId ? _self.assetRowId : assetRowId // ignore: cast_nullable_to_non_nullable
as int?,assetName: freezed == assetName ? _self.assetName : assetName // ignore: cast_nullable_to_non_nullable
as String?,expenseType: null == expenseType ? _self.expenseType : expenseType // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,expenseDate: freezed == expenseDate ? _self.expenseDate : expenseDate // ignore: cast_nullable_to_non_nullable
as String?,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,calendarEventRowId: freezed == calendarEventRowId ? _self.calendarEventRowId : calendarEventRowId // ignore: cast_nullable_to_non_nullable
as int?,todoRowId: freezed == todoRowId ? _self.todoRowId : todoRowId // ignore: cast_nullable_to_non_nullable
as int?,createAt: freezed == createAt ? _self.createAt : createAt // ignore: cast_nullable_to_non_nullable
as String?,modifyAt: freezed == modifyAt ? _self.modifyAt : modifyAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Expense].
extension ExpensePatterns on Expense {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Expense value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Expense() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Expense value)  $default,){
final _that = this;
switch (_that) {
case _Expense():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Expense value)?  $default,){
final _that = this;
switch (_that) {
case _Expense() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  int? categoryRowId,  String? categoryName,  String? categoryIcon,  String? categoryColor,  int? assetRowId,  String? assetName,  String expenseType,  int amount,  String? description,  String? expenseDate,  String? merchant,  String? paymentMethod,  int? calendarEventRowId,  int? todoRowId,  String? createAt,  String? modifyAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Expense() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.categoryRowId,_that.categoryName,_that.categoryIcon,_that.categoryColor,_that.assetRowId,_that.assetName,_that.expenseType,_that.amount,_that.description,_that.expenseDate,_that.merchant,_that.paymentMethod,_that.calendarEventRowId,_that.todoRowId,_that.createAt,_that.modifyAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  int? categoryRowId,  String? categoryName,  String? categoryIcon,  String? categoryColor,  int? assetRowId,  String? assetName,  String expenseType,  int amount,  String? description,  String? expenseDate,  String? merchant,  String? paymentMethod,  int? calendarEventRowId,  int? todoRowId,  String? createAt,  String? modifyAt)  $default,) {final _that = this;
switch (_that) {
case _Expense():
return $default(_that.rowId,_that.userRowId,_that.categoryRowId,_that.categoryName,_that.categoryIcon,_that.categoryColor,_that.assetRowId,_that.assetName,_that.expenseType,_that.amount,_that.description,_that.expenseDate,_that.merchant,_that.paymentMethod,_that.calendarEventRowId,_that.todoRowId,_that.createAt,_that.modifyAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowId,  int? userRowId,  int? categoryRowId,  String? categoryName,  String? categoryIcon,  String? categoryColor,  int? assetRowId,  String? assetName,  String expenseType,  int amount,  String? description,  String? expenseDate,  String? merchant,  String? paymentMethod,  int? calendarEventRowId,  int? todoRowId,  String? createAt,  String? modifyAt)?  $default,) {final _that = this;
switch (_that) {
case _Expense() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.categoryRowId,_that.categoryName,_that.categoryIcon,_that.categoryColor,_that.assetRowId,_that.assetName,_that.expenseType,_that.amount,_that.description,_that.expenseDate,_that.merchant,_that.paymentMethod,_that.calendarEventRowId,_that.todoRowId,_that.createAt,_that.modifyAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Expense implements Expense {
  const _Expense({required this.rowId, this.userRowId, this.categoryRowId, this.categoryName, this.categoryIcon, this.categoryColor, this.assetRowId, this.assetName, required this.expenseType, required this.amount, this.description, this.expenseDate, this.merchant, this.paymentMethod, this.calendarEventRowId, this.todoRowId, this.createAt, this.modifyAt});
  factory _Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);

@override final  int rowId;
@override final  int? userRowId;
@override final  int? categoryRowId;
@override final  String? categoryName;
@override final  String? categoryIcon;
@override final  String? categoryColor;
@override final  int? assetRowId;
@override final  String? assetName;
@override final  String expenseType;
// 'EXPENSE' | 'INCOME'
@override final  int amount;
@override final  String? description;
@override final  String? expenseDate;
// ISO LocalDateTime ('YYYY-MM-DDTHH:mm:ss')
@override final  String? merchant;
@override final  String? paymentMethod;
@override final  int? calendarEventRowId;
@override final  int? todoRowId;
@override final  String? createAt;
@override final  String? modifyAt;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseCopyWith<_Expense> get copyWith => __$ExpenseCopyWithImpl<_Expense>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExpenseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Expense&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.categoryRowId, categoryRowId) || other.categoryRowId == categoryRowId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.categoryIcon, categoryIcon) || other.categoryIcon == categoryIcon)&&(identical(other.categoryColor, categoryColor) || other.categoryColor == categoryColor)&&(identical(other.assetRowId, assetRowId) || other.assetRowId == assetRowId)&&(identical(other.assetName, assetName) || other.assetName == assetName)&&(identical(other.expenseType, expenseType) || other.expenseType == expenseType)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.description, description) || other.description == description)&&(identical(other.expenseDate, expenseDate) || other.expenseDate == expenseDate)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.calendarEventRowId, calendarEventRowId) || other.calendarEventRowId == calendarEventRowId)&&(identical(other.todoRowId, todoRowId) || other.todoRowId == todoRowId)&&(identical(other.createAt, createAt) || other.createAt == createAt)&&(identical(other.modifyAt, modifyAt) || other.modifyAt == modifyAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,userRowId,categoryRowId,categoryName,categoryIcon,categoryColor,assetRowId,assetName,expenseType,amount,description,expenseDate,merchant,paymentMethod,calendarEventRowId,todoRowId,createAt,modifyAt);

@override
String toString() {
  return 'Expense(rowId: $rowId, userRowId: $userRowId, categoryRowId: $categoryRowId, categoryName: $categoryName, categoryIcon: $categoryIcon, categoryColor: $categoryColor, assetRowId: $assetRowId, assetName: $assetName, expenseType: $expenseType, amount: $amount, description: $description, expenseDate: $expenseDate, merchant: $merchant, paymentMethod: $paymentMethod, calendarEventRowId: $calendarEventRowId, todoRowId: $todoRowId, createAt: $createAt, modifyAt: $modifyAt)';
}


}

/// @nodoc
abstract mixin class _$ExpenseCopyWith<$Res> implements $ExpenseCopyWith<$Res> {
  factory _$ExpenseCopyWith(_Expense value, $Res Function(_Expense) _then) = __$ExpenseCopyWithImpl;
@override @useResult
$Res call({
 int rowId, int? userRowId, int? categoryRowId, String? categoryName, String? categoryIcon, String? categoryColor, int? assetRowId, String? assetName, String expenseType, int amount, String? description, String? expenseDate, String? merchant, String? paymentMethod, int? calendarEventRowId, int? todoRowId, String? createAt, String? modifyAt
});




}
/// @nodoc
class __$ExpenseCopyWithImpl<$Res>
    implements _$ExpenseCopyWith<$Res> {
  __$ExpenseCopyWithImpl(this._self, this._then);

  final _Expense _self;
  final $Res Function(_Expense) _then;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = null,Object? userRowId = freezed,Object? categoryRowId = freezed,Object? categoryName = freezed,Object? categoryIcon = freezed,Object? categoryColor = freezed,Object? assetRowId = freezed,Object? assetName = freezed,Object? expenseType = null,Object? amount = null,Object? description = freezed,Object? expenseDate = freezed,Object? merchant = freezed,Object? paymentMethod = freezed,Object? calendarEventRowId = freezed,Object? todoRowId = freezed,Object? createAt = freezed,Object? modifyAt = freezed,}) {
  return _then(_Expense(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,categoryRowId: freezed == categoryRowId ? _self.categoryRowId : categoryRowId // ignore: cast_nullable_to_non_nullable
as int?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,categoryIcon: freezed == categoryIcon ? _self.categoryIcon : categoryIcon // ignore: cast_nullable_to_non_nullable
as String?,categoryColor: freezed == categoryColor ? _self.categoryColor : categoryColor // ignore: cast_nullable_to_non_nullable
as String?,assetRowId: freezed == assetRowId ? _self.assetRowId : assetRowId // ignore: cast_nullable_to_non_nullable
as int?,assetName: freezed == assetName ? _self.assetName : assetName // ignore: cast_nullable_to_non_nullable
as String?,expenseType: null == expenseType ? _self.expenseType : expenseType // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,expenseDate: freezed == expenseDate ? _self.expenseDate : expenseDate // ignore: cast_nullable_to_non_nullable
as String?,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,calendarEventRowId: freezed == calendarEventRowId ? _self.calendarEventRowId : calendarEventRowId // ignore: cast_nullable_to_non_nullable
as int?,todoRowId: freezed == todoRowId ? _self.todoRowId : todoRowId // ignore: cast_nullable_to_non_nullable
as int?,createAt: freezed == createAt ? _self.createAt : createAt // ignore: cast_nullable_to_non_nullable
as String?,modifyAt: freezed == modifyAt ? _self.modifyAt : modifyAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
