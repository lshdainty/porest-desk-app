import 'dart:math' as math;

/// 웹 Recharts 의 auto-nice Y축을 fl_chart 로 이식한 공유 유틸.
///
/// fl_chart 는 min/max/interval 을 직접 줘야 하므로(auto-nice 없음), 데이터 범위를 받아
/// ① 항상 0 을 포함하고(양수 추이는 0 부터, 음수면 0 아래로 확장),
/// ② 끝점·간격을 1·2·2.5·5×10ⁿ "딱 떨어지는" 값으로 맞춘 축을 돌려준다.
///
/// 앱의 모든 단일 Y축 차트(순자산 추이·자산 잔액 추이·일별 순저축 등)가 이 함수를
/// 공유 → 차트 간/웹과 동일한 눈금. 웹(porest-desk-front)의 `niceAxis(format)` 와 정합.
///
/// 예) max 60,881,200 → (min 0, max 80,000,000, interval 20,000,000)
///     = 0 / 2,000만 / 4,000만 / 6,000만 / 8,000만.
({double min, double max, double interval}) niceAxis(
  double dataMin,
  double dataMax, {
  int targetSteps = 4, // 구간 4 → 라벨 약 5개
}) {
  final lo = math.min(0.0, dataMin);
  var hi = math.max(0.0, dataMax);
  if (lo == hi) hi = lo + 1; // 전부 0/동일값일 때 0 division 방지
  final step = niceStep((hi - lo) / targetSteps);
  final niceMin = (lo / step).floorToDouble() * step;
  final niceMax = (hi / step).ceilToDouble() * step;
  return (min: niceMin, max: niceMax, interval: step);
}

/// [rough] 이상이 되는 가장 가까운 "깔끔한" 간격 (1·2·2.5·5×10ⁿ).
double niceStep(double rough) {
  if (rough <= 0) return 1;
  final exp = (math.log(rough) / math.ln10).floorToDouble();
  final pow10 = math.pow(10, exp).toDouble();
  final frac = rough / pow10; // [1, 10)
  final double niceFrac;
  if (frac <= 1) {
    niceFrac = 1;
  } else if (frac <= 2) {
    niceFrac = 2;
  } else if (frac <= 2.5) {
    niceFrac = 2.5;
  } else if (frac <= 5) {
    niceFrac = 5;
  } else {
    niceFrac = 10;
  }
  return niceFrac * pow10;
}
