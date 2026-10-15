import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/chart/p_chart_parts.dart';
import 'package:porest_desk_app/shared/ds/chart/p_chart_values.dart';

/// 열지도 줄 — 시간대 하나. [label] 은 이름("저녁" · 13 · 700), [sub] 는 시간("18~22시" · 11 · fg-neutral-subtle).
class PHeatmapRow {
  const PHeatmapRow({required this.key, required this.label, this.sub});

  final String key;
  final String label;
  final String? sub;
}

/// 열지도 칸 열 — 요일 하나("수" · 12 · fg-neutral-subtle).
class PHeatmapColumn {
  const PHeatmapColumn({required this.key, required this.label});

  final String key;
  final String label;
}

const _tabular = [FontFeature.tabularFigures()];

/// 열지도 — 요일 × 시간 같은 두 축의 세기. 왼쪽 시간대 라벨 열 56 + 요일 칸, 위 요일 머리 12. 칸은 정사각형 · 모서리 4 ·
/// 사이 6. 세기는 다섯 단계 — 브랜드 채움을 카드 면에 18 · 35 · 55 · 75 · 100% 섞은 색(가장 큰 값의 8 · 22 · 45 · 75%
/// 에서 끊는다), 값이 없으면 bg-neutral-weak. 가장 큰 칸에 고리를 두르지 않는다.
///
/// 칸에 금액을 적는 것은 칸 폭이 [textMinCellWidth](112) 이상일 때뿐이다 — 원까지 11 / 15 · 700 · 고정폭 숫자(빈 칸은
/// "—" fg-neutral-subtle). 폰은 늘 좁아 세기 색만 칠한다 — 좁다고 돈을 줄여 쓰거나 글자를 줄이지 않는다. 글자색은 단계마다
/// 칸 바탕 위 4.5 를 넘는 쪽(라이트 75 · 100% 만 흰 글자, 다크는 전부 fg-neutral).
///
/// 칸을 누르면 툴팁(머리 "수요일 저녁 18~22시" · 줄 "■ 지출 35,000원", 네모는 그 칸의 세기 색)이 칸 위에 뜬다 — 손을 떼도
/// 남고, 다른 곳을 누르면 닫힌다. 값은 칸 글자가 아니라 툴팁 · 표로 보기에서 읽는다.
class PHeatmap extends StatefulWidget {
  const PHeatmap({
    super.key,
    required this.label,
    required this.rows,
    required this.columns,
    required this.values,
    this.formatValue,
    this.valueLabel = '지출',
    this.noValueText = '없음',
    this.textMinCellWidth = kHeatTextMinCellWidth,
    this.tooltipLabel,
    this.description,
  });

  /// 요약 이름 — "10월 요일 · 시간대별 지출, 가장 많은 때 토요일 저녁".
  final String label;
  final String? description;
  final List<PHeatmapRow> rows;
  final List<PHeatmapColumn> columns;

  /// 줄 × 칸 — 0 · null 은 값 없음.
  final List<List<double?>> values;

  /// 칸 · 툴팁의 값 — 기본 원까지("35,000원").
  final String Function(double value)? formatValue;

  /// 툴팁 줄의 이름 — 기본 "지출"("■ 지출 35,000원").
  final String valueLabel;

  /// 값이 없는 칸의 툴팁 값.
  final String noValueText;

  /// 칸 폭이 이보다 좁으면 칸에 글을 두지 않는다 — 기본 112.
  final double textMinCellWidth;

  /// 툴팁 머리 — 기본 "{요일} {시간대} {시간}".
  final String Function(PHeatmapRow row, PHeatmapColumn column)? tooltipLabel;

  @override
  State<PHeatmap> createState() => _PHeatmapState();
}

class _PHeatmapState extends State<PHeatmap> {
  ({int row, int col})? _active;

  void _close() {
    if (_active == null) return;
    setState(() => _active = null);
  }

