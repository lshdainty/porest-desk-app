import 'package:freezed_annotation/freezed_annotation.dart';

part 'group.freezed.dart';
part 'group.g.dart';

@freezed
abstract class Group with _$Group {
  const factory Group({
    required int rowId,
    required String groupName,
    String? description,
    int? groupTypeId,
    String? groupTypeName,
    String? groupTypeColor,
    String? inviteCode,
    @Default(0) int memberCount,
    String? createAt,
  }) = _Group;

  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);
}
