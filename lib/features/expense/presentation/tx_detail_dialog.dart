import 'package:flutter/material.dart';
import 'package:porest_desk_app/core/format/currency.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/core/sync/keep_alive_refresh.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_detail.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/expense_split/application/expense_split_providers.dart';
import 'package:porest_desk_app/features/dutch_pay/presentation/dutch_pay_from_tx_dialog.dart';
import 'package:porest_desk_app/features/expense_split/presentation/split_tx_dialog.dart';
import 'package:porest_desk_app/features/recurring/presentation/recurring_settings_drawer.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/expense_split/domain/expense_split.dart';
import 'package:porest_desk_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:porest_desk_app/features/expense/presentation/widgets/expense_row.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

/// 거래 상세 다이얼로그 — front `TxDetailDialog` 미러.
///
/// 구성:
/// - Hero: 카테고리 색 그라데이션 배경 + 큰 아이콘 + 가맹점 + 큰 금액 + 날짜
/// - Field rows: 카테고리 / 금액 / 계좌·카드 / 결제 수단 / 날짜·시간 / 메모
/// - Quick actions (3-col grid): 내역 분할 / 반복 설정 / 더치페이
/// - Footer: 삭제 / 편집 / 확인
void showTxDetailDialog(BuildContext context, Expense expense) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  final isIncome = expense.expenseType == 'INCOME';
  showPSheet<void>(
    context,
    title: isIncome ? l.expIncomeDetail : l.expExpenseDetail,
    contentBuilder: (ctx, scrollCtrl) => _DetailBody(
      expense: expense,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) =>
        _TxDetailFooter(expense: expense, controller: controller),
  ).whenComplete(controller.dispose);
}

