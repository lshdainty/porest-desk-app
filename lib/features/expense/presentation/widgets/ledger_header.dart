import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/format_locale.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_cards.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/l10n/ds_l10n.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/divider/p_divider.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_parts.dart';

/// 가계부 원장 머리 — 달 이동 · 합계 · 인사이트 · 소비 요약 · 주 달력(I-07 7 · 8 · 11).
///
/// 이 머리는 ds Scroll Auto Hide 가 통째로 숨긴다(12). 구조는 그대로 두고 값 · 부품 · 색 역할 이름만 ds 로 옮겼다.

String ledgerYmd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// 달 이동 줄 — ‹ M월 › + 오른쪽 거르기 · 거래 추가. 단추는 Button ghost medium iconOnly(보이는 40 · 아이콘 18 · 누르는 44).
class LedgerMonthNav extends StatelessWidget {
  const LedgerMonthNav({
    super.key,
    required this.label,
    required this.onPrev,
    required this.onNext,
    required this.onOpenFilter,
    required this.onAddTx,
    this.showMonth = true,
  });

  final String label;
  final bool showMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onOpenFilter;
  final VoidCallback onAddTx;

  // 단추 40 의 안쪽 아이콘이 화면 여백 24 에 서도록 여백을 단추 안쪽 여백만큼 덜어 낸다.
  static const double _bleed = (PSpacing.x10 - PSpacing.x4_5) / 2;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpacing.globalGutter - _bleed,
      ),
      child: Row(
        children: [
          if (showMonth) ...[
            PButton.icon(
              icon: LucideIcons.chevronLeft,
              semanticLabel: dsL(context)?.dsDatePrevMonth ?? '이전 달',
              variant: PButtonVariant.ghost,
              onPressed: onPrev,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: PSpacing.x1),
              child: Text(
                label,
                style: PTypography.t6.copyWith(
                  color: c.fgNeutral,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            PButton.icon(
              icon: LucideIcons.chevronRight,
              semanticLabel: dsL(context)?.dsDateNextMonth ?? '다음 달',
              variant: PButtonVariant.ghost,
              onPressed: onNext,
            ),
          ],
          const Spacer(),
          // 걸린 조건의 개수는 배지로 말하지 않는다 — 아래 칩 줄이 말한다.
          PButton.icon(
            icon: LucideIcons.slidersHorizontal,
            semanticLabel: l.expFilter,
            variant: PButtonVariant.ghost,
            onPressed: onOpenFilter,
          ),
          PButton.icon(
            icon: LucideIcons.plus,
            semanticLabel: l.expAdd,
            variant: PButtonVariant.ghost,
            onPressed: onAddTx,
          ),
        ],
      ),
    );
  }
}

/// 이달 지출 합계(R13 지표 t9) + 인사이트 한 줄 + [소비 요약] 단추.
class LedgerTotalRow extends StatelessWidget {
  const LedgerTotalRow({
    super.key,
    required this.total,
    required this.insight,
    required this.summaryOpen,
    required this.onToggleSummary,
    this.loading = false,
    this.failed = false,
  });

  /// 합계 글 — 로딩 중이면 null.
  final String? total;

  /// 인사이트 한 줄 — 없으면 null.
  final Widget? insight;
  final bool summaryOpen;
  final VoidCallback onToggleSummary;

  /// 숫자 자리만 기다린다(틀은 그대로 그린다).
  final bool loading;

  /// 실패 — 숫자를 그리지 않고 [소비 요약] 은 막는다(자리의 안내는 목록 자리 Result Section 이 맡는다).
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpacing.globalGutter,
        PSpacing.x2,
        PSpacing.globalGutter,
        0,
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final button = Semantics(
            container: true,
            expanded: summaryOpen,
            child: PButton(
              label: l.txmSpendSummary,
              size: PButtonSize.small,
              variant: PButtonVariant.neutralOutline,
              onPressed: (loading || failed) ? null : onToggleSummary,
            ),
          );
          final figures = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (loading) ...[
                PSkeleton.text(PTypography.t9, width: 160),
                const SizedBox(height: PSpacing.x1_5),
                PSkeleton.text(PTypography.t4, width: 200),
              ] else if (!failed) ...[
                Text(
                  // 금액은 쉼표 뒤에서만 줄을 바꾼다 — 큰 글자에서 숫자 가운데가 끊기지 않게
                  keepAllAmount(total ?? ''),
                  semanticsLabel: total,
                  style: PTypography.t9.copyWith(
                    color: c.fgNeutral,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (insight != null)
                  Padding(
                    padding: const EdgeInsets.only(top: PSpacing.x1_5),
                    child: insight,
                  ),
              ],
            ],
          );
          // 단추가 폭의 절반을 넘게 차지하면(큰 글자 · 영어) 합계가 글자 하나씩 꺾이므로 단추를 아래 줄로 내린다(웹 flex-wrap).
          final wide = PButton(
            label: l.txmSpendSummary,
            size: PButtonSize.small,
            onPressed: null,
          ).naturalWidth(context);
          if (wide > box.maxWidth * 0.5) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PSpacing.x3,
              children: [figures, button],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PSpacing.x3,
            children: [
              Expanded(child: figures),
              button,
            ],
          );
        },
      ),
    );
  }
}

