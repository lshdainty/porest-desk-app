import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/card/p_card.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/chart/p_chart.dart';
import 'package:porest_desk_app/shared/ds/result_section/p_result_section.dart';
import 'package:porest_desk_app/shared/ds/skeleton/p_skeleton.dart';

/// 카탈로그(/dev/ds) — 선(이중 축 · 하나) · 막대 · 도넛 · 열지도 · 툴팁 · 지표 타일(켬 · 끔) · 도넛 범례 · 색 10 · 가장 나쁜 값(데이터 1개 ·
/// 모두 0 · 음수 · 1억 넘는 금액 · 항목 12개) · 빈 · 실패 · 기다림 · 표로 보기. 웹 견본과 같은 구성이다. 차트는 카드 본문 안에 둔다(폰은
/// 카드 폭이 좁아 열지도 칸이 112 보다 좁다 — 칸 글이 보이는 모습은 가로로 미는 넓은 판에서 본다). 호버 · 키보드 초점은 웹 상태라 없다.
class ChartDemo extends StatelessWidget {
  const ChartDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TrendBlock(),
        _SingleAxisBlock(),
        _BarBlock(),
        _DonutBlock(),
        _HeatBlock(),
        _TooltipBlock(),
        _TilesBlock(),
        _DonutLegendBlock(),
        _PaletteBlock(),
        _WorstBlock(),
        _ManyBlock(),
        _HeatWorstBlock(),
        _WaitFailBlock(),
        _TableBlock(),
      ],
    );
  }
}

void _noop() {}

/// 회색 바닥 위 카드 — 차트는 카드 본문 안에 둔다.
class _CardBody extends StatelessWidget {
  const _CardBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.colors.bgLayerBasement,
      borderRadius: BorderRadius.circular(PRounded.r3),
    ),
    child: Padding(
      padding: const EdgeInsets.all(PSpacing.x2),
      child: PCard(children: [PCardContent(children: children)]),
    ),
  );
}

// ── 데이터 ───────────────────────────────────────────────────

// 오늘(8일)에서 끝나는 날짜별 수입 · 지출 — 오늘 뒤는 0 으로 채우지 않는다
const _days = ['1일', '2일', '3일', '4일', '5일', '6일', '7일', '8일'];
const _income = <double>[0, 4200000, 0, 120000, 0, 35000, 0, 86000];
const _expense = <double>[
  18000,
  36000,
  12000,
  86400,
  54000,
  9800,
  41000,
  64500,
];

double _sum(List<double> v) => v.fold(0, (a, b) => a + b);

String _head(String c) => '10월 $c';

List<PChartLegendItem> _tiles(List<double> income, List<double> expense) => [
  PChartLegendItem(
    key: 'income',
    label: '수입',
    color: PChartColor.blue,
    total: formatWon(_sum(income)),
  ),
  PChartLegendItem(
    key: 'expense',
    label: '지출',
    color: PChartColor.red,
    total: formatWon(_sum(expense)),
  ),
];

/// 수입 · 지출 추이 — 지표 타일 + 선(영역) 차트. 타일을 누르면 계열이 켜지고 꺼진다.
class _Trend extends StatefulWidget {
  const _Trend({
    required this.categories,
    required this.income,
    required this.expense,
    this.dual = true,
    this.label,
  });

  final List<String> categories;
  final List<double> income;
  final List<double> expense;
  final bool dual;
  final String? label;

  @override
  State<_Trend> createState() => _TrendState();
}

class _TrendState extends State<_Trend> {
  Set<String> _hidden = {};

