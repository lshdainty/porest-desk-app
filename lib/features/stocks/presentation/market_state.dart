/// 장 상태 계산 — 정규장 운영 시간(오프셋 붙은 ISO)을 순간으로 견주고, 보이는 시각은 모두 한국 시각이다.
library;

import 'package:flutter/material.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

// ---- 장 상태 계산 (지금 순간 vs 정규장 세션 순간) ----------------------------------
//
// 토스 OpenAPI market-calendar(KR · US 둘 다): 세션 시각은 **한국 시각 오프셋이 붙은 ISO date-time** 이다 —
// 예) 미국 정규장 "2026-03-25T22:30:00+09:00" ~ "2026-03-26T05:00:00+09:00"(자정을 넘는다), 국내 "…T09:00:00+09:00"
// (`~/qa/design-work/refs/stocks-api/_raw/toss/latest_openapi.json` UsRegularMarketSession · RegularMarketSession 의 example ·
// 백엔드는 그대로 넘긴다 `TossMarketInfoDto.UsSession(String startTime, String endTime)`). 그래서 시각을 순간으로 읽어 지금과
// 견주면 시장 시간대 · 서머타임 · 자정 넘김을 따질 일이 없고, 보이는 시각은 그대로 한국 시각이다.
// 옛 "HH:MM:SS" 글(시험 · 옛 하네스)은 그날 한국 시각으로 읽는다.

enum StockTz { kr, us }

/// 장 상태가 읽는 시각 — 제품은 실제 시각 그대로, 시험 · 하네스만 고정한다(통계의 `statsNow` 와 같은 방식).
/// 고정했으면 시험이 끝날 때 되돌린다(벽시계와 섞이면 다음 날부터 조용히 깨진다).
@visibleForTesting
DateTime Function() stocksNow = DateTime.now;

/// 지금 시각 — 제품 코드는 [stocksNow] 를 직접 부르지 않고 이 함수로 읽는다(시험용 변수라 분석기가 막는다).
DateTime stocksClock() => stocksNow();

const _kst = Duration(hours: 9);

/// 세션 시각 글 → 순간(UTC). 오프셋 붙은 ISO 는 그대로, "HH:MM[:SS]" 는 [nowUtc] 의 한국 날짜 그 시각으로 읽는다.
DateTime? _instantOf(String? raw, DateTime nowUtc) {
  if (raw == null || raw.isEmpty) return null;
  final iso = DateTime.tryParse(raw);
  if (iso != null && raw.length > 8) return iso.toUtc();
  final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(raw);
  if (m == null) return null;
  final kstNow = nowUtc.add(_kst);
  return DateTime.utc(
    kstNow.year,
    kstNow.month,
    kstNow.day,
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
  ).subtract(_kst);
}

/// 보이는 시각은 모두 한국 시각 — 나무 장 상태 줄("장중 · 오후 1:05")도 같은 시계를 쓴다.
DateTime stocksKstNow() => stocksNow().toUtc().add(_kst);

/// 장 상태 — 열림 여부와 줄 글. 보이는 시각은 모두 한국 시각 · 오전 · 오후 12시간.
({bool open, String detail}) marketStateNow(
  TossMarketSession? session,
  StockTz tz,
  AppLocalizations l,
) => marketStateAt(session, stocksNow().toUtc(), l);

@visibleForTesting
({bool open, String detail}) marketStateAt(
  TossMarketSession? session,
  DateTime nowUtc,
  AppLocalizations l,
) {
  var start = _instantOf(session?.startTime, nowUtc);
  var end = _instantOf(session?.endTime, nowUtc);
  if (start == null || end == null) {
    return (open: false, detail: l.stocksMarketHoliday);
  }
  // 오프셋 없는 "22:30 ~ 05:00" 처럼 끝이 시작보다 이르면 다음 날 끝이다(자정 넘김)
  if (end.isBefore(start)) end = end.add(const Duration(days: 1));
  // 자정을 넘는 세션이 어제 시작해 지금 진행 중이면 시작을 하루 앞으로 당긴다
  if (nowUtc.isBefore(start) &&
      !nowUtc.isAfter(end.subtract(const Duration(days: 1)))) {
    start = start.subtract(const Duration(days: 1));
    end = end.subtract(const Duration(days: 1));
  }
  String clock(DateTime utc) => timeOfDay12(utc.add(_kst));
  if (!nowUtc.isBefore(start) && !nowUtc.isAfter(end)) {
    return (open: true, detail: l.stocksMarketTrading(clock(nowUtc)));
  }
  if (nowUtc.isBefore(start)) {
    return (open: false, detail: l.stocksMarketOpensAt(clock(start)));
  }
  return (open: false, detail: l.stocksMarketClosed);
}
