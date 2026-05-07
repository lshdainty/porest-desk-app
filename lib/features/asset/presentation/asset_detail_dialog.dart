import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/format/krw.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../card/presentation/card_performance_bar.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense.dart';
import '../../expense/presentation/tx_detail_dialog.dart';
import '../application/asset_providers.dart';
import '../domain/asset.dart';
import '../domain/asset_transfer.dart';
import '../domain/asset_type_meta.dart';
import 'asset_edit_dialog.dart';

/// 자산 상세 — front `AssetDetailDialog` 모바일 미러.
///
/// 구성:
/// - 헤더: 자산 이름·유형·잔액
/// - 잔액 추이 (12주 라인 차트)
/// - 최근 거래 (5건)
/// - 액션: 편집 / 삭제
void showAssetDetailRich(BuildContext context, Asset asset) {
  WoltModalSheet.show<void>(
    context: context,
    pageListBuilder: (modalCtx) => [
      WoltModalSheetPage(
        topBarTitle: Text(asset.assetName),
        isTopBarLayerAlwaysVisible: true,
        backgroundColor:
            Theme.of(modalCtx).extension<PorestTokens>()?.bgSurface,
        trailingNavBarWidget: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: Navigator.of(modalCtx).pop,
        ),
        child: _DetailBody(asset: asset),
      ),
    ],
  );
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.asset});
  final Asset asset;
  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  bool _deleting = false;

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('자산 삭제'),
        content:
            const Text('이 자산을 삭제하시겠습니까? 연결된 거래는 유지됩니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: context.tokens.statusDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.delete(widget.asset.rowId);
      ref.invalidate(assetsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('자산이 삭제되었습니다')),
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
    final asset = widget.asset;
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final masked = settings.hideAmounts;
    final meta = AssetTypeMeta.of(asset.assetType);
    final fg = parseColor(asset.color, fallback: t.fgBrand);
    final bg = softBg(fg);
    final trendAsync = ref
        .watch(assetBalanceTrendProvider((assetId: asset.rowId, weeks: 12)));
    final recentAsync = ref
        .watch(expensesByAssetProvider((assetId: asset.rowId, limit: 5)));

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, PSpace.x16, PSpace.x16, PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 자산 헤더
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: bg, borderRadius: PRadius.brMd),
                alignment: Alignment.center,
                child: Icon(meta.icon, size: 22, color: fg),
              ),
              const SizedBox(width: PSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(asset.assetName,
                        style: PTypo.h3.copyWith(color: t.fgPrimary)),
                    const SizedBox(height: 2),
                    Text(meta.label,
                        style:
                            PTypo.caption.copyWith(color: t.fgTertiary)),
                  ],
                ),
              ),
              Text(krwMasked(asset.balance ?? 0, masked),
                  style: PTypo.moneyLg.copyWith(
                      color: t.fgPrimary, fontWeight: PFontWeight.bold)),
            ],
          ),
          const SizedBox(height: PSpace.x16),
          if ((asset.institution ?? '').isNotEmpty ||
              (asset.memo ?? '').isNotEmpty) ...[
            if ((asset.institution ?? '').isNotEmpty)
              _InfoRow('금융사', asset.institution!, tokens: t),
            if ((asset.memo ?? '').isNotEmpty)
              _InfoRow('메모', asset.memo!, tokens: t),
            const SizedBox(height: PSpace.x16),
          ],

          // 카드 실적 바 (CARD 타입에 한해)
          if (asset.assetType == 'CREDIT_CARD' ||
              asset.assetType == 'CHECK_CARD') ...[
            CardPerformanceBar(
              assetRowId: asset.rowId,
              yearMonth: _currentYearMonth(),
              masked: masked,
            ),
            const SizedBox(height: PSpace.x16),
          ],

          // 잔액 추이
          Row(
            children: [
              Icon(LucideIcons.lineChart,
                  size: 14, color: t.fgSecondary),
              const SizedBox(width: 6),
              Text('잔액 추이 (12주)',
                  style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary, fontWeight: PFontWeight.bold)),
            ],
          ),
          const SizedBox(height: PSpace.x8),
          SizedBox(
            height: 100,
            child: _BalanceTrendChart(async: trendAsync, tokens: t),
          ),
          const SizedBox(height: PSpace.x20),

          // 최근 거래
          Row(
            children: [
              Icon(LucideIcons.receipt, size: 14, color: t.fgSecondary),
              const SizedBox(width: 6),
              Text('최근 거래',
                  style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary, fontWeight: PFontWeight.bold)),
            ],
          ),
          const SizedBox(height: PSpace.x8),
          _RecentExpenses(async: recentAsync, masked: masked, tokens: t),

          const SizedBox(height: PSpace.x24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.statusDanger,
                    side: BorderSide(
                        color: t.statusDanger.withValues(alpha: 0.5)),
                  ),
                  onPressed: _deleting ? null : _delete,
                  icon: _deleting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(LucideIcons.trash2, size: 16),
                  label: const Text('삭제'),
                ),
              ),
              const SizedBox(width: PSpace.x8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _deleting
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          showAssetEditForm(context, asset);
                        },
                  icon: const Icon(LucideIcons.pencil, size: 16),
                  label: const Text('편집'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {required this.tokens});
  final String label;
  final String value;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(label,
                style: PTypo.caption.copyWith(color: tokens.fgSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: PTypo.bodySm.copyWith(color: tokens.fgPrimary)),
          ),
        ],
      ),
    );
  }
}