  @override
  Widget build(BuildContext context) {
    final items = _tiles(widget.income, widget.expense);
    final summary = '수입 ${items[0].total} · 지출 ${items[1].total}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PSpacing.x2,
      children: [
        PChartLegendTiles(
          items: items,
          hidden: _hidden,
          onHiddenChanged: (h) => setState(() => _hidden = h),
        ),
        PLineChart(
          label: widget.label ?? '10월 수입 · 지출 추이, $summary',
          description: summary,
          categories: widget.categories,
          hidden: _hidden,
          headFormatter: _head,
          series: [
            PChartSeries(
              key: 'income',
              label: '수입',
              color: PChartColor.blue,
              values: widget.income,
            ),
            PChartSeries(
              key: 'expense',
              label: '지출',
              color: PChartColor.red,
              values: widget.expense,
              onRight: widget.dual,
            ),
          ],
        ),
      ],
    );
  }
}

class _TrendBlock extends StatelessWidget {
  const _TrendBlock();

  @override
  Widget build(BuildContext context) => const DemoBlock(
    title:
        '수입 · 지출 추이 — 지표 타일(누르면 계열을 켜고 끈다, 마지막 하나는 끌 수 없다) + 이중 축(왼쪽 수입 blue · 오른쪽 지출 red) · 오늘(8일)에서 끝남 · 차트를 짚으면 툴팁(손을 떼도 남는다)',
    children: [
      _CardBody(
        children: [
          _Trend(categories: _days, income: _income, expense: _expense),
        ],
      ),
    ],
  );
}

class _SingleAxisBlock extends StatelessWidget {
  const _SingleAxisBlock();

  @override
  Widget build(BuildContext context) => DemoBlock(
    title: '축 하나 — 같은 크기의 두 계열(눈금 글자는 회색) · 가리킴(세로 점선 + 점 + 툴팁)',
    children: [
      _CardBody(
        children: [
          _Trend(
            categories: _days,
            income: [for (final v in _income) v / 40],
            expense: _expense,
            dual: false,
            label: '10월 수입 · 지출 추이(같은 단위)',
          ),
        ],
      ),
    ],
  );
}

const _weeks = ['1주', '2주', '3주', '4주'];
const _weekIncome = <double>[4200000, 0, 120000, 86000];
const _weekExpense = <double>[310000, 450000, 280000, 200000];

class _BarBlock extends StatefulWidget {
  const _BarBlock();

  @override
  State<_BarBlock> createState() => _BarBlockState();
}

class _BarBlockState extends State<_BarBlock> {
  Set<String> _hidden = {};

