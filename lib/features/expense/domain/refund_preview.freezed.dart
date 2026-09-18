// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'refund_preview.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RefundPreview {

 bool get applies; int get refundAmount; String get reason;
/// Create a copy of RefundPreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RefundPreviewCopyWith<RefundPreview> get copyWith => _$RefundPreviewCopyWithImpl<RefundPreview>(this as RefundPreview, _$identity);

  /// Serializes this RefundPreview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RefundPreview&&(identical(other.applies, applies) || other.applies == applies)&&(identical(other.refundAmount, refundAmount) || other.refundAmount == refundAmount)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,applies,refundAmount,reason);

@override
String toString() {
  return 'RefundPreview(applies: $applies, refundAmount: $refundAmount, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $RefundPreviewCopyWith<$Res>  {
  factory $RefundPreviewCopyWith(RefundPreview value, $Res Function(RefundPreview) _then) = _$RefundPreviewCopyWithImpl;
@useResult
$Res call({
 bool applies, int refundAmount, String reason
});




}
/// @nodoc
class _$RefundPreviewCopyWithImpl<$Res>
    implements $RefundPreviewCopyWith<$Res> {
  _$RefundPreviewCopyWithImpl(this._self, this._then);

  final RefundPreview _self;
  final $Res Function(RefundPreview) _then;

/// Create a copy of RefundPreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? applies = null,Object? refundAmount = null,Object? reason = null,}) {
  return _then(_self.copyWith(
applies: null == applies ? _self.applies : applies // ignore: cast_nullable_to_non_nullable
as bool,refundAmount: null == refundAmount ? _self.refundAmount : refundAmount // ignore: cast_nullable_to_non_nullable
as int,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RefundPreview].
extension RefundPreviewPatterns on RefundPreview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RefundPreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RefundPreview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RefundPreview value)  $default,){
final _that = this;
switch (_that) {
case _RefundPreview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RefundPreview value)?  $default,){
final _that = this;
switch (_that) {
case _RefundPreview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool applies,  int refundAmount,  String reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RefundPreview() when $default != null:
return $default(_that.applies,_that.refundAmount,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool applies,  int refundAmount,  String reason)  $default,) {final _that = this;
switch (_that) {
case _RefundPreview():
return $default(_that.applies,_that.refundAmount,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool applies,  int refundAmount,  String reason)?  $default,) {final _that = this;
switch (_that) {
case _RefundPreview() when $default != null:
return $default(_that.applies,_that.refundAmount,_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RefundPreview implements RefundPreview {
  const _RefundPreview({this.applies = false, this.refundAmount = 0, this.reason = ''});
  factory _RefundPreview.fromJson(Map<String, dynamic> json) => _$RefundPreviewFromJson(json);

@override@JsonKey() final  bool applies;
@override@JsonKey() final  int refundAmount;
@override@JsonKey() final  String reason;

/// Create a copy of RefundPreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RefundPreviewCopyWith<_RefundPreview> get copyWith => __$RefundPreviewCopyWithImpl<_RefundPreview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RefundPreviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RefundPreview&&(identical(other.applies, applies) || other.applies == applies)&&(identical(other.refundAmount, refundAmount) || other.refundAmount == refundAmount)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,applies,refundAmount,reason);

@override
String toString() {
  return 'RefundPreview(applies: $applies, refundAmount: $refundAmount, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$RefundPreviewCopyWith<$Res> implements $RefundPreviewCopyWith<$Res> {
  factory _$RefundPreviewCopyWith(_RefundPreview value, $Res Function(_RefundPreview) _then) = __$RefundPreviewCopyWithImpl;
@override @useResult
$Res call({
 bool applies, int refundAmount, String reason
});




}
/// @nodoc
class __$RefundPreviewCopyWithImpl<$Res>
    implements _$RefundPreviewCopyWith<$Res> {
  __$RefundPreviewCopyWithImpl(this._self, this._then);

  final _RefundPreview _self;
  final $Res Function(_RefundPreview) _then;

/// Create a copy of RefundPreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? applies = null,Object? refundAmount = null,Object? reason = null,}) {
  return _then(_RefundPreview(
applies: null == applies ? _self.applies : applies // ignore: cast_nullable_to_non_nullable
as bool,refundAmount: null == refundAmount ? _self.refundAmount : refundAmount // ignore: cast_nullable_to_non_nullable
as int,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
