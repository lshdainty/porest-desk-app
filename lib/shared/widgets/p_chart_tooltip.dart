import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// 터치 좌표 기준 동적 툴팁 배치 — web recharts 정합.
///
/// 코너 고정이 아니라 포인터(터치) 바로 옆에 띄우되, 툴팁 실제 크기를 받아
/// 차트 영역을 벗어나지 않게 상하좌우 clamp/flip 한다.
/// 차트를 감싼 Stack 안에서 사용: `if (pos != null) PChartTooltipLayer(anchor: pos, child: ...)`.
class PChartTooltipLayer extends StatelessWidget {
  const PChartTooltipLayer({
    super.key,
    required this.anchor,
    required this.child,
  });

  /// 차트 로컬 좌표 (fl_chart touchCallback 의 event.localPosition).
  final Offset anchor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomSingleChildLayout(
          delegate: _PChartTooltipLayoutDelegate(anchor),
          child: child,
        ),
      ),
    );
  }
}

class _PChartTooltipLayoutDelegate extends SingleChildLayoutDelegate {
  _PChartTooltipLayoutDelegate(this.anchor);
  final Offset anchor;
  static const double _gap = 12;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // 가로: 포인터 우측 우선, 공간 부족 시 좌측으로 flip (recharts 동작)
    double x = anchor.dx + _gap;
    if (x + childSize.width > size.width) {
      x = anchor.dx - _gap - childSize.width;
    }
    x = x.clamp(0.0, math.max(0.0, size.width - childSize.width));
    // 세로: 포인터 높이에 중앙 정렬 후 상하 clamp
    double y = anchor.dy - childSize.height / 2;
    y = y.clamp(0.0, math.max(0.0, size.height - childSize.height));
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_PChartTooltipLayoutDelegate oldDelegate) =>
      oldDelegate.anchor != anchor;
}

/// 차트 위에 떠있는 커스텀 오버레이 툴팁 — web ChartTooltip 미러.
///
/// fl_chart 1.2.0 의 RichText 기반 툴팁(`LineTooltipItem`/`BarTooltipItem`)은
/// 모든 자식이 `TextSpan` 이어야 해서 web 의 라운드 사각 인디케이터(radius-xs)나
/// `SizedBox + textAlign:right` 같은 레이아웃 기반 정렬이 불가능. `WidgetSpan` 은
/// placeholder dimensions 미설정으로 assertion 실패. → 기본 툴팁을 끄고
/// 차트 Stack 위 `Positioned` 로 직접 렌더한다 (stats _TrendBigCard 패턴 공용화).
class PChartTooltipBox extends StatelessWidget {
  const PChartTooltipBox({
    super.key,
    required this.title,
    required this.rows,
    this.labelWidth = 36,
    this.footer = const [],
  });
  final String title;
  final List<PChartTooltipRowData> rows;

  /// 라벨 고정폭 — 한글 폭 차이 무시하고 amount 시작 위치 고정 (2자 36 / 3자 40).
  final double labelWidth;

  /// divider 아래 보조 행 (인디케이터 없는 label-value) — web 툴팁 지출/한도 영역 정합.
  final List<PChartTooltipFooterRowData> footer;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return IgnorePointer(
      ignoring: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: t.bgSurface,
          border: Border.all(color: t.borderSubtle, width: 1),
          borderRadius: PRadius.brLg,
          boxShadow: t.shadowSm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: PTypo.micro.copyWith(
                color: t.fgTertiary,
                fontWeight: PFontWeight.semi,
              ),
            ),
            const SizedBox(height: 6),
            for (final r in rows) ...[
              _PChartTooltipRow(data: r, labelWidth: labelWidth),
              if (r != rows.last) const SizedBox(height: 4),
            ],
            if (footer.isNotEmpty) ...[
              Container(
                // 본문 행(인디케이터9+8+label+12+amount110) 폭과 동일한 고정 폭.
                // Positioned 오버레이는 폭이 unbounded 라 Spacer 사용을 위해 필수.
                width: labelWidth + 139,
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: t.borderSubtle)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final f in footer) ...[
                      Row(
                        children: [
                          Text(
                            f.label,
                            style: PTypo.micro.copyWith(color: t.fgSecondary),
                          ),
                          const Spacer(),
                          Text(
                            f.value,
                            style: PTypo.micro.copyWith(
                              color: t.fgSecondary,
                              fontWeight: PFontWeight.semi,
                            ),
                          ),
                        ],
                      ),
                      if (f != footer.last) const SizedBox(height: 3),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// footer 보조 행 데이터 — label 좌측 / value 우측 (인디케이터 없음).
class PChartTooltipFooterRowData {
  const PChartTooltipFooterRowData({required this.label, required this.value});
  final String label;
  final String value;
}

class PChartTooltipRowData {
  const PChartTooltipRowData({
    required this.color,
    required this.label,
    required this.amount,
    this.amountColor,
  });
  final Color color;
  final String label;
  final String amount;
  final Color? amountColor;
}

class _PChartTooltipRow extends StatelessWidget {
  const _PChartTooltipRow({required this.data, required this.labelWidth});
  final PChartTooltipRowData data;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // web 툴팁 인디케이터 정합 — 원(●)이 아닌 라운드 사각형(radius-xs)
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: data.color,
            borderRadius: PRadius.brXs,
          ),
        ),
        const SizedBox(width: 8),
        // 라벨 폭 고정 — 한글 폭 차이 무시하고 amount 시작 위치를 고정.
        SizedBox(
          width: labelWidth,
          child: Text(
            data.label,
            style: PTypo.caption.copyWith(color: t.fgSecondary),
          ),
        ),
        const SizedBox(width: 12),
        // amount 는 우측 정렬된 고정폭 박스 안에 둬서 행 간 우측 끝점 일치.
        SizedBox(
          width: 110,
          child: Text(
            data.amount,
            textAlign: TextAlign.right,
            style: PTypo.bodySm.copyWith(
              color: data.amountColor ?? t.fgPrimary,
              fontWeight: PFontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
