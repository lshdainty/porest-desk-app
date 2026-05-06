import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/format/date.dart';
import '../../../core/format/krw.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../expense_split/presentation/split_tx_dialog.dart';
import '../../recurring/presentation/recurring_edit_dialog.dart';
import '../application/expense_providers.dart';
import '../domain/expense.dart';
import 'add_tx_sheet.dart';

void showTxDetailDialog(BuildContext context, Expense expense) {
  WoltModalSheet.show<void>(
    context: context,
    pageListBuilder: (modalCtx) => [
      WoltModalSheetPage(
        topBarTitle: const Text('거래 상세'),
        isTopBarLayerAlwaysVisible: true,
        backgroundColor: Theme.of(modalCtx).extension<PorestTokens>()?.bgSurface,
        trailingNavBarWidget: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: Navigator.of(modalCtx).pop,
        ),
        child: _DetailBody(expense: expense),
      ),
    ],
  );
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.expense});
  final Expense expense;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  bool _deleting = false;

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('거래 삭제'),
        content: const Text('이 거래를 삭제하시겠습니까? 되돌릴 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.tokens.statusDanger),
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
        final d = parseIsoDate(widget.expense.expenseDate!.substring(0, 10));
        ref.invalidate(monthExpensesProvider((year: d.year, month: d.month)));
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

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final e = widget.expense;
    final positive = e.signedAmount > 0;

    final colorRaw = e.categoryColor;
    final fg = parseColor(colorRaw, fallback: t.fgBrand);
    final bg = softBg(fg);
    final icon = lucideByName(e.categoryIcon, fallback: LucideIcons.tag);

    final dateLabel = e.expenseDate != null
        ? formatDay(parseIsoDate(e.expenseDate!.substring(0, 10)))
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, PSpace.x16, PSpace.x16, PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리 헤더 + 금액
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: bg, borderRadius: PRadius.brMd),
                alignment: Alignment.center,
                child: Icon(icon, size: 24, color: fg),
              ),
              const SizedBox(width: PSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.merchant ?? e.description ?? (e.categoryName ?? '미지정'),
                        style: PTypo.h3.copyWith(color: t.fgPrimary)),
                    const SizedBox(height: 2),
                    Text(_typeLabel(e.expenseType),
                        style: PTypo.caption.copyWith(color: t.fgTertiary)),
                  ],
                ),
              ),
              Text(
                krwMasked(e.signedAmount, settings.hideAmounts, sign: true),
                style: PTypo.moneyLg.copyWith(
                    color: positive ? t.statusSuccess : t.fgPrimary,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x20),
          Divider(height: 1, color: t.borderSubtle),
          const SizedBox(height: PSpace.x16),

          // 정보 행들
          _DetailRow(label: '카테고리', value: e.categoryName ?? '-', tokens: t),
          _DetailRow(label: '자산', value: e.assetName ?? '-', tokens: t),
          if (dateLabel != null)
            _DetailRow(label: '날짜', value: '${dateLabel.md} (${dateLabel.dow})', tokens: t),
          if (e.merchant != null && e.merchant!.isNotEmpty)
            _DetailRow(label: '가맹점', value: e.merchant!, tokens: t),
          if (e.paymentMethod != null && e.paymentMethod!.isNotEmpty)
            _DetailRow(label: '결제 수단', value: e.paymentMethod!, tokens: t),
          if (e.description != null && e.description!.isNotEmpty)
            _DetailRow(label: '메모', value: e.description!, tokens: t),

          const SizedBox(height: PSpace.x24),

          // 액션
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _deleting
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          showAddTxSheet(context, edit: e);
                        },
                  icon: const Icon(LucideIcons.pencil, size: 16),
                  label: const Text('수정'),
                ),
              ),
              const SizedBox(width: PSpace.x8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.statusDanger,
                    side: BorderSide(color: t.statusDanger.withValues(alpha: 0.5)),
                  ),
                  onPressed: _deleting ? null : _delete,
                  icon: _deleting
                      ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(LucideIcons.trash2, size: 16),
                  label: const Text('삭제'),
                ),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _deleting
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          showRecurringEditDialog(context, fromExpense: e);
                        },
                  icon: const Icon(LucideIcons.repeat, size: 16),
                  label: const Text('반복 설정'),
                ),
              ),
              const SizedBox(width: PSpace.x8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _deleting
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          showSplitTxDialog(context, e);
                        },
                  icon: const Icon(LucideIcons.scissors, size: 16),
                  label: const Text('내역 분할'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _typeLabel(String type) => switch (type) {
        'EXPENSE' => '지출',
        'INCOME' => '수입',
        'TRANSFER' => '이체',
        _ => type,
      };
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, required this.tokens});
  final String label;
  final String value;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PSpace.x8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: PTypo.bodySm.copyWith(color: tokens.fgSecondary)),
          ),
          Expanded(
            child: Text(value, style: PTypo.body.copyWith(color: tokens.fgPrimary)),
          ),
        ],
      ),
    );
  }
}
