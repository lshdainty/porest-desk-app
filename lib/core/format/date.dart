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

/// 올해가 아니면 연도를 붙인다 — 반복거래는 내년치를 미리 만들어 두는데, 연도가 없으면
/// 2027-01-01 이 그냥 "1월 1일" 로 보여 올해 것과 구분되지 않는다.
DayLabel formatDay(DateTime d) {
  final otherYear = d.year != DateTime.now().year;
  if (localeIsEn()) {
    // en: 로케일 스켈레톤 (Jul 15 · Mon). intl 내장 en 데이터 → init 불필요.
    return DayLabel(
      md: otherYear
          ? DateFormat.yMMMd('en').format(d)
          : DateFormat.MMMd('en').format(d),
      dow: DateFormat.E('en').format(d),
      date: d,
    );
  }
  // ko: 기존 수동 포맷 그대로 (회귀 0).
  return DayLabel(
    md: otherYear
        ? '${d.year}년 ${d.month}월 ${d.day}일'
        : '${d.month}월 ${d.day}일',
    dow: _dows[d.weekday % 7],
    date: d,
  );
}

/// porest-desk-front `formatMonthDayDow` 포팅 — ko "8월 3일 (월)" / en "Aug 3 (Mon)".
///
/// 올해가 아니면 [formatDay] 가 md 에 연도를 넣어 준다 → "2027년 1월 1일 (금)".
/// `'${x.md} (${x.dow})'` 인라인이 여러 화면에 흩어져 있어 한자리로 모은다.
String monthDayDow(DateTime d) {
  final x = formatDay(d);
  return '${x.md} (${x.dow})';
}

/// 'YYYY-MM-DD' 파싱 헬퍼.
DateTime parseIsoDate(String s) => DateTime.parse(s);

/// "YYYY년 M월" 헤더 포맷 (en: "Jul 2026"). ko 는 기존 수동 포맷 그대로.
String yearMonth(DateTime d) =>
    localeIsEn() ? DateFormat.yMMM('en').format(d) : '${d.year}년 ${d.month}월';

/// "YYYY년" (en: "2026"). ko 는 기존 수동 포맷 그대로.
String yearOnly(DateTime d) =>
    localeIsEn() ? DateFormat.y('en').format(d) : '${d.year}년';

/// "M월" (en: "Jul"). ko 는 기존 수동 포맷 그대로.
String monthOnly(DateTime d) =>
    localeIsEn() ? DateFormat.MMM('en').format(d) : '${d.month}월';

/// 요일 헤더 라벨 7개. ko 는 기존 수동 배열 그대로, en 은 DateFormat.E('en').
/// [mondayFirst] true → 월~일, false → 일~토. 인라인 요일 배열 통일용.
List<String> weekdayLabels({bool mondayFirst = false}) {
  if (localeIsEn()) {
    // 2024-01-01 = 월요일 · 2023-12-31 = 일요일 기준으로 7일 라벨 생성.
    final base = mondayFirst ? DateTime(2024, 1, 1) : DateTime(2023, 12, 31);
    return [
      for (var i = 0; i < 7; i++)
        DateFormat.E('en').format(base.add(Duration(days: i)))
    ];
  }
  return mondayFirst
      ? const ['월', '화', '수', '목', '금', '토', '일']
      : const ['일', '월', '화', '수', '목', '금', '토'];
}

/// 월간 첫 날.
DateTime monthStart(DateTime d) => DateTime(d.year, d.month, 1);

/// `Java LocalDateTime` 호환 ISO_LOCAL_DATE_TIME (`YYYY-MM-DDTHH:mm:ss`).
String toIsoLocal(DateTime d) {
  return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(d);
}
