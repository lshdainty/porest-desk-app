import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required int rowId,
    int? userRowId,
    String? notificationType,
    required String title,
    String? message,
    String? referenceType,
    int? referenceId,
    @Default(false) bool isRead,
    String? readAt,
    String? createAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
}
