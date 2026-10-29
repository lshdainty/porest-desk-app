import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';

/// 월 격자 모델(I-09 10) — 웹 `widgets/calendar/lib/helpers.ts` `calculateMonthEventPositions` ·
/// `ui/month-view/month-model.ts` 와 같은 규칙이다. 일정 하나에 줄 번호 하나를 **달 전체에서 먼저** 정하고, 그 일정이
/// 걸친 모든 날이 같은 줄에 앉는다(칸마다 따로 늘어놓지 않는다). 그래서 이어지는 띠와 공휴일이 줄이 어긋나지 않는다.

/// 격자가 그리는 한 건 — 일정 또는 공휴일.
class CalendarGridItem {
  const CalendarGridItem({
    required this.key,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.allDay,
    this.event,
  });

  /// 일정 [event] 를 격자 한 건으로 — 웹 `getEventUniqueKey`(`{id}-{startDate}`)와 같은 키.
  factory CalendarGridItem.ofEvent(CalendarEvent e) => CalendarGridItem(
    key: '${e.rowId}-${e.startDate}',
    title: e.title,
    startAt: e.start,
    endAt: e.end,
    allDay: e.isAllDayBool,
    event: e,
  );

  /// 공휴일 — 종일 하루(웹 `convertHolidayToIEvent` 와 같다: 00:00 ~ 23:59:59 · 종일).
  factory CalendarGridItem.ofHoliday(String dateKey, String name) =>
      CalendarGridItem(
        key: 'holiday-$dateKey',
        title: name,
        startAt: DateTime.parse('${dateKey}T00:00:00'),
        endAt: DateTime.parse('${dateKey}T23:59:59'),
        allDay: true,
      );

  final String key;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final bool allDay;

  /// 공휴일이면 null.
  final CalendarEvent? event;

  bool get isHoliday => event == null;

  DateTime get startDay => DateTime(startAt.year, startAt.month, startAt.day);
  DateTime get endDay => DateTime(endAt.year, endAt.month, endAt.day);

  /// 날짜로 하루를 넘나드는가 — 칩이 첫 · 사이 · 끝 조각으로 이어진다.
  bool get spansDays => endDay.isAfter(startDay);

  /// 웹 `multiDayEvents` — 종일이거나 날을 넘나든다. 공휴일도 여기다(길이 0).
  bool get isMulti => allDay || spansDays;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// 일정마다 줄 번호(0부터) — 웹 `calculateMonthEventPositions`. 이어지는 일정(길이 → 시작 순)을 먼저, 그 뒤 하루 일정(시작
/// 순)을 앉히고, 모든 날에 빈 같은 줄을 찾는다. 달 밖 날은 잘라 내고 줄 수에는 위쪽 한도가 없다. 이 달에 걸치지 않는 건 빠진다.
Map<String, int> calculateMonthPositions(
  List<CalendarGridItem> items,
  DateTime month,
) {
  final monthStart = DateTime(month.year, month.month);
  final monthEnd = DateTime(month.year, month.month + 1, 0);
  final occupied = <DateTime, Set<int>>{};
  for (
    var d = monthStart;
    !d.isAfter(monthEnd);
    d = DateTime(d.year, d.month, d.day + 1)
  ) {
    occupied[d] = <int>{};
  }

  int cmpStart(CalendarGridItem a, CalendarGridItem b) =>
      a.startAt.compareTo(b.startAt);
  // 웹은 안정 정렬이다 — 같으면 들어온 차례를 지킨다
  List<CalendarGridItem> sorted(
    Iterable<CalendarGridItem> src,
    int Function(CalendarGridItem, CalendarGridItem) cmp,
  ) {
    final indexed = [
      for (var i = 0; i < src.length; i++) (i, src.elementAt(i)),
    ];
    indexed.sort((a, b) {
      final c = cmp(a.$2, b.$2);
      return c != 0 ? c : a.$1.compareTo(b.$1);
    });
    return [for (final e in indexed) e.$2];
  }

  int duration(CalendarGridItem e) => e.endAt.difference(e.startAt).inDays;
  final multi = sorted(items.where((e) => e.isMulti), (a, b) {
    final d = duration(b).compareTo(duration(a));
    return d != 0 ? d : cmpStart(a, b);
  });
  final single = sorted(items.where((e) => !e.isMulti), cmpStart);

  final positions = <String, int>{};
  for (final e in [...multi, ...single]) {
    final from = e.startAt.isBefore(monthStart) ? monthStart : e.startDay;
    final to =
        e.endAt.isAfter(
          DateTime(
            monthEnd.year,
            monthEnd.month,
            monthEnd.day,
            23,
            59,
            59,
            999,
          ),
        )
        ? monthEnd
        : e.endDay;
    if (from.isAfter(to)) continue;
    final days = <DateTime>[
      for (
        var d = from;
        !d.isAfter(to);
        d = DateTime(d.year, d.month, d.day + 1)
      )
        d,
    ];
    var position = 0;
    bool fits(int p) =>
        days.every((d) => occupied[d] != null && !occupied[d]!.contains(p));
    while (!fits(position)) {
      position += 1;
      if (position > 200) {
        position = -1;
        break;
      }
    }
    if (position == -1) continue;
    for (final d in days) {
      occupied[d]?.add(position);
    }
    positions[e.key] = position;
  }
  return positions;
}

/// 칸 안 칩 자리의 실측 — 모두 px.
class ChipMetrics {
  const ChipMetrics({
    required this.avail,
    required this.chip,
    required this.more,
    required this.gap,
  });

