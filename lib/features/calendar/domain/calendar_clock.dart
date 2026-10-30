/// 캘린더가 읽는 오늘 — 달력 격자의 오늘 원 · 처음 보는 달 · 일정 폼의 날짜 기본값과 올해 판정이 모두 이것 하나를 본다.
/// 시험 · 렌더 하네스가 고정한다(`dashboardNow` 와 같은 이음매). 앱은 늘 [DateTime.now].
DateTime Function() calendarNow = DateTime.now;
