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
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_empty_state.dart';
import '../../../shared/widgets/p_modal.dart';
import '../application/dutch_pay_providers.dart';
import '../domain/dutch_pay.dart';
import 'dutch_pay_create_dialog.dart';

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
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('더치페이'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: t.bgBrand,
        foregroundColor: t.fgOnBrand,
        onPressed: () => showDutchPayCreateDialog(context),
        child: const Icon(LucideIcons.plus),
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(dutchPayListProvider);
          await ref.read(dutchPayListProvider.future);
        },
        child: listAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
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
              padding: const EdgeInsets.fromLTRB(
                  PSpace.x16, PSpace.x12, PSpace.x16, PSpace.x80),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: ${e.message}')),
      );
    }
  }

  Future<void> _settle(BuildContext context, WidgetRef ref, int id) async {
    try {
      final repo = await ref.read(dutchPayRepositoryProvider.future);
      await repo.settle(id);
      ref.invalidate(dutchPayListProvider);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('정산 실패: ${e.message}')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: ${e.message}')),
      );
    }
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
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: PRadius.brLg,
        border: Border.all(color: tokens.borderSubtle),
      ),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: tokens.statusSuccessSubtle,
                              borderRadius: PRadius.brXs,
                            ),
                            child: Text('정산 완료',
                                style: PTypo.caption.copyWith(
                                    color: tokens.statusSuccessFg,
                                    fontWeight: PFontWeight.bold,
                                    fontSize: PFontSize.micro)),
                          ),
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
                      fontWeight: PFontWeight.heavy)),
              IconButton(
                onPressed: onDelete,
                icon: Icon(LucideIcons.trash2,
                    size: 14, color: tokens.fgTertiary),
                tooltip: '삭제',
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints.tightFor(width: 28, height: 28),
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
                    Text(krwMasked(p.amount, masked),
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
