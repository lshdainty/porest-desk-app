// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stats_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MonthlyTrend {

 int get year; int get month; int get totalIncome; int get totalExpense;
/// Create a copy of MonthlyTrend
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthlyTrendCopyWith<MonthlyTrend> get copyWith => _$MonthlyTrendCopyWithImpl<MonthlyTrend>(this as MonthlyTrend, _$identity);

  /// Serializes this MonthlyTrend to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthlyTrend&&(identical(other.year, year) || other.year == year)&&(identical(other.month, month) || other.month == month)&&(identical(other.totalIncome, totalIncome) || other.totalIncome == totalIncome)&&(identical(other.totalExpense, totalExpense) || other.totalExpense == totalExpense));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,year,month,totalIncome,totalExpense);

@override
String toString() {
  return 'MonthlyTrend(year: $year, month: $month, totalIncome: $totalIncome, totalExpense: $totalExpense)';
}


}

/// @nodoc
abstract mixin class $MonthlyTrendCopyWith<$Res>  {
  factory $MonthlyTrendCopyWith(MonthlyTrend value, $Res Function(MonthlyTrend) _then) = _$MonthlyTrendCopyWithImpl;
@useResult
$Res call({
 int year, int month, int totalIncome, int totalExpense
});




}
/// @nodoc
class _$MonthlyTrendCopyWithImpl<$Res>
    implements $MonthlyTrendCopyWith<$Res> {
  _$MonthlyTrendCopyWithImpl(this._self, this._then);

  final MonthlyTrend _self;
  final $Res Function(MonthlyTrend) _then;

/// Create a copy of MonthlyTrend
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? year = null,Object? month = null,Object? totalIncome = null,Object? totalExpense = null,}) {
  return _then(_self.copyWith(
year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,totalIncome: null == totalIncome ? _self.totalIncome : totalIncome // ignore: cast_nullable_to_non_nullable
as int,totalExpense: null == totalExpense ? _self.totalExpense : totalExpense // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MonthlyTrend].
extension MonthlyTrendPatterns on MonthlyTrend {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonthlyTrend value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonthlyTrend() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonthlyTrend value)  $default,){
final _that = this;
switch (_that) {
case _MonthlyTrend():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonthlyTrend value)?  $default,){
final _that = this;
switch (_that) {
case _MonthlyTrend() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int year,  int month,  int totalIncome,  int totalExpense)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonthlyTrend() when $default != null:
return $default(_that.year,_that.month,_that.totalIncome,_that.totalExpense);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int year,  int month,  int totalIncome,  int totalExpense)  $default,) {final _that = this;
switch (_that) {
case _MonthlyTrend():
return $default(_that.year,_that.month,_that.totalIncome,_that.totalExpense);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int year,  int month,  int totalIncome,  int totalExpense)?  $default,) {final _that = this;
switch (_that) {
case _MonthlyTrend() when $default != null:
return $default(_that.year,_that.month,_that.totalIncome,_that.totalExpense);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MonthlyTrend implements MonthlyTrend {
  const _MonthlyTrend({required this.year, required this.month, this.totalIncome = 0, this.totalExpense = 0});
  factory _MonthlyTrend.fromJson(Map<String, dynamic> json) => _$MonthlyTrendFromJson(json);

@override final  int year;
@override final  int month;
@override@JsonKey() final  int totalIncome;
@override@JsonKey() final  int totalExpense;

/// Create a copy of MonthlyTrend
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonthlyTrendCopyWith<_MonthlyTrend> get copyWith => __$MonthlyTrendCopyWithImpl<_MonthlyTrend>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MonthlyTrendToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonthlyTrend&&(identical(other.year, year) || other.year == year)&&(identical(other.month, month) || other.month == month)&&(identical(other.totalIncome, totalIncome) || other.totalIncome == totalIncome)&&(identical(other.totalExpense, totalExpense) || other.totalExpense == totalExpense));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,year,month,totalIncome,totalExpense);

@override
String toString() {
  return 'MonthlyTrend(year: $year, month: $month, totalIncome: $totalIncome, totalExpense: $totalExpense)';
}


}

/// @nodoc
abstract mixin class _$MonthlyTrendCopyWith<$Res> implements $MonthlyTrendCopyWith<$Res> {
  factory _$MonthlyTrendCopyWith(_MonthlyTrend value, $Res Function(_MonthlyTrend) _then) = __$MonthlyTrendCopyWithImpl;
@override @useResult
$Res call({
 int year, int month, int totalIncome, int totalExpense
});




}
/// @nodoc
class __$MonthlyTrendCopyWithImpl<$Res>
    implements _$MonthlyTrendCopyWith<$Res> {
  __$MonthlyTrendCopyWithImpl(this._self, this._then);

  final _MonthlyTrend _self;
  final $Res Function(_MonthlyTrend) _then;

/// Create a copy of MonthlyTrend
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? year = null,Object? month = null,Object? totalIncome = null,Object? totalExpense = null,}) {
  return _then(_MonthlyTrend(
year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,totalIncome: null == totalIncome ? _self.totalIncome : totalIncome // ignore: cast_nullable_to_non_nullable
as int,totalExpense: null == totalExpense ? _self.totalExpense : totalExpense // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CategoryBreakdown {

 int? get categoryRowId; String? get categoryName; int? get parentCategoryRowId; String? get parentCategoryName; String? get expenseType; int get totalAmount;
/// Create a copy of CategoryBreakdown
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryBreakdownCopyWith<CategoryBreakdown> get copyWith => _$CategoryBreakdownCopyWithImpl<CategoryBreakdown>(this as CategoryBreakdown, _$identity);

  /// Serializes this CategoryBreakdown to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryBreakdown&&(identical(other.categoryRowId, categoryRowId) || other.categoryRowId == categoryRowId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.parentCategoryRowId, parentCategoryRowId) || other.parentCategoryRowId == parentCategoryRowId)&&(identical(other.parentCategoryName, parentCategoryName) || other.parentCategoryName == parentCategoryName)&&(identical(other.expenseType, expenseType) || other.expenseType == expenseType)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,categoryRowId,categoryName,parentCategoryRowId,parentCategoryName,expenseType,totalAmount);

@override
String toString() {
  return 'CategoryBreakdown(categoryRowId: $categoryRowId, categoryName: $categoryName, parentCategoryRowId: $parentCategoryRowId, parentCategoryName: $parentCategoryName, expenseType: $expenseType, totalAmount: $totalAmount)';
}


}

/// @nodoc
abstract mixin class $CategoryBreakdownCopyWith<$Res>  {
  factory $CategoryBreakdownCopyWith(CategoryBreakdown value, $Res Function(CategoryBreakdown) _then) = _$CategoryBreakdownCopyWithImpl;
@useResult
$Res call({
 int? categoryRowId, String? categoryName, int? parentCategoryRowId, String? parentCategoryName, String? expenseType, int totalAmount
});




}
/// @nodoc
class _$CategoryBreakdownCopyWithImpl<$Res>
    implements $CategoryBreakdownCopyWith<$Res> {
  _$CategoryBreakdownCopyWithImpl(this._self, this._then);

  final CategoryBreakdown _self;
  final $Res Function(CategoryBreakdown) _then;

/// Create a copy of CategoryBreakdown
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryRowId = freezed,Object? categoryName = freezed,Object? parentCategoryRowId = freezed,Object? parentCategoryName = freezed,Object? expenseType = freezed,Object? totalAmount = null,}) {
  return _then(_self.copyWith(
categoryRowId: freezed == categoryRowId ? _self.categoryRowId : categoryRowId // ignore: cast_nullable_to_non_nullable
as int?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,parentCategoryRowId: freezed == parentCategoryRowId ? _self.parentCategoryRowId : parentCategoryRowId // ignore: cast_nullable_to_non_nullable
as int?,parentCategoryName: freezed == parentCategoryName ? _self.parentCategoryName : parentCategoryName // ignore: cast_nullable_to_non_nullable
as String?,expenseType: freezed == expenseType ? _self.expenseType : expenseType // ignore: cast_nullable_to_non_nullable
as String?,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryBreakdown].
extension CategoryBreakdownPatterns on CategoryBreakdown {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryBreakdown value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryBreakdown() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryBreakdown value)  $default,){
final _that = this;
switch (_that) {
case _CategoryBreakdown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryBreakdown value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryBreakdown() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? categoryRowId,  String? categoryName,  int? parentCategoryRowId,  String? parentCategoryName,  String? expenseType,  int totalAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryBreakdown() when $default != null:
return $default(_that.categoryRowId,_that.categoryName,_that.parentCategoryRowId,_that.parentCategoryName,_that.expenseType,_that.totalAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? categoryRowId,  String? categoryName,  int? parentCategoryRowId,  String? parentCategoryName,  String? expenseType,  int totalAmount)  $default,) {final _that = this;
switch (_that) {
case _CategoryBreakdown():
return $default(_that.categoryRowId,_that.categoryName,_that.parentCategoryRowId,_that.parentCategoryName,_that.expenseType,_that.totalAmount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? categoryRowId,  String? categoryName,  int? parentCategoryRowId,  String? parentCategoryName,  String? expenseType,  int totalAmount)?  $default,) {final _that = this;
switch (_that) {
case _CategoryBreakdown() when $default != null:
return $default(_that.categoryRowId,_that.categoryName,_that.parentCategoryRowId,_that.parentCategoryName,_that.expenseType,_that.totalAmount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategoryBreakdown implements CategoryBreakdown {
  const _CategoryBreakdown({this.categoryRowId, this.categoryName, this.parentCategoryRowId, this.parentCategoryName, this.expenseType, this.totalAmount = 0});
  factory _CategoryBreakdown.fromJson(Map<String, dynamic> json) => _$CategoryBreakdownFromJson(json);

@override final  int? categoryRowId;
@override final  String? categoryName;
@override final  int? parentCategoryRowId;
@override final  String? parentCategoryName;
@override final  String? expenseType;
@override@JsonKey() final  int totalAmount;

/// Create a copy of CategoryBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryBreakdownCopyWith<_CategoryBreakdown> get copyWith => __$CategoryBreakdownCopyWithImpl<_CategoryBreakdown>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryBreakdownToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryBreakdown&&(identical(other.categoryRowId, categoryRowId) || other.categoryRowId == categoryRowId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.parentCategoryRowId, parentCategoryRowId) || other.parentCategoryRowId == parentCategoryRowId)&&(identical(other.parentCategoryName, parentCategoryName) || other.parentCategoryName == parentCategoryName)&&(identical(other.expenseType, expenseType) || other.expenseType == expenseType)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,categoryRowId,categoryName,parentCategoryRowId,parentCategoryName,expenseType,totalAmount);

@override
String toString() {
  return 'CategoryBreakdown(categoryRowId: $categoryRowId, categoryName: $categoryName, parentCategoryRowId: $parentCategoryRowId, parentCategoryName: $parentCategoryName, expenseType: $expenseType, totalAmount: $totalAmount)';
}


}

/// @nodoc
abstract mixin class _$CategoryBreakdownCopyWith<$Res> implements $CategoryBreakdownCopyWith<$Res> {
  factory _$CategoryBreakdownCopyWith(_CategoryBreakdown value, $Res Function(_CategoryBreakdown) _then) = __$CategoryBreakdownCopyWithImpl;
@override @useResult
$Res call({
 int? categoryRowId, String? categoryName, int? parentCategoryRowId, String? parentCategoryName, String? expenseType, int totalAmount
});




}
/// @nodoc
class __$CategoryBreakdownCopyWithImpl<$Res>
    implements _$CategoryBreakdownCopyWith<$Res> {
  __$CategoryBreakdownCopyWithImpl(this._self, this._then);

  final _CategoryBreakdown _self;
  final $Res Function(_CategoryBreakdown) _then;

/// Create a copy of CategoryBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryRowId = freezed,Object? categoryName = freezed,Object? parentCategoryRowId = freezed,Object? parentCategoryName = freezed,Object? expenseType = freezed,Object? totalAmount = null,}) {
  return _then(_CategoryBreakdown(
categoryRowId: freezed == categoryRowId ? _self.categoryRowId : categoryRowId // ignore: cast_nullable_to_non_nullable
as int?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,parentCategoryRowId: freezed == parentCategoryRowId ? _self.parentCategoryRowId : parentCategoryRowId // ignore: cast_nullable_to_non_nullable
as int?,parentCategoryName: freezed == parentCategoryName ? _self.parentCategoryName : parentCategoryName // ignore: cast_nullable_to_non_nullable
as String?,expenseType: freezed == expenseType ? _self.expenseType : expenseType // ignore: cast_nullable_to_non_nullable
as String?,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$MonthlySummary {

 int get year; int get month; int get totalIncome; int get totalExpense; List<CategoryBreakdown> get categoryBreakdown;
/// Create a copy of MonthlySummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthlySummaryCopyWith<MonthlySummary> get copyWith => _$MonthlySummaryCopyWithImpl<MonthlySummary>(this as MonthlySummary, _$identity);

  /// Serializes this MonthlySummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthlySummary&&(identical(other.year, year) || other.year == year)&&(identical(other.month, month) || other.month == month)&&(identical(other.totalIncome, totalIncome) || other.totalIncome == totalIncome)&&(identical(other.totalExpense, totalExpense) || other.totalExpense == totalExpense)&&const DeepCollectionEquality().equals(other.categoryBreakdown, categoryBreakdown));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,year,month,totalIncome,totalExpense,const DeepCollectionEquality().hash(categoryBreakdown));

@override
String toString() {
  return 'MonthlySummary(year: $year, month: $month, totalIncome: $totalIncome, totalExpense: $totalExpense, categoryBreakdown: $categoryBreakdown)';
}


}

/// @nodoc
abstract mixin class $MonthlySummaryCopyWith<$Res>  {
  factory $MonthlySummaryCopyWith(MonthlySummary value, $Res Function(MonthlySummary) _then) = _$MonthlySummaryCopyWithImpl;
@useResult
$Res call({
 int year, int month, int totalIncome, int totalExpense, List<CategoryBreakdown> categoryBreakdown
});




}
/// @nodoc
class _$MonthlySummaryCopyWithImpl<$Res>
    implements $MonthlySummaryCopyWith<$Res> {
  _$MonthlySummaryCopyWithImpl(this._self, this._then);

  final MonthlySummary _self;
  final $Res Function(MonthlySummary) _then;

/// Create a copy of MonthlySummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? year = null,Object? month = null,Object? totalIncome = null,Object? totalExpense = null,Object? categoryBreakdown = null,}) {
  return _then(_self.copyWith(
year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,totalIncome: null == totalIncome ? _self.totalIncome : totalIncome // ignore: cast_nullable_to_non_nullable
as int,totalExpense: null == totalExpense ? _self.totalExpense : totalExpense // ignore: cast_nullable_to_non_nullable
as int,categoryBreakdown: null == categoryBreakdown ? _self.categoryBreakdown : categoryBreakdown // ignore: cast_nullable_to_non_nullable
as List<CategoryBreakdown>,
  ));
}

}


/// Adds pattern-matching-related methods to [MonthlySummary].
extension MonthlySummaryPatterns on MonthlySummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonthlySummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonthlySummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonthlySummary value)  $default,){
final _that = this;
switch (_that) {
case _MonthlySummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonthlySummary value)?  $default,){
final _that = this;
switch (_that) {
case _MonthlySummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int year,  int month,  int totalIncome,  int totalExpense,  List<CategoryBreakdown> categoryBreakdown)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonthlySummary() when $default != null:
return $default(_that.year,_that.month,_that.totalIncome,_that.totalExpense,_that.categoryBreakdown);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int year,  int month,  int totalIncome,  int totalExpense,  List<CategoryBreakdown> categoryBreakdown)  $default,) {final _that = this;
switch (_that) {
case _MonthlySummary():
return $default(_that.year,_that.month,_that.totalIncome,_that.totalExpense,_that.categoryBreakdown);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int year,  int month,  int totalIncome,  int totalExpense,  List<CategoryBreakdown> categoryBreakdown)?  $default,) {final _that = this;
switch (_that) {
case _MonthlySummary() when $default != null:
return $default(_that.year,_that.month,_that.totalIncome,_that.totalExpense,_that.categoryBreakdown);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MonthlySummary implements MonthlySummary {
  const _MonthlySummary({required this.year, required this.month, this.totalIncome = 0, this.totalExpense = 0, final  List<CategoryBreakdown> categoryBreakdown = const <CategoryBreakdown>[]}): _categoryBreakdown = categoryBreakdown;
  factory _MonthlySummary.fromJson(Map<String, dynamic> json) => _$MonthlySummaryFromJson(json);

@override final  int year;
@override final  int month;
@override@JsonKey() final  int totalIncome;
@override@JsonKey() final  int totalExpense;
 final  List<CategoryBreakdown> _categoryBreakdown;
@override@JsonKey() List<CategoryBreakdown> get categoryBreakdown {
  if (_categoryBreakdown is EqualUnmodifiableListView) return _categoryBreakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoryBreakdown);
}


/// Create a copy of MonthlySummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonthlySummaryCopyWith<_MonthlySummary> get copyWith => __$MonthlySummaryCopyWithImpl<_MonthlySummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MonthlySummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonthlySummary&&(identical(other.year, year) || other.year == year)&&(identical(other.month, month) || other.month == month)&&(identical(other.totalIncome, totalIncome) || other.totalIncome == totalIncome)&&(identical(other.totalExpense, totalExpense) || other.totalExpense == totalExpense)&&const DeepCollectionEquality().equals(other._categoryBreakdown, _categoryBreakdown));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,year,month,totalIncome,totalExpense,const DeepCollectionEquality().hash(_categoryBreakdown));

@override
String toString() {
  return 'MonthlySummary(year: $year, month: $month, totalIncome: $totalIncome, totalExpense: $totalExpense, categoryBreakdown: $categoryBreakdown)';
}


}

/// @nodoc
abstract mixin class _$MonthlySummaryCopyWith<$Res> implements $MonthlySummaryCopyWith<$Res> {
  factory _$MonthlySummaryCopyWith(_MonthlySummary value, $Res Function(_MonthlySummary) _then) = __$MonthlySummaryCopyWithImpl;
@override @useResult
$Res call({
 int year, int month, int totalIncome, int totalExpense, List<CategoryBreakdown> categoryBreakdown
});




}
/// @nodoc
class __$MonthlySummaryCopyWithImpl<$Res>
    implements _$MonthlySummaryCopyWith<$Res> {
  __$MonthlySummaryCopyWithImpl(this._self, this._then);

  final _MonthlySummary _self;
  final $Res Function(_MonthlySummary) _then;

/// Create a copy of MonthlySummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? year = null,Object? month = null,Object? totalIncome = null,Object? totalExpense = null,Object? categoryBreakdown = null,}) {
  return _then(_MonthlySummary(
year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,totalIncome: null == totalIncome ? _self.totalIncome : totalIncome // ignore: cast_nullable_to_non_nullable
as int,totalExpense: null == totalExpense ? _self.totalExpense : totalExpense // ignore: cast_nullable_to_non_nullable
as int,categoryBreakdown: null == categoryBreakdown ? _self._categoryBreakdown : categoryBreakdown // ignore: cast_nullable_to_non_nullable
as List<CategoryBreakdown>,
  ));
}


}


/// @nodoc
mixin _$MerchantSummary {

 String? get merchant; int get totalAmount; int get count;
/// Create a copy of MerchantSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MerchantSummaryCopyWith<MerchantSummary> get copyWith => _$MerchantSummaryCopyWithImpl<MerchantSummary>(this as MerchantSummary, _$identity);

  /// Serializes this MerchantSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MerchantSummary&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,merchant,totalAmount,count);

@override
String toString() {
  return 'MerchantSummary(merchant: $merchant, totalAmount: $totalAmount, count: $count)';
}


}

/// @nodoc
abstract mixin class $MerchantSummaryCopyWith<$Res>  {
  factory $MerchantSummaryCopyWith(MerchantSummary value, $Res Function(MerchantSummary) _then) = _$MerchantSummaryCopyWithImpl;
@useResult
$Res call({
 String? merchant, int totalAmount, int count
});




}
/// @nodoc
class _$MerchantSummaryCopyWithImpl<$Res>
    implements $MerchantSummaryCopyWith<$Res> {
  _$MerchantSummaryCopyWithImpl(this._self, this._then);

  final MerchantSummary _self;
  final $Res Function(MerchantSummary) _then;

/// Create a copy of MerchantSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? merchant = freezed,Object? totalAmount = null,Object? count = null,}) {
  return _then(_self.copyWith(
merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MerchantSummary].
extension MerchantSummaryPatterns on MerchantSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MerchantSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MerchantSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MerchantSummary value)  $default,){
final _that = this;
switch (_that) {
case _MerchantSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MerchantSummary value)?  $default,){
final _that = this;
switch (_that) {
case _MerchantSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? merchant,  int totalAmount,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MerchantSummary() when $default != null:
return $default(_that.merchant,_that.totalAmount,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? merchant,  int totalAmount,  int count)  $default,) {final _that = this;
switch (_that) {
case _MerchantSummary():
return $default(_that.merchant,_that.totalAmount,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? merchant,  int totalAmount,  int count)?  $default,) {final _that = this;
switch (_that) {
case _MerchantSummary() when $default != null:
return $default(_that.merchant,_that.totalAmount,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MerchantSummary implements MerchantSummary {
  const _MerchantSummary({this.merchant, this.totalAmount = 0, this.count = 0});
  factory _MerchantSummary.fromJson(Map<String, dynamic> json) => _$MerchantSummaryFromJson(json);

@override final  String? merchant;
@override@JsonKey() final  int totalAmount;
@override@JsonKey() final  int count;

/// Create a copy of MerchantSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MerchantSummaryCopyWith<_MerchantSummary> get copyWith => __$MerchantSummaryCopyWithImpl<_MerchantSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MerchantSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MerchantSummary&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,merchant,totalAmount,count);

@override
String toString() {
  return 'MerchantSummary(merchant: $merchant, totalAmount: $totalAmount, count: $count)';
}


}

/// @nodoc
abstract mixin class _$MerchantSummaryCopyWith<$Res> implements $MerchantSummaryCopyWith<$Res> {
  factory _$MerchantSummaryCopyWith(_MerchantSummary value, $Res Function(_MerchantSummary) _then) = __$MerchantSummaryCopyWithImpl;
@override @useResult
$Res call({
 String? merchant, int totalAmount, int count
});




}
/// @nodoc
class __$MerchantSummaryCopyWithImpl<$Res>
    implements _$MerchantSummaryCopyWith<$Res> {
  __$MerchantSummaryCopyWithImpl(this._self, this._then);

  final _MerchantSummary _self;
  final $Res Function(_MerchantSummary) _then;

/// Create a copy of MerchantSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? merchant = freezed,Object? totalAmount = null,Object? count = null,}) {
  return _then(_MerchantSummary(
merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AssetExpenseSummary {

 int? get assetRowId; String? get assetName; int get totalAmount; int get count;
/// Create a copy of AssetExpenseSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetExpenseSummaryCopyWith<AssetExpenseSummary> get copyWith => _$AssetExpenseSummaryCopyWithImpl<AssetExpenseSummary>(this as AssetExpenseSummary, _$identity);

  /// Serializes this AssetExpenseSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetExpenseSummary&&(identical(other.assetRowId, assetRowId) || other.assetRowId == assetRowId)&&(identical(other.assetName, assetName) || other.assetName == assetName)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,assetRowId,assetName,totalAmount,count);

@override
String toString() {
  return 'AssetExpenseSummary(assetRowId: $assetRowId, assetName: $assetName, totalAmount: $totalAmount, count: $count)';
}


}

/// @nodoc
abstract mixin class $AssetExpenseSummaryCopyWith<$Res>  {
  factory $AssetExpenseSummaryCopyWith(AssetExpenseSummary value, $Res Function(AssetExpenseSummary) _then) = _$AssetExpenseSummaryCopyWithImpl;
@useResult
$Res call({
 int? assetRowId, String? assetName, int totalAmount, int count
});




}
/// @nodoc
class _$AssetExpenseSummaryCopyWithImpl<$Res>
    implements $AssetExpenseSummaryCopyWith<$Res> {
  _$AssetExpenseSummaryCopyWithImpl(this._self, this._then);

  final AssetExpenseSummary _self;
  final $Res Function(AssetExpenseSummary) _then;

/// Create a copy of AssetExpenseSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? assetRowId = freezed,Object? assetName = freezed,Object? totalAmount = null,Object? count = null,}) {
  return _then(_self.copyWith(
assetRowId: freezed == assetRowId ? _self.assetRowId : assetRowId // ignore: cast_nullable_to_non_nullable
as int?,assetName: freezed == assetName ? _self.assetName : assetName // ignore: cast_nullable_to_non_nullable
as String?,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AssetExpenseSummary].
extension AssetExpenseSummaryPatterns on AssetExpenseSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssetExpenseSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssetExpenseSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssetExpenseSummary value)  $default,){
final _that = this;
switch (_that) {
case _AssetExpenseSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssetExpenseSummary value)?  $default,){
final _that = this;
switch (_that) {
case _AssetExpenseSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? assetRowId,  String? assetName,  int totalAmount,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssetExpenseSummary() when $default != null:
return $default(_that.assetRowId,_that.assetName,_that.totalAmount,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? assetRowId,  String? assetName,  int totalAmount,  int count)  $default,) {final _that = this;
switch (_that) {
case _AssetExpenseSummary():
return $default(_that.assetRowId,_that.assetName,_that.totalAmount,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? assetRowId,  String? assetName,  int totalAmount,  int count)?  $default,) {final _that = this;
switch (_that) {
case _AssetExpenseSummary() when $default != null:
return $default(_that.assetRowId,_that.assetName,_that.totalAmount,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssetExpenseSummary implements AssetExpenseSummary {
  const _AssetExpenseSummary({this.assetRowId, this.assetName, this.totalAmount = 0, this.count = 0});
  factory _AssetExpenseSummary.fromJson(Map<String, dynamic> json) => _$AssetExpenseSummaryFromJson(json);

@override final  int? assetRowId;
@override final  String? assetName;
@override@JsonKey() final  int totalAmount;
@override@JsonKey() final  int count;

/// Create a copy of AssetExpenseSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssetExpenseSummaryCopyWith<_AssetExpenseSummary> get copyWith => __$AssetExpenseSummaryCopyWithImpl<_AssetExpenseSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssetExpenseSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssetExpenseSummary&&(identical(other.assetRowId, assetRowId) || other.assetRowId == assetRowId)&&(identical(other.assetName, assetName) || other.assetName == assetName)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,assetRowId,assetName,totalAmount,count);

@override
String toString() {
  return 'AssetExpenseSummary(assetRowId: $assetRowId, assetName: $assetName, totalAmount: $totalAmount, count: $count)';
}


}

/// @nodoc
abstract mixin class _$AssetExpenseSummaryCopyWith<$Res> implements $AssetExpenseSummaryCopyWith<$Res> {
  factory _$AssetExpenseSummaryCopyWith(_AssetExpenseSummary value, $Res Function(_AssetExpenseSummary) _then) = __$AssetExpenseSummaryCopyWithImpl;
@override @useResult
$Res call({
 int? assetRowId, String? assetName, int totalAmount, int count
});




}
/// @nodoc
class __$AssetExpenseSummaryCopyWithImpl<$Res>
    implements _$AssetExpenseSummaryCopyWith<$Res> {
  __$AssetExpenseSummaryCopyWithImpl(this._self, this._then);

  final _AssetExpenseSummary _self;
  final $Res Function(_AssetExpenseSummary) _then;

/// Create a copy of AssetExpenseSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? assetRowId = freezed,Object? assetName = freezed,Object? totalAmount = null,Object? count = null,}) {
  return _then(_AssetExpenseSummary(
assetRowId: freezed == assetRowId ? _self.assetRowId : assetRowId // ignore: cast_nullable_to_non_nullable
as int?,assetName: freezed == assetName ? _self.assetName : assetName // ignore: cast_nullable_to_non_nullable
as String?,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$HeatmapCell {

 int get dayOfWeek;// 1=월 ~ 7=일 (백엔드 표기 따름)
 int get hour;// 0~23
 int get totalAmount;
/// Create a copy of HeatmapCell
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HeatmapCellCopyWith<HeatmapCell> get copyWith => _$HeatmapCellCopyWithImpl<HeatmapCell>(this as HeatmapCell, _$identity);

  /// Serializes this HeatmapCell to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HeatmapCell&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.hour, hour) || other.hour == hour)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dayOfWeek,hour,totalAmount);

@override
String toString() {
  return 'HeatmapCell(dayOfWeek: $dayOfWeek, hour: $hour, totalAmount: $totalAmount)';
}


}

/// @nodoc
abstract mixin class $HeatmapCellCopyWith<$Res>  {
  factory $HeatmapCellCopyWith(HeatmapCell value, $Res Function(HeatmapCell) _then) = _$HeatmapCellCopyWithImpl;
@useResult
$Res call({
 int dayOfWeek, int hour, int totalAmount
});




}
/// @nodoc
class _$HeatmapCellCopyWithImpl<$Res>
    implements $HeatmapCellCopyWith<$Res> {
  _$HeatmapCellCopyWithImpl(this._self, this._then);

  final HeatmapCell _self;
  final $Res Function(HeatmapCell) _then;

/// Create a copy of HeatmapCell
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dayOfWeek = null,Object? hour = null,Object? totalAmount = null,}) {
  return _then(_self.copyWith(
dayOfWeek: null == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int,hour: null == hour ? _self.hour : hour // ignore: cast_nullable_to_non_nullable
as int,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [HeatmapCell].
extension HeatmapCellPatterns on HeatmapCell {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HeatmapCell value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HeatmapCell() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HeatmapCell value)  $default,){
final _that = this;
switch (_that) {
case _HeatmapCell():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HeatmapCell value)?  $default,){
final _that = this;
switch (_that) {
case _HeatmapCell() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int dayOfWeek,  int hour,  int totalAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HeatmapCell() when $default != null:
return $default(_that.dayOfWeek,_that.hour,_that.totalAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int dayOfWeek,  int hour,  int totalAmount)  $default,) {final _that = this;
switch (_that) {
case _HeatmapCell():
return $default(_that.dayOfWeek,_that.hour,_that.totalAmount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int dayOfWeek,  int hour,  int totalAmount)?  $default,) {final _that = this;
switch (_that) {
case _HeatmapCell() when $default != null:
return $default(_that.dayOfWeek,_that.hour,_that.totalAmount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HeatmapCell implements HeatmapCell {
  const _HeatmapCell({required this.dayOfWeek, required this.hour, this.totalAmount = 0});
  factory _HeatmapCell.fromJson(Map<String, dynamic> json) => _$HeatmapCellFromJson(json);

@override final  int dayOfWeek;
// 1=월 ~ 7=일 (백엔드 표기 따름)
@override final  int hour;
// 0~23
@override@JsonKey() final  int totalAmount;

/// Create a copy of HeatmapCell
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HeatmapCellCopyWith<_HeatmapCell> get copyWith => __$HeatmapCellCopyWithImpl<_HeatmapCell>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HeatmapCellToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HeatmapCell&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.hour, hour) || other.hour == hour)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dayOfWeek,hour,totalAmount);

@override
String toString() {
  return 'HeatmapCell(dayOfWeek: $dayOfWeek, hour: $hour, totalAmount: $totalAmount)';
}


}

/// @nodoc
abstract mixin class _$HeatmapCellCopyWith<$Res> implements $HeatmapCellCopyWith<$Res> {
  factory _$HeatmapCellCopyWith(_HeatmapCell value, $Res Function(_HeatmapCell) _then) = __$HeatmapCellCopyWithImpl;
@override @useResult
$Res call({
 int dayOfWeek, int hour, int totalAmount
});




}
/// @nodoc
class __$HeatmapCellCopyWithImpl<$Res>
    implements _$HeatmapCellCopyWith<$Res> {
  __$HeatmapCellCopyWithImpl(this._self, this._then);

  final _HeatmapCell _self;
  final $Res Function(_HeatmapCell) _then;

/// Create a copy of HeatmapCell
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dayOfWeek = null,Object? hour = null,Object? totalAmount = null,}) {
  return _then(_HeatmapCell(
dayOfWeek: null == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int,hour: null == hour ? _self.hour : hour // ignore: cast_nullable_to_non_nullable
as int,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