class _TxDetailFooter extends StatelessWidget {
  const _TxDetailFooter({required this.expense, required this.controller});
  final Expense expense;
  final PSheetController controller;
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) {
        final busy = controller.submitting;
        // 시스템이 만든 거래(매도 실현손익·이체 이자)는 원본을 지워야 사라진다.
        // 버튼을 눌러야 거부 토스트가 뜨는 대신 아예 감춘다.
        final locked = expense.autoSource != null;
        return PViewFooter(
          onDelete: locked ? null : controller.onDelete,
          deleting: busy,
          onEdit: busy || locked
              ? null
              : () {
                  Navigator.of(ctx).pop();
                  showAddTxSheet(ctx, edit: expense);
                },
          onConfirm: () => Navigator.of(ctx).pop(),
        );
      },
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({
    required this.expense,
    required this.scrollController,
    required this.controller,
  });
  final Expense expense;
  final ScrollController scrollController;
  final PSheetController controller;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  bool _deleting = false;
  bool _splitExpanded = true; // 분할 요약 카드 펼침 상태

  @override
  void initState() {
    super.initState();
    widget.controller.onDelete = _delete;
  }

  void _setDeleting(bool v) {
    setState(() => _deleting = v);
    widget.controller.setSubmitting(v);
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    // 환불이 달려 있으면 그것도 함께 사라진다 — 모르고 지우면 지출 총액이 조용히 바뀐다.
    final refundCount = widget.expense.refundCount;
    final message = refundCount > 0
        ? '${l.expDeleteConfirm}\n\n${l.expDeleteRefundWarn(refundCount, krw(widget.expense.refundedAmount))}'
        : l.expDeleteConfirm;
    final ok = await showPConfirmDialog(
      context,
      title: l.expDelete,
      message: message,
      confirmLabel: l.actionDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;

    _setDeleting(true);
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      await repo.delete(widget.expense.rowId);
      if (widget.expense.expenseDate != null) {
        final iso = widget.expense.expenseDate!.substring(0, 10);
        final parts = iso.split('-');
        final y = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        ref.invalidate(monthExpensesProvider((year: y, month: m)));
      }
      invalidateAfterExpenseChange(ref);
      if (!mounted) return;
      Navigator.of(context).pop();
      showPSnackBar(context, l.expDeleted, severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(
        context,
        '${l.expDeleteFailed}: ${e.message}',
        severity: PSnackSeverity.error,
      );
    } finally {
      if (mounted) _setDeleting(false);
    }
  }

  String _paymentMethodLabel(AppLocalizations l, String? m) => switch (m) {
    'CASH' => l.expPayCash,
    'CARD' => l.expPayCard,
    'TRANSFER' => l.expPayTransfer,
    'OTHER' => l.expPayOther,
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final masked = ref.watch(hideCardProvider('ledger.txDetail'));
    final e = widget.expense;
    final isIncome = e.expenseType == 'INCOME';
    // 분할 내역 — 퀵액션 배지 개수 + 요약 카드(내역·비율) 표시용.
    final splits = ref.watch(expenseSplitsProvider(e.rowId)).value ?? const <ExpenseSplit>[];
    final splitCount = splits.length;
    final categories = ref.watch(categoriesProvider).value ?? const <ExpenseCategory>[];

    // 카테고리 색은 다크에서 light variant 로 swap(웹 getPaletteByColor 정합) — parseColor(raw) 금지.
    final fg = resolveChartColor(context, e.categoryColor, fallback: t.fgBrand);
    final icon = lucideByName(e.categoryIcon, fallback: LucideIcons.tag);

    final assets = ref.watch(assetsProvider).value ?? const [];
    final asset = assets.where((a) => a.rowId == e.assetRowId).firstOrNull;
    final assetLabel = asset == null
        ? null
        : (asset.institution != null && asset.institution!.isNotEmpty
              ? '${asset.institution} · ${asset.assetName}'
              : asset.assetName);

    final dayStr = (e.expenseDate ?? '').length >= 10
        ? e.expenseDate!.substring(0, 10)
        : null;
    final timeStr = (e.expenseDate ?? '').length >= 16
        ? e.expenseDate!.substring(11, 16)
        : null;
    final timeLabel = (timeStr != null && timeStr != '00:00') ? timeStr : null;

    final paymentLabel = _paymentMethodLabel(l, e.paymentMethod);
    final displayMerchant =
        e.merchant ?? e.description ?? e.categoryName ?? l.expTxFallback;
    // 웹 TxDetailDialog 매칭: 수입=fg-brand (초록), 지출=fg-primary (검정)
    final amountColor = t.fgPrimary;
    final amountText = masked
        ? '••••••'
        : '${isIncome ? '+' : '−'}${krw(e.amount, abs: true)}';

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.x20, 0, PSpace.x20, PSpace.x16),
      children: [
        // Hero — 플랫 좌측 정렬(design 신판 토스 톤, PDetailHero)
        PDetailHero(
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: softBg(context, fg),
              borderRadius: PRadius.tile(32),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: fg),
          ),
          title: displayMerchant,
          meta: dayStr == null
              ? null
              : (timeLabel != null ? '$dayStr · $timeLabel' : dayStr),
          amount: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: amountText,
                  style: TextStyle(
                    fontFamily: PTypo.sans,
                    color: amountColor,
                    fontSize: PFontSize.displayMd,
                    fontWeight: PFontWeight.bold,
                    letterSpacing: -0.96,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (!masked)
                  TextSpan(
                    text: wonUnit(),
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      color: amountColor,
                      fontSize: PFontSize.h4,
                      fontWeight: PFontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Fields — 카드 없는 플랫 행(PDetailField, 웹 body-sm=앱 body 정합)
        PDetailFieldGroup(
          children: [
            PDetailField(
              label: l.expCategory,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: fg,
                      borderRadius: PRadius.brXs,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    e.categoryName ?? l.expUncategorized,
                    style: PTypo.body.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                ],
              ),
            ),
            PDetailField(
              label: l.expAmount,
              child: Text(
                '$amountText${masked ? '' : wonUnit()}',
                style: PTypo.body.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.bold,
                ),
              ),
            ),
            if (e.originalCurrency != null && e.originalAmount != null)
              PDetailField(
                label: l.expForeignPayment,
                child: Text(
                  e.exchangeRate != null
                      ? '${formatOriginalAmount(e.originalAmount!, e.originalCurrency!, Localizations.localeOf(context).toString())} × ${_trimRate(e.exchangeRate!)}'
                      : formatOriginalAmount(e.originalAmount!, e.originalCurrency!,
                          Localizations.localeOf(context).toString()),
                  style: PTypo.body.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
              ),
            if (assetLabel != null)
              PDetailField(
                label: l.expAccountCard,
                child: Text(
                  assetLabel,
                  style: PTypo.body.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
              ),
            if (paymentLabel.isNotEmpty)
              PDetailField(
                label: l.expPaymentMethod,
                child: Text(
                  paymentLabel,
                  style: PTypo.body.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
              ),
            if (dayStr != null)
              PDetailField(
                label: l.expDateTime,
                child: Text(
                  timeLabel != null ? '$dayStr $timeLabel' : dayStr,
                  style: PTypo.body.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
              ),
            PDetailField(
              label: l.expDescription,
              child: Text(
                (e.description ?? '').isEmpty ? l.expValueNone : e.description!,
                style: PTypo.body.copyWith(
                  color: (e.description ?? '').isEmpty
                      ? t.fgTertiary
                      : t.fgPrimary,
                  fontWeight: PFontWeight.medium,
                ),
              ),
            ),
          ],
        ),
        // 시스템이 만든 거래 — 왜 못 고치는지 알려 준다. 버튼만 없으면 고장으로 보인다.
        if (e.autoSource != null)
          PDetailSection(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: PSpace.x12, vertical: PSpace.x8),
              decoration: BoxDecoration(
                color: t.bgMuted,
                borderRadius: PRadius.brMd,
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.lock, size: 14, color: t.fgTertiary),
                  const SizedBox(width: PSpace.x8),
                  Expanded(
                    child: Text(
                      switch (e.autoSource) {
                        'TRADE_REALIZED' => l.expAutoSourceTradeRealized,
                        'TRANSFER_INTEREST' => l.expAutoSourceTransferInterest,
                        _ => l.expAutoSourceDefault,
                      },
                      style: PTypo.caption.copyWith(color: t.fgTertiary),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 환불 연결 — 이 거래에 달린 환불이 있으면 알린다. 지우면 함께 사라지고,
        // 지출 총액도 상계된 값으로 잡혀 있다는 걸 여기서만 알 수 있다.
        if (e.refundCount > 0)
          PDetailSection(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: PSpace.x12, vertical: PSpace.x8),
              decoration: BoxDecoration(
                color: t.bgMuted,
                borderRadius: PRadius.brMd,
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.undo2, size: 15, color: t.fgTertiary),
                  const SizedBox(width: PSpace.x8),
                  Expanded(
                    child: Text(
                      l.expRefundLinked(e.refundCount, krw(e.refundedAmount)),
                      style: PTypo.bodySm.copyWith(color: t.fgSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Quick actions — 원형 아이콘(PDetailQuickAction, 연결 시 active)
        PDetailSection(
          child: Row(
            children: [
              // 환불 — 지출에만. 수입으로 기록하되 원거래에 묶여 통계에서 지출을 상계한다
              // (수입이 부풀지 않는다). 부분 환불이면 금액만 고치면 된다.
              if (!isIncome)
                Expanded(
                  child: PDetailQuickAction(
                    icon: LucideIcons.undo2,
                    label: l.expRefund,
                    onTap: _deleting
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            showAddTxSheet(context, refundOf: e);
                          },
                  ),
                ),
              Expanded(
                child: PDetailQuickAction(
                  icon: LucideIcons.scissors,
                  label: l.expSplit,
                  active: splitCount > 0,
                  badge: splitCount > 0 ? l.expItemsCount(splitCount) : null,
                  onTap: _deleting
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          showSplitTxDialog(context, e);
                        },
                ),
              ),
              Expanded(
                child: PDetailQuickAction(
                  icon: LucideIcons.repeat,
                  label: l.expConvertRecurring,
                  onTap: _deleting
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          showRecurringSettingsDialog(context, expense: e);
                        },
                ),
              ),
              Expanded(
                child: PDetailQuickAction(
                  icon: LucideIcons.users,
                  label: l.dutchTitle,
                  onTap: _deleting
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          showDutchPayFromTxDialog(context, e);
                        },
                ),
              ),
            ],
          ),
        ),
        // 분할 내역 요약 — 분할이 있으면 접을 수 있는 카드로 항목·비율 표시(쉬운 확인)
        if (splits.isNotEmpty)
          _SplitSummaryCard(
            splits: splits,
            isIncome: isIncome,
            total: e.amount.abs(),
            categories: categories,
            expanded: _splitExpanded,
            onToggle: () => setState(() => _splitExpanded = !_splitExpanded),
            tokens: t,
          ),
        // Merchant history — 같은 가맹점·같은 달 이전 거래
        if ((e.merchant ?? '').isNotEmpty && dayStr != null)
          _MerchantHistorySection(
            merchant: e.merchant!,
            year: int.parse(dayStr.substring(0, 4)),
            month: int.parse(dayStr.substring(5, 7)),
            excludeRowId: e.rowId,
            masked: masked,
            tokens: t,
          ),
      ],
    );
  }
}

/// "이마트에서의 이전 거래" 섹션 — 같은 가맹점·같은 달 거래 리스트.
class _MerchantHistorySection extends ConsumerWidget {
  const _MerchantHistorySection({
    required this.merchant,
    required this.year,
    required this.month,
    required this.excludeRowId,
    required this.masked,
    required this.tokens,
  });
  final String merchant;
  final int year;
  final int month;
  final int excludeRowId;
  final bool masked;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(
      merchantMonthExpensesProvider((
        merchant: merchant,
        year: year,
        month: month,
      )),
    );
    final all = async.value ?? const <Expense>[];
    final history = all.where((x) => x.rowId != excludeRowId).take(5).toList();
    if (history.isEmpty) return const SizedBox.shrink();

    final monthCount = all.length;
    final monthTotal = all.fold<int>(0, (s, x) => s + x.amount.abs());
    final categories = ref.watch(categoriesProvider).value ?? const [];

    // 가계부 메인 리스트 미러 — 날짜별 그룹(provider 최신순 유지).
    // 일 합계는 상단 스탯이 대신하므로 헤더는 날짜(요일)만.
    final dayGroups = <String, List<Expense>>{};
    for (final h in history) {
      final k = h.expenseDateOnly ?? '';
      dayGroups.putIfAbsent(k, () => <Expense>[]).add(h);
    }

    // 섹션 제목 + 2열 스플릿 통계(이번 달 거래/총 금액) + 플랫 리스트 —
    // design 신판(카드 제거), 마스킹 시 '원' 미노출(web MaskAmount 컨벤션).
    return PDetailSection(
      title: Text(l.expPrevTxAt(merchant)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: PSpace.x4, bottom: PSpace.x4),
            child: PDetailStatSplit(
              items: [
                PDetailStat(
                  label: l.expThisMonth,
                  value: l.expTimesCount(monthCount),
                ),
                PDetailStat(
                  label: l.expTotal,
                  value: masked
                      ? '••••••'
                      : krwSigned(monthTotal, false, unit: true),
                ),
              ],
            ),
          ),
          for (final entry in dayGroups.entries) ...[
            // 웹 DateGroupHeader 미러 — "7월 8일"(primary/bold) + "수"(tertiary).
            // 이번 달 내역이므로 연도 없이 날짜만(사용자 결정).
            Padding(
              padding: const EdgeInsets.only(top: PSpace.x12, bottom: 6),
              child: Builder(builder: (context) {
                final d = DateTime.tryParse(entry.key);
                if (d == null) {
                  return Text(
                    entry.key,
                    style:
                        PTypo.bodySm.copyWith(color: tokens.fgSecondary),
                  );
                }
                final label = formatDay(d);
                return Row(
                  children: [
                    Text(
                      label.md,
                      style: PTypo.bodySm.copyWith(
                        color: tokens.fgPrimary,
                        fontWeight: PFontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: PSpace.x8),
                    Text(
                      label.dow,
                      style:
                          PTypo.bodySm.copyWith(color: tokens.fgTertiary),
                    ),
                  ],
                );
              }),
            ),
            for (final h in entry.value)
              ExpenseRow(
                expense: h,
                category: h.categoryRowId == null
                    ? null
                    : categories.byRowId(h.categoryRowId!),
                masked: masked,
                interactive: false,
              ),
          ],
        ],
      ),
    );
  }
}

