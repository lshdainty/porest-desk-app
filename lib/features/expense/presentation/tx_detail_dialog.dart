import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/format/krw.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../asset/application/asset_providers.dart';
import '../../dutch_pay/presentation/dutch_pay_create_dialog.dart';
import '../../expense_split/presentation/split_tx_dialog.dart';
import '../../recurring/presentation/recurring_edit_dialog.dart';
import '../application/expense_providers.dart';
import '../domain/expense.dart';
import 'add_tx_sheet.dart';
import 'widgets/expense_row.dart';

/// 거래 상세 다이얼로그 — front `TxDetailDialog` 미러.
///
/// 구성:
/// - Hero: 카테고리 색 그라데이션 배경 + 큰 아이콘 + 가맹점 + 큰 금액 + 날짜
/// - Field rows: 카테고리 / 금액 / 계좌·카드 / 결제 수단 / 날짜·시간 / 메모
/// - Quick actions (3-col grid): 내역 분할 / 반복 설정 / 더치페이
/// - Footer: 삭제 / 편집 / 확인
void showTxDetailDialog(BuildContext context, Expense expense) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor:
        Theme.of(context).extension<PorestTokens>()?.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) =>
          _DetailBody(expense: expense, scrollController: scrollCtrl),
    ),
  );
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody(
      {required this.expense, required this.scrollController});
  final Expense expense;
  final ScrollController scrollController;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  bool _deleting = false;

  Future<void> _delete() async {
    final t = context.tokens;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('거래 삭제'),
        content: const Text('이 거래를 삭제하시겠습니까? 연결된 자산 잔액이 함께 조정됩니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: t.statusDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _deleting = true);
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
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('거래가 삭제되었습니다')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
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
    final settings =
        ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final masked = settings.hideAmounts;
    final e = widget.expense;
    final isIncome = e.expenseType == 'INCOME';
    final title = isIncome ? '수입 상세' : '지출 상세';

    final fg = parseColor(e.categoryColor, fallback: t.fgBrand);
    final bg = softBg(fg);
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
    final displayMerchant = e.merchant ?? e.description ?? e.categoryName ?? '거래';
    final amountColor =
        isIncome ? t.statusSuccessFg : t.statusDangerFg;
    final amountText = masked
        ? '••••'
        : '${isIncome ? '+' : '−'}${krw(e.amount, abs: true)}';

    return Column(
      children: [
        // Grab handle
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: t.borderSubtle,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(
              PSpace.x20, PSpace.x12, PSpace.x12, PSpace.x12),
          child: Row(
            children: [
              Text(title,
                  style: TextStyle(
                      color: t.fgPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.34)),
              const Spacer(),
              IconButton(
                icon: Icon(LucideIcons.x, color: t.fgSecondary, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(
                PSpace.x20, 0, PSpace.x20, PSpace.x16),
            children: [
              // Hero card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [bg, t.bgSurface],
                  ),
                  border: Border.all(color: fg.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: bg, borderRadius: PRadius.brSm),
                      alignment: Alignment.center,
                      child: Icon(icon, size: 20, color: fg),
                    ),
                    const SizedBox(height: 12),
                    Text(displayMerchant,
                        style: PTypo.bodySm.copyWith(
                            color: t.fgSecondary,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: amountText,
                            style: TextStyle(
                              color: amountColor,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.02,
                              fontFamily: 'monospace',
                            ),
                          ),
                          if (!masked)
                            TextSpan(
                              text: '원',
                              style: TextStyle(
                                color: amountColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
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
                  borderRadius: BorderRadius.circular(12),
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
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(e.categoryName ?? '미분류',
                              style: PTypo.bodySm.copyWith(
                                  color: t.fgPrimary,
                                  fontWeight: FontWeight.w600)),
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
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace'),
                      ),
                    ),
                    if (assetLabel != null)
                      _FieldRow(
                        label: '계좌·카드',
                        tokens: t,
                        child: Text(assetLabel,
                            style: PTypo.bodySm.copyWith(
                                color: t.fgPrimary,
                                fontWeight: FontWeight.w500)),
                      ),
                    if (paymentLabel.isNotEmpty)
                      _FieldRow(
                        label: '결제 수단',
                        tokens: t,
                        child: Text(paymentLabel,
                            style: PTypo.bodySm.copyWith(
                                color: t.fgPrimary,
                                fontWeight: FontWeight.w500)),
                      ),
                    if (dayStr != null)
                      _FieldRow(
                        label: '날짜·시간',
                        tokens: t,
                        child: Text(
                          timeLabel != null ? '$dayStr $timeLabel' : dayStr,
                          style: PTypo.bodySm.copyWith(
                              color: t.fgPrimary,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    _FieldRow(
                      label: '메모',
                      tokens: t,
                      isLast: true,
                      child: Text(
                        (e.description ?? '').isEmpty
                            ? '없음'
                            : e.description!,
                        style: PTypo.bodySm.copyWith(
                            color: (e.description ?? '').isEmpty
                                ? t.fgTertiary
                                : t.fgPrimary,
                            fontWeight: FontWeight.w500),
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
                              showRecurringEditDialog(context,
                                  fromExpense: e);
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
                              showDutchPayCreateDialog(context,
                                  fromExpense: e);
                            },
                    ),
                  ),
                ],
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
          ),
        ),
        // Footer
        Padding(
          padding: const EdgeInsets.fromLTRB(
              PSpace.x16, PSpace.x12, PSpace.x16, PSpace.x16),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: _deleting ? null : _delete,
                icon: _deleting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(LucideIcons.trash2,
                        size: 14, color: t.statusDangerFg),
                label: Text('삭제',
                    style: PTypo.body.copyWith(color: t.statusDangerFg)),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _deleting
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        showAddTxSheet(context, edit: e);
                      },
                icon: Icon(LucideIcons.pencil,
                    size: 14, color: t.fgSecondary),
                label: Text('편집',
                    style: PTypo.body.copyWith(color: t.fgSecondary)),
              ),
              const SizedBox(width: PSpace.x8),
              FilledButton(
                onPressed: _deleting
                    ? null
                    : () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: t.bgBrand,
                  foregroundColor: t.fgOnBrand,
                  padding: const EdgeInsets.symmetric(
                      horizontal: PSpace.x16, vertical: PSpace.x12),
                ),
                child: const Text('확인'),
              ),
            ],
          ),
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
    final async = ref.watch(merchantMonthExpensesProvider(
        (merchant: merchant, year: year, month: month)));
    final all = async.value ?? const <Expense>[];
    final history = all.where((x) => x.rowId != excludeRowId).take(5).toList();
    if (history.isEmpty) return const SizedBox.shrink();

    final monthCount = all.length;
    final monthTotal =
        all.fold<int>(0, (s, x) => s + x.amount.abs());
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
                Text('$merchant에서의 이전 거래',
                    style: PTypo.bodySm.copyWith(
                        color: t.fgPrimary,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(
                  masked
                      ? '이번 달 $monthCount회 · ••••원'
                      : '이번 달 $monthCount회 · ${krw(monthTotal)}원',
                  style: PTypo.caption.copyWith(color: t.fgTertiary),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: t.bgSurface,
              border: Border.all(color: t.borderSubtle),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                for (int i = 0; i < history.length; i++) ...[
                  ExpenseRow(
                    expense: history[i],
                    category: history[i].categoryRowId == null
                        ? null
                        : categories.byRowId(history[i].categoryRowId!),
                    masked: masked,
                  ),
                  if (i < history.length - 1)
                    Divider(height: 1, color: t.borderSubtle),
                ],
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
          top: isFirst ? const Radius.circular(11) : Radius.zero,
          bottom: isLast ? const Radius.circular(11) : Radius.zero,
        ),
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: PSpace.x16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style:
                    PTypo.caption.copyWith(color: tokens.fgTertiary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: child,
            ),
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
  });
  final IconData icon;
  final String label;
  final PorestTokens tokens;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        decoration: BoxDecoration(
          color: tokens.bgSurface,
          border: Border.all(color: tokens.borderSubtle),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 18,
                color: onTap == null
                    ? tokens.fgTertiary
                    : tokens.fgSecondary),
            const SizedBox(height: 8),
            Text(label,
                style: PTypo.caption.copyWith(
                  color: onTap == null
                      ? tokens.fgTertiary
                      : tokens.fgSecondary,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}
