import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';

/// 할일 화면/다이얼로그 공유 메타 — 태그 7종, 우선순위 색/라벨, 상대시간·overdue.
///
/// 웹 `screens-life.jsx` `TODO_TAGS` / `TODO_PRIO` / `lifeRelativeDate` 미러.
/// tag 는 기존 `category` 필드에 저장(자유 텍스트 → select 7종).

/// 태그 7종 — 기본 '개인'. 저장은 todo.category 필드.
const kTodoTags = <String>[
  '가계부',
  '자산',
  '결제',
  '업무',
  '개인',
  '건강',
  '고정비',
];

const kTodoDefaultTag = '개인';

/// 미정의/빈 category → 기본 '개인'.
String todoTagOrDefault(String? raw) {
  final v = raw?.trim();
  if (v == null || v.isEmpty) return kTodoDefaultTag;
  return kTodoTags.contains(v) ? v : kTodoDefaultTag;
}

/// 우선순위 메타 — 라벨 + chip 색/배경.
///
/// high = chart-red(테마 적응) + bg 14% 틴트(surface 혼합)
/// med  = chart-orange + 14% 틴트
/// low  = fg-tertiary + bg-sunken
class TodoPrioMeta {
  const TodoPrioMeta(this.code, this.label);
  final String code;
  final String label;

  /// 칩/아이콘 전경색 (테마 적응).
  Color color(BuildContext context) {
    final t = context.tokens;
    return switch (code) {
      'HIGH' => resolveChartColor(context, '#c73838', fallback: t.statusDanger),
      'MEDIUM' =>
        resolveChartColor(context, '#b36418', fallback: t.statusWarning),
      _ => t.fgTertiary,
    };
  }

  /// 칩/아이콘 배경 — high/med 는 색 14% 틴트(surface 불투명 혼합), low 는 bg-sunken.
  Color bg(BuildContext context) {
    final t = context.tokens;
    if (code == 'LOW') return t.bgSunken;
    return Color.lerp(t.bgSurface, color(context), 0.14)!;
  }
}

const kTodoPrios = <TodoPrioMeta>[
  TodoPrioMeta('HIGH', '중요'),
  TodoPrioMeta('MEDIUM', '보통'),
  TodoPrioMeta('LOW', '여유'),
];

TodoPrioMeta todoPrioOf(String? code) => kTodoPrios.firstWhere(
      (p) => p.code == (code ?? 'MEDIUM'),
      orElse: () => kTodoPrios[1],
    );

/// 우선순위 정렬 가중치 (high → med → low desc).
int todoPrioRank(String? code) => switch (code) {
      'HIGH' => 3,
      'MEDIUM' => 2,
      'LOW' => 1,
      _ => 0,
    };

/// overdue 강조용 chart-red (테마 적응) — 체크 테두리·상대시간 색.
Color todoOverdueColor(BuildContext context) =>
    resolveChartColor(context, '#c73838', fallback: context.tokens.statusDanger);

/// 자정 기준 날짜(시·분 절단).
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// 미완료 & due < 오늘 → overdue.
bool isTodoOverdue(DateTime? due, DateTime today) {
  if (due == null) return false;
  return dateOnly(due).isBefore(dateOnly(today));
}

/// 상대시간 — 오늘/내일/어제/N일 후/N일 전(±7), 그 외 'M월 D일'.
/// 웹 `lifeRelativeDate` 미러.
String todoRelativeDate(DateTime? due, DateTime today) {
  if (due == null) return '마감일 없음';
  final d = dateOnly(due);
  final base = dateOnly(today);
  final diff = d.difference(base).inDays;
  if (diff == 0) return '오늘';
  if (diff == 1) return '내일';
  if (diff == -1) return '어제';
  if (diff > 1 && diff <= 7) return '$diff일 후';
  if (diff < -1 && diff >= -7) return '${-diff}일 전';
  return '${d.month}월 ${d.day}일';
}

/// 그룹 헤더 라벨 — '5월 19일 (월) · N건'.
String todoGroupLabel(DateTime? due, int count) {
  if (due == null) return '마감일 없음 · $count건';
  final d = dateOnly(due);
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  final w = weekdays[(d.weekday - 1) % 7];
  return '${d.month}월 ${d.day}일 ($w) · $count건';
}
