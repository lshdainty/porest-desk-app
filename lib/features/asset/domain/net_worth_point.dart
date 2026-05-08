import 'package:freezed_annotation/freezed_annotation.dart';

part 'net_worth_point.freezed.dart';
part 'net_worth_point.g.dart';

/// 순자산 추이 한 점. 백엔드 응답 그대로 — `{year, month, netWorth}`.
@freezed
abstract class NetWorthPoint with _$NetWorthPoint {
  const NetWorthPoint._();

  const factory NetWorthPoint({
    required int year,
    required int month, // 1~12
    @Default(0) int netWorth,
  }) = _NetWorthPoint;

  factory NetWorthPoint.fromJson(Map<String, dynamic> json) =>
      _$NetWorthPointFromJson(json);

  /// 'YYYY-MM' 라벨 — 차트에서 사용.
  String get monthLabel =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
}
