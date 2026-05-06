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
import '../../../shared/icons/lucide_icon_map.dart';
import '../../asset/application/asset_providers.dart';
import '../../expense/application/expense_providers.dart';

/// 홈 / 대시보드.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final user = ref.watch(authProvider).value;
    final assetsAsync = ref.watch(assetsProvider);

    final now = DateTime.now();
    final monthKey = (year: now.year, month: now.month);
    final expensesAsync = ref.watch(monthExpensesProvider(monthKey));

    return RefreshIndicator(
      color: t.bgBrand,
      onRefresh: () async {
        ref.invalidate(assetsProvider);
        ref.invalidate(monthExpensesProvider(monthKey));
        await Future.wait([
          ref.read(assetsProvider.future),
          ref.read(monthExpensesProvider(monthKey).future),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.all(PSpace.x16),
        children: [
          // 환영 + 순자산 hero
          assetsAsync.when(
            loading: () => _HeroSkeleton(),
            error: (e, _) => _HeroError(message: '자산 정보를 불러오지 못했습니다'),
            data: (assets) {
              final netWorth =
                  assets.fold<int>(0, (s, a) => s + (a.balance ?? 0));
              return Container(
                padding: const EdgeInsets.all(PSpace.x20),
                decoration: BoxDecoration(
                  color: t.surfaceHero,
                  borderRadius: PRadius.brXl,
                  border: Border.all(
                      color: t.borderBrand.withValues(alpha: 0.3)),
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
                            color: t.fgPrimary,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: PSpace.x12),
                    Row(
                      children: [
                        Icon(LucideIcons.wallet, size: 14, color: t.fgSecondary),
                        const SizedBox(width: 4),
                        Text(
                            '계좌 ${assets.where((a) => a.assetType == "BANK_ACCOUNT").length}개 · '
                            '카드 ${assets.where((a) => a.assetType == "CARD").length}개',
                            style: PTypo.caption.copyWith(color: t.fgSecondary)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: PSpace.x16),

          // 이번달 요약
          expensesAsync.when(
            loading: () => const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => _ErrorCard(text: '이번달 거래를 불러오지 못했습니다'),
            data: (raw) {
              final monthIncome = raw
                  .where((e) => e.expenseType == 'INCOME')
                  .fold<int>(0, (s, e) => s + e.amount);
              final monthExpense = raw
                  .where((e) => e.expenseType == 'EXPENSE')
                  .fold<int>(0, (s, e) => s + e.amount);
              final balance = monthIncome - monthExpense;
              return Column(
                children: [
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
                ],
              );
            },
          ),

          const SizedBox(height: PSpace.x24),
          Text('자산 요약', style: PTypo.h4.copyWith(color: t.fgPrimary)),
          const SizedBox(height: PSpace.x8),
          assetsAsync.when(
            loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: PSpace.x16),
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => _ErrorCard(text: '자산 목록을 불러오지 못했습니다'),
            data: (assets) {
              if (assets.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(PSpace.x16),
                  decoration: BoxDecoration(
                    color: t.bgSurface,
                    borderRadius: PRadius.brLg,
                    border: Border.all(color: t.borderSubtle),
                  ),
                  child: Text('등록된 자산이 없습니다',
                      style: PTypo.bodySm.copyWith(color: t.fgTertiary)),
                );
              }
              return Container(
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
                            Icon(assetTypeIcon(assets[i].assetType),
                                size: 18, color: t.fgSecondary),
                            const SizedBox(width: PSpace.x12),
                            Expanded(
                              child: Text(assets[i].assetName,
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
              );
            },
          ),

          const SizedBox(height: PSpace.x24),
          Text('Phase 7+: 차트 + 카테고리 분석 + 최근 거래',
              style: PTypo.caption.copyWith(color: t.fgTertiary)),
        ],
      ),
    );
  }
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

class _HeroSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(PSpace.x20),
      decoration: BoxDecoration(
        color: t.surfaceHero,
        borderRadius: PRadius.brXl,
      ),
      height: 140,
      child: Center(child: CircularProgressIndicator(color: t.bgBrand)),
    );
  }
}

class _HeroError extends StatelessWidget {
  const _HeroError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(PSpace.x20),
      decoration: BoxDecoration(
        color: t.statusDangerSubtle,
        borderRadius: PRadius.brXl,
      ),
      child: Text(message, style: PTypo.bodySm.copyWith(color: t.statusDangerFg)),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(PSpace.x16),
      decoration: BoxDecoration(
        color: t.statusDangerSubtle,
        borderRadius: PRadius.brLg,
      ),
      child: Text(text, style: PTypo.bodySm.copyWith(color: t.statusDangerFg)),
    );
  }
}
