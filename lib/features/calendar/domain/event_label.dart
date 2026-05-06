import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_label.freezed.dart';
part 'event_label.g.dart';

@freezed
abstract class EventLabel with _$EventLabel {
  const factory EventLabel({
    required int rowId,
    int? userRowId,
    required String labelName,
    String? color,
    int? sortOrder,
  }) = _EventLabel;

  factory EventLabel.fromJson(Map<String, dynamic> json) =>
      _$EventLabelFromJson(json);
}
