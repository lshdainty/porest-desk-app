// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saving_goal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SavingGoal {

 int get rowId; int? get userRowId; String get title; String? get description; int get targetAmount; int get currentAmount; String? get currency; String? get deadlineDate; String? get icon; String? get color; int? get linkedAssetRowId; int? get sortOrder; String? get isAchieved;// 'Y'|'N'
 String? get achievedAt;
/// Create a copy of SavingGoal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavingGoalCopyWith<SavingGoal> get copyWith => _$SavingGoalCopyWithImpl<SavingGoal>(this as SavingGoal, _$identity);

  /// Serializes this SavingGoal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavingGoal&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.targetAmount, targetAmount) || other.targetAmount == targetAmount)&&(identical(other.currentAmount, currentAmount) || other.currentAmount == currentAmount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.deadlineDate, deadlineDate) || other.deadlineDate == deadlineDate)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.linkedAssetRowId, linkedAssetRowId) || other.linkedAssetRowId == linkedAssetRowId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isAchieved, isAchieved) || other.isAchieved == isAchieved)&&(identical(other.achievedAt, achievedAt) || other.achievedAt == achievedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,userRowId,title,description,targetAmount,currentAmount,currency,deadlineDate,icon,color,linkedAssetRowId,sortOrder,isAchieved,achievedAt);

@override
String toString() {
  return 'SavingGoal(rowId: $rowId, userRowId: $userRowId, title: $title, description: $description, targetAmount: $targetAmount, currentAmount: $currentAmount, currency: $currency, deadlineDate: $deadlineDate, icon: $icon, color: $color, linkedAssetRowId: $linkedAssetRowId, sortOrder: $sortOrder, isAchieved: $isAchieved, achievedAt: $achievedAt)';
}


}

