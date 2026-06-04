import 'package:flutter/material.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

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
  });
  final String title;
  final List<PChartTooltipRowData> rows;

  /// 라벨 고정폭 — 한글 폭 차이 무시하고 amount 시작 위치 고정 (2자 36 / 3자 40).
  final double labelWidth;

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
          ],
        ),
      ),
    );
  }
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
