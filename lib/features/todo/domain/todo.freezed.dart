// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'todo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Todo {

 int get rowId; int? get userRowId; String? get type;// 'TASK' | 'NOTE'
 String get title; String? get content; String? get priority;// 'HIGH' | 'MEDIUM' | 'LOW'
 String? get category; String? get status;// 'PENDING' | 'IN_PROGRESS' | 'COMPLETED'
 String? get dueDate;// 'YYYY-MM-DD'
 String? get completedAt; int? get sortOrder; String? get isPinned; int? get projectRowId; String? get projectName; int? get parentRowId; int get subtaskCount; int get subtaskCompletedCount; String? get createAt; String? get modifyAt;
/// Create a copy of Todo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TodoCopyWith<Todo> get copyWith => _$TodoCopyWithImpl<Todo>(this as Todo, _$identity);

  /// Serializes this Todo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Todo&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.category, category) || other.category == category)&&(identical(other.status, status) || other.status == status)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.projectRowId, projectRowId) || other.projectRowId == projectRowId)&&(identical(other.projectName, projectName) || other.projectName == projectName)&&(identical(other.parentRowId, parentRowId) || other.parentRowId == parentRowId)&&(identical(other.subtaskCount, subtaskCount) || other.subtaskCount == subtaskCount)&&(identical(other.subtaskCompletedCount, subtaskCompletedCount) || other.subtaskCompletedCount == subtaskCompletedCount)&&(identical(other.createAt, createAt) || other.createAt == createAt)&&(identical(other.modifyAt, modifyAt) || other.modifyAt == modifyAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,rowId,userRowId,type,title,content,priority,category,status,dueDate,completedAt,sortOrder,isPinned,projectRowId,projectName,parentRowId,subtaskCount,subtaskCompletedCount,createAt,modifyAt]);

@override
String toString() {
  return 'Todo(rowId: $rowId, userRowId: $userRowId, type: $type, title: $title, content: $content, priority: $priority, category: $category, status: $status, dueDate: $dueDate, completedAt: $completedAt, sortOrder: $sortOrder, isPinned: $isPinned, projectRowId: $projectRowId, projectName: $projectName, parentRowId: $parentRowId, subtaskCount: $subtaskCount, subtaskCompletedCount: $subtaskCompletedCount, createAt: $createAt, modifyAt: $modifyAt)';
}


}