  @override
  Widget build(BuildContext context) {
    final items = _tiles(_weekIncome, _weekExpense);
    return DemoBlock(
      title: '기간별 합 — 막대(최대 폭 28 · 위 모서리 4 · 막대 사이 4) · 한 묶음 두 계열',
      children: [
        _CardBody(
          children: [
            PChartLegendTiles(
              items: items,
              hidden: _hidden,
              onHiddenChanged: (h) => setState(() => _hidden = h),
            ),
            PBarChart(
              label: '10월 주별 수입 · 지출',
              description: '수입 ${items[0].total} · 지출 ${items[1].total}',
              categories: _weeks,
              hidden: _hidden,
              series: const [
                PChartSeries(
                  key: 'income',
                  label: '수입',
                  color: PChartColor.blue,
                  values: _weekIncome,
                ),
                PChartSeries(
                  key: 'expense',
                  label: '지출',
                  color: PChartColor.red,
                  values: _weekExpense,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _Category {
  const _Category(
    this.id,
    this.name,
    this.amount, {
    this.saved,
    this.sub = false,
  });

  final String id;
  final String name;
  final double amount;
  final PChartColor? saved;
  final bool sub;
}

const _categories = [
  _Category('food', '식비', 384400, sub: true),
  _Category('traffic', '교통', 212000, sub: true),
  _Category('event', '경조사', 150000, saved: PChartColor.red),
  _Category('sub', '구독', 96000),
  _Category('health', '의료', 54000),
  _Category('shop', '쇼핑', 31000),
];

const _many = [
  ..._categories,
  _Category('c7', '문화', 28000),
  _Category('c8', '여행', 24000),
  _Category('c9', '교육', 21000),
  _Category('c10', '반려동물', 15000),
  _Category('c11', '육아', 12000),
  _Category('c12', '기부', 9000),
];

/// 카테고리 도넛 — 가운데 합계 + 목록 범례. 저장된 색 먼저, 색 없는 항목은 쓰지 않은 색부터, 10개를 넘으면 상위 9 + 회색 기타.
class _Donut extends StatefulWidget {
  const _Donut({required this.items, required this.label, this.diameter = 160});

  final List<_Category> items;
  final String label;
  final double diameter;

  @override
  State<_Donut> createState() => _DonutState();
}

class _DonutState extends State<_Donut> {
  bool _fits = true;

  @override
  Widget build(BuildContext context) {
    final slices = assignChartColors<_Category>(
      widget.items,
      colorOf: (c) => c.saved,
      groupOthers: (rest) =>
          _Category('others', '기타', rest.fold(0, (a, c) => a + c.amount)),
    );
    final total = widget.items.fold<double>(0, (a, c) => a + c.amount);
    final totalText = formatWon(total);
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PSpacing.x4,
      children: [
        if (!_fits)
          Text(
            '10월 지출 $totalText',
            key: const ValueKey('chart-donut-total'),
            style: PTypography.t5.copyWith(
              color: c.fgNeutral,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        PDonutChart(
          label: widget.label,
          description: '합계 $totalText',
          diameter: widget.diameter,
          centerLabel: '10월 지출',
          centerAmount: totalText,
          onFitChanged: (v) => setState(() => _fits = v),
          slices: [
            for (final s in slices)
              PDonutSlice(
                key: s.item.id,
                label: s.item.name,
                amount: s.item.amount,
                color: s.color,
              ),
          ],
        ),
        PChartDonutLegend(
          bleed: PSpacing.x6,
          items: [
            for (final s in slices)
              PChartDonutLegendItem(
                key: s.item.id,
                label: s.item.name,
                color: s.color,
                percent: '${(s.item.amount / total * 100).round()}%',
                amount: formatWon(s.item.amount),
                onTap: s.item.sub ? _noop : null,
              ),
          ],
        ),
      ],
    );
  }
}

class _DonutBlock extends StatelessWidget {
  const _DonutBlock();

  @override
  Widget build(BuildContext context) => const DemoBlock(
    title:
        '카테고리 비율 — 도넛(두께 22 · 폰 지름 120 은 18) · 가운데 합계는 원까지 · 목록 범례 · 저장된 빨강(경조사)과 같은 색이 두 번 나오지 않는다 · 하위 있는 줄만 누르는 줄',
    children: [
      _CardBody(
        children: [
          _Donut(items: _categories, label: '10월 카테고리별 지출, 합계 927,400원'),
        ],
      ),
      _CardBody(
        children: [
          _Donut(
            items: _categories,
            diameter: 120,
            label: '10월 카테고리별 지출(폰 지름 120)',
          ),
        ],
      ),
    ],
  );
}

const _heatRows = [
  PHeatmapRow(key: 'dawn', label: '새벽', sub: '0~6시'),
  PHeatmapRow(key: 'am', label: '오전', sub: '6~12시'),
  PHeatmapRow(key: 'pm', label: '오후', sub: '12~18시'),
  PHeatmapRow(key: 'eve', label: '저녁', sub: '18~22시'),
  PHeatmapRow(key: 'night', label: '밤', sub: '22~24시'),
];
const _heatCols = [
  PHeatmapColumn(key: '일', label: '일'),
  PHeatmapColumn(key: '월', label: '월'),
  PHeatmapColumn(key: '화', label: '화'),
  PHeatmapColumn(key: '수', label: '수'),
  PHeatmapColumn(key: '목', label: '목'),
  PHeatmapColumn(key: '금', label: '금'),
  PHeatmapColumn(key: '토', label: '토'),
];
const List<List<double?>> _heatValues = [
  [0, 4000, 0, 0, 2500, 0, 12000],
  [8000, 42000, 36000, 12000, 31000, 54000, 18000],
  [21000, 98000, 64000, 48000, 72000, 81000, 134000],
  [35000, 52000, 18000, 120000, 64000, 205000, 340000],
  [null, 0, 9000, 0, 15000, 22000, 0],
];
// 가장 나쁜 값 — 1억 넘는 금액(칸 폭 112 에 999억까지 들어간다)
final List<List<double?>> _heatBig = [
  for (final row in _heatValues)
    [for (final v in row) v == null || v == 0 ? v : v * 2900],
];
const List<List<double?>> _heatHuge = [
  [99999999999, 0, 1, 123456789, null, 5, 70000000000],
  [8000, 42000, 36000, 12000, 31000, 54000, 18000],
  [21000, 98000, 64000, 48000, 72000, 81000, 134000],
  [35000, 52000, 18000, 120000, 64000, 205000, 340000],
  [null, 0, 9000, 0, 15000, 22000, 0],
];

String _heatHead(PHeatmapRow r, PHeatmapColumn c) =>
    '${c.label}요일 ${r.label} ${r.sub}';

/// 넓은 판 — 폰에서는 가로로 밀어 본다(칸 폭이 112 이상일 때 글이 보인다).
class _Wide extends StatelessWidget {
  const _Wide({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SizedBox(width: 960, child: child),
  );
}

class _HeatBlock extends StatelessWidget {
  const _HeatBlock();

  @override
  Widget build(BuildContext context) => DemoBlock(
    title:
        '요일 × 시간 세기 — 열지도(칸 정사각형 · 모서리 4 · 사이 6 · 세기 다섯 단계 · 가장 큰 칸에 고리 없음). 폰 폭의 좁은 칸은 세기 색만 — 값은 칸을 누르면 툴팁. 칸 폭 112 이상(가로로 미는 넓은 판)이면 원까지',
    children: [
      _CardBody(
        children: [
          PHeatmap(
            label: '10월 요일 · 시간대별 지출(폰), 가장 많은 때 토요일 저녁',
            rows: _heatRows,
            columns: _heatCols,
            values: _heatValues,
            tooltipLabel: _heatHead,
          ),
        ],
      ),
      _CardBody(
        children: [
          _Wide(
            child: PHeatmap(
              label: '10월 요일 · 시간대별 지출, 가장 많은 때 토요일 저녁',
              rows: _heatRows,
              columns: _heatCols,
              values: _heatValues,
              tooltipLabel: _heatHead,
            ),
          ),
        ],
      ),
    ],
  );
}

class _TooltipBlock extends StatelessWidget {
  const _TooltipBlock();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DemoBlock(
      title: '툴팁 — 떠 있는 표면(테두리 없음), 머리 12 · 줄 ■ 라벨 값(값은 오른쪽 · 고정폭 · 원까지)',
      children: [
        DemoRow(
          label: '툴팁',
          children: [
            PChartTooltip(
              head: '10월 8일 (목)',
              rows: [
                PChartTooltipRow(
                  swatch: c.chartBlue,
                  name: '수입',
                  value: formatWon(120000),
                ),
                PChartTooltipRow(
                  swatch: c.chartRed,
                  name: '지출',
                  value: formatWon(86400),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _TilesBlock extends StatelessWidget {
  const _TilesBlock();

  @override
  Widget build(BuildContext context) => DemoBlock(
    title:
        '지표 타일 — 켠 계열(옅은 바탕 chart-색-subtle) · 끈 계열(흰 면 + 1px 테두리). 마지막 하나는 끌 수 없어 켠 견본은 셋을 둔다. 누르면 2px 거리 축소',
    children: [
      DemoRow(
        label: 'shown',
        children: [
          SizedBox(
            width: 330,
            child: PChartLegendTiles(
              items: [
                PChartLegendItem(
                  key: 'red',
                  label: 'red',
                  color: PChartColor.red,
                  total: formatWon(1240000),
                ),
                PChartLegendItem(
                  key: 'b',
                  label: '수입',
                  color: PChartColor.blue,
                  total: formatWon(4200000),
                ),
                PChartLegendItem(
                  key: 'c',
                  label: '저축',
                  color: PChartColor.green,
                  total: formatWon(300000),
                ),
              ],
            ),
          ),
        ],
      ),
      DemoRow(
        label: 'hidden',
        children: [
          SizedBox(
            width: 150,
            child: PChartLegendTiles(
              hidden: const {'expense'},
              items: [
                PChartLegendItem(
                  key: 'expense',
                  label: '지출',
                  color: PChartColor.red,
                  total: formatWon(1240000),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

class _DonutLegendBlock extends StatelessWidget {
  const _DonutLegendBlock();

  @override
  Widget build(BuildContext context) => DemoBlock(
    title:
        '도넛 범례 줄 — 쉬는 줄 · 누르는 줄(누름 바탕 = bg-layer-default-pressed, 카드 끝까지 내고 안쪽 6 알약)',
    children: [
      _CardBody(
        children: [
          PChartDonutLegend(
            bleed: PSpacing.x6,
            items: [
              PChartDonutLegendItem(
                key: 'rest',
                label: '식비 — 쉬는 줄',
                color: PChartColor.orange,
                percent: '41%',
                amount: formatWon(384400),
              ),
              PChartDonutLegendItem(
                key: 'press',
                label: '식비 — 누르는 줄',
                color: PChartColor.orange,
                percent: '41%',
                amount: formatWon(384400),
                onTap: _noop,
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _PaletteBlock extends StatelessWidget {
  const _PaletteBlock();

  @override
  Widget build(BuildContext context) => DemoBlock(
    title:
        '색 10 — 차트 10색(라이트 700 · 다크 800-dark) 배정 순서 blue → … → brown, 회색은 기타 전용',
    children: [
      for (final color in PChartColor.values)
        SizedBox(
          width: 330,
          child: PChartLegendTiles(
            semanticLabel: color.name,
            items: [
              PChartLegendItem(
                key: color.name,
                label: color.name,
                color: color,
                total: formatWon(1240000),
              ),
              PChartLegendItem(
                key: '${color.name}-other',
                label: color == PChartColor.blue ? 'green' : 'blue',
                color: color == PChartColor.blue
                    ? PChartColor.green
                    : PChartColor.blue,
                total: formatWon(300000),
              ),
            ],
          ),
        ),
    ],
  );
}

class _WorstBlock extends StatelessWidget {
  const _WorstBlock();

  @override
  Widget build(BuildContext context) => DemoBlock(
    title: '가장 나쁜 값 — 데이터 1개 · 모두 0 · 음수(−3,000만 축이 잘리지 않음) · 1억 넘는 금액',
    children: [
      const _CardBody(
        children: [
          _Trend(
            categories: ['1일'],
            income: [0],
            expense: [18000],
            dual: false,
            label: '10월 1일 수입 · 지출(하루)',
          ),
        ],
      ),
      _CardBody(
        children: [
          _Trend(
            categories: _days,
            income: List.filled(_days.length, 0),
            expense: List.filled(_days.length, 0),
            dual: false,
            label: '10월 수입 · 지출 추이, 모두 0원',
          ),
        ],
      ),
      const _CardBody(
        children: [
          PBarChart(
            label: '순자산 변화, 가장 낮은 때 −30,000,000원',
            categories: ['7월', '8월', '9월', '10월'],
            series: [
              PChartSeries(
                key: 'a',
                label: '자산',
                color: PChartColor.blue,
                values: [-30000000, -18000000, 2000000, 10000000],
              ),
              PChartSeries(
                key: 'b',
                label: '부채',
                color: PChartColor.red,
                values: [-12000000, 4000000, 9000000, -5000000],
              ),
            ],
          ),
        ],
      ),
      _CardBody(
        children: [
          _Trend(
            categories: _days,
            income: [for (final v in _income) v * 30],
            expense: [for (final v in _expense) v * 1400],
            dual: false,
            label: '10월 수입 · 지출 추이, 1억 넘는 금액',
          ),
        ],
      ),
    ],
  );
}

class _ManyBlock extends StatelessWidget {
  const _ManyBlock();

  @override
  Widget build(BuildContext context) => DemoBlock(
    title:
        '항목 12개 · 가운데에 들어가지 않는 합계 — 상위 9 + 회색 기타(목록 10줄), 도넛 가운데 글을 빼고 목록 위에 합계를 둔다(줄이지 않는다)',
    children: [
      const _CardBody(
        children: [_Donut(items: _many, label: '10월 카테고리별 지출, 항목 12개')],
      ),
      _CardBody(
        children: [
          _Donut(
            items: [
              for (final c in _many)
                _Category(c.id, c.name, c.amount * 300, saved: c.saved),
            ],
            diameter: 120,
            label: '10월 카테고리별 지출, 1억 넘는 합계',
          ),
        ],
      ),
    ],
  );
}

class _HeatWorstBlock extends StatelessWidget {
  const _HeatWorstBlock();

  @override
  Widget build(BuildContext context) => DemoBlock(
    title:
        '열지도 가장 나쁜 값 — 1억 넘는 금액 · 999억(칸 112 에 들어간다) · 1원 · 값 없음(—) · 폰 폭에서도 색만',
    children: [
      _CardBody(
        children: [
          _Wide(
            child: PHeatmap(
              label: '10월 요일 · 시간대별 지출, 큰 금액',
              rows: _heatRows,
              columns: _heatCols,
              values: _heatHuge,
              tooltipLabel: _heatHead,
            ),
          ),
        ],
      ),
      _CardBody(
        children: [
          _Wide(
            child: PHeatmap(
              label: '10월 요일 · 시간대별 지출, 1억 넘는 금액',
              rows: _heatRows,
              columns: _heatCols,
              values: _heatBig,
              tooltipLabel: _heatHead,
            ),
          ),
        ],
      ),
    ],
  );
}

class _WaitFailBlock extends StatelessWidget {
  const _WaitFailBlock();

  @override
  Widget build(BuildContext context) => DemoBlock(
    title:
        '빈 · 실패 · 기다림 — 카드 머리 · 타일 이름 · 범례 틀은 그리고 차트 자리만 바꾼다(빈 축 · 회색 고리 · 0 막대로 대신하지 않는다)',
    children: [
      _CardBody(
        children: [PSkeleton(height: 200, radius: PSkeletonRadius.r16)],
      ),
      const _CardBody(
        children: [
          PResultSection(
            size: PResultSize.medium,
            placement: PResultPlacement.card,
            icon: LucideIcons.receiptText,
            title: '이번 달 지출이 없어요',
          ),
        ],
      ),
      _CardBody(
        children: [
          PResultSection(
            kind: PResultKind.failure,
            size: PResultSize.medium,
            placement: PResultPlacement.card,
            title: '추이를 불러오지 못했어요',
            description: '잠시 뒤 다시 시도해주세요.',
            primaryAction: const PResultAction(
              label: '다시 시도',
              onPressed: _noop,
            ),
          ),
        ],
      ),
    ],
  );
}

class _TableBlock extends StatelessWidget {
  const _TableBlock();

  @override
  Widget build(BuildContext context) => DemoBlock(
    title: '표로 보기 — 날짜마다 값을 읽어야 하는 차트의 대체(보조 기술용 숨긴 표, 펼치면 이 모습)',
    children: [
      _CardBody(
        children: [
          PChartDataTable(
            visuallyHidden: false,
            caption: '10월 날짜별 수입 · 지출',
            columns: const [
              PChartDataColumn('날짜'),
              PChartDataColumn('수입'),
              PChartDataColumn('지출'),
            ],
            rows: [
              for (var i = 0; i < 4; i++)
                [
                  '10월 ${_days[i]}',
                  formatWon(_income[i]),
                  formatWon(_expense[i]),
                ],
            ],
          ),
        ],
      ),
    ],
  );
}
