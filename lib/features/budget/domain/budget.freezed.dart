// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Budget {

 int get rowId; int? get userRowId; int? get categoryRowId; String? get categoryName; int get budgetAmount; int get budgetYear; int get budgetMonth;
/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BudgetCopyWith<Budget> get copyWith => _$BudgetCopyWithImpl<Budget>(this as Budget, _$identity);

  /// Serializes this Budget to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Budget&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.categoryRowId, categoryRowId) || other.categoryRowId == categoryRowId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.budgetAmount, budgetAmount) || other.budgetAmount == budgetAmount)&&(identical(other.budgetYear, budgetYear) || other.budgetYear == budgetYear)&&(identical(other.budgetMonth, budgetMonth) || other.budgetMonth == budgetMonth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,userRowId,categoryRowId,categoryName,budgetAmount,budgetYear,budgetMonth);

@override
String toString() {
  return 'Budget(rowId: $rowId, userRowId: $userRowId, categoryRowId: $categoryRowId, categoryName: $categoryName, budgetAmount: $budgetAmount, budgetYear: $budgetYear, budgetMonth: $budgetMonth)';
}


}

/// @nodoc
abstract mixin class $BudgetCopyWith<$Res>  {
  factory $BudgetCopyWith(Budget value, $Res Function(Budget) _then) = _$BudgetCopyWithImpl;
@useResult
$Res call({
 int rowId, int? userRowId, int? categoryRowId, String? categoryName, int budgetAmount, int budgetYear, int budgetMonth
});




}
/// @nodoc
class _$BudgetCopyWithImpl<$Res>
    implements $BudgetCopyWith<$Res> {
  _$BudgetCopyWithImpl(this._self, this._then);

  final Budget _self;
  final $Res Function(Budget) _then;

/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = null,Object? userRowId = freezed,Object? categoryRowId = freezed,Object? categoryName = freezed,Object? budgetAmount = null,Object? budgetYear = null,Object? budgetMonth = null,}) {
  return _then(_self.copyWith(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,categoryRowId: freezed == categoryRowId ? _self.categoryRowId : categoryRowId // ignore: cast_nullable_to_non_nullable
as int?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,budgetAmount: null == budgetAmount ? _self.budgetAmount : budgetAmount // ignore: cast_nullable_to_non_nullable
as int,budgetYear: null == budgetYear ? _self.budgetYear : budgetYear // ignore: cast_nullable_to_non_nullable
as int,budgetMonth: null == budgetMonth ? _self.budgetMonth : budgetMonth // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Budget].
extension BudgetPatterns on Budget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Budget value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Budget() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Budget value)  $default,){
final _that = this;
switch (_that) {
case _Budget():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Budget value)?  $default,){
final _that = this;
switch (_that) {
case _Budget() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  int? categoryRowId,  String? categoryName,  int budgetAmount,  int budgetYear,  int budgetMonth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Budget() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.categoryRowId,_that.categoryName,_that.budgetAmount,_that.budgetYear,_that.budgetMonth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  int? categoryRowId,  String? categoryName,  int budgetAmount,  int budgetYear,  int budgetMonth)  $default,) {final _that = this;
switch (_that) {
case _Budget():
return $default(_that.rowId,_that.userRowId,_that.categoryRowId,_that.categoryName,_that.budgetAmount,_that.budgetYear,_that.budgetMonth);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowId,  int? userRowId,  int? categoryRowId,  String? categoryName,  int budgetAmount,  int budgetYear,  int budgetMonth)?  $default,) {final _that = this;
switch (_that) {
case _Budget() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.categoryRowId,_that.categoryName,_that.budgetAmount,_that.budgetYear,_that.budgetMonth);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Budget implements Budget {
  const _Budget({required this.rowId, this.userRowId, this.categoryRowId, this.categoryName, required this.budgetAmount, required this.budgetYear, required this.budgetMonth});
  factory _Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);

@override final  int rowId;
@override final  int? userRowId;
@override final  int? categoryRowId;
@override final  String? categoryName;
@override final  int budgetAmount;
@override final  int budgetYear;
@override final  int budgetMonth;

/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BudgetCopyWith<_Budget> get copyWith => __$BudgetCopyWithImpl<_Budget>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BudgetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Budget&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.categoryRowId, categoryRowId) || other.categoryRowId == categoryRowId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.budgetAmount, budgetAmount) || other.budgetAmount == budgetAmount)&&(identical(other.budgetYear, budgetYear) || other.budgetYear == budgetYear)&&(identical(other.budgetMonth, budgetMonth) || other.budgetMonth == budgetMonth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,userRowId,categoryRowId,categoryName,budgetAmount,budgetYear,budgetMonth);

@override
String toString() {
  return 'Budget(rowId: $rowId, userRowId: $userRowId, categoryRowId: $categoryRowId, categoryName: $categoryName, budgetAmount: $budgetAmount, budgetYear: $budgetYear, budgetMonth: $budgetMonth)';
}


}

/// @nodoc
abstract mixin class _$BudgetCopyWith<$Res> implements $BudgetCopyWith<$Res> {
  factory _$BudgetCopyWith(_Budget value, $Res Function(_Budget) _then) = __$BudgetCopyWithImpl;
@override @useResult
$Res call({
 int rowId, int? userRowId, int? categoryRowId, String? categoryName, int budgetAmount, int budgetYear, int budgetMonth
});




}
/// @nodoc
class __$BudgetCopyWithImpl<$Res>
    implements _$BudgetCopyWith<$Res> {
  __$BudgetCopyWithImpl(this._self, this._then);

  final _Budget _self;
  final $Res Function(_Budget) _then;

/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = null,Object? userRowId = freezed,Object? categoryRowId = freezed,Object? categoryName = freezed,Object? budgetAmount = null,Object? budgetYear = null,Object? budgetMonth = null,}) {
  return _then(_Budget(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,categoryRowId: freezed == categoryRowId ? _self.categoryRowId : categoryRowId // ignore: cast_nullable_to_non_nullable
as int?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,budgetAmount: null == budgetAmount ? _self.budgetAmount : budgetAmount // ignore: cast_nullable_to_non_nullable
as int,budgetYear: null == budgetYear ? _self.budgetYear : budgetYear // ignore: cast_nullable_to_non_nullable
as int,budgetMonth: null == budgetMonth ? _self.budgetMonth : budgetMonth // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