/// 펼친 소비 요약 — 카드 없이 보기만 하는 List 줄 셋(수입 · 지출 · 합계). 흰 화면 위 테두리 카드를 두지 않는다.
class LedgerSummaryList extends StatelessWidget {
  const LedgerSummaryList({
    super.key,
    required this.income,
    required this.expense,
    required this.flags,
  });

  final int income;
  final int expense;
  final MaskFlags flags;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    TextStyle value(Color color) => TextStyle(
      color: color,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final net = income - expense;
    return Padding(
      padding: const EdgeInsets.only(top: PSpacing.x2),
      child: PList(
        semanticLabel: l.txmSpendSummary,
        children: [
          PListItem(
            title: l.expSummaryIncome,
            suffix: PListValue.amount(
              krwSigned(
                income,
                flags.of(MaskKind.income),
                sign: '+',
                unit: true,
              ),
              style: value(c.fgBrand),
            ),
          ),
          PListItem(
            title: l.expSummaryExpense,
            suffix: PListValue.amount(
              krwSigned(
                expense,
                flags.of(MaskKind.expense),
                sign: '−',
                unit: true,
              ),
              style: value(c.fgNeutral),
            ),
          ),
          PListItem(
            title: l.expTotal,
            // 합계 줄 제목만 700(지시서 8 — 화면 값)
            titleWeight: FontWeight.w700,
            suffix: PListValue.amount(
              krwSigned(
                net.abs(),
                flags.of(MaskKind.net),
                sign: net >= 0 ? '+' : '−',
                unit: true,
              ),
              style: value(c.fgNeutral),
            ),
          ),
        ],
      ),
    );
  }
}

/// 툴팁 머리 — "10월 21일 (목)"(chart.md · 웹과 같은 꼴).
String _tooltipHead(String ds) {
  final d = DateTime.parse(ds);
  final dow = formatDay(d).dow;
  return localeIsEn()
      ? DateFormat('MMM d (E)', 'en').format(d)
      : '${d.month}월 ${d.day}일 ($dow)';
}

/// 접이식 캘린더 — 접힘: 선택 주 1줄 / 펼침: 월 전체. 요일 t2 · 날 숫자 t5 · 칸 금액 t1.
class LedgerCalendar extends StatelessWidget {
  const LedgerCalendar({
    super.key,
    required this.month,
    required this.selected,
    required this.expanded,
    required this.byDay,
    required this.flags,
    required this.onSelect,
    required this.onToggleExpand,
    this.loading = false,
  });

  final DateTime month;
  final String? selected;
  final bool expanded;
  final Map<String, ({int out, int inn})> byDay;

  /// 화면 카드 + 종류 카드 — 금액마다 자기 종류로 판정한다.
  final MaskFlags flags;
  final ValueChanged<String> onSelect;
  final VoidCallback onToggleExpand;

  /// 칸 금액 자리만 기다린다(요일 · 날 숫자는 그대로).
  final bool loading;

