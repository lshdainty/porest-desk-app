import 'package:freezed_annotation/freezed_annotation.dart';

part 'dutch_pay.freezed.dart';
part 'dutch_pay.g.dart';

@freezed
abstract class DutchPay with _$DutchPay {
  const factory DutchPay({
    required int rowId,
    int? userRowId,
    int? sourceExpenseRowId,
    required String title,
    String? description,
    required int totalAmount,
    String? currency,
    String? splitMethod, // EQUAL/CUSTOM/RATIO
    String? dutchPayDate,
    @Default(false) bool isSettled,
    @Default(<DutchPayParticipant>[]) List<DutchPayParticipant> participants,
    String? createAt,
  }) = _DutchPay;

  factory DutchPay.fromJson(Map<String, dynamic> json) =>
      _$DutchPayFromJson(json);
}

@freezed
abstract class DutchPayParticipant with _$DutchPayParticipant {
  const factory DutchPayParticipant({
    required int rowId,
    int? userRowId,
    String? participantName,
    @Default(0) int amount,

    /// 이 사람이 결제했는가. 한 정산에 한 명 — 나머지는 그 사람에게 갚을 참여자다.
    @Default(false) bool isPayer,
    @Default(false) bool isPaid,
    String? paidAt,
  }) = _DutchPayParticipant;

  factory DutchPayParticipant.fromJson(Map<String, dynamic> json) =>
      _$DutchPayParticipantFromJson(json);
}
