// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expense_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExpenseTemplate {

 int get rowId; int? get userRowId; String get templateName; int get categoryRowId; String? get categoryName; int get assetRowId; String? get assetName; String get expenseType; int get amount; String? get description; String? get merchant; String? get paymentMethod; int? get useCount; int? get sortOrder; String? get lockAmount;// 'Y' | 'N'
 String? get lastUsedAt; String? get createAt; String? get modifyAt;
/// Create a copy of ExpenseTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseTemplateCopyWith<ExpenseTemplate> get copyWith => _$ExpenseTemplateCopyWithImpl<ExpenseTemplate>(this as ExpenseTemplate, _$identity);

  /// Serializes this ExpenseTemplate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpenseTemplate&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.templateName, templateName) || other.templateName == templateName)&&(identical(other.categoryRowId, categoryRowId) || other.categoryRowId == categoryRowId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.assetRowId, assetRowId) || other.assetRowId == assetRowId)&&(identical(other.assetName, assetName) || other.assetName == assetName)&&(identical(other.expenseType, expenseType) || other.expenseType == expenseType)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.description, description) || other.description == description)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.useCount, useCount) || other.useCount == useCount)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.lockAmount, lockAmount) || other.lockAmount == lockAmount)&&(identical(other.lastUsedAt, lastUsedAt) || other.lastUsedAt == lastUsedAt)&&(identical(other.createAt, createAt) || other.createAt == createAt)&&(identical(other.modifyAt, modifyAt) || other.modifyAt == modifyAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,userRowId,templateName,categoryRowId,categoryName,assetRowId,assetName,expenseType,amount,description,merchant,paymentMethod,useCount,sortOrder,lockAmount,lastUsedAt,createAt,modifyAt);

@override
String toString() {
  return 'ExpenseTemplate(rowId: $rowId, userRowId: $userRowId, templateName: $templateName, categoryRowId: $categoryRowId, categoryName: $categoryName, assetRowId: $assetRowId, assetName: $assetName, expenseType: $expenseType, amount: $amount, description: $description, merchant: $merchant, paymentMethod: $paymentMethod, useCount: $useCount, sortOrder: $sortOrder, lockAmount: $lockAmount, lastUsedAt: $lastUsedAt, createAt: $createAt, modifyAt: $modifyAt)';
}


}