  double? _value(int r, int c) {
    if (r >= widget.values.length) return null;
    final row = widget.values[r];
    return c < row.length ? row[c] : null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fmt = widget.formatValue ?? formatWon;
    var max = 0.0;
    for (final row in widget.values) {
      for (final v in row) {
        if (v != null && v > 0) max = math.max(max, v);
      }
    }
    final texts = heatTextColors(c);
    final cols = widget.columns.length;
    final hasSub = widget.rows.any((r) => r.sub != null);

    return PChartFrame(
      label: widget.label,
      description: widget.description,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cell = math.max(
            0.0,
            (constraints.maxWidth - kHeatLabelColumn - kHeatGap * cols) /
                math.max(1, cols),
          );
          final showText = cell >= widget.textMinCellWidth;
          // 줄 높이 — 칸(정사각형)과 시간대 라벨(13 + 11) 중 큰 쪽
          final rowH = math.max(cell, hasSub ? 33.0 : 18.0);
          const headH = 16.0;
          double cellLeft(int col) =>
              kHeatLabelColumn + kHeatGap + col * (cell + kHeatGap);
          double cellTop(int row) => headH + kHeatGap + row * (rowH + kHeatGap);
          final active = _active;
          final activeRow = active == null || active.row >= widget.rows.length
              ? null
              : widget.rows[active.row];
          final activeCol = active == null || active.col >= cols
              ? null
              : widget.columns[active.col];

          return TapRegion(
            onTapOutside: (_) => _close(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  key: const ValueKey('chart-heatmap'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: kHeatGap,
                  children: [
                    SizedBox(
                      height: headH,
                      child: Row(
                        children: [
                          const SizedBox(width: kHeatLabelColumn + kHeatGap),
                          for (var col = 0; col < cols; col++) ...[
                            SizedBox(
                              width: cell,
                              child: Text(
                                widget.columns[col].label,
                                key: ValueKey('chart-heatmap-column-$col'),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: PTypography.t2.copyWith(
                                  color: c.fgNeutralSubtle,
                                ),
                              ),
                            ),
                            if (col < cols - 1) const SizedBox(width: kHeatGap),
                          ],
                        ],
                      ),
                    ),
                    for (var r = 0; r < widget.rows.length; r++)
                      SizedBox(
                        height: rowH,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: kHeatLabelColumn,
                              height: rowH,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.rows[r].label,
                                    key: ValueKey('chart-heatmap-row-$r'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: PTypography.t3.copyWith(
                                      color: c.fgNeutral,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (widget.rows[r].sub != null)
                                    Text(
                                      widget.rows[r].sub!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: PTypography.t1.copyWith(
                                        color: c.fgNeutralSubtle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: kHeatGap),
                            for (var col = 0; col < cols; col++) ...[
                              _Cell(
                                key: ValueKey('chart-heatmap-cell-$r-$col'),
                                size: cell,
                                step: heatStep(_value(r, col), max),
                                text: showText
                                    ? (heatStep(_value(r, col), max) < 0
                                          ? '—'
                                          : fmt(_value(r, col)!))
                                    : null,
                                colors: c,
                                textColors: texts,
                                onTap: () => setState(
                                  () => _active = (row: r, col: col),
                                ),
                              ),
                              if (col < cols - 1)
                                const SizedBox(width: kHeatGap),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
                if (active != null && activeRow != null && activeCol != null)
                  PChartTipLayer(
                    anchor: Offset(
                      cellLeft(active.col) + cell / 2,
                      cellTop(active.row),
                    ),
                    side: PChartTipSide.above,
                    child: _tip(c, fmt, activeRow, activeCol, max, active),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tip(
    PColors c,
    String Function(double) fmt,
    PHeatmapRow row,
    PHeatmapColumn col,
    double max,
    ({int row, int col}) active,
  ) {
    final v = _value(active.row, active.col);
    final step = heatStep(v, max);
    final head =
        widget.tooltipLabel?.call(row, col) ??
        [col.label, row.label, ?row.sub].join(' ');
    return PChartTooltip(
      head: head,
      rows: [
        PChartTooltipRow(
          swatch: step < 0 ? c.bgNeutralWeak : heatStepColor(c, step),
          name: widget.valueLabel,
          value: step < 0 ? widget.noValueText : fmt(v!),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    super.key,
    required this.size,
    required this.step,
    required this.text,
    required this.colors,
    required this.textColors,
    required this.onTap,
  });

  final double size;
  final int step;
  final String? text;
  final PColors colors;
  final List<Color> textColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => onTap(),
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PRounded.r1),
        color: step < 0 ? colors.bgNeutralWeak : heatStepColor(colors, step),
      ),
      child: text == null
          ? null
          : Text(
              text!,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: PTypography.t1.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: _tabular,
                color: step < 0 ? colors.fgNeutralSubtle : textColors[step],
              ),
            ),
    ),
  );
}
