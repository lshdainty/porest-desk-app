import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

/// 할일 화면/다이얼로그 공유 메타 — 태그 묶음 키, 우선순위 색/라벨, 상대시간·overdue.
///
/// 웹 `screens-life.jsx` `TODO_PRIO` / `lifeRelativeDate` 미러.
/// tag 는 기존 `category` 필드에 저장(자유 텍스트 — 목록은 서버 태그 마스터가 SoT).

/// '태그 없음' 묶음을 가리키는 sentinel — 칩 필터·묶음 키와 표시에만 쓰고
/// **서버로는 나가지 않는다**(편집기는 이 값을 쓰지 않고 `null` 을 싣는다).
///
/// 종전엔 `category` 가 비면 '개인' 을 그렸다. 태그를 지우면 서버가 그 할 일의
/// `category` 를 실제로 비우는데(`TodoTagServiceImpl.deleteTag`) 화면이 '개인' 을
/// 계속 그리면, 삭제 확인창이 약속한 "태그 없음으로 남아요" 와 어긋난다 —
/// **'개인' 태그를 지운 사용자가 여전히 '개인' 을 본다.**
///
/// 값은 U+FFFF(비문자)다. 태그 이름은 사용자가 치는 글자라 어떤 평범한 문자열도
/// sentinel 로 쓸 수 없다. 웹 `src/pages/todo/lib/todo-tags.ts` 의 `NO_TAG_KEY` ·
/// 메모 쪽 `kMemoNoTagKey` 와 **같은 값**이다.
const kTodoNoTagKey = '\u{FFFF}';

/// 칩 필터·묶음에서 이 할 일이 속할 키. 태그가 없으면 '태그 없음' 묶음이다.
///
/// 웹 `todoTagKey` 미러. 이름을 **지어내지 않는다** — 옛 `todoTagOrDefault` 는 빈
/// `category` 를 '개인' 으로 채웠고, 그 값이 편집기 기본값으로 흘러 제목만 고쳐
/// 저장해도 서버가 '개인' 태그를 새로 만들었다(QA #105).
String todoTagKey(String? category) {
  final v = category?.trim();
  return (v == null || v.isEmpty) ? kTodoNoTagKey : v;
}

/// 묶음 키 → 화면 라벨. sentinel 은 번역 문구로 바꿔 그린다 — U+FFFF 를 그대로
/// 그리면 안 보이는 글자 하나가 태그 이름 자리에 남는다. 웹 `tagKeyLabel` 미러.
String todoTagLabel(AppLocalizations l, String key) =>
    key == kTodoNoTagKey ? l.todoTagNone : key;

/// 우선순위 메타 — 라벨 + chip 색/배경.
///
/// 중요=error(빨강) / 보통=warning(노랑) / 여유=info(파랑) —
/// status*Fg 토큰은 다크에서 *-light 로 스왑(웹 status-*-fg 정합, 사용자 결정).
class TodoPrioMeta {
  const TodoPrioMeta(this.code, this.label);
  final String code;
  final String label;

  /// 칩/아이콘 전경색 (다크 light 스왑 내장 토큰).
  Color color(BuildContext context) {
    final t = context.tokens;
    return switch (code) {
      'HIGH' => t.statusDangerFg,
      'MEDIUM' => t.statusWarningFg,
      _ => t.statusInfoFg,
    };
  }

  /// 칩/아이콘 배경 — 색 14% 틴트(surface 불투명 혼합).
  Color bg(BuildContext context) {
    final t = context.tokens;
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

/// 우선순위 표시 라벨 로컬라이즈 (meta.label 은 내부 fallback). HIGH 중요 / MEDIUM 보통 / LOW 여유.
String todoPrioLabel(AppLocalizations l, String? code) => switch (code) {
  'HIGH' => l.todoPriorityImportant,
  'LOW' => l.todoPriorityRelaxed,
  _ => l.todoPriorityMedium,
};

/// 우선순위 정렬 가중치 (high → med → low desc).
int todoPrioRank(String? code) => switch (code) {
  'HIGH' => 3,
  'MEDIUM' => 2,
  'LOW' => 1,
  _ => 0,
};

/// overdue 강조용 chart-red (테마 적응) — 체크 테두리·상대시간 색.
Color todoOverdueColor(BuildContext context) => resolveChartColor(
  context,
  '#c73838',
  fallback: context.tokens.statusDanger,
);

/// 자정 기준 날짜(시·분 절단).
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// 미완료 & due < 오늘 → overdue.
bool isTodoOverdue(DateTime? due, DateTime today) {
  if (due == null) return false;
  return dateOnly(due).isBefore(dateOnly(today));
}

/// 상대시간 — 오늘/내일/어제/N일 후/N일 전(±7), 그 외 'M월 D일'.
/// 웹 `lifeRelativeDate` 미러. [l] 로케일 라우팅(ko 회귀 0, en 은 date.dart 스켈레톤).
String todoRelativeDate(AppLocalizations l, DateTime? due, DateTime today) {
  if (due == null) return l.todoNoDue;
  final d = dateOnly(due);
  final base = dateOnly(today);
  final diff = d.difference(base).inDays;
  if (diff == 0) return l.dateToday;
  if (diff == 1) return l.dateTomorrow;
  if (diff == -1) return l.dateYesterday;
  if (diff > 1 && diff <= 7) return l.dateInDays(diff);
  if (diff < -1 && diff >= -7) return l.dateDaysAgo(-diff);
  return formatDay(d).md;
}

/// 그룹 헤더 라벨 — '5월 19일 (월) · N건'.
/// 상대날짜·M월D일·요일·건을 한 함수에서 통째 처리(부분전환 시 en 혼용 방지). [l] 로케일 라우팅.
String todoGroupLabel(AppLocalizations l, DateTime? due, int count) {
  if (due == null) return l.todoGroupLabel(l.todoNoDue, count);
  final day = formatDay(dateOnly(due));
  return l.todoGroupLabel('${day.md} (${day.dow})', count);
}
