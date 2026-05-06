import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/format/krw.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense.dart';

/// 홈 / 대시보드 — v0.1 핵심 카드 + 마스킹 토글 시연.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final user = ref.watch(authProvider).value;
    final expenses = ref.watch(expensesProvider);

    final now = DateTime.now();
    final inMonth = expenses.where((e) {
      final parts = e.date.split('-');
      return int.parse(parts[0]) == now.year && int.parse(parts[1]) == now.month;
    }).toList();
    final monthIncome = inMonth.where((e) => e.type == TxType.income)
        .fold<int>(0, (s, e) => s + e.amount);
    final monthExpense = inMonth.where((e) => e.type == TxType.expense)
        .fold<int>(0, (s, e) => s + e.amount);
    final balance = monthIncome - monthExpense;

    final assets = ref.watch(assetsProvider);
    final netWorth = assets.fold<int>(0, (s, a) => s + (a.balance ?? 0));

    return ListView(
      padding: const EdgeInsets.all(PSpace.x16),
      children: [
        // 환영 + 순자산 hero 카드
        Container(
          padding: const EdgeInsets.all(PSpace.x20),
          decoration: BoxDecoration(
            color: t.surfaceHero,
            borderRadius: PRadius.brXl,
            border: Border.all(color: t.borderBrand.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user == null
                    ? '안녕하세요'
                    : '${user.userName}님, 안녕하세요',
                style: PTypo.bodySm.copyWith(color: t.fgSecondary),
              ),
              const SizedBox(height: PSpace.x4),
              Text('순자산',
                  style: PTypo.caption.copyWith(color: t.fgTertiary)),
              const SizedBox(height: PSpace.x4),
              Text(krwMasked(netWorth, settings.hideAmounts),
                  style: PTypo.displayMd.copyWith(
                      color: t.fgPrimary, fontWeight: FontWeight.w800)),
              const SizedBox(height: PSpace.x12),
              Row(
                children: [
                  Icon(LucideIcons.wallet, size: 14, color: t.fgSecondary),
                  const SizedBox(width: 4),
                  Text('계좌 ${assets.where((a) => a.type == "account").length}개 · 카드 ${assets.where((a) => a.type == "card").length}개',
                      style: PTypo.caption.copyWith(color: t.fgSecondary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x16),

        // 이번달 요약 3 stat 카드
        Row(
          children: [
            Expanded(
              child: _StatCard(
                  label: '이번달 수입',
                  value: krwMasked(monthIncome, settings.hideAmounts),
                  color: t.statusSuccess,
                  icon: LucideIcons.arrowDownLeft),
            ),
            const SizedBox(width: PSpace.x8),
            Expanded(
              child: _StatCard(
                  label: '이번달 지출',
                  value: krwMasked(monthExpense, settings.hideAmounts),
                  color: t.fgPrimary,
                  icon: LucideIcons.arrowUpRight),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x8),
        _StatCard(
          label: '이번달 잔액',
          value: krwMasked(balance, settings.hideAmounts, sign: true),
          color: balance >= 0 ? t.statusSuccess : t.statusDanger,
          icon: LucideIcons.equal,
          full: true,
        ),

        const SizedBox(height: PSpace.x24),
        Text('자산 요약',
            style: PTypo.h4.copyWith(color: t.fgPrimary)),
        const SizedBox(height: PSpace.x8),
        Container(
          decoration: BoxDecoration(
            color: t.bgSurface,
            borderRadius: PRadius.brLg,
            border: Border.all(color: t.borderSubtle),
          ),
          child: Column(
            children: [
              for (int i = 0; i < assets.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: PSpace.x16, vertical: PSpace.x12),
                  child: Row(
                    children: [
                      Icon(_assetIcon(assets[i].type), size: 18, color: t.fgSecondary),
                      const SizedBox(width: PSpace.x12),
                      Expanded(
                        child: Text(assets[i].name,
                            style: PTypo.body.copyWith(color: t.fgPrimary)),
                      ),
                      Text(
                        assets[i].balance == null
                            ? '—'
                            : krwMasked(assets[i].balance!, settings.hideAmounts),
                        style: PTypo.money.copyWith(color: t.fgPrimary),
                      ),
                    ],
                  ),
                ),
                if (i < assets.length - 1)
                  Divider(height: 1, color: t.borderSubtle, indent: 46),
              ],
            ],
          ),
        ),

        const SizedBox(height: PSpace.x24),
        Text('Phase 7+: 차트 + 카테고리 분석 + 최근 거래',
            style: PTypo.caption.copyWith(color: t.fgTertiary)),
      ],
    );
  }

  IconData _assetIcon(String type) => switch (type) {
        'cash' => LucideIcons.banknote,
        'card' => LucideIcons.creditCard,
        'investment' => LucideIcons.trendingUp,
        _ => LucideIcons.landmark,
      };
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.full = false,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool full;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(PSpace.x16),
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: PRadius.brLg,
        border: Border.all(color: t.borderSubtle),
      ),
      child: full
          ? Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: PSpace.x8),
                Text(label, style: PTypo.caption.copyWith(color: t.fgTertiary)),
                const Spacer(),
                Text(value,
                    style: PTypo.money.copyWith(color: color, fontWeight: FontWeight.w700)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: t.fgTertiary),
                    const SizedBox(width: 6),
                    Text(label, style: PTypo.caption.copyWith(color: t.fgTertiary)),
                  ],
                ),
                const SizedBox(height: PSpace.x8),
                Text(value,
                    style: PTypo.money.copyWith(
                        color: color, fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
    );
  }
}
