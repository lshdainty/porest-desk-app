import 'package:freezed_annotation/freezed_annotation.dart';

part 'net_worth_point.freezed.dart';
part 'net_worth_point.g.dart';

/// 순자산 추이 한 점.
@freezed
abstract class NetWorthPoint with _$NetWorthPoint {
  const factory NetWorthPoint({
    required String month, // 'YYYY-MM'
    @Default(0) int totalAssets,
    @Default(0) int totalDebt,
    @Default(0) int netWorth,
  }) = _NetWorthPoint;

  factory NetWorthPoint.fromJson(Map<String, dynamic> json) =>
      _$NetWorthPointFromJson(json);
}
