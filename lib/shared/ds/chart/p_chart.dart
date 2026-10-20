/// Chart — 숫자의 흐름 · 비율 · 세기를 그림으로 보이는 차트(선 · 막대 · 도넛 · 열지도). 차트는 카드 본문 안에 두고, 같은
/// 숫자를 범례 · 툴팁의 글로도 읽을 수 있게 한다. 수치 원본은 groo-design `specs/components/chart.yaml`(값은
/// `test/fixtures/design_spec/chart.json`). 웹(desk-front `src/shared/ds/chart`)과 같은 값이다. 차트 라이브러리는 fl_chart.
///
///   [PLineChart] · [PBarChart]   선(영역) · 막대 — categories × series(이중 축: 계열 하나를 onRight). 위 지표 타일이 범례다
///   [PDonutChart]                도넛 — 가운데 합계, 구멍에 안 들어가면 onFitChanged 로 알린다(목록 위에 합계를 둔다)
///   [PHeatmap]                   요일 × 시간 열지도
///   [PChartLegendTiles]          선 · 막대 위 지표 타일(켜고 끄기 — 마지막 하나는 잠김)
///   [PChartDonutLegend]          도넛 목록 범례(하위가 있는 줄만 누르는 줄)
///   [PChartDataTable]            표로 보기 — 보조 기술용 숨긴 표(또는 펼친 표)
///   [PChartFrame] · [PChartTooltip]   차트 상자(요약 이름) · 툴팁 표면
///   assignChartColors · formatWon · formatAxisWon   색 배정 · 숫자
///
/// 색 — 차트 10색(라이트 팔레트 700 · 다크 800-dark). 저장된 색 먼저, 나머지는 쓰지 않은 색부터 배정 순서(blue → green →
/// orange → violet → pink → indigo → red → yellow → brown), 10개를 넘으면 상위 9 + 회색 "기타". 수입 blue · 지출 red.
/// 숫자 — 돈은 원까지(빼기 U+2212), 축만 만 · 억 · 조(소수 한 자리). 오늘 뒤 날짜는 0 으로 채우지 않는다(categories 에 넘기지
/// 않는다). 빈 · 실패 · 기다림은 차트 자리에 [PResultSection] · [PSkeleton] 을 두고 카드 머리 · 타일 이름 · 범례 틀은 그대로
/// 둔다(빈 축 · 회색 고리 · 0 막대로 대신하지 않는다).
///
/// 접근성 — 차트 상자는 `Semantics` 로 요약 이름(label)을 갖고 안의 그림 · 툴팁은 보조 기술에서 뺀다. 같은 값은 지표 타일 ·
/// 목록 범례와 [PChartDataTable] 이 읽어 준다. 모션 줄이기면 그려짐(300ms)을 하지 않는다. 키보드 이동 · 포커스 링은 웹 상태라
/// 앱에는 없다.
library;

export 'package:groo_damda_app/shared/ds/chart/p_chart_cartesian.dart';
export 'package:groo_damda_app/shared/ds/chart/p_chart_donut.dart';
export 'package:groo_damda_app/shared/ds/chart/p_chart_heatmap.dart';
export 'package:groo_damda_app/shared/ds/chart/p_chart_parts.dart';
export 'package:groo_damda_app/shared/ds/chart/p_chart_values.dart';