  /// 칩 자리(날 숫자 아래 ~ 칸 아래) 높이.
  final double avail;

  /// 칩 한 줄 높이.
  final double chip;

  /// "+N개" 줄 높이.
  final double more;

  /// 줄 사이.
  final double gap;
}

/// [rows] 줄이 필요한 칸에서 칩 몇 줄을 그리고 "+N개" 를 둘지 — 웹 `planSlots`.
({int shown, bool more}) planSlots(int rows, ChipMetrics m) {
  if (rows <= 0) return (shown: 0, more: false);
  final all = rows * m.chip + (rows - 1) * m.gap;
  if (all <= m.avail) return (shown: rows, more: false);
  final n = ((m.avail - m.more) / (m.chip + m.gap)).floor().clamp(0, rows);
  return (shown: n, more: true);
}

enum ChipPart { none, first, middle, last }

class ChipSlot {
  ChipSlot(this.item, this.part);

  final CalendarGridItem item;
  final ChipPart part;

  /// 이 칸이 이 주에서 이어진 띠의 제목을 그리는 칸이면 띠가 차지하는 칸 수(아니면 0).
  int labelDays = 0;

  /// 제목 띠가 이 일정의 끝 칸까지 이어지는가(끝 칸 오른쪽 안쪽 여백을 비운다).
  bool labelReachesEnd = false;
}

class CellModel {
  CellModel({
    required this.day,
    required this.isOutside,
    required this.slots,
    required this.hidden,
    required this.total,
  });

  final DateTime day;
  final bool isOutside;

  /// 줄 번호 차례의 칩 — 비어 있는 줄은 null(띠가 줄을 맞추려고 비워 둔다).
  final List<ChipSlot?> slots;

  /// 접힌 일정 수("+N개").
  final int hidden;

  /// 이 칸에 걸린 일정 수.
  final int total;
}

ChipPart _partOf(CalendarGridItem e, DateTime day) {
  if (!e.spansDays) return ChipPart.none;
  if (day == e.startDay) return ChipPart.first;
  if (day == e.endDay) return ChipPart.last;
  return ChipPart.middle;
}

/// 칸마다 "어떤 줄에 어떤 칩이 서고 몇 개가 접히는가" — 웹 `buildMonthModel`. 이어지는 일정의 제목은 주마다 한 번,
/// 그 주에서 띠가 처음 보이는 칸에 둔다(첫 칸에서 접혔어도 뒤 칸에 보이는 조각에 제목이 남는다).
List<CellModel> buildMonthModel(
  List<DateTime> days,
  DateTime month,
  List<CalendarGridItem> items,
  Map<String, int> positions,
  ChipMetrics metrics,
) {
  final base = <CellModel>[];
  for (final d in days) {
    final day = _day(d);
    final here =
        items
            .where(
              (e) =>
                  (positions[e.key] ?? -1) >= 0 &&
                  !day.isBefore(e.startDay) &&
                  !day.isAfter(e.endDay),
            )
            .toList()
          ..sort((a, b) {
            // 웹 `getMonthCellEvents` — 이어지는 것(날짜 문자열이 다른 것)이 먼저, 같으면 줄 번호
            final am = a.startAt != a.endAt, bm = b.startAt != b.endAt;
            if (am != bm) return am ? -1 : 1;
            return positions[a.key]!.compareTo(positions[b.key]!);
          });
    final rows = here.fold<int>(
      0,
      (n, e) => positions[e.key]! + 1 > n ? positions[e.key]! + 1 : n,
    );
    final plan = planSlots(rows, metrics);
    final slots = List<ChipSlot?>.filled(plan.shown, null);
    var hidden = 0;
    for (final e in here) {
      final p = positions[e.key]!;
      if (p < plan.shown) {
        slots[p] = ChipSlot(e, _partOf(e, day));
      } else {
        hidden += 1;
      }
    }
    base.add(
      CellModel(
        day: day,
        isOutside: day.month != month.month,
        slots: slots,
        hidden: hidden,
        total: here.length,
      ),
    );
  }
  for (var row = 0; row * 7 < base.length; row++) {
    final hosted = <String>{};
    for (var i = 0; i < 7 && row * 7 + i < base.length; i++) {
      final c = base[row * 7 + i];
      for (final slot in c.slots) {
        if (slot == null || slot.part == ChipPart.none) continue;
        if (!hosted.add(slot.item.key)) continue;
        final toEnd = slot.item.endDay.difference(c.day).inDays + 1;
        final weekdayFromSunday = c.day.weekday % 7;
        var left = [
          toEnd,
          7 - weekdayFromSunday,
          7 - i,
        ].reduce((a, b) => a < b ? a : b);
        // 웹과 달리 이어서 보이는 조각까지만 — 중간 칸에서 접혀 "+N개" 만 남았으면 제목이 그 글자를 덮지 않게 거기서 멈춘다
        var visible = 1;
        while (visible < left &&
            base[row * 7 + i + visible].slots.any(
              (o) => o?.item.key == slot.item.key,
            )) {
          visible += 1;
        }
        final reachesEnd = visible == toEnd;
        left = visible;
        slot.labelDays = left;
        slot.labelReachesEnd = reachesEnd;
      }
    }
  }
  return base;
}