class _BalanceTrendChart extends StatelessWidget {
  const _BalanceTrendChart({required this.async, required this.tokens});
  final AsyncValue<List<AssetBalancePoint>> async;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    final list = async.value ?? const <AssetBalancePoint>[];
    if (async.isLoading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (list.isEmpty) {
      return Center(
          child: Text('데이터 없음',
              style: PTypo.caption.copyWith(color: tokens.fgTertiary)));
    }
    final spots = [
      for (int i = 0; i < list.length; i++)
        FlSpot(i.toDouble(), list[i].balance.toDouble()),
    ];
    final maxY = list
        .map((p) => p.balance)
        .fold<int>(0, (m, v) => v > m ? v : m)
        .toDouble();
    final minY = list
        .map((p) => p.balance)
        .fold<int>(list.first.balance, (m, v) => v < m ? v : m)
        .toDouble();
    return LineChart(
      LineChartData(
        minY: minY * 0.95,
        maxY: maxY > 0 ? maxY * 1.05 : 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: tokens.fgBrand,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: tokens.fgBrand.withValues(alpha: 0.12),
            ),
          ),
        ],
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(enabled: true),
      ),
    );
  }
}

class _RecentExpenses extends StatelessWidget {
  const _RecentExpenses(
      {required this.async, required this.masked, required this.tokens});
  final AsyncValue<List<Expense>> async;
  final bool masked;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    final list = async.value ?? const <Expense>[];
    if (async.isLoading && list.isEmpty) {
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()));
    }
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text('거래 내역 없음',
              style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: PRadius.brMd,
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        children: [
          for (int i = 0; i < list.length; i++) ...[
            _ExpenseRow(expense: list[i], masked: masked, tokens: tokens),
            if (i < list.length - 1)
              Divider(height: 1, color: tokens.borderSubtle, indent: 12),
          ],
        ],
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    required this.masked,
    required this.tokens,
  });
  final Expense expense;
  final bool masked;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    final isIncome = expense.expenseType != 'EXPENSE';
    final color = parseColor(expense.categoryColor, fallback: tokens.fgBrand);
    final bg = softBg(color);
    return InkWell(
      onTap: () => showTxDetailDialog(context, expense),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: bg, borderRadius: PRadius.brSm),
              alignment: Alignment.center,
              child: Icon(lucideByName(expense.categoryIcon),
                  size: 14, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      expense.merchant ?? expense.description ??
                          (expense.categoryName ?? '거래'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PTypo.bodySm.copyWith(color: tokens.fgPrimary)),
                  if ((expense.expenseDateOnly ?? '').isNotEmpty)
                    Text(expense.expenseDateOnly!,
                        style: PTypo.caption
                            .copyWith(color: tokens.fgTertiary)),
                ],
              ),
            ),
            Text(
              krwMasked(expense.signedAmount, masked, sign: true),
              style: PTypo.bodySm.copyWith(
                  color: isIncome ? tokens.statusSuccess : tokens.fgPrimary,
                  fontWeight: PFontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

String _currentYearMonth() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}';
}
