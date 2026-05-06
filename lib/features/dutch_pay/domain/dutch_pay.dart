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
    @Default(false) bool isPaid,
    String? paidAt,
  }) = _DutchPayParticipant;

  factory DutchPayParticipant.fromJson(Map<String, dynamic> json) =>
      _$DutchPayParticipantFromJson(json);
}
