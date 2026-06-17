import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/core/sync/keep_alive_refresh.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
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

/// 거래 상세 다이얼로그 — front `TxDetailDialog` 미러.
///
/// 구성:
/// - Hero: 카테고리 색 그라데이션 배경 + 큰 아이콘 + 가맹점 + 큰 금액 + 날짜
/// - Field rows: 카테고리 / 금액 / 계좌·카드 / 결제 수단 / 날짜·시간 / 메모
/// - Quick actions (3-col grid): 내역 분할 / 반복 설정 / 더치페이
/// - Footer: 삭제 / 편집 / 확인
void showTxDetailDialog(BuildContext context, Expense expense) {
  final controller = PSheetController();
  final isIncome = expense.expenseType == 'INCOME';
  showPSheet<void>(
    context,
    title: isIncome ? '수입 상세' : '지출 상세',
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
        return Row(
          children: [
            PButton(
              label: '삭제',
              icon: LucideIcons.trash2,
              variant: PButtonVariant.ghost,
              dangerous: true,
              loading: busy,
              onPressed: busy ? null : controller.onDelete,
            ),
            const Spacer(),
            PButton(
              label: '편집',
              icon: LucideIcons.pencil,
              variant: PButtonVariant.ghost,
              onPressed: busy
                  ? null
                  : () {
                      Navigator.of(ctx).pop();
                      showAddTxSheet(ctx, edit: expense);
                    },
            ),
            const SizedBox(width: PSpace.x8),
            PButton(
              label: '확인',
              onPressed: busy ? null : () => Navigator.of(ctx).pop(),
            ),
          ],
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
    final ok = await showPConfirmDialog(
      context,
      title: '거래 삭제',
      message: '이 거래를 삭제하시겠습니까? 연결된 자산 잔액이 함께 조정됩니다.',
      confirmLabel: '삭제',
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
      invalidateAssetsAfterExpense(ref);
      if (!mounted) return;
      Navigator.of(context).pop();
      showPSnackBar(context, '거래가 삭제되었습니다', severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(
        context,
        '삭제 실패: ${e.message}',
        severity: PSnackSeverity.error,
      );
    } finally {
      if (mounted) _setDeleting(false);
    }
  }

  String _paymentMethodLabel(String? m) => switch (m) {
    'CASH' => '현금',
    'CARD' => '카드',
    'TRANSFER' => '계좌이체',
    'OTHER' => '기타',
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final masked = settings.hideAmounts;
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

    final paymentLabel = _paymentMethodLabel(e.paymentMethod);
    final displayMerchant =
        e.merchant ?? e.description ?? e.categoryName ?? '거래';
    // 웹 TxDetailDialog 매칭: 수입=fg-brand (초록), 지출=fg-primary (검정)
    final amountColor = isIncome ? t.fgIncome : t.fgPrimary;
    final amountText = masked
        ? '••••••'
        : '${isIncome ? '+' : '−'}${krw(e.amount, abs: true)}';

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.x20, 0, PSpace.x20, PSpace.x16),
      children: [
        // Hero card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(fg.withValues(alpha: 0.18), t.bgSurface),
                t.bgSurface,
              ],
              stops: const [0.0, 0.85],
            ),
            border: Border.all(color: fg.withValues(alpha: 0.2)),
            borderRadius: PRadius.brXl,
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.18),
                  borderRadius: PRadius.tile(40),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: fg),
              ),
              const SizedBox(height: 12),
              Text(
                displayMerchant,
                style: PTypo.bodySm.copyWith(
                  color: t.fgSecondary,
                  fontWeight: PFontWeight.medium,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: amountText,
                      style: TextStyle(
                        color: amountColor,
                        fontSize: PFontSize.displayMd,
                        fontWeight: PFontWeight.bold,
                        letterSpacing: -1.02,
                      ),
                    ),
                    if (!masked)
                      TextSpan(
                        text: '원',
                        style: TextStyle(
                          color: amountColor,
                          fontSize: PFontSize.h4,
                          fontWeight: PFontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              if (dayStr != null) ...[
                const SizedBox(height: 6),
                Text(
                  timeLabel != null ? '$dayStr · $timeLabel' : dayStr,
                  style: PTypo.caption.copyWith(color: t.fgTertiary),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Field rows
        Container(
          decoration: BoxDecoration(
            color: t.borderSubtle,
            border: Border.all(color: t.borderSubtle),
            borderRadius: PRadius.brLg,
          ),
          child: Column(
            children: [
              _FieldRow(
                label: '카테고리',
                tokens: t,
                isFirst: true,
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
                      e.categoryName ?? '미분류',
                      style: PTypo.bodySm.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.semi,
                      ),
                    ),
                  ],
                ),
              ),
              _FieldRow(
                label: '금액',
                tokens: t,
                child: Text(
                  '$amountText${masked ? '' : '원'}',
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
              ),
              if (assetLabel != null)
                _FieldRow(
                  label: '계좌·카드',
                  tokens: t,
                  child: Text(
                    assetLabel,
                    style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.medium,
                    ),
                  ),
                ),
              if (paymentLabel.isNotEmpty)
                _FieldRow(
                  label: '결제 수단',
                  tokens: t,
                  child: Text(
                    paymentLabel,
                    style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.medium,
                    ),
                  ),
                ),
              if (dayStr != null)
                _FieldRow(
                  label: '날짜·시간',
                  tokens: t,
                  child: Text(
                    timeLabel != null ? '$dayStr $timeLabel' : dayStr,
                    style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.medium,
                    ),
                  ),
                ),
              _FieldRow(
                label: '메모',
                tokens: t,
                isLast: true,
                child: Text(
                  (e.description ?? '').isEmpty ? '없음' : e.description!,
                  style: PTypo.bodySm.copyWith(
                    color: (e.description ?? '').isEmpty
                        ? t.fgTertiary
                        : t.fgPrimary,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Quick action grid (3-col)
        Row(
          children: [
            Expanded(
              child: _QuickBtn(
                icon: LucideIcons.scissors,
                label: '내역 분할',
                tokens: t,
                badge: splitCount > 0 ? '$splitCount개' : null,
                onTap: _deleting
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        showSplitTxDialog(context, e);
                      },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _QuickBtn(
                icon: LucideIcons.repeat,
                label: '반복 설정',
                tokens: t,
                onTap: _deleting
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        showRecurringSettingsDialog(context, expense: e);
                      },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _QuickBtn(
                icon: LucideIcons.users,
                label: '더치페이',
                tokens: t,
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
        // 분할 내역 요약 — 분할이 있으면 접을 수 있는 카드로 항목·비율 표시(쉬운 확인)
        if (splits.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SplitSummaryCard(
            splits: splits,
            isIncome: isIncome,
            total: e.amount.abs(),
            categories: categories,
            expanded: _splitExpanded,
            onToggle: () => setState(() => _splitExpanded = !_splitExpanded),
            tokens: t,
          ),
        ],
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
    final t = tokens;
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

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$merchant에서의 이전 거래',
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
                const Spacer(),
                RichText(
                  text: TextSpan(
                    style: PTypo.caption.copyWith(color: t.fgTertiary),
                    children: [
                      const TextSpan(text: '이번 달 '),
                      TextSpan(
                        // 마스킹 시 '원' 미노출 — web MaskAmount+HideUnit 컨벤션
                        text: masked
                            ? '$monthCount회 · ••••••'
                            : '$monthCount회 · ${krw(monthTotal)}원',
                        style: PTypo.caption.copyWith(
                          color: t.fgSecondary,
                          fontWeight: PFontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: t.bgSurface,
              border: Border.all(color: t.borderSubtle),
              borderRadius: PRadius.brLg,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                for (final h in history)
                  ExpenseRow(
                    expense: h,
                    category: h.categoryRowId == null
                        ? null
                        : categories.byRowId(h.categoryRowId!),
                    masked: masked,
                    interactive: false,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.child,
    required this.tokens,
    this.isFirst = false,
    this.isLast = false,
  });
  final String label;
  final Widget child;
  final PorestTokens tokens;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(PRadius.lg) : Radius.zero,
          bottom: isLast ? const Radius.circular(PRadius.lg) : Radius.zero,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: PSpace.x16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: PTypo.caption.copyWith(color: tokens.fgTertiary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: child),
          ),
        ],
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  const _QuickBtn({
    required this.icon,
    required this.label,
    required this.tokens,
    required this.onTap,
    this.badge,
  });
  final IconData icon;
  final String label;
  final PorestTokens tokens;
  final VoidCallback? onTap;
  /// 우상단 배지(예: 분할 개수 'N개'). null 이면 미표시.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: PRadius.brLg,
      child: Stack(
        children: [
          Container(
            // Stack(loose) 안에서 카드가 내용 폭으로 줄지 않도록 폭을 채운다(Expanded 3등분 유지).
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            decoration: BoxDecoration(
              color: tokens.bgSurface,
              border: Border.all(color: tokens.borderSubtle),
              borderRadius: PRadius.brLg,
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: onTap == null ? tokens.fgTertiary : tokens.fgSecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: PTypo.caption.copyWith(
                    color: onTap == null ? tokens.fgTertiary : tokens.fgSecondary,
                    fontWeight: PFontWeight.semi,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: 6,
              right: 6,
              child: PBadge(label: badge!, variant: PBadgeVariant.softBrand),
            ),
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
    return Container(
      decoration: BoxDecoration(
        color: t.bgSurface,
        border: Border.all(color: t.borderSubtle),
        borderRadius: PRadius.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: PRadius.brLg,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(LucideIcons.split, size: 16, color: t.fgBrand),
                  const SizedBox(width: 8),
                  Text('내역 분할 ${splits.length}개',
                      style: PTypo.bodySm.copyWith(
                          color: t.fgPrimary, fontWeight: PFontWeight.bold)),
                  const SizedBox(width: 8),
                  Text('합계 ${krw(total)}원',
                      style: PTypo.caption.copyWith(color: t.fgTertiary)),
                  const Spacer(),
                  Icon(
                      expanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 18,
                      color: t.fgTertiary),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: ClipRRect(
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
            ),
            for (int i = 0; i < splits.length; i++)
              Padding(
                padding: EdgeInsets.fromLTRB(
                    14, 0, 14, i == splits.length - 1 ? 12 : 10),
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
                                : (splits[i].categoryName ?? '항목'),
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
                      '${isIncome ? '+' : '−'}${krw(splits[i].amount)}원',
                      style: PTypo.bodySm.copyWith(
                          color: isIncome ? t.fgIncome : t.fgExpense,
                          fontWeight: PFontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
