// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expense_split.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExpenseSplit {

 int get rowId; int get expenseRowId; int get categoryRowId; String? get categoryName; int get amount; String? get label; int? get sortOrder; String? get createAt; String? get modifyAt;
/// Create a copy of ExpenseSplit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseSplitCopyWith<ExpenseSplit> get copyWith => _$ExpenseSplitCopyWithImpl<ExpenseSplit>(this as ExpenseSplit, _$identity);

  /// Serializes this ExpenseSplit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpenseSplit&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.expenseRowId, expenseRowId) || other.expenseRowId == expenseRowId)&&(identical(other.categoryRowId, categoryRowId) || other.categoryRowId == categoryRowId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.label, label) || other.label == label)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.createAt, createAt) || other.createAt == createAt)&&(identical(other.modifyAt, modifyAt) || other.modifyAt == modifyAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,expenseRowId,categoryRowId,categoryName,amount,label,sortOrder,createAt,modifyAt);

@override
String toString() {
  return 'ExpenseSplit(rowId: $rowId, expenseRowId: $expenseRowId, categoryRowId: $categoryRowId, categoryName: $categoryName, amount: $amount, label: $label, sortOrder: $sortOrder, createAt: $createAt, modifyAt: $modifyAt)';
}


}

/// @nodoc
abstract mixin class $ExpenseSplitCopyWith<$Res>  {
  factory $ExpenseSplitCopyWith(ExpenseSplit value, $Res Function(ExpenseSplit) _then) = _$ExpenseSplitCopyWithImpl;
@useResult
$Res call({
 int rowId, int expenseRowId, int categoryRowId, String? categoryName, int amount, String? label, int? sortOrder, String? createAt, String? modifyAt
});




}
/// @nodoc
class _$ExpenseSplitCopyWithImpl<$Res>
    implements $ExpenseSplitCopyWith<$Res> {
  _$ExpenseSplitCopyWithImpl(this._self, this._then);

  final ExpenseSplit _self;
  final $Res Function(ExpenseSplit) _then;

/// Create a copy of ExpenseSplit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = null,Object? expenseRowId = null,Object? categoryRowId = null,Object? categoryName = freezed,Object? amount = null,Object? label = freezed,Object? sortOrder = freezed,Object? createAt = freezed,Object? modifyAt = freezed,}) {
  return _then(_self.copyWith(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,expenseRowId: null == expenseRowId ? _self.expenseRowId : expenseRowId // ignore: cast_nullable_to_non_nullable
as int,categoryRowId: null == categoryRowId ? _self.categoryRowId : categoryRowId // ignore: cast_nullable_to_non_nullable
as int,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,createAt: freezed == createAt ? _self.createAt : createAt // ignore: cast_nullable_to_non_nullable
as String?,modifyAt: freezed == modifyAt ? _self.modifyAt : modifyAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExpenseSplit].
extension ExpenseSplitPatterns on ExpenseSplit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExpenseSplit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExpenseSplit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExpenseSplit value)  $default,){
final _that = this;
switch (_that) {
case _ExpenseSplit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExpenseSplit value)?  $default,){
final _that = this;
switch (_that) {
case _ExpenseSplit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowId,  int expenseRowId,  int categoryRowId,  String? categoryName,  int amount,  String? label,  int? sortOrder,  String? createAt,  String? modifyAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExpenseSplit() when $default != null:
return $default(_that.rowId,_that.expenseRowId,_that.categoryRowId,_that.categoryName,_that.amount,_that.label,_that.sortOrder,_that.createAt,_that.modifyAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowId,  int expenseRowId,  int categoryRowId,  String? categoryName,  int amount,  String? label,  int? sortOrder,  String? createAt,  String? modifyAt)  $default,) {final _that = this;
switch (_that) {
case _ExpenseSplit():
return $default(_that.rowId,_that.expenseRowId,_that.categoryRowId,_that.categoryName,_that.amount,_that.label,_that.sortOrder,_that.createAt,_that.modifyAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowId,  int expenseRowId,  int categoryRowId,  String? categoryName,  int amount,  String? label,  int? sortOrder,  String? createAt,  String? modifyAt)?  $default,) {final _that = this;
switch (_that) {
case _ExpenseSplit() when $default != null:
return $default(_that.rowId,_that.expenseRowId,_that.categoryRowId,_that.categoryName,_that.amount,_that.label,_that.sortOrder,_that.createAt,_that.modifyAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExpenseSplit implements ExpenseSplit {
  const _ExpenseSplit({required this.rowId, required this.expenseRowId, required this.categoryRowId, this.categoryName, required this.amount, this.label, this.sortOrder, this.createAt, this.modifyAt});
  factory _ExpenseSplit.fromJson(Map<String, dynamic> json) => _$ExpenseSplitFromJson(json);

@override final  int rowId;
@override final  int expenseRowId;
@override final  int categoryRowId;
@override final  String? categoryName;
@override final  int amount;
@override final  String? label;
@override final  int? sortOrder;
@override final  String? createAt;
@override final  String? modifyAt;

/// Create a copy of ExpenseSplit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseSplitCopyWith<_ExpenseSplit> get copyWith => __$ExpenseSplitCopyWithImpl<_ExpenseSplit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExpenseSplitToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExpenseSplit&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.expenseRowId, expenseRowId) || other.expenseRowId == expenseRowId)&&(identical(other.categoryRowId, categoryRowId) || other.categoryRowId == categoryRowId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.label, label) || other.label == label)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.createAt, createAt) || other.createAt == createAt)&&(identical(other.modifyAt, modifyAt) || other.modifyAt == modifyAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,expenseRowId,categoryRowId,categoryName,amount,label,sortOrder,createAt,modifyAt);

@override
String toString() {
  return 'ExpenseSplit(rowId: $rowId, expenseRowId: $expenseRowId, categoryRowId: $categoryRowId, categoryName: $categoryName, amount: $amount, label: $label, sortOrder: $sortOrder, createAt: $createAt, modifyAt: $modifyAt)';
}


}

/// @nodoc
abstract mixin class _$ExpenseSplitCopyWith<$Res> implements $ExpenseSplitCopyWith<$Res> {
  factory _$ExpenseSplitCopyWith(_ExpenseSplit value, $Res Function(_ExpenseSplit) _then) = __$ExpenseSplitCopyWithImpl;
@override @useResult
$Res call({
 int rowId, int expenseRowId, int categoryRowId, String? categoryName, int amount, String? label, int? sortOrder, String? createAt, String? modifyAt
});




}
/// @nodoc
class __$ExpenseSplitCopyWithImpl<$Res>
    implements _$ExpenseSplitCopyWith<$Res> {
  __$ExpenseSplitCopyWithImpl(this._self, this._then);

  final _ExpenseSplit _self;
  final $Res Function(_ExpenseSplit) _then;

/// Create a copy of ExpenseSplit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = null,Object? expenseRowId = null,Object? categoryRowId = null,Object? categoryName = freezed,Object? amount = null,Object? label = freezed,Object? sortOrder = freezed,Object? createAt = freezed,Object? modifyAt = freezed,}) {
  return _then(_ExpenseSplit(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,expenseRowId: null == expenseRowId ? _self.expenseRowId : expenseRowId // ignore: cast_nullable_to_non_nullable
as int,categoryRowId: null == categoryRowId ? _self.categoryRowId : categoryRowId // ignore: cast_nullable_to_non_nullable
as int,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,createAt: freezed == createAt ? _self.createAt : createAt // ignore: cast_nullable_to_non_nullable
as String?,modifyAt: freezed == modifyAt ? _self.modifyAt : modifyAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