  /// 날 숫자 원 — 눈금 36.
  static const double dayCircle = PSpacing.x9;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final today = DateTime.now();
    final todayStr = ledgerYmd(today);
    final firstDow = DateTime(month.year, month.month, 1).weekday % 7;
    final dim = DateTime(month.year, month.month + 1, 0).day;
    final cells = <({int d, String ds})?>[];
    for (var i = 0; i < firstDow; i++) {
      cells.add(null);
    }
    for (var d = 1; d <= dim; d++) {
      cells.add((
        d: d,
        ds: '${month.year}-${month.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}',
      ));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final weeks = <List<({int d, String ds})?>>[];
    for (var i = 0; i < cells.length; i += 7) {
      weeks.add(cells.sublist(i, i + 7));
    }
    var selWeek = weeks.indexWhere(
      (w) => w.any((c) => c != null && c.ds == selected),
    );
    if (selWeek < 0) {
      selWeek = weeks.indexWhere(
        (w) => w.any((c) => c != null && c.ds == todayStr),
      );
    }
    if (selWeek < 0) selWeek = 0;

    TextStyle amountStyle(Color color) => PTypography.t1.copyWith(
      fontWeight: FontWeight.w700,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    Widget cell(({int d, String ds})? cellData, int i) {
      if (cellData == null) {
        return const Expanded(child: SizedBox(height: PSpacing.x14));
      }
      final isSel = cellData.ds == selected;
      final data = loading ? null : byDay[cellData.ds];
      final future = cellData.ds.compareTo(todayStr) > 0;
      // 오는 날은 불투명도로 흐리지 않고 옅은 글자색 역할로 말한다(v106).
      // 일 = 치명 · 토 = 브랜드(옛 뜻 그대로 — 색 이름만 새것)
      final numColor = isSel
          ? c.staticWhite
          : future
          ? c.fgNeutralSubtle
          : (i % 7 == 0
                ? c.fgCritical
                : (i % 7 == 6 ? c.fgBrand : c.fgNeutral));
      Widget amounts() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (data!.out > 0)
            Text(
              '−${flags.of(MaskKind.expense) ? '••' : krw(data.out)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: amountStyle(c.fgNeutral),
            ),
          if (data.inn > 0)
            Text(
              '+${flags.of(MaskKind.income) ? '••' : krw(data.inn)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: amountStyle(c.fgBrand),
            ),
        ],
      );
      return Expanded(
        child: InkWell(
          onTap: () => onSelect(cellData.ds),
          borderRadius: BorderRadius.circular(PRounded.r3),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, PSpacing.x1, 0, PSpacing.x2),
            child: Column(
              children: [
                // 칸 폭보다 넓어지면(글자 200%) 원째 줄여 맞춘다 — 숫자가 두 줄로 꺾이지 않는다
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    // 최소 36 · 좌우 4 — 글자 200% 에서 두 자리 날이 잘리지 않게 글을 따라 늘어난다(웹 `min-w-x9 px-x1`)
                    constraints: const BoxConstraints(
                      minWidth: dayCircle,
                      minHeight: dayCircle,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: PSpacing.x1,
                    ),
                    decoration: isSel
                        ? BoxDecoration(
                            color: c.bgBrandSolid,
                            borderRadius: BorderRadius.circular(PRounded.full),
                          )
                        : null,
                    child: Center(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: Text(
                        '${cellData.d}',
                        maxLines: 1,
                        softWrap: false,
                        style: PTypography.t5.copyWith(
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: numColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: PSpacing.x1),
                if (loading)
                  PSkeleton.text(PTypography.t1, width: 32)
                else if (data != null)
                  LedgerCellTooltip(
                    title: _tooltipHead(cellData.ds),
                    out: data.out,
                    inn: data.inn,
                    flags: flags,
                    child: amounts(),
                  )
                else
                  const SizedBox(height: PSpacing.x3),
              ],
            ),
          ),
        ),
      );
    }

    final dows = weekdayLabels();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpacing.x4,
        PSpacing.x3,
        PSpacing.x4,
        0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      PSpacing.x1_5,
                      0,
                      PSpacing.x2,
                    ),
                    child: Text(
                      dows[i],
                      textAlign: TextAlign.center,
                      // 일 = 치명 · 토 = 브랜드 · 평일 = 옅은 중립 (뜻은 그대로, 색 역할 이름만)
                      style: PTypography.t2.copyWith(
                        fontWeight: FontWeight.w400,
                        color: i == 0
                            ? c.fgCritical
                            : i == 6
                            ? c.fgBrand
                            : c.fgNeutralSubtle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (final w in expanded ? weeks : [weeks[selWeek]])
            Row(
              // 금액 줄 수가 달라도 날짜 숫자 y 고정.
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (var i = 0; i < 7; i++) cell(w[i], i)],
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: PSpacing.x1),
            child: Center(
              child: Semantics(
                container: true,
                expanded: expanded,
                child: PButton.icon(
                  icon: expanded
                      ? LucideIcons.chevronUp
                      : LucideIcons.chevronDown,
                  // 이름은 늘 "월 달력" — 펼침 여부는 expanded 가 말한다
                  semanticLabel: AppLocalizations.of(context).txmCalendarToggle,
                  variant: PButtonVariant.ghost,
                  onPressed: onToggleExpand,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 머리 아래 선 — Divider 1px `stroke-neutral-subtle` 화면 폭.
class LedgerHeaderDivider extends StatelessWidget {
  const LedgerHeaderDivider({super.key});

  @override
  Widget build(BuildContext context) => const PDivider();
}

/// 칸 금액의 길게 누르기 툴팁 — 지출 · 수입을 차트형 툴팁으로(앱 기존 동작 그대로, 색 역할 이름만 새것).
class LedgerCellTooltip extends StatelessWidget {
  const LedgerCellTooltip({
    super.key,
    required this.title,
    required this.out,
    required this.inn,
    required this.flags,
    required this.child,
  });

  final String title;
  final int out;
  final int inn;
  final MaskFlags flags;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    return Tooltip(
      richMessage: WidgetSpan(
        child: PChartTooltip(
          head: title,
          rows: [
            PChartTooltipRow(
              swatch: c.chartRed,
              name: l.expSummaryExpense,
              value: krwSigned(
                out,
                flags.of(MaskKind.expense),
                sign: '−',
                unit: true,
              ),
            ),
            PChartTooltipRow(
              swatch: c.chartBlue,
              name: l.expSummaryIncome,
              value: krwSigned(
                inn,
                flags.of(MaskKind.income),
                sign: '+',
                unit: true,
              ),
            ),
          ],
        ),
      ),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: child,
    );
  }
}