/// 분할 내역 요약 카드 — 헤더(개수·합계·펼침) + 비율 바 + 항목별(이름·카테고리·비율·금액).
/// 거래에 분할이 있을 때 거래 상세에서 한눈에 확인용(웹 TxDetailDialog 분할 요약 정합).
class _SplitSummaryCard extends StatelessWidget {
  const _SplitSummaryCard({
    required this.splits,
    required this.isIncome,
    required this.total,
    required this.categories,
    required this.expanded,
    required this.onToggle,
    required this.tokens,
  });
  final List<ExpenseSplit> splits;
  final bool isIncome;
  final int total;
  final List<ExpenseCategory> categories;
  final bool expanded;
  final VoidCallback onToggle;
  final PorestTokens tokens;

  Color _colorFor(BuildContext context, int categoryRowId) => resolveChartColor(
      context, categories.byRowId(categoryRowId)?.color,
      fallback: tokens.fgBrand);

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final l = AppLocalizations.of(context);
    return PDetailSection(
      title: Text('${l.expSplit} ${l.expItemsCount(splits.length)}'),
      // 접기 토글 — 합계 우측 chevron (사용자 결정, 웹 정합)
      trailing: InkWell(
        onTap: onToggle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${l.expTotal} ${krwSigned(total, false, unit: true)}',
                style: PTypo.caption.copyWith(color: t.fgTertiary)),
            const SizedBox(width: 6),
            Icon(
                expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: 16,
                color: t.fgTertiary),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: PRadius.brFull,
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  for (final s in splits)
                    if (total > 0 && s.amount > 0)
                      Flexible(
                        flex: s.amount,
                        child: Container(
                            color: _colorFor(context, s.categoryRowId)),
                      ),
                ],
              ),
            ),
          ),
          if (expanded)
            for (int i = 0; i < splits.length; i++)
              Padding(
                padding: EdgeInsets.only(
                    top: 10, bottom: i == splits.length - 1 ? 0 : 0),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _colorFor(context, splits[i].categoryRowId),
                        borderRadius: PRadius.brXs,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (splits[i].label?.trim().isNotEmpty ?? false)
                                ? splits[i].label!
                                : (splits[i].categoryName ?? l.expItem),
                            style: PTypo.bodySm.copyWith(
                                color: t.fgPrimary,
                                fontWeight: PFontWeight.semi),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${splits[i].categoryName ?? '-'} · '
                            '${total > 0 ? ((splits[i].amount / total) * 100).round() : 0}%',
                            style: PTypo.caption.copyWith(color: t.fgTertiary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      krwSigned(splits[i].amount, false,
                          sign: isIncome ? '+' : '−', unit: true),
                      // 행 금액 중립색 — 가계부 리스트 정합(사용자 결정)
                      style: PTypo.bodySm.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.bold),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// 1400.000000 을 1400 으로 — 상세에 소수 6자리를 그대로 보여 주면 지저분하다.
String _trimRate(double rate) {
  final s = rate.toStringAsFixed(6);
  return s.contains('.')
      ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : s;
}