/// @nodoc
abstract mixin class $SavingGoalCopyWith<$Res>  {
  factory $SavingGoalCopyWith(SavingGoal value, $Res Function(SavingGoal) _then) = _$SavingGoalCopyWithImpl;
@useResult
$Res call({
 int rowId, int? userRowId, String title, String? description, int targetAmount, int currentAmount, String? currency, String? deadlineDate, String? icon, String? color, int? linkedAssetRowId, int? sortOrder, String? isAchieved, String? achievedAt
});




}
/// @nodoc
class _$SavingGoalCopyWithImpl<$Res>
    implements $SavingGoalCopyWith<$Res> {
  _$SavingGoalCopyWithImpl(this._self, this._then);

  final SavingGoal _self;
  final $Res Function(SavingGoal) _then;

/// Create a copy of SavingGoal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = null,Object? userRowId = freezed,Object? title = null,Object? description = freezed,Object? targetAmount = null,Object? currentAmount = null,Object? currency = freezed,Object? deadlineDate = freezed,Object? icon = freezed,Object? color = freezed,Object? linkedAssetRowId = freezed,Object? sortOrder = freezed,Object? isAchieved = freezed,Object? achievedAt = freezed,}) {
  return _then(_self.copyWith(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,targetAmount: null == targetAmount ? _self.targetAmount : targetAmount // ignore: cast_nullable_to_non_nullable
as int,currentAmount: null == currentAmount ? _self.currentAmount : currentAmount // ignore: cast_nullable_to_non_nullable
as int,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,deadlineDate: freezed == deadlineDate ? _self.deadlineDate : deadlineDate // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,linkedAssetRowId: freezed == linkedAssetRowId ? _self.linkedAssetRowId : linkedAssetRowId // ignore: cast_nullable_to_non_nullable
as int?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,isAchieved: freezed == isAchieved ? _self.isAchieved : isAchieved // ignore: cast_nullable_to_non_nullable
as String?,achievedAt: freezed == achievedAt ? _self.achievedAt : achievedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SavingGoal].
extension SavingGoalPatterns on SavingGoal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavingGoal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavingGoal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavingGoal value)  $default,){
final _that = this;
switch (_that) {
case _SavingGoal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavingGoal value)?  $default,){
final _that = this;
switch (_that) {
case _SavingGoal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  String title,  String? description,  int targetAmount,  int currentAmount,  String? currency,  String? deadlineDate,  String? icon,  String? color,  int? linkedAssetRowId,  int? sortOrder,  String? isAchieved,  String? achievedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavingGoal() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.title,_that.description,_that.targetAmount,_that.currentAmount,_that.currency,_that.deadlineDate,_that.icon,_that.color,_that.linkedAssetRowId,_that.sortOrder,_that.isAchieved,_that.achievedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  String title,  String? description,  int targetAmount,  int currentAmount,  String? currency,  String? deadlineDate,  String? icon,  String? color,  int? linkedAssetRowId,  int? sortOrder,  String? isAchieved,  String? achievedAt)  $default,) {final _that = this;
switch (_that) {
case _SavingGoal():
return $default(_that.rowId,_that.userRowId,_that.title,_that.description,_that.targetAmount,_that.currentAmount,_that.currency,_that.deadlineDate,_that.icon,_that.color,_that.linkedAssetRowId,_that.sortOrder,_that.isAchieved,_that.achievedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowId,  int? userRowId,  String title,  String? description,  int targetAmount,  int currentAmount,  String? currency,  String? deadlineDate,  String? icon,  String? color,  int? linkedAssetRowId,  int? sortOrder,  String? isAchieved,  String? achievedAt)?  $default,) {final _that = this;
switch (_that) {
case _SavingGoal() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.title,_that.description,_that.targetAmount,_that.currentAmount,_that.currency,_that.deadlineDate,_that.icon,_that.color,_that.linkedAssetRowId,_that.sortOrder,_that.isAchieved,_that.achievedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SavingGoal implements SavingGoal {
  const _SavingGoal({required this.rowId, this.userRowId, required this.title, this.description, required this.targetAmount, this.currentAmount = 0, this.currency, this.deadlineDate, this.icon, this.color, this.linkedAssetRowId, this.sortOrder, this.isAchieved, this.achievedAt});
  factory _SavingGoal.fromJson(Map<String, dynamic> json) => _$SavingGoalFromJson(json);

@override final  int rowId;
@override final  int? userRowId;
@override final  String title;
@override final  String? description;
@override final  int targetAmount;
@override@JsonKey() final  int currentAmount;
@override final  String? currency;
@override final  String? deadlineDate;
@override final  String? icon;
@override final  String? color;
@override final  int? linkedAssetRowId;
@override final  int? sortOrder;
@override final  String? isAchieved;
// 'Y'|'N'
@override final  String? achievedAt;

/// Create a copy of SavingGoal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavingGoalCopyWith<_SavingGoal> get copyWith => __$SavingGoalCopyWithImpl<_SavingGoal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SavingGoalToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavingGoal&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.targetAmount, targetAmount) || other.targetAmount == targetAmount)&&(identical(other.currentAmount, currentAmount) || other.currentAmount == currentAmount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.deadlineDate, deadlineDate) || other.deadlineDate == deadlineDate)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.linkedAssetRowId, linkedAssetRowId) || other.linkedAssetRowId == linkedAssetRowId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isAchieved, isAchieved) || other.isAchieved == isAchieved)&&(identical(other.achievedAt, achievedAt) || other.achievedAt == achievedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,userRowId,title,description,targetAmount,currentAmount,currency,deadlineDate,icon,color,linkedAssetRowId,sortOrder,isAchieved,achievedAt);

@override
String toString() {
  return 'SavingGoal(rowId: $rowId, userRowId: $userRowId, title: $title, description: $description, targetAmount: $targetAmount, currentAmount: $currentAmount, currency: $currency, deadlineDate: $deadlineDate, icon: $icon, color: $color, linkedAssetRowId: $linkedAssetRowId, sortOrder: $sortOrder, isAchieved: $isAchieved, achievedAt: $achievedAt)';
}


}

/// @nodoc
abstract mixin class _$SavingGoalCopyWith<$Res> implements $SavingGoalCopyWith<$Res> {
  factory _$SavingGoalCopyWith(_SavingGoal value, $Res Function(_SavingGoal) _then) = __$SavingGoalCopyWithImpl;
@override @useResult
$Res call({
 int rowId, int? userRowId, String title, String? description, int targetAmount, int currentAmount, String? currency, String? deadlineDate, String? icon, String? color, int? linkedAssetRowId, int? sortOrder, String? isAchieved, String? achievedAt
});




}
/// @nodoc
class __$SavingGoalCopyWithImpl<$Res>
    implements _$SavingGoalCopyWith<$Res> {
  __$SavingGoalCopyWithImpl(this._self, this._then);

  final _SavingGoal _self;
  final $Res Function(_SavingGoal) _then;

/// Create a copy of SavingGoal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = null,Object? userRowId = freezed,Object? title = null,Object? description = freezed,Object? targetAmount = null,Object? currentAmount = null,Object? currency = freezed,Object? deadlineDate = freezed,Object? icon = freezed,Object? color = freezed,Object? linkedAssetRowId = freezed,Object? sortOrder = freezed,Object? isAchieved = freezed,Object? achievedAt = freezed,}) {
  return _then(_SavingGoal(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,targetAmount: null == targetAmount ? _self.targetAmount : targetAmount // ignore: cast_nullable_to_non_nullable
as int,currentAmount: null == currentAmount ? _self.currentAmount : currentAmount // ignore: cast_nullable_to_non_nullable
as int,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,deadlineDate: freezed == deadlineDate ? _self.deadlineDate : deadlineDate // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,linkedAssetRowId: freezed == linkedAssetRowId ? _self.linkedAssetRowId : linkedAssetRowId // ignore: cast_nullable_to_non_nullable
as int?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,isAchieved: freezed == isAchieved ? _self.isAchieved : isAchieved // ignore: cast_nullable_to_non_nullable
as String?,achievedAt: freezed == achievedAt ? _self.achievedAt : achievedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
