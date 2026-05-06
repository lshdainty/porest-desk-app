// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'card_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CardCompany {

 int? get rowId; String? get name; String? get nameEng; String? get logoUrl;
/// Create a copy of CardCompany
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardCompanyCopyWith<CardCompany> get copyWith => _$CardCompanyCopyWithImpl<CardCompany>(this as CardCompany, _$identity);

  /// Serializes this CardCompany to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardCompany&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameEng, nameEng) || other.nameEng == nameEng)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,name,nameEng,logoUrl);

@override
String toString() {
  return 'CardCompany(rowId: $rowId, name: $name, nameEng: $nameEng, logoUrl: $logoUrl)';
}


}

/// @nodoc
abstract mixin class $CardCompanyCopyWith<$Res>  {
  factory $CardCompanyCopyWith(CardCompany value, $Res Function(CardCompany) _then) = _$CardCompanyCopyWithImpl;
@useResult
$Res call({
 int? rowId, String? name, String? nameEng, String? logoUrl
});




}
/// @nodoc
class _$CardCompanyCopyWithImpl<$Res>
    implements $CardCompanyCopyWith<$Res> {
  _$CardCompanyCopyWithImpl(this._self, this._then);

  final CardCompany _self;
  final $Res Function(CardCompany) _then;

/// Create a copy of CardCompany
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = freezed,Object? name = freezed,Object? nameEng = freezed,Object? logoUrl = freezed,}) {
  return _then(_self.copyWith(
rowId: freezed == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,nameEng: freezed == nameEng ? _self.nameEng : nameEng // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CardCompany].
extension CardCompanyPatterns on CardCompany {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardCompany value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardCompany() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardCompany value)  $default,){
final _that = this;
switch (_that) {
case _CardCompany():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardCompany value)?  $default,){
final _that = this;
switch (_that) {
case _CardCompany() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? rowId,  String? name,  String? nameEng,  String? logoUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardCompany() when $default != null:
return $default(_that.rowId,_that.name,_that.nameEng,_that.logoUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? rowId,  String? name,  String? nameEng,  String? logoUrl)  $default,) {final _that = this;
switch (_that) {
case _CardCompany():
return $default(_that.rowId,_that.name,_that.nameEng,_that.logoUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? rowId,  String? name,  String? nameEng,  String? logoUrl)?  $default,) {final _that = this;
switch (_that) {
case _CardCompany() when $default != null:
return $default(_that.rowId,_that.name,_that.nameEng,_that.logoUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CardCompany implements CardCompany {
  const _CardCompany({this.rowId, this.name, this.nameEng, this.logoUrl});
  factory _CardCompany.fromJson(Map<String, dynamic> json) => _$CardCompanyFromJson(json);

@override final  int? rowId;
@override final  String? name;
@override final  String? nameEng;
@override final  String? logoUrl;

/// Create a copy of CardCompany
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardCompanyCopyWith<_CardCompany> get copyWith => __$CardCompanyCopyWithImpl<_CardCompany>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CardCompanyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardCompany&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameEng, nameEng) || other.nameEng == nameEng)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,name,nameEng,logoUrl);

@override
String toString() {
  return 'CardCompany(rowId: $rowId, name: $name, nameEng: $nameEng, logoUrl: $logoUrl)';
}


}

/// @nodoc
abstract mixin class _$CardCompanyCopyWith<$Res> implements $CardCompanyCopyWith<$Res> {
  factory _$CardCompanyCopyWith(_CardCompany value, $Res Function(_CardCompany) _then) = __$CardCompanyCopyWithImpl;
@override @useResult
$Res call({
 int? rowId, String? name, String? nameEng, String? logoUrl
});




}
/// @nodoc
class __$CardCompanyCopyWithImpl<$Res>
    implements _$CardCompanyCopyWith<$Res> {
  __$CardCompanyCopyWithImpl(this._self, this._then);

  final _CardCompany _self;
  final $Res Function(_CardCompany) _then;

/// Create a copy of CardCompany
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = freezed,Object? name = freezed,Object? nameEng = freezed,Object? logoUrl = freezed,}) {
  return _then(_CardCompany(
rowId: freezed == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,nameEng: freezed == nameEng ? _self.nameEng : nameEng // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CardAnnualFee {

 int? get amount; String? get label;
/// Create a copy of CardAnnualFee
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardAnnualFeeCopyWith<CardAnnualFee> get copyWith => _$CardAnnualFeeCopyWithImpl<CardAnnualFee>(this as CardAnnualFee, _$identity);

  /// Serializes this CardAnnualFee to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardAnnualFee&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amount,label);

@override
String toString() {
  return 'CardAnnualFee(amount: $amount, label: $label)';
}


}

/// @nodoc
abstract mixin class $CardAnnualFeeCopyWith<$Res>  {
  factory $CardAnnualFeeCopyWith(CardAnnualFee value, $Res Function(CardAnnualFee) _then) = _$CardAnnualFeeCopyWithImpl;
@useResult
$Res call({
 int? amount, String? label
});




}
/// @nodoc
class _$CardAnnualFeeCopyWithImpl<$Res>
    implements $CardAnnualFeeCopyWith<$Res> {
  _$CardAnnualFeeCopyWithImpl(this._self, this._then);

  final CardAnnualFee _self;
  final $Res Function(CardAnnualFee) _then;

/// Create a copy of CardAnnualFee
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = freezed,Object? label = freezed,}) {
  return _then(_self.copyWith(
amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int?,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CardAnnualFee].
extension CardAnnualFeePatterns on CardAnnualFee {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardAnnualFee value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardAnnualFee() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardAnnualFee value)  $default,){
final _that = this;
switch (_that) {
case _CardAnnualFee():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardAnnualFee value)?  $default,){
final _that = this;
switch (_that) {
case _CardAnnualFee() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? amount,  String? label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardAnnualFee() when $default != null:
return $default(_that.amount,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? amount,  String? label)  $default,) {final _that = this;
switch (_that) {
case _CardAnnualFee():
return $default(_that.amount,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? amount,  String? label)?  $default,) {final _that = this;
switch (_that) {
case _CardAnnualFee() when $default != null:
return $default(_that.amount,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CardAnnualFee implements CardAnnualFee {
  const _CardAnnualFee({this.amount, this.label});
  factory _CardAnnualFee.fromJson(Map<String, dynamic> json) => _$CardAnnualFeeFromJson(json);

@override final  int? amount;
@override final  String? label;

/// Create a copy of CardAnnualFee
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardAnnualFeeCopyWith<_CardAnnualFee> get copyWith => __$CardAnnualFeeCopyWithImpl<_CardAnnualFee>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CardAnnualFeeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardAnnualFee&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amount,label);

@override
String toString() {
  return 'CardAnnualFee(amount: $amount, label: $label)';
}


}

/// @nodoc
abstract mixin class _$CardAnnualFeeCopyWith<$Res> implements $CardAnnualFeeCopyWith<$Res> {
  factory _$CardAnnualFeeCopyWith(_CardAnnualFee value, $Res Function(_CardAnnualFee) _then) = __$CardAnnualFeeCopyWithImpl;
@override @useResult
$Res call({
 int? amount, String? label
});




}
/// @nodoc
class __$CardAnnualFeeCopyWithImpl<$Res>
    implements _$CardAnnualFeeCopyWith<$Res> {
  __$CardAnnualFeeCopyWithImpl(this._self, this._then);

  final _CardAnnualFee _self;
  final $Res Function(_CardAnnualFee) _then;

/// Create a copy of CardAnnualFee
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = freezed,Object? label = freezed,}) {
  return _then(_CardAnnualFee(
amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int?,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CardPerformance {

 int? get requiredAmount; String? get requiredText; String? get isRequired;
/// Create a copy of CardPerformance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardPerformanceCopyWith<CardPerformance> get copyWith => _$CardPerformanceCopyWithImpl<CardPerformance>(this as CardPerformance, _$identity);

  /// Serializes this CardPerformance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardPerformance&&(identical(other.requiredAmount, requiredAmount) || other.requiredAmount == requiredAmount)&&(identical(other.requiredText, requiredText) || other.requiredText == requiredText)&&(identical(other.isRequired, isRequired) || other.isRequired == isRequired));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requiredAmount,requiredText,isRequired);

@override
String toString() {
  return 'CardPerformance(requiredAmount: $requiredAmount, requiredText: $requiredText, isRequired: $isRequired)';
}


}

/// @nodoc
abstract mixin class $CardPerformanceCopyWith<$Res>  {
  factory $CardPerformanceCopyWith(CardPerformance value, $Res Function(CardPerformance) _then) = _$CardPerformanceCopyWithImpl;
@useResult
$Res call({
 int? requiredAmount, String? requiredText, String? isRequired
});




}
/// @nodoc
class _$CardPerformanceCopyWithImpl<$Res>
    implements $CardPerformanceCopyWith<$Res> {
  _$CardPerformanceCopyWithImpl(this._self, this._then);

  final CardPerformance _self;
  final $Res Function(CardPerformance) _then;

/// Create a copy of CardPerformance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requiredAmount = freezed,Object? requiredText = freezed,Object? isRequired = freezed,}) {
  return _then(_self.copyWith(
requiredAmount: freezed == requiredAmount ? _self.requiredAmount : requiredAmount // ignore: cast_nullable_to_non_nullable
as int?,requiredText: freezed == requiredText ? _self.requiredText : requiredText // ignore: cast_nullable_to_non_nullable
as String?,isRequired: freezed == isRequired ? _self.isRequired : isRequired // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CardPerformance].
extension CardPerformancePatterns on CardPerformance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardPerformance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardPerformance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardPerformance value)  $default,){
final _that = this;
switch (_that) {
case _CardPerformance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardPerformance value)?  $default,){
final _that = this;
switch (_that) {
case _CardPerformance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? requiredAmount,  String? requiredText,  String? isRequired)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardPerformance() when $default != null:
return $default(_that.requiredAmount,_that.requiredText,_that.isRequired);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? requiredAmount,  String? requiredText,  String? isRequired)  $default,) {final _that = this;
switch (_that) {
case _CardPerformance():
return $default(_that.requiredAmount,_that.requiredText,_that.isRequired);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? requiredAmount,  String? requiredText,  String? isRequired)?  $default,) {final _that = this;
switch (_that) {
case _CardPerformance() when $default != null:
return $default(_that.requiredAmount,_that.requiredText,_that.isRequired);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CardPerformance implements CardPerformance {
  const _CardPerformance({this.requiredAmount, this.requiredText, this.isRequired});
  factory _CardPerformance.fromJson(Map<String, dynamic> json) => _$CardPerformanceFromJson(json);

@override final  int? requiredAmount;
@override final  String? requiredText;
@override final  String? isRequired;

/// Create a copy of CardPerformance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardPerformanceCopyWith<_CardPerformance> get copyWith => __$CardPerformanceCopyWithImpl<_CardPerformance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CardPerformanceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardPerformance&&(identical(other.requiredAmount, requiredAmount) || other.requiredAmount == requiredAmount)&&(identical(other.requiredText, requiredText) || other.requiredText == requiredText)&&(identical(other.isRequired, isRequired) || other.isRequired == isRequired));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requiredAmount,requiredText,isRequired);

@override
String toString() {
  return 'CardPerformance(requiredAmount: $requiredAmount, requiredText: $requiredText, isRequired: $isRequired)';
}


}

/// @nodoc
abstract mixin class _$CardPerformanceCopyWith<$Res> implements $CardPerformanceCopyWith<$Res> {
  factory _$CardPerformanceCopyWith(_CardPerformance value, $Res Function(_CardPerformance) _then) = __$CardPerformanceCopyWithImpl;
@override @useResult
$Res call({
 int? requiredAmount, String? requiredText, String? isRequired
});




}
/// @nodoc
class __$CardPerformanceCopyWithImpl<$Res>
    implements _$CardPerformanceCopyWith<$Res> {
  __$CardPerformanceCopyWithImpl(this._self, this._then);

  final _CardPerformance _self;
  final $Res Function(_CardPerformance) _then;

/// Create a copy of CardPerformance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requiredAmount = freezed,Object? requiredText = freezed,Object? isRequired = freezed,}) {
  return _then(_CardPerformance(
requiredAmount: freezed == requiredAmount ? _self.requiredAmount : requiredAmount // ignore: cast_nullable_to_non_nullable
as int?,requiredText: freezed == requiredText ? _self.requiredText : requiredText // ignore: cast_nullable_to_non_nullable
as String?,isRequired: freezed == isRequired ? _self.isRequired : isRequired // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CardCatalogSummary {

 int get rowId; int? get externalCardId; CardCompany? get company; String get cardName; String? get cardType;// CREDIT/CHECK
 String? get benefitType; String? get isDiscontinued; String? get onlyOnline; String? get launchDate; String? get imgUrl; String? get detailUrl; CardAnnualFee? get annualFee; CardPerformance? get performance;
/// Create a copy of CardCatalogSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardCatalogSummaryCopyWith<CardCatalogSummary> get copyWith => _$CardCatalogSummaryCopyWithImpl<CardCatalogSummary>(this as CardCatalogSummary, _$identity);

  /// Serializes this CardCatalogSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardCatalogSummary&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.externalCardId, externalCardId) || other.externalCardId == externalCardId)&&(identical(other.company, company) || other.company == company)&&(identical(other.cardName, cardName) || other.cardName == cardName)&&(identical(other.cardType, cardType) || other.cardType == cardType)&&(identical(other.benefitType, benefitType) || other.benefitType == benefitType)&&(identical(other.isDiscontinued, isDiscontinued) || other.isDiscontinued == isDiscontinued)&&(identical(other.onlyOnline, onlyOnline) || other.onlyOnline == onlyOnline)&&(identical(other.launchDate, launchDate) || other.launchDate == launchDate)&&(identical(other.imgUrl, imgUrl) || other.imgUrl == imgUrl)&&(identical(other.detailUrl, detailUrl) || other.detailUrl == detailUrl)&&(identical(other.annualFee, annualFee) || other.annualFee == annualFee)&&(identical(other.performance, performance) || other.performance == performance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,externalCardId,company,cardName,cardType,benefitType,isDiscontinued,onlyOnline,launchDate,imgUrl,detailUrl,annualFee,performance);

@override
String toString() {
  return 'CardCatalogSummary(rowId: $rowId, externalCardId: $externalCardId, company: $company, cardName: $cardName, cardType: $cardType, benefitType: $benefitType, isDiscontinued: $isDiscontinued, onlyOnline: $onlyOnline, launchDate: $launchDate, imgUrl: $imgUrl, detailUrl: $detailUrl, annualFee: $annualFee, performance: $performance)';
}


}

/// @nodoc
abstract mixin class $CardCatalogSummaryCopyWith<$Res>  {
  factory $CardCatalogSummaryCopyWith(CardCatalogSummary value, $Res Function(CardCatalogSummary) _then) = _$CardCatalogSummaryCopyWithImpl;
@useResult
$Res call({
 int rowId, int? externalCardId, CardCompany? company, String cardName, String? cardType, String? benefitType, String? isDiscontinued, String? onlyOnline, String? launchDate, String? imgUrl, String? detailUrl, CardAnnualFee? annualFee, CardPerformance? performance
});


$CardCompanyCopyWith<$Res>? get company;$CardAnnualFeeCopyWith<$Res>? get annualFee;$CardPerformanceCopyWith<$Res>? get performance;

}
/// @nodoc
class _$CardCatalogSummaryCopyWithImpl<$Res>
    implements $CardCatalogSummaryCopyWith<$Res> {
  _$CardCatalogSummaryCopyWithImpl(this._self, this._then);

  final CardCatalogSummary _self;
  final $Res Function(CardCatalogSummary) _then;

/// Create a copy of CardCatalogSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = null,Object? externalCardId = freezed,Object? company = freezed,Object? cardName = null,Object? cardType = freezed,Object? benefitType = freezed,Object? isDiscontinued = freezed,Object? onlyOnline = freezed,Object? launchDate = freezed,Object? imgUrl = freezed,Object? detailUrl = freezed,Object? annualFee = freezed,Object? performance = freezed,}) {
  return _then(_self.copyWith(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,externalCardId: freezed == externalCardId ? _self.externalCardId : externalCardId // ignore: cast_nullable_to_non_nullable
as int?,company: freezed == company ? _self.company : company // ignore: cast_nullable_to_non_nullable
as CardCompany?,cardName: null == cardName ? _self.cardName : cardName // ignore: cast_nullable_to_non_nullable
as String,cardType: freezed == cardType ? _self.cardType : cardType // ignore: cast_nullable_to_non_nullable
as String?,benefitType: freezed == benefitType ? _self.benefitType : benefitType // ignore: cast_nullable_to_non_nullable
as String?,isDiscontinued: freezed == isDiscontinued ? _self.isDiscontinued : isDiscontinued // ignore: cast_nullable_to_non_nullable
as String?,onlyOnline: freezed == onlyOnline ? _self.onlyOnline : onlyOnline // ignore: cast_nullable_to_non_nullable
as String?,launchDate: freezed == launchDate ? _self.launchDate : launchDate // ignore: cast_nullable_to_non_nullable
as String?,imgUrl: freezed == imgUrl ? _self.imgUrl : imgUrl // ignore: cast_nullable_to_non_nullable
as String?,detailUrl: freezed == detailUrl ? _self.detailUrl : detailUrl // ignore: cast_nullable_to_non_nullable
as String?,annualFee: freezed == annualFee ? _self.annualFee : annualFee // ignore: cast_nullable_to_non_nullable
as CardAnnualFee?,performance: freezed == performance ? _self.performance : performance // ignore: cast_nullable_to_non_nullable
as CardPerformance?,
  ));
}
/// Create a copy of CardCatalogSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardCompanyCopyWith<$Res>? get company {
    if (_self.company == null) {
    return null;
  }

  return $CardCompanyCopyWith<$Res>(_self.company!, (value) {
    return _then(_self.copyWith(company: value));
  });
}/// Create a copy of CardCatalogSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardAnnualFeeCopyWith<$Res>? get annualFee {
    if (_self.annualFee == null) {
    return null;
  }

  return $CardAnnualFeeCopyWith<$Res>(_self.annualFee!, (value) {
    return _then(_self.copyWith(annualFee: value));
  });
}/// Create a copy of CardCatalogSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardPerformanceCopyWith<$Res>? get performance {
    if (_self.performance == null) {
    return null;
  }

  return $CardPerformanceCopyWith<$Res>(_self.performance!, (value) {
    return _then(_self.copyWith(performance: value));
  });
}
}


/// Adds pattern-matching-related methods to [CardCatalogSummary].
extension CardCatalogSummaryPatterns on CardCatalogSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardCatalogSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardCatalogSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardCatalogSummary value)  $default,){
final _that = this;
switch (_that) {
case _CardCatalogSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardCatalogSummary value)?  $default,){
final _that = this;
switch (_that) {
case _CardCatalogSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowId,  int? externalCardId,  CardCompany? company,  String cardName,  String? cardType,  String? benefitType,  String? isDiscontinued,  String? onlyOnline,  String? launchDate,  String? imgUrl,  String? detailUrl,  CardAnnualFee? annualFee,  CardPerformance? performance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardCatalogSummary() when $default != null:
return $default(_that.rowId,_that.externalCardId,_that.company,_that.cardName,_that.cardType,_that.benefitType,_that.isDiscontinued,_that.onlyOnline,_that.launchDate,_that.imgUrl,_that.detailUrl,_that.annualFee,_that.performance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowId,  int? externalCardId,  CardCompany? company,  String cardName,  String? cardType,  String? benefitType,  String? isDiscontinued,  String? onlyOnline,  String? launchDate,  String? imgUrl,  String? detailUrl,  CardAnnualFee? annualFee,  CardPerformance? performance)  $default,) {final _that = this;
switch (_that) {
case _CardCatalogSummary():
return $default(_that.rowId,_that.externalCardId,_that.company,_that.cardName,_that.cardType,_that.benefitType,_that.isDiscontinued,_that.onlyOnline,_that.launchDate,_that.imgUrl,_that.detailUrl,_that.annualFee,_that.performance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowId,  int? externalCardId,  CardCompany? company,  String cardName,  String? cardType,  String? benefitType,  String? isDiscontinued,  String? onlyOnline,  String? launchDate,  String? imgUrl,  String? detailUrl,  CardAnnualFee? annualFee,  CardPerformance? performance)?  $default,) {final _that = this;
switch (_that) {
case _CardCatalogSummary() when $default != null:
return $default(_that.rowId,_that.externalCardId,_that.company,_that.cardName,_that.cardType,_that.benefitType,_that.isDiscontinued,_that.onlyOnline,_that.launchDate,_that.imgUrl,_that.detailUrl,_that.annualFee,_that.performance);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CardCatalogSummary implements CardCatalogSummary {
  const _CardCatalogSummary({required this.rowId, this.externalCardId, this.company, required this.cardName, this.cardType, this.benefitType, this.isDiscontinued, this.onlyOnline, this.launchDate, this.imgUrl, this.detailUrl, this.annualFee, this.performance});
  factory _CardCatalogSummary.fromJson(Map<String, dynamic> json) => _$CardCatalogSummaryFromJson(json);

@override final  int rowId;
@override final  int? externalCardId;
@override final  CardCompany? company;
@override final  String cardName;
@override final  String? cardType;
// CREDIT/CHECK
@override final  String? benefitType;
@override final  String? isDiscontinued;
@override final  String? onlyOnline;
@override final  String? launchDate;
@override final  String? imgUrl;
@override final  String? detailUrl;
@override final  CardAnnualFee? annualFee;
@override final  CardPerformance? performance;

/// Create a copy of CardCatalogSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardCatalogSummaryCopyWith<_CardCatalogSummary> get copyWith => __$CardCatalogSummaryCopyWithImpl<_CardCatalogSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CardCatalogSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardCatalogSummary&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.externalCardId, externalCardId) || other.externalCardId == externalCardId)&&(identical(other.company, company) || other.company == company)&&(identical(other.cardName, cardName) || other.cardName == cardName)&&(identical(other.cardType, cardType) || other.cardType == cardType)&&(identical(other.benefitType, benefitType) || other.benefitType == benefitType)&&(identical(other.isDiscontinued, isDiscontinued) || other.isDiscontinued == isDiscontinued)&&(identical(other.onlyOnline, onlyOnline) || other.onlyOnline == onlyOnline)&&(identical(other.launchDate, launchDate) || other.launchDate == launchDate)&&(identical(other.imgUrl, imgUrl) || other.imgUrl == imgUrl)&&(identical(other.detailUrl, detailUrl) || other.detailUrl == detailUrl)&&(identical(other.annualFee, annualFee) || other.annualFee == annualFee)&&(identical(other.performance, performance) || other.performance == performance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,externalCardId,company,cardName,cardType,benefitType,isDiscontinued,onlyOnline,launchDate,imgUrl,detailUrl,annualFee,performance);

@override
String toString() {
  return 'CardCatalogSummary(rowId: $rowId, externalCardId: $externalCardId, company: $company, cardName: $cardName, cardType: $cardType, benefitType: $benefitType, isDiscontinued: $isDiscontinued, onlyOnline: $onlyOnline, launchDate: $launchDate, imgUrl: $imgUrl, detailUrl: $detailUrl, annualFee: $annualFee, performance: $performance)';
}


}

/// @nodoc
abstract mixin class _$CardCatalogSummaryCopyWith<$Res> implements $CardCatalogSummaryCopyWith<$Res> {
  factory _$CardCatalogSummaryCopyWith(_CardCatalogSummary value, $Res Function(_CardCatalogSummary) _then) = __$CardCatalogSummaryCopyWithImpl;
@override @useResult
$Res call({
 int rowId, int? externalCardId, CardCompany? company, String cardName, String? cardType, String? benefitType, String? isDiscontinued, String? onlyOnline, String? launchDate, String? imgUrl, String? detailUrl, CardAnnualFee? annualFee, CardPerformance? performance
});


@override $CardCompanyCopyWith<$Res>? get company;@override $CardAnnualFeeCopyWith<$Res>? get annualFee;@override $CardPerformanceCopyWith<$Res>? get performance;

}
/// @nodoc
class __$CardCatalogSummaryCopyWithImpl<$Res>
    implements _$CardCatalogSummaryCopyWith<$Res> {
  __$CardCatalogSummaryCopyWithImpl(this._self, this._then);

  final _CardCatalogSummary _self;
  final $Res Function(_CardCatalogSummary) _then;

/// Create a copy of CardCatalogSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = null,Object? externalCardId = freezed,Object? company = freezed,Object? cardName = null,Object? cardType = freezed,Object? benefitType = freezed,Object? isDiscontinued = freezed,Object? onlyOnline = freezed,Object? launchDate = freezed,Object? imgUrl = freezed,Object? detailUrl = freezed,Object? annualFee = freezed,Object? performance = freezed,}) {
  return _then(_CardCatalogSummary(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,externalCardId: freezed == externalCardId ? _self.externalCardId : externalCardId // ignore: cast_nullable_to_non_nullable
as int?,company: freezed == company ? _self.company : company // ignore: cast_nullable_to_non_nullable
as CardCompany?,cardName: null == cardName ? _self.cardName : cardName // ignore: cast_nullable_to_non_nullable
as String,cardType: freezed == cardType ? _self.cardType : cardType // ignore: cast_nullable_to_non_nullable
as String?,benefitType: freezed == benefitType ? _self.benefitType : benefitType // ignore: cast_nullable_to_non_nullable
as String?,isDiscontinued: freezed == isDiscontinued ? _self.isDiscontinued : isDiscontinued // ignore: cast_nullable_to_non_nullable
as String?,onlyOnline: freezed == onlyOnline ? _self.onlyOnline : onlyOnline // ignore: cast_nullable_to_non_nullable
as String?,launchDate: freezed == launchDate ? _self.launchDate : launchDate // ignore: cast_nullable_to_non_nullable
as String?,imgUrl: freezed == imgUrl ? _self.imgUrl : imgUrl // ignore: cast_nullable_to_non_nullable
as String?,detailUrl: freezed == detailUrl ? _self.detailUrl : detailUrl // ignore: cast_nullable_to_non_nullable
as String?,annualFee: freezed == annualFee ? _self.annualFee : annualFee // ignore: cast_nullable_to_non_nullable
as CardAnnualFee?,performance: freezed == performance ? _self.performance : performance // ignore: cast_nullable_to_non_nullable
as CardPerformance?,
  ));
}

/// Create a copy of CardCatalogSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardCompanyCopyWith<$Res>? get company {
    if (_self.company == null) {
    return null;
  }

  return $CardCompanyCopyWith<$Res>(_self.company!, (value) {
    return _then(_self.copyWith(company: value));
  });
}/// Create a copy of CardCatalogSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardAnnualFeeCopyWith<$Res>? get annualFee {
    if (_self.annualFee == null) {
    return null;
  }

  return $CardAnnualFeeCopyWith<$Res>(_self.annualFee!, (value) {
    return _then(_self.copyWith(annualFee: value));
  });
}/// Create a copy of CardCatalogSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardPerformanceCopyWith<$Res>? get performance {
    if (_self.performance == null) {
    return null;
  }

  return $CardPerformanceCopyWith<$Res>(_self.performance!, (value) {
    return _then(_self.copyWith(performance: value));
  });
}
}


/// @nodoc
mixin _$CardBenefit {

 int? get rowId; String? get category; String? get categoryIcon; String? get title; String? get summary; String? get detail; int? get sortOrder;
/// Create a copy of CardBenefit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardBenefitCopyWith<CardBenefit> get copyWith => _$CardBenefitCopyWithImpl<CardBenefit>(this as CardBenefit, _$identity);

  /// Serializes this CardBenefit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardBenefit&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.category, category) || other.category == category)&&(identical(other.categoryIcon, categoryIcon) || other.categoryIcon == categoryIcon)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,category,categoryIcon,title,summary,detail,sortOrder);

@override
String toString() {
  return 'CardBenefit(rowId: $rowId, category: $category, categoryIcon: $categoryIcon, title: $title, summary: $summary, detail: $detail, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $CardBenefitCopyWith<$Res>  {
  factory $CardBenefitCopyWith(CardBenefit value, $Res Function(CardBenefit) _then) = _$CardBenefitCopyWithImpl;
@useResult
$Res call({
 int? rowId, String? category, String? categoryIcon, String? title, String? summary, String? detail, int? sortOrder
});




}
/// @nodoc
class _$CardBenefitCopyWithImpl<$Res>
    implements $CardBenefitCopyWith<$Res> {
  _$CardBenefitCopyWithImpl(this._self, this._then);

  final CardBenefit _self;
  final $Res Function(CardBenefit) _then;

/// Create a copy of CardBenefit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = freezed,Object? category = freezed,Object? categoryIcon = freezed,Object? title = freezed,Object? summary = freezed,Object? detail = freezed,Object? sortOrder = freezed,}) {
  return _then(_self.copyWith(
rowId: freezed == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,categoryIcon: freezed == categoryIcon ? _self.categoryIcon : categoryIcon // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CardBenefit].
extension CardBenefitPatterns on CardBenefit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardBenefit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardBenefit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardBenefit value)  $default,){
final _that = this;
switch (_that) {
case _CardBenefit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardBenefit value)?  $default,){
final _that = this;
switch (_that) {
case _CardBenefit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? rowId,  String? category,  String? categoryIcon,  String? title,  String? summary,  String? detail,  int? sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardBenefit() when $default != null:
return $default(_that.rowId,_that.category,_that.categoryIcon,_that.title,_that.summary,_that.detail,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? rowId,  String? category,  String? categoryIcon,  String? title,  String? summary,  String? detail,  int? sortOrder)  $default,) {final _that = this;
switch (_that) {
case _CardBenefit():
return $default(_that.rowId,_that.category,_that.categoryIcon,_that.title,_that.summary,_that.detail,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? rowId,  String? category,  String? categoryIcon,  String? title,  String? summary,  String? detail,  int? sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _CardBenefit() when $default != null:
return $default(_that.rowId,_that.category,_that.categoryIcon,_that.title,_that.summary,_that.detail,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CardBenefit implements CardBenefit {
  const _CardBenefit({this.rowId, this.category, this.categoryIcon, this.title, this.summary, this.detail, this.sortOrder});
  factory _CardBenefit.fromJson(Map<String, dynamic> json) => _$CardBenefitFromJson(json);

@override final  int? rowId;
@override final  String? category;
@override final  String? categoryIcon;
@override final  String? title;
@override final  String? summary;
@override final  String? detail;
@override final  int? sortOrder;

/// Create a copy of CardBenefit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardBenefitCopyWith<_CardBenefit> get copyWith => __$CardBenefitCopyWithImpl<_CardBenefit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CardBenefitToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardBenefit&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.category, category) || other.category == category)&&(identical(other.categoryIcon, categoryIcon) || other.categoryIcon == categoryIcon)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,category,categoryIcon,title,summary,detail,sortOrder);

@override
String toString() {
  return 'CardBenefit(rowId: $rowId, category: $category, categoryIcon: $categoryIcon, title: $title, summary: $summary, detail: $detail, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$CardBenefitCopyWith<$Res> implements $CardBenefitCopyWith<$Res> {
  factory _$CardBenefitCopyWith(_CardBenefit value, $Res Function(_CardBenefit) _then) = __$CardBenefitCopyWithImpl;
@override @useResult
$Res call({
 int? rowId, String? category, String? categoryIcon, String? title, String? summary, String? detail, int? sortOrder
});




}
/// @nodoc
class __$CardBenefitCopyWithImpl<$Res>
    implements _$CardBenefitCopyWith<$Res> {
  __$CardBenefitCopyWithImpl(this._self, this._then);

  final _CardBenefit _self;
  final $Res Function(_CardBenefit) _then;

/// Create a copy of CardBenefit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = freezed,Object? category = freezed,Object? categoryIcon = freezed,Object? title = freezed,Object? summary = freezed,Object? detail = freezed,Object? sortOrder = freezed,}) {
  return _then(_CardBenefit(
rowId: freezed == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,categoryIcon: freezed == categoryIcon ? _self.categoryIcon : categoryIcon // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$CardTagGroup {

 String? get category; List<String> get tags;
/// Create a copy of CardTagGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardTagGroupCopyWith<CardTagGroup> get copyWith => _$CardTagGroupCopyWithImpl<CardTagGroup>(this as CardTagGroup, _$identity);

  /// Serializes this CardTagGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardTagGroup&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.tags, tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,const DeepCollectionEquality().hash(tags));

@override
String toString() {
  return 'CardTagGroup(category: $category, tags: $tags)';
}


}

/// @nodoc
abstract mixin class $CardTagGroupCopyWith<$Res>  {
  factory $CardTagGroupCopyWith(CardTagGroup value, $Res Function(CardTagGroup) _then) = _$CardTagGroupCopyWithImpl;
@useResult
$Res call({
 String? category, List<String> tags
});




}
/// @nodoc
class _$CardTagGroupCopyWithImpl<$Res>
    implements $CardTagGroupCopyWith<$Res> {
  _$CardTagGroupCopyWithImpl(this._self, this._then);

  final CardTagGroup _self;
  final $Res Function(CardTagGroup) _then;

/// Create a copy of CardTagGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = freezed,Object? tags = null,}) {
  return _then(_self.copyWith(
category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [CardTagGroup].
extension CardTagGroupPatterns on CardTagGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardTagGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardTagGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardTagGroup value)  $default,){
final _that = this;
switch (_that) {
case _CardTagGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardTagGroup value)?  $default,){
final _that = this;
switch (_that) {
case _CardTagGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? category,  List<String> tags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardTagGroup() when $default != null:
return $default(_that.category,_that.tags);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? category,  List<String> tags)  $default,) {final _that = this;
switch (_that) {
case _CardTagGroup():
return $default(_that.category,_that.tags);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? category,  List<String> tags)?  $default,) {final _that = this;
switch (_that) {
case _CardTagGroup() when $default != null:
return $default(_that.category,_that.tags);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CardTagGroup implements CardTagGroup {
  const _CardTagGroup({this.category, final  List<String> tags = const <String>[]}): _tags = tags;
  factory _CardTagGroup.fromJson(Map<String, dynamic> json) => _$CardTagGroupFromJson(json);

@override final  String? category;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}


/// Create a copy of CardTagGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardTagGroupCopyWith<_CardTagGroup> get copyWith => __$CardTagGroupCopyWithImpl<_CardTagGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CardTagGroupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardTagGroup&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._tags, _tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,const DeepCollectionEquality().hash(_tags));

@override
String toString() {
  return 'CardTagGroup(category: $category, tags: $tags)';
}


}

/// @nodoc
abstract mixin class _$CardTagGroupCopyWith<$Res> implements $CardTagGroupCopyWith<$Res> {
  factory _$CardTagGroupCopyWith(_CardTagGroup value, $Res Function(_CardTagGroup) _then) = __$CardTagGroupCopyWithImpl;
@override @useResult
$Res call({
 String? category, List<String> tags
});




}
/// @nodoc
class __$CardTagGroupCopyWithImpl<$Res>
    implements _$CardTagGroupCopyWith<$Res> {
  __$CardTagGroupCopyWithImpl(this._self, this._then);

  final _CardTagGroup _self;
  final $Res Function(_CardTagGroup) _then;

/// Create a copy of CardTagGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = freezed,Object? tags = null,}) {
  return _then(_CardTagGroup(
category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$CardCatalogDetail {

 CardCatalogSummary get summary; List<String> get brands; List<CardBenefit> get benefits; List<CardBenefit> get cautions; List<CardTagGroup> get topBenefits; List<CardTagGroup> get searchBenefits;
/// Create a copy of CardCatalogDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardCatalogDetailCopyWith<CardCatalogDetail> get copyWith => _$CardCatalogDetailCopyWithImpl<CardCatalogDetail>(this as CardCatalogDetail, _$identity);

  /// Serializes this CardCatalogDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardCatalogDetail&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.brands, brands)&&const DeepCollectionEquality().equals(other.benefits, benefits)&&const DeepCollectionEquality().equals(other.cautions, cautions)&&const DeepCollectionEquality().equals(other.topBenefits, topBenefits)&&const DeepCollectionEquality().equals(other.searchBenefits, searchBenefits));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,summary,const DeepCollectionEquality().hash(brands),const DeepCollectionEquality().hash(benefits),const DeepCollectionEquality().hash(cautions),const DeepCollectionEquality().hash(topBenefits),const DeepCollectionEquality().hash(searchBenefits));

@override
String toString() {
  return 'CardCatalogDetail(summary: $summary, brands: $brands, benefits: $benefits, cautions: $cautions, topBenefits: $topBenefits, searchBenefits: $searchBenefits)';
}


}

/// @nodoc
abstract mixin class $CardCatalogDetailCopyWith<$Res>  {
  factory $CardCatalogDetailCopyWith(CardCatalogDetail value, $Res Function(CardCatalogDetail) _then) = _$CardCatalogDetailCopyWithImpl;
@useResult
$Res call({
 CardCatalogSummary summary, List<String> brands, List<CardBenefit> benefits, List<CardBenefit> cautions, List<CardTagGroup> topBenefits, List<CardTagGroup> searchBenefits
});


$CardCatalogSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class _$CardCatalogDetailCopyWithImpl<$Res>
    implements $CardCatalogDetailCopyWith<$Res> {
  _$CardCatalogDetailCopyWithImpl(this._self, this._then);

  final CardCatalogDetail _self;
  final $Res Function(CardCatalogDetail) _then;

/// Create a copy of CardCatalogDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? summary = null,Object? brands = null,Object? benefits = null,Object? cautions = null,Object? topBenefits = null,Object? searchBenefits = null,}) {
  return _then(_self.copyWith(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as CardCatalogSummary,brands: null == brands ? _self.brands : brands // ignore: cast_nullable_to_non_nullable
as List<String>,benefits: null == benefits ? _self.benefits : benefits // ignore: cast_nullable_to_non_nullable
as List<CardBenefit>,cautions: null == cautions ? _self.cautions : cautions // ignore: cast_nullable_to_non_nullable
as List<CardBenefit>,topBenefits: null == topBenefits ? _self.topBenefits : topBenefits // ignore: cast_nullable_to_non_nullable
as List<CardTagGroup>,searchBenefits: null == searchBenefits ? _self.searchBenefits : searchBenefits // ignore: cast_nullable_to_non_nullable
as List<CardTagGroup>,
  ));
}
/// Create a copy of CardCatalogDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardCatalogSummaryCopyWith<$Res> get summary {
  
  return $CardCatalogSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}


/// Adds pattern-matching-related methods to [CardCatalogDetail].
extension CardCatalogDetailPatterns on CardCatalogDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardCatalogDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardCatalogDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardCatalogDetail value)  $default,){
final _that = this;
switch (_that) {
case _CardCatalogDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardCatalogDetail value)?  $default,){
final _that = this;
switch (_that) {
case _CardCatalogDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CardCatalogSummary summary,  List<String> brands,  List<CardBenefit> benefits,  List<CardBenefit> cautions,  List<CardTagGroup> topBenefits,  List<CardTagGroup> searchBenefits)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardCatalogDetail() when $default != null:
return $default(_that.summary,_that.brands,_that.benefits,_that.cautions,_that.topBenefits,_that.searchBenefits);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CardCatalogSummary summary,  List<String> brands,  List<CardBenefit> benefits,  List<CardBenefit> cautions,  List<CardTagGroup> topBenefits,  List<CardTagGroup> searchBenefits)  $default,) {final _that = this;
switch (_that) {
case _CardCatalogDetail():
return $default(_that.summary,_that.brands,_that.benefits,_that.cautions,_that.topBenefits,_that.searchBenefits);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CardCatalogSummary summary,  List<String> brands,  List<CardBenefit> benefits,  List<CardBenefit> cautions,  List<CardTagGroup> topBenefits,  List<CardTagGroup> searchBenefits)?  $default,) {final _that = this;
switch (_that) {
case _CardCatalogDetail() when $default != null:
return $default(_that.summary,_that.brands,_that.benefits,_that.cautions,_that.topBenefits,_that.searchBenefits);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CardCatalogDetail implements CardCatalogDetail {
  const _CardCatalogDetail({required this.summary, final  List<String> brands = const <String>[], final  List<CardBenefit> benefits = const <CardBenefit>[], final  List<CardBenefit> cautions = const <CardBenefit>[], final  List<CardTagGroup> topBenefits = const <CardTagGroup>[], final  List<CardTagGroup> searchBenefits = const <CardTagGroup>[]}): _brands = brands,_benefits = benefits,_cautions = cautions,_topBenefits = topBenefits,_searchBenefits = searchBenefits;
  factory _CardCatalogDetail.fromJson(Map<String, dynamic> json) => _$CardCatalogDetailFromJson(json);

@override final  CardCatalogSummary summary;
 final  List<String> _brands;
@override@JsonKey() List<String> get brands {
  if (_brands is EqualUnmodifiableListView) return _brands;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_brands);
}

 final  List<CardBenefit> _benefits;
@override@JsonKey() List<CardBenefit> get benefits {
  if (_benefits is EqualUnmodifiableListView) return _benefits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_benefits);
}

 final  List<CardBenefit> _cautions;
@override@JsonKey() List<CardBenefit> get cautions {
  if (_cautions is EqualUnmodifiableListView) return _cautions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cautions);
}

 final  List<CardTagGroup> _topBenefits;
@override@JsonKey() List<CardTagGroup> get topBenefits {
  if (_topBenefits is EqualUnmodifiableListView) return _topBenefits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topBenefits);
}

 final  List<CardTagGroup> _searchBenefits;
@override@JsonKey() List<CardTagGroup> get searchBenefits {
  if (_searchBenefits is EqualUnmodifiableListView) return _searchBenefits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_searchBenefits);
}


/// Create a copy of CardCatalogDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardCatalogDetailCopyWith<_CardCatalogDetail> get copyWith => __$CardCatalogDetailCopyWithImpl<_CardCatalogDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CardCatalogDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardCatalogDetail&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other._brands, _brands)&&const DeepCollectionEquality().equals(other._benefits, _benefits)&&const DeepCollectionEquality().equals(other._cautions, _cautions)&&const DeepCollectionEquality().equals(other._topBenefits, _topBenefits)&&const DeepCollectionEquality().equals(other._searchBenefits, _searchBenefits));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,summary,const DeepCollectionEquality().hash(_brands),const DeepCollectionEquality().hash(_benefits),const DeepCollectionEquality().hash(_cautions),const DeepCollectionEquality().hash(_topBenefits),const DeepCollectionEquality().hash(_searchBenefits));

@override
String toString() {
  return 'CardCatalogDetail(summary: $summary, brands: $brands, benefits: $benefits, cautions: $cautions, topBenefits: $topBenefits, searchBenefits: $searchBenefits)';
}


}

/// @nodoc
abstract mixin class _$CardCatalogDetailCopyWith<$Res> implements $CardCatalogDetailCopyWith<$Res> {
  factory _$CardCatalogDetailCopyWith(_CardCatalogDetail value, $Res Function(_CardCatalogDetail) _then) = __$CardCatalogDetailCopyWithImpl;
@override @useResult
$Res call({
 CardCatalogSummary summary, List<String> brands, List<CardBenefit> benefits, List<CardBenefit> cautions, List<CardTagGroup> topBenefits, List<CardTagGroup> searchBenefits
});


@override $CardCatalogSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class __$CardCatalogDetailCopyWithImpl<$Res>
    implements _$CardCatalogDetailCopyWith<$Res> {
  __$CardCatalogDetailCopyWithImpl(this._self, this._then);

  final _CardCatalogDetail _self;
  final $Res Function(_CardCatalogDetail) _then;

/// Create a copy of CardCatalogDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? summary = null,Object? brands = null,Object? benefits = null,Object? cautions = null,Object? topBenefits = null,Object? searchBenefits = null,}) {
  return _then(_CardCatalogDetail(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as CardCatalogSummary,brands: null == brands ? _self._brands : brands // ignore: cast_nullable_to_non_nullable
as List<String>,benefits: null == benefits ? _self._benefits : benefits // ignore: cast_nullable_to_non_nullable
as List<CardBenefit>,cautions: null == cautions ? _self._cautions : cautions // ignore: cast_nullable_to_non_nullable
as List<CardBenefit>,topBenefits: null == topBenefits ? _self._topBenefits : topBenefits // ignore: cast_nullable_to_non_nullable
as List<CardTagGroup>,searchBenefits: null == searchBenefits ? _self._searchBenefits : searchBenefits // ignore: cast_nullable_to_non_nullable
as List<CardTagGroup>,
  ));
}

/// Create a copy of CardCatalogDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardCatalogSummaryCopyWith<$Res> get summary {
  
  return $CardCatalogSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}

// dart format on
