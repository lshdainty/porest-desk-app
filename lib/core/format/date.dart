import 'package:intl/intl.dart';

import 'package:porest_desk_app/core/format/format_locale.dart';

/// porest-desk-front `formatDay(dStr)` 포팅 — "M월 D일" + "요일".
class DayLabel {
  const DayLabel({required this.md, required this.dow, required this.date});
  final String md;
  final String dow;
  final DateTime date;
}

const _dows = ['일', '월', '화', '수', '목', '금', '토'];

DayLabel formatDay(DateTime d) {
  if (localeIsEn()) {
    // en: 로케일 스켈레톤 (Jul 15 · Mon). intl 내장 en 데이터 → init 불필요.
    return DayLabel(
      md: DateFormat.MMMd('en').format(d),
      dow: DateFormat.E('en').format(d),
      date: d,
    );
  }
  // ko: 기존 수동 포맷 그대로 (회귀 0).
  return DayLabel(
    md: '${d.month}월 ${d.day}일',
    dow: _dows[d.weekday % 7],
    date: d,
  );
}

/// 'YYYY-MM-DD' 파싱 헬퍼.
DateTime parseIsoDate(String s) => DateTime.parse(s);

/// "YYYY년 M월" 헤더 포맷 (en: "Jul 2026"). ko 는 기존 수동 포맷 그대로.
String yearMonth(DateTime d) =>
    localeIsEn() ? DateFormat.yMMM('en').format(d) : '${d.year}년 ${d.month}월';

/// 월간 첫 날.
DateTime monthStart(DateTime d) => DateTime(d.year, d.month, 1);

/// `Java LocalDateTime` 호환 ISO_LOCAL_DATE_TIME (`YYYY-MM-DDTHH:mm:ss`).
String toIsoLocal(DateTime d) {
  return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(d);
}
