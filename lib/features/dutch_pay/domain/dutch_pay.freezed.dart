// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dutch_pay.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DutchPay {

 int get rowId; int? get userRowId; int? get sourceExpenseRowId; String get title; String? get description; int get totalAmount; String? get currency; String? get splitMethod;// EQUAL/CUSTOM/RATIO
 String? get dutchPayDate; bool get isSettled; List<DutchPayParticipant> get participants; String? get createAt;
/// Create a copy of DutchPay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DutchPayCopyWith<DutchPay> get copyWith => _$DutchPayCopyWithImpl<DutchPay>(this as DutchPay, _$identity);

  /// Serializes this DutchPay to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DutchPay&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.sourceExpenseRowId, sourceExpenseRowId) || other.sourceExpenseRowId == sourceExpenseRowId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.splitMethod, splitMethod) || other.splitMethod == splitMethod)&&(identical(other.dutchPayDate, dutchPayDate) || other.dutchPayDate == dutchPayDate)&&(identical(other.isSettled, isSettled) || other.isSettled == isSettled)&&const DeepCollectionEquality().equals(other.participants, participants)&&(identical(other.createAt, createAt) || other.createAt == createAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,userRowId,sourceExpenseRowId,title,description,totalAmount,currency,splitMethod,dutchPayDate,isSettled,const DeepCollectionEquality().hash(participants),createAt);

@override
String toString() {
  return 'DutchPay(rowId: $rowId, userRowId: $userRowId, sourceExpenseRowId: $sourceExpenseRowId, title: $title, description: $description, totalAmount: $totalAmount, currency: $currency, splitMethod: $splitMethod, dutchPayDate: $dutchPayDate, isSettled: $isSettled, participants: $participants, createAt: $createAt)';
}


}

