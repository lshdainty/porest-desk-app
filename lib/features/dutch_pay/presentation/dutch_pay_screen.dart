import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/krw.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/widgets/p_badge.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_empty_state.dart';
import '../../../shared/widgets/p_floating_action_button.dart';
import '../../../shared/widgets/p_modal.dart';
import '../application/dutch_pay_providers.dart';
import '../domain/dutch_pay.dart';
import 'dutch_pay_create_dialog.dart';
import '../../../shared/widgets/p_skeleton.dart';
import '../../../shared/widgets/p_snack_bar.dart';

class DutchPayScreen extends ConsumerWidget {
  const DutchPayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final listAsync = ref.watch(dutchPayListProvider);
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: PButton.icon(
          icon: LucideIcons.arrowLeft,
          onPressed: () => context.pop(),
        ),
        title: const Text('더치페이'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      floatingActionButton: PFloatingActionButton(
        icon: LucideIcons.plus,
        onPressed: () => showDutchPayCreateDialog(context),
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(dutchPayListProvider);
          await ref.read(dutchPayListProvider.future);
        },
        child: listAsync.when(
          loading: () => _DutchPaySkeleton(tokens: t),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(PSpace.x16),
            child: Text('더치페이 로드 실패\n$e',
                style: PTypo.bodySm.copyWith(color: t.statusDanger)),
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(children: const [
                PEmptyState(
                  icon: LucideIcons.divide,
                  message: '등록된 더치페이가 없습니다',
                ),
              ]);
            }
            final sorted = [...items]..sort((a, b) {
                if (a.isSettled != b.isSettled) {
                  return a.isSettled ? 1 : -1;
                }
                return (b.dutchPayDate ?? '')
                    .compareTo(a.dutchPayDate ?? '');
              });
            return ListView.separated(
              padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x20, vertical: PSpace.x24),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const SizedBox(height: PSpace.x8),
              itemBuilder: (_, i) => _DutchPayCard(
                dp: sorted[i],
                masked: settings.hideAmounts,
                tokens: t,
                onMarkPaid: (pid) => _markPaid(context, ref, sorted[i].rowId, pid),
                onSettle: () => _settle(context, ref, sorted[i].rowId),
                onDelete: () => _delete(context, ref, sorted[i]),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _markPaid(
      BuildContext context, WidgetRef ref, int dpId, int pid) async {
    try {
      final repo = await ref.read(dutchPayRepositoryProvider.future);
      await repo.markPaid(dpId, pid);
      ref.invalidate(dutchPayListProvider);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      showPSnackBar(context, '실패: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  Future<void> _settle(BuildContext context, WidgetRef ref, int id) async {
    try {
      final repo = await ref.read(dutchPayRepositoryProvider.future);
      await repo.settle(id);
      ref.invalidate(dutchPayListProvider);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      showPSnackBar(context, '정산 실패: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, DutchPay dp) async {
    final ok = await showPConfirmDialog(
      context,
      title: '더치페이 삭제',
      message: '"${dp.title}"을(를) 삭제할까요?',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      final repo = await ref.read(dutchPayRepositoryProvider.future);
      await repo.delete(dp.rowId);
      ref.invalidate(dutchPayListProvider);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      showPSnackBar(context, '삭제 실패: ${e.message}', severity: PSnackSeverity.error);
    }
  }
}

/// 더치페이 목록 skeleton — PCard bordered × 3 (제목+메타+진행바+참여자 행).
class _DutchPaySkeleton extends StatelessWidget {
  const _DutchPaySkeleton({required this.tokens});
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpace.x20,
        vertical: PSpace.x24,
      ),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: PSpace.x8),
      itemBuilder: (_, i) => PCard(
        variant: PCardVariant.bordered,
        padding: const EdgeInsets.all(PSpace.x12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PSkeleton.line(width: 120),
                      const SizedBox(height: 4),
                      PSkeleton.line(width: 80, height: 12),
                    ],
                  ),
                ),
                const PSkeleton.line(width: 72),
                const SizedBox(width: PSpace.x8),
                const PSkeleton(width: 28, height: 28),
              ],
            ),
            const SizedBox(height: PSpace.x8),
            PSkeleton(
              width: double.infinity,
              height: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: PSpace.x12),
            for (int j = 0; j < 2; j++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const PSkeleton(width: 18, height: 18),
                    const SizedBox(width: PSpace.x8),
                    const PSkeleton.line(width: 60),
                    const Spacer(),
                    PSkeleton.line(width: 48, height: 12),
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

class _DutchPayCard extends StatelessWidget {
  const _DutchPayCard({
    required this.dp,
    required this.masked,
    required this.tokens,
    required this.onMarkPaid,
    required this.onSettle,
    required this.onDelete,
  });
  final DutchPay dp;
  final bool masked;
  final PorestTokens tokens;
  final ValueChanged<int> onMarkPaid;
  final VoidCallback onSettle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final paidCount = dp.participants.where((p) => p.isPaid).length;
    final totalP = dp.participants.length;
    final progress = totalP == 0 ? 0.0 : paidCount / totalP;
    return PCard(
      variant: PCardVariant.bordered,
      padding: const EdgeInsets.all(PSpace.x12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(dp.title,
                              style: PTypo.body.copyWith(
                                  color: tokens.fgPrimary,
                                  fontWeight: PFontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (dp.isSettled) ...[
                          const SizedBox(width: 6),
                          const PBadge(
                              label: '정산 완료',
                              variant: PBadgeVariant.softSuccess),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${dp.dutchPayDate ?? ''} · $paidCount/$totalP명 지불',
                      style: PTypo.caption
                          .copyWith(color: tokens.fgTertiary),
                    ),
                  ],
                ),
              ),
              Text(krwMasked(dp.totalAmount, masked),
                  style: PTypo.body.copyWith(
                      color: tokens.fgPrimary,
                      fontWeight: PFontWeight.bold)),
              PButton.icon(
                icon: LucideIcons.trash2,
                size: PButtonSize.sm,
                iconColor: tokens.fgTertiary,
                tooltip: '삭제',
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: PSpace.x8),
          ClipRRect(
            borderRadius: PRadius.brXs,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: tokens.bgTrack,
              color: progress >= 1 ? tokens.statusSuccess : tokens.fgBrand,
            ),
          ),
          const SizedBox(height: PSpace.x12),
          for (final p in dp.participants) ...[
            InkWell(
              onTap: dp.isSettled ? null : () => onMarkPaid(p.rowId),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      p.isPaid
                          ? LucideIcons.checkCircle
                          : LucideIcons.circle,
                      size: 14,
                      color: p.isPaid
                          ? tokens.statusSuccess
                          : tokens.fgTertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(p.participantName ?? '(이름 없음)',
                          style: PTypo.bodySm.copyWith(
                              color: tokens.fgPrimary,
                              decoration: p.isPaid
                                  ? TextDecoration.lineThrough
                                  : null)),
                    ),
                    Text(krwMasked(p.amount, masked, mask: '••••'),
                        style: PTypo.bodySm.copyWith(
                            color: tokens.fgPrimary,
                            fontWeight: PFontWeight.semi)),
                  ],
                ),
              ),
            ),
          ],
          if (!dp.isSettled && paidCount == totalP && totalP > 0) ...[
            const SizedBox(height: PSpace.x8),
            SizedBox(
              width: double.infinity,
              child: PButton(
                label: '정산 완료 처리',
                icon: LucideIcons.checkCheck,
                variant: PButtonVariant.outline,
                size: PButtonSize.sm,
                fullWidth: true,
                onPressed: onSettle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