/// @nodoc
abstract mixin class $ExpenseTemplateCopyWith<$Res>  {
  factory $ExpenseTemplateCopyWith(ExpenseTemplate value, $Res Function(ExpenseTemplate) _then) = _$ExpenseTemplateCopyWithImpl;
@useResult
$Res call({
 int rowId, int? userRowId, String templateName, int categoryRowId, String? categoryName, int assetRowId, String? assetName, String expenseType, int amount, String? description, String? merchant, String? paymentMethod, int? useCount, int? sortOrder, String? lockAmount, String? lastUsedAt, String? createAt, String? modifyAt
});




}
/// @nodoc
class _$ExpenseTemplateCopyWithImpl<$Res>
    implements $ExpenseTemplateCopyWith<$Res> {
  _$ExpenseTemplateCopyWithImpl(this._self, this._then);

  final ExpenseTemplate _self;
  final $Res Function(ExpenseTemplate) _then;

/// Create a copy of ExpenseTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = null,Object? userRowId = freezed,Object? templateName = null,Object? categoryRowId = null,Object? categoryName = freezed,Object? assetRowId = null,Object? assetName = freezed,Object? expenseType = null,Object? amount = null,Object? description = freezed,Object? merchant = freezed,Object? paymentMethod = freezed,Object? useCount = freezed,Object? sortOrder = freezed,Object? lockAmount = freezed,Object? lastUsedAt = freezed,Object? createAt = freezed,Object? modifyAt = freezed,}) {
  return _then(_self.copyWith(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,templateName: null == templateName ? _self.templateName : templateName // ignore: cast_nullable_to_non_nullable
as String,categoryRowId: null == categoryRowId ? _self.categoryRowId : categoryRowId // ignore: cast_nullable_to_non_nullable
as int,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,assetRowId: null == assetRowId ? _self.assetRowId : assetRowId // ignore: cast_nullable_to_non_nullable
as int,assetName: freezed == assetName ? _self.assetName : assetName // ignore: cast_nullable_to_non_nullable
as String?,expenseType: null == expenseType ? _self.expenseType : expenseType // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,useCount: freezed == useCount ? _self.useCount : useCount // ignore: cast_nullable_to_non_nullable
as int?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,lockAmount: freezed == lockAmount ? _self.lockAmount : lockAmount // ignore: cast_nullable_to_non_nullable
as String?,lastUsedAt: freezed == lastUsedAt ? _self.lastUsedAt : lastUsedAt // ignore: cast_nullable_to_non_nullable
as String?,createAt: freezed == createAt ? _self.createAt : createAt // ignore: cast_nullable_to_non_nullable
as String?,modifyAt: freezed == modifyAt ? _self.modifyAt : modifyAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExpenseTemplate].
extension ExpenseTemplatePatterns on ExpenseTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExpenseTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExpenseTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExpenseTemplate value)  $default,){
final _that = this;
switch (_that) {
case _ExpenseTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExpenseTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _ExpenseTemplate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  String templateName,  int categoryRowId,  String? categoryName,  int assetRowId,  String? assetName,  String expenseType,  int amount,  String? description,  String? merchant,  String? paymentMethod,  int? useCount,  int? sortOrder,  String? lockAmount,  String? lastUsedAt,  String? createAt,  String? modifyAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExpenseTemplate() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.templateName,_that.categoryRowId,_that.categoryName,_that.assetRowId,_that.assetName,_that.expenseType,_that.amount,_that.description,_that.merchant,_that.paymentMethod,_that.useCount,_that.sortOrder,_that.lockAmount,_that.lastUsedAt,_that.createAt,_that.modifyAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  String templateName,  int categoryRowId,  String? categoryName,  int assetRowId,  String? assetName,  String expenseType,  int amount,  String? description,  String? merchant,  String? paymentMethod,  int? useCount,  int? sortOrder,  String? lockAmount,  String? lastUsedAt,  String? createAt,  String? modifyAt)  $default,) {final _that = this;
switch (_that) {
case _ExpenseTemplate():
return $default(_that.rowId,_that.userRowId,_that.templateName,_that.categoryRowId,_that.categoryName,_that.assetRowId,_that.assetName,_that.expenseType,_that.amount,_that.description,_that.merchant,_that.paymentMethod,_that.useCount,_that.sortOrder,_that.lockAmount,_that.lastUsedAt,_that.createAt,_that.modifyAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowId,  int? userRowId,  String templateName,  int categoryRowId,  String? categoryName,  int assetRowId,  String? assetName,  String expenseType,  int amount,  String? description,  String? merchant,  String? paymentMethod,  int? useCount,  int? sortOrder,  String? lockAmount,  String? lastUsedAt,  String? createAt,  String? modifyAt)?  $default,) {final _that = this;
switch (_that) {
case _ExpenseTemplate() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.templateName,_that.categoryRowId,_that.categoryName,_that.assetRowId,_that.assetName,_that.expenseType,_that.amount,_that.description,_that.merchant,_that.paymentMethod,_that.useCount,_that.sortOrder,_that.lockAmount,_that.lastUsedAt,_that.createAt,_that.modifyAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExpenseTemplate implements ExpenseTemplate {
  const _ExpenseTemplate({required this.rowId, this.userRowId, required this.templateName, required this.categoryRowId, this.categoryName, required this.assetRowId, this.assetName, required this.expenseType, required this.amount, this.description, this.merchant, this.paymentMethod, this.useCount, this.sortOrder, this.lockAmount, this.lastUsedAt, this.createAt, this.modifyAt});
  factory _ExpenseTemplate.fromJson(Map<String, dynamic> json) => _$ExpenseTemplateFromJson(json);

@override final  int rowId;
@override final  int? userRowId;
@override final  String templateName;
@override final  int categoryRowId;
@override final  String? categoryName;
@override final  int assetRowId;
@override final  String? assetName;
@override final  String expenseType;
@override final  int amount;
@override final  String? description;
@override final  String? merchant;
@override final  String? paymentMethod;
@override final  int? useCount;
@override final  int? sortOrder;
@override final  String? lockAmount;
// 'Y' | 'N'
@override final  String? lastUsedAt;
@override final  String? createAt;
@override final  String? modifyAt;

/// Create a copy of ExpenseTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseTemplateCopyWith<_ExpenseTemplate> get copyWith => __$ExpenseTemplateCopyWithImpl<_ExpenseTemplate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExpenseTemplateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExpenseTemplate&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.templateName, templateName) || other.templateName == templateName)&&(identical(other.categoryRowId, categoryRowId) || other.categoryRowId == categoryRowId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.assetRowId, assetRowId) || other.assetRowId == assetRowId)&&(identical(other.assetName, assetName) || other.assetName == assetName)&&(identical(other.expenseType, expenseType) || other.expenseType == expenseType)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.description, description) || other.description == description)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.useCount, useCount) || other.useCount == useCount)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.lockAmount, lockAmount) || other.lockAmount == lockAmount)&&(identical(other.lastUsedAt, lastUsedAt) || other.lastUsedAt == lastUsedAt)&&(identical(other.createAt, createAt) || other.createAt == createAt)&&(identical(other.modifyAt, modifyAt) || other.modifyAt == modifyAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,userRowId,templateName,categoryRowId,categoryName,assetRowId,assetName,expenseType,amount,description,merchant,paymentMethod,useCount,sortOrder,lockAmount,lastUsedAt,createAt,modifyAt);

@override
String toString() {
  return 'ExpenseTemplate(rowId: $rowId, userRowId: $userRowId, templateName: $templateName, categoryRowId: $categoryRowId, categoryName: $categoryName, assetRowId: $assetRowId, assetName: $assetName, expenseType: $expenseType, amount: $amount, description: $description, merchant: $merchant, paymentMethod: $paymentMethod, useCount: $useCount, sortOrder: $sortOrder, lockAmount: $lockAmount, lastUsedAt: $lastUsedAt, createAt: $createAt, modifyAt: $modifyAt)';
}


}

/// @nodoc
abstract mixin class _$ExpenseTemplateCopyWith<$Res> implements $ExpenseTemplateCopyWith<$Res> {
  factory _$ExpenseTemplateCopyWith(_ExpenseTemplate value, $Res Function(_ExpenseTemplate) _then) = __$ExpenseTemplateCopyWithImpl;
@override @useResult
$Res call({
 int rowId, int? userRowId, String templateName, int categoryRowId, String? categoryName, int assetRowId, String? assetName, String expenseType, int amount, String? description, String? merchant, String? paymentMethod, int? useCount, int? sortOrder, String? lockAmount, String? lastUsedAt, String? createAt, String? modifyAt
});




}
/// @nodoc
class __$ExpenseTemplateCopyWithImpl<$Res>
    implements _$ExpenseTemplateCopyWith<$Res> {
  __$ExpenseTemplateCopyWithImpl(this._self, this._then);

  final _ExpenseTemplate _self;
  final $Res Function(_ExpenseTemplate) _then;

/// Create a copy of ExpenseTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = null,Object? userRowId = freezed,Object? templateName = null,Object? categoryRowId = null,Object? categoryName = freezed,Object? assetRowId = null,Object? assetName = freezed,Object? expenseType = null,Object? amount = null,Object? description = freezed,Object? merchant = freezed,Object? paymentMethod = freezed,Object? useCount = freezed,Object? sortOrder = freezed,Object? lockAmount = freezed,Object? lastUsedAt = freezed,Object? createAt = freezed,Object? modifyAt = freezed,}) {
  return _then(_ExpenseTemplate(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,templateName: null == templateName ? _self.templateName : templateName // ignore: cast_nullable_to_non_nullable
as String,categoryRowId: null == categoryRowId ? _self.categoryRowId : categoryRowId // ignore: cast_nullable_to_non_nullable
as int,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,assetRowId: null == assetRowId ? _self.assetRowId : assetRowId // ignore: cast_nullable_to_non_nullable
as int,assetName: freezed == assetName ? _self.assetName : assetName // ignore: cast_nullable_to_non_nullable
as String?,expenseType: null == expenseType ? _self.expenseType : expenseType // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,useCount: freezed == useCount ? _self.useCount : useCount // ignore: cast_nullable_to_non_nullable
as int?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,lockAmount: freezed == lockAmount ? _self.lockAmount : lockAmount // ignore: cast_nullable_to_non_nullable
as String?,lastUsedAt: freezed == lastUsedAt ? _self.lastUsedAt : lastUsedAt // ignore: cast_nullable_to_non_nullable
as String?,createAt: freezed == createAt ? _self.createAt : createAt // ignore: cast_nullable_to_non_nullable
as String?,modifyAt: freezed == modifyAt ? _self.modifyAt : modifyAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