/// @nodoc
abstract mixin class $DutchPayCopyWith<$Res>  {
  factory $DutchPayCopyWith(DutchPay value, $Res Function(DutchPay) _then) = _$DutchPayCopyWithImpl;
@useResult
$Res call({
 int rowId, int? userRowId, int? sourceExpenseRowId, String title, String? description, int totalAmount, String? currency, String? splitMethod, String? dutchPayDate, bool isSettled, List<DutchPayParticipant> participants, String? createAt
});




}
/// @nodoc
class _$DutchPayCopyWithImpl<$Res>
    implements $DutchPayCopyWith<$Res> {
  _$DutchPayCopyWithImpl(this._self, this._then);

  final DutchPay _self;
  final $Res Function(DutchPay) _then;

/// Create a copy of DutchPay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = null,Object? userRowId = freezed,Object? sourceExpenseRowId = freezed,Object? title = null,Object? description = freezed,Object? totalAmount = null,Object? currency = freezed,Object? splitMethod = freezed,Object? dutchPayDate = freezed,Object? isSettled = null,Object? participants = null,Object? createAt = freezed,}) {
  return _then(_self.copyWith(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,sourceExpenseRowId: freezed == sourceExpenseRowId ? _self.sourceExpenseRowId : sourceExpenseRowId // ignore: cast_nullable_to_non_nullable
as int?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,splitMethod: freezed == splitMethod ? _self.splitMethod : splitMethod // ignore: cast_nullable_to_non_nullable
as String?,dutchPayDate: freezed == dutchPayDate ? _self.dutchPayDate : dutchPayDate // ignore: cast_nullable_to_non_nullable
as String?,isSettled: null == isSettled ? _self.isSettled : isSettled // ignore: cast_nullable_to_non_nullable
as bool,participants: null == participants ? _self.participants : participants // ignore: cast_nullable_to_non_nullable
as List<DutchPayParticipant>,createAt: freezed == createAt ? _self.createAt : createAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DutchPay].
extension DutchPayPatterns on DutchPay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DutchPay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DutchPay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DutchPay value)  $default,){
final _that = this;
switch (_that) {
case _DutchPay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DutchPay value)?  $default,){
final _that = this;
switch (_that) {
case _DutchPay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  int? sourceExpenseRowId,  String title,  String? description,  int totalAmount,  String? currency,  String? splitMethod,  String? dutchPayDate,  bool isSettled,  List<DutchPayParticipant> participants,  String? createAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DutchPay() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.sourceExpenseRowId,_that.title,_that.description,_that.totalAmount,_that.currency,_that.splitMethod,_that.dutchPayDate,_that.isSettled,_that.participants,_that.createAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  int? sourceExpenseRowId,  String title,  String? description,  int totalAmount,  String? currency,  String? splitMethod,  String? dutchPayDate,  bool isSettled,  List<DutchPayParticipant> participants,  String? createAt)  $default,) {final _that = this;
switch (_that) {
case _DutchPay():
return $default(_that.rowId,_that.userRowId,_that.sourceExpenseRowId,_that.title,_that.description,_that.totalAmount,_that.currency,_that.splitMethod,_that.dutchPayDate,_that.isSettled,_that.participants,_that.createAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowId,  int? userRowId,  int? sourceExpenseRowId,  String title,  String? description,  int totalAmount,  String? currency,  String? splitMethod,  String? dutchPayDate,  bool isSettled,  List<DutchPayParticipant> participants,  String? createAt)?  $default,) {final _that = this;
switch (_that) {
case _DutchPay() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.sourceExpenseRowId,_that.title,_that.description,_that.totalAmount,_that.currency,_that.splitMethod,_that.dutchPayDate,_that.isSettled,_that.participants,_that.createAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DutchPay implements DutchPay {
  const _DutchPay({required this.rowId, this.userRowId, this.sourceExpenseRowId, required this.title, this.description, required this.totalAmount, this.currency, this.splitMethod, this.dutchPayDate, this.isSettled = false, final  List<DutchPayParticipant> participants = const <DutchPayParticipant>[], this.createAt}): _participants = participants;
  factory _DutchPay.fromJson(Map<String, dynamic> json) => _$DutchPayFromJson(json);

@override final  int rowId;
@override final  int? userRowId;
@override final  int? sourceExpenseRowId;
@override final  String title;
@override final  String? description;
@override final  int totalAmount;
@override final  String? currency;
@override final  String? splitMethod;
// EQUAL/CUSTOM/RATIO
@override final  String? dutchPayDate;
@override@JsonKey() final  bool isSettled;
 final  List<DutchPayParticipant> _participants;
@override@JsonKey() List<DutchPayParticipant> get participants {
  if (_participants is EqualUnmodifiableListView) return _participants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participants);
}

@override final  String? createAt;

/// Create a copy of DutchPay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DutchPayCopyWith<_DutchPay> get copyWith => __$DutchPayCopyWithImpl<_DutchPay>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DutchPayToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DutchPay&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.sourceExpenseRowId, sourceExpenseRowId) || other.sourceExpenseRowId == sourceExpenseRowId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.splitMethod, splitMethod) || other.splitMethod == splitMethod)&&(identical(other.dutchPayDate, dutchPayDate) || other.dutchPayDate == dutchPayDate)&&(identical(other.isSettled, isSettled) || other.isSettled == isSettled)&&const DeepCollectionEquality().equals(other._participants, _participants)&&(identical(other.createAt, createAt) || other.createAt == createAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,userRowId,sourceExpenseRowId,title,description,totalAmount,currency,splitMethod,dutchPayDate,isSettled,const DeepCollectionEquality().hash(_participants),createAt);

@override
String toString() {
  return 'DutchPay(rowId: $rowId, userRowId: $userRowId, sourceExpenseRowId: $sourceExpenseRowId, title: $title, description: $description, totalAmount: $totalAmount, currency: $currency, splitMethod: $splitMethod, dutchPayDate: $dutchPayDate, isSettled: $isSettled, participants: $participants, createAt: $createAt)';
}


}

/// @nodoc
abstract mixin class _$DutchPayCopyWith<$Res> implements $DutchPayCopyWith<$Res> {
  factory _$DutchPayCopyWith(_DutchPay value, $Res Function(_DutchPay) _then) = __$DutchPayCopyWithImpl;
@override @useResult
$Res call({
 int rowId, int? userRowId, int? sourceExpenseRowId, String title, String? description, int totalAmount, String? currency, String? splitMethod, String? dutchPayDate, bool isSettled, List<DutchPayParticipant> participants, String? createAt
});




}
/// @nodoc
class __$DutchPayCopyWithImpl<$Res>
    implements _$DutchPayCopyWith<$Res> {
  __$DutchPayCopyWithImpl(this._self, this._then);

  final _DutchPay _self;
  final $Res Function(_DutchPay) _then;

/// Create a copy of DutchPay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = null,Object? userRowId = freezed,Object? sourceExpenseRowId = freezed,Object? title = null,Object? description = freezed,Object? totalAmount = null,Object? currency = freezed,Object? splitMethod = freezed,Object? dutchPayDate = freezed,Object? isSettled = null,Object? participants = null,Object? createAt = freezed,}) {
  return _then(_DutchPay(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,sourceExpenseRowId: freezed == sourceExpenseRowId ? _self.sourceExpenseRowId : sourceExpenseRowId // ignore: cast_nullable_to_non_nullable
as int?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,splitMethod: freezed == splitMethod ? _self.splitMethod : splitMethod // ignore: cast_nullable_to_non_nullable
as String?,dutchPayDate: freezed == dutchPayDate ? _self.dutchPayDate : dutchPayDate // ignore: cast_nullable_to_non_nullable
as String?,isSettled: null == isSettled ? _self.isSettled : isSettled // ignore: cast_nullable_to_non_nullable
as bool,participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<DutchPayParticipant>,createAt: freezed == createAt ? _self.createAt : createAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$DutchPayParticipant {

 int get rowId; int? get userRowId; String? get participantName; int get amount;/// 이 사람이 결제했는가. 한 정산에 한 명 — 나머지는 그 사람에게 갚을 참여자다.
 bool get isPayer; bool get isPaid; String? get paidAt;
/// Create a copy of DutchPayParticipant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DutchPayParticipantCopyWith<DutchPayParticipant> get copyWith => _$DutchPayParticipantCopyWithImpl<DutchPayParticipant>(this as DutchPayParticipant, _$identity);

  /// Serializes this DutchPayParticipant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DutchPayParticipant&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.participantName, participantName) || other.participantName == participantName)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.isPayer, isPayer) || other.isPayer == isPayer)&&(identical(other.isPaid, isPaid) || other.isPaid == isPaid)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,userRowId,participantName,amount,isPayer,isPaid,paidAt);

@override
String toString() {
  return 'DutchPayParticipant(rowId: $rowId, userRowId: $userRowId, participantName: $participantName, amount: $amount, isPayer: $isPayer, isPaid: $isPaid, paidAt: $paidAt)';
}


}

/// @nodoc
abstract mixin class $DutchPayParticipantCopyWith<$Res>  {
  factory $DutchPayParticipantCopyWith(DutchPayParticipant value, $Res Function(DutchPayParticipant) _then) = _$DutchPayParticipantCopyWithImpl;
@useResult
$Res call({
 int rowId, int? userRowId, String? participantName, int amount, bool isPayer, bool isPaid, String? paidAt
});




}
/// @nodoc
class _$DutchPayParticipantCopyWithImpl<$Res>
    implements $DutchPayParticipantCopyWith<$Res> {
  _$DutchPayParticipantCopyWithImpl(this._self, this._then);

  final DutchPayParticipant _self;
  final $Res Function(DutchPayParticipant) _then;

/// Create a copy of DutchPayParticipant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = null,Object? userRowId = freezed,Object? participantName = freezed,Object? amount = null,Object? isPayer = null,Object? isPaid = null,Object? paidAt = freezed,}) {
  return _then(_self.copyWith(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,participantName: freezed == participantName ? _self.participantName : participantName // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,isPayer: null == isPayer ? _self.isPayer : isPayer // ignore: cast_nullable_to_non_nullable
as bool,isPaid: null == isPaid ? _self.isPaid : isPaid // ignore: cast_nullable_to_non_nullable
as bool,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DutchPayParticipant].
extension DutchPayParticipantPatterns on DutchPayParticipant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DutchPayParticipant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DutchPayParticipant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DutchPayParticipant value)  $default,){
final _that = this;
switch (_that) {
case _DutchPayParticipant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DutchPayParticipant value)?  $default,){
final _that = this;
switch (_that) {
case _DutchPayParticipant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  String? participantName,  int amount,  bool isPayer,  bool isPaid,  String? paidAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DutchPayParticipant() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.participantName,_that.amount,_that.isPayer,_that.isPaid,_that.paidAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  String? participantName,  int amount,  bool isPayer,  bool isPaid,  String? paidAt)  $default,) {final _that = this;
switch (_that) {
case _DutchPayParticipant():
return $default(_that.rowId,_that.userRowId,_that.participantName,_that.amount,_that.isPayer,_that.isPaid,_that.paidAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowId,  int? userRowId,  String? participantName,  int amount,  bool isPayer,  bool isPaid,  String? paidAt)?  $default,) {final _that = this;
switch (_that) {
case _DutchPayParticipant() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.participantName,_that.amount,_that.isPayer,_that.isPaid,_that.paidAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DutchPayParticipant implements DutchPayParticipant {
  const _DutchPayParticipant({required this.rowId, this.userRowId, this.participantName, this.amount = 0, this.isPayer = false, this.isPaid = false, this.paidAt});
  factory _DutchPayParticipant.fromJson(Map<String, dynamic> json) => _$DutchPayParticipantFromJson(json);

@override final  int rowId;
@override final  int? userRowId;
@override final  String? participantName;
@override@JsonKey() final  int amount;
/// 이 사람이 결제했는가. 한 정산에 한 명 — 나머지는 그 사람에게 갚을 참여자다.
@override@JsonKey() final  bool isPayer;
@override@JsonKey() final  bool isPaid;
@override final  String? paidAt;

/// Create a copy of DutchPayParticipant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DutchPayParticipantCopyWith<_DutchPayParticipant> get copyWith => __$DutchPayParticipantCopyWithImpl<_DutchPayParticipant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DutchPayParticipantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DutchPayParticipant&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.participantName, participantName) || other.participantName == participantName)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.isPayer, isPayer) || other.isPayer == isPayer)&&(identical(other.isPaid, isPaid) || other.isPaid == isPaid)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowId,userRowId,participantName,amount,isPayer,isPaid,paidAt);

@override
String toString() {
  return 'DutchPayParticipant(rowId: $rowId, userRowId: $userRowId, participantName: $participantName, amount: $amount, isPayer: $isPayer, isPaid: $isPaid, paidAt: $paidAt)';
}


}

/// @nodoc
abstract mixin class _$DutchPayParticipantCopyWith<$Res> implements $DutchPayParticipantCopyWith<$Res> {
  factory _$DutchPayParticipantCopyWith(_DutchPayParticipant value, $Res Function(_DutchPayParticipant) _then) = __$DutchPayParticipantCopyWithImpl;
@override @useResult
$Res call({
 int rowId, int? userRowId, String? participantName, int amount, bool isPayer, bool isPaid, String? paidAt
});




}
/// @nodoc
class __$DutchPayParticipantCopyWithImpl<$Res>
    implements _$DutchPayParticipantCopyWith<$Res> {
  __$DutchPayParticipantCopyWithImpl(this._self, this._then);

  final _DutchPayParticipant _self;
  final $Res Function(_DutchPayParticipant) _then;

/// Create a copy of DutchPayParticipant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = null,Object? userRowId = freezed,Object? participantName = freezed,Object? amount = null,Object? isPayer = null,Object? isPaid = null,Object? paidAt = freezed,}) {
  return _then(_DutchPayParticipant(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,participantName: freezed == participantName ? _self.participantName : participantName // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,isPayer: null == isPayer ? _self.isPayer : isPayer // ignore: cast_nullable_to_non_nullable
as bool,isPaid: null == isPaid ? _self.isPaid : isPaid // ignore: cast_nullable_to_non_nullable
as bool,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