/// @nodoc
abstract mixin class $TodoCopyWith<$Res>  {
  factory $TodoCopyWith(Todo value, $Res Function(Todo) _then) = _$TodoCopyWithImpl;
@useResult
$Res call({
 int rowId, int? userRowId, String? type, String title, String? content, String? priority, String? category, String? status, String? dueDate, String? completedAt, int? sortOrder, String? isPinned, int? projectRowId, String? projectName, int? parentRowId, int subtaskCount, int subtaskCompletedCount, String? createAt, String? modifyAt
});




}
/// @nodoc
class _$TodoCopyWithImpl<$Res>
    implements $TodoCopyWith<$Res> {
  _$TodoCopyWithImpl(this._self, this._then);

  final Todo _self;
  final $Res Function(Todo) _then;

/// Create a copy of Todo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = null,Object? userRowId = freezed,Object? type = freezed,Object? title = null,Object? content = freezed,Object? priority = freezed,Object? category = freezed,Object? status = freezed,Object? dueDate = freezed,Object? completedAt = freezed,Object? sortOrder = freezed,Object? isPinned = freezed,Object? projectRowId = freezed,Object? projectName = freezed,Object? parentRowId = freezed,Object? subtaskCount = null,Object? subtaskCompletedCount = null,Object? createAt = freezed,Object? modifyAt = freezed,}) {
  return _then(_self.copyWith(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as String?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,isPinned: freezed == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as String?,projectRowId: freezed == projectRowId ? _self.projectRowId : projectRowId // ignore: cast_nullable_to_non_nullable
as int?,projectName: freezed == projectName ? _self.projectName : projectName // ignore: cast_nullable_to_non_nullable
as String?,parentRowId: freezed == parentRowId ? _self.parentRowId : parentRowId // ignore: cast_nullable_to_non_nullable
as int?,subtaskCount: null == subtaskCount ? _self.subtaskCount : subtaskCount // ignore: cast_nullable_to_non_nullable
as int,subtaskCompletedCount: null == subtaskCompletedCount ? _self.subtaskCompletedCount : subtaskCompletedCount // ignore: cast_nullable_to_non_nullable
as int,createAt: freezed == createAt ? _self.createAt : createAt // ignore: cast_nullable_to_non_nullable
as String?,modifyAt: freezed == modifyAt ? _self.modifyAt : modifyAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Todo].
extension TodoPatterns on Todo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Todo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Todo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Todo value)  $default,){
final _that = this;
switch (_that) {
case _Todo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Todo value)?  $default,){
final _that = this;
switch (_that) {
case _Todo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  String? type,  String title,  String? content,  String? priority,  String? category,  String? status,  String? dueDate,  String? completedAt,  int? sortOrder,  String? isPinned,  int? projectRowId,  String? projectName,  int? parentRowId,  int subtaskCount,  int subtaskCompletedCount,  String? createAt,  String? modifyAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Todo() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.type,_that.title,_that.content,_that.priority,_that.category,_that.status,_that.dueDate,_that.completedAt,_that.sortOrder,_that.isPinned,_that.projectRowId,_that.projectName,_that.parentRowId,_that.subtaskCount,_that.subtaskCompletedCount,_that.createAt,_that.modifyAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  String? type,  String title,  String? content,  String? priority,  String? category,  String? status,  String? dueDate,  String? completedAt,  int? sortOrder,  String? isPinned,  int? projectRowId,  String? projectName,  int? parentRowId,  int subtaskCount,  int subtaskCompletedCount,  String? createAt,  String? modifyAt)  $default,) {final _that = this;
switch (_that) {
case _Todo():
return $default(_that.rowId,_that.userRowId,_that.type,_that.title,_that.content,_that.priority,_that.category,_that.status,_that.dueDate,_that.completedAt,_that.sortOrder,_that.isPinned,_that.projectRowId,_that.projectName,_that.parentRowId,_that.subtaskCount,_that.subtaskCompletedCount,_that.createAt,_that.modifyAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowId,  int? userRowId,  String? type,  String title,  String? content,  String? priority,  String? category,  String? status,  String? dueDate,  String? completedAt,  int? sortOrder,  String? isPinned,  int? projectRowId,  String? projectName,  int? parentRowId,  int subtaskCount,  int subtaskCompletedCount,  String? createAt,  String? modifyAt)?  $default,) {final _that = this;
switch (_that) {
case _Todo() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.type,_that.title,_that.content,_that.priority,_that.category,_that.status,_that.dueDate,_that.completedAt,_that.sortOrder,_that.isPinned,_that.projectRowId,_that.projectName,_that.parentRowId,_that.subtaskCount,_that.subtaskCompletedCount,_that.createAt,_that.modifyAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Todo implements Todo {
  const _Todo({required this.rowId, this.userRowId, this.type, required this.title, this.content, this.priority, this.category, this.status, this.dueDate, this.completedAt, this.sortOrder, this.isPinned, this.projectRowId, this.projectName, this.parentRowId, this.subtaskCount = 0, this.subtaskCompletedCount = 0, this.createAt, this.modifyAt});
  factory _Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);

@override final  int rowId;
@override final  int? userRowId;
@override final  String? type;
// 'TASK' | 'NOTE'
@override final  String title;
@override final  String? content;
@override final  String? priority;
// 'HIGH' | 'MEDIUM' | 'LOW'
@override final  String? category;
@override final  String? status;
// 'PENDING' | 'IN_PROGRESS' | 'COMPLETED'
@override final  String? dueDate;
// 'YYYY-MM-DD'
@override final  String? completedAt;
@override final  int? sortOrder;
@override final  String? isPinned;
@override final  int? projectRowId;
@override final  String? projectName;
@override final  int? parentRowId;
@override@JsonKey() final  int subtaskCount;
@override@JsonKey() final  int subtaskCompletedCount;
@override final  String? createAt;
@override final  String? modifyAt;

/// Create a copy of Todo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TodoCopyWith<_Todo> get copyWith => __$TodoCopyWithImpl<_Todo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TodoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Todo&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.category, category) || other.category == category)&&(identical(other.status, status) || other.status == status)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.projectRowId, projectRowId) || other.projectRowId == projectRowId)&&(identical(other.projectName, projectName) || other.projectName == projectName)&&(identical(other.parentRowId, parentRowId) || other.parentRowId == parentRowId)&&(identical(other.subtaskCount, subtaskCount) || other.subtaskCount == subtaskCount)&&(identical(other.subtaskCompletedCount, subtaskCompletedCount) || other.subtaskCompletedCount == subtaskCompletedCount)&&(identical(other.createAt, createAt) || other.createAt == createAt)&&(identical(other.modifyAt, modifyAt) || other.modifyAt == modifyAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,rowId,userRowId,type,title,content,priority,category,status,dueDate,completedAt,sortOrder,isPinned,projectRowId,projectName,parentRowId,subtaskCount,subtaskCompletedCount,createAt,modifyAt]);

@override
String toString() {
  return 'Todo(rowId: $rowId, userRowId: $userRowId, type: $type, title: $title, content: $content, priority: $priority, category: $category, status: $status, dueDate: $dueDate, completedAt: $completedAt, sortOrder: $sortOrder, isPinned: $isPinned, projectRowId: $projectRowId, projectName: $projectName, parentRowId: $parentRowId, subtaskCount: $subtaskCount, subtaskCompletedCount: $subtaskCompletedCount, createAt: $createAt, modifyAt: $modifyAt)';
}


}

/// @nodoc
abstract mixin class _$TodoCopyWith<$Res> implements $TodoCopyWith<$Res> {
  factory _$TodoCopyWith(_Todo value, $Res Function(_Todo) _then) = __$TodoCopyWithImpl;
@override @useResult
$Res call({
 int rowId, int? userRowId, String? type, String title, String? content, String? priority, String? category, String? status, String? dueDate, String? completedAt, int? sortOrder, String? isPinned, int? projectRowId, String? projectName, int? parentRowId, int subtaskCount, int subtaskCompletedCount, String? createAt, String? modifyAt
});




}
/// @nodoc
class __$TodoCopyWithImpl<$Res>
    implements _$TodoCopyWith<$Res> {
  __$TodoCopyWithImpl(this._self, this._then);

  final _Todo _self;
  final $Res Function(_Todo) _then;

/// Create a copy of Todo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = null,Object? userRowId = freezed,Object? type = freezed,Object? title = null,Object? content = freezed,Object? priority = freezed,Object? category = freezed,Object? status = freezed,Object? dueDate = freezed,Object? completedAt = freezed,Object? sortOrder = freezed,Object? isPinned = freezed,Object? projectRowId = freezed,Object? projectName = freezed,Object? parentRowId = freezed,Object? subtaskCount = null,Object? subtaskCompletedCount = null,Object? createAt = freezed,Object? modifyAt = freezed,}) {
  return _then(_Todo(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as String?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,isPinned: freezed == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as String?,projectRowId: freezed == projectRowId ? _self.projectRowId : projectRowId // ignore: cast_nullable_to_non_nullable
as int?,projectName: freezed == projectName ? _self.projectName : projectName // ignore: cast_nullable_to_non_nullable
as String?,parentRowId: freezed == parentRowId ? _self.parentRowId : parentRowId // ignore: cast_nullable_to_non_nullable
as int?,subtaskCount: null == subtaskCount ? _self.subtaskCount : subtaskCount // ignore: cast_nullable_to_non_nullable
as int,subtaskCompletedCount: null == subtaskCompletedCount ? _self.subtaskCompletedCount : subtaskCompletedCount // ignore: cast_nullable_to_non_nullable
as int,createAt: freezed == createAt ? _self.createAt : createAt // ignore: cast_nullable_to_non_nullable
as String?,modifyAt: freezed == modifyAt ? _self.modifyAt : modifyAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
