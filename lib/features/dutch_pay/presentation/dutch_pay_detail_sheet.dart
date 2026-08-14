import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_progress.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/features/dutch_pay/application/dutch_pay_providers.dart';
import 'package:porest_desk_app/features/dutch_pay/domain/dutch_pay.dart';
import 'package:porest_desk_app/features/dutch_pay/presentation/dutch_pay_screen.dart' show DutchAvatar, dutchKDate;

/// 더치페이 세션 상세 시트 (web `DutchDetailDialog` 미러).
///
/// hero(금액·1인당) + 참여자 rows(체크=markPaid 유지, '요청'=UI-only 스낵바) +
/// 푸터(진행 중→일괄 요청 UI-only + 닫기 / 완료→닫기). 데이터는
/// [dutchPayListProvider] 에서 [dpId] 로 라이브 조회 — markPaid 후 즉시 반영.
///
/// 결제자는 서버가 저장한 isPayer 로 판정한다 — 첫 번째 참여자로 추측하지 않는다.
void showDutchPayDetailSheet(
  BuildContext context, {
  required int dpId,
  required ValueChanged<int> onMarkPaid,
  required VoidCallback onSettle,
  required VoidCallback onDelete,
}) {
  showPSheet<void>(
    context,
    title: AppLocalizations.of(context).dutchDetailTitle,
    contentBuilder: (ctx, scrollCtrl) => _Body(
      dpId: dpId,
      scrollController: scrollCtrl,
      onMarkPaid: onMarkPaid,
      onSettle: onSettle,
      onDelete: onDelete,
    ),
    initialChildSize: 0.7,
  );
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.dpId,
    required this.scrollController,
    required this.onMarkPaid,
    required this.onSettle,
    required this.onDelete,
  });
  final int dpId;
  final ScrollController scrollController;
  final ValueChanged<int> onMarkPaid;
  final VoidCallback onSettle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final masked =
        ref.watch(hideCardProvider('dutchpay.sessions'));
    final listAsync = ref.watch(dutchPayListProvider);
    final dp = listAsync.value
        ?.where((d) => d.rowId == dpId)
        .cast<DutchPay?>()
        .firstOrNull;

    if (dp == null) {
      return const Padding(
        padding: EdgeInsets.all(PSpace.x24),
        child: Center(child: PCircularProgressIndicator()),
      );
    }

    final total = dp.participants.length;
    final paid = dp.participants.where((p) => p.isPaid).length;
    final perPerson = total == 0 ? 0 : dp.totalAmount ~/ total;
    final place = (dp.description ?? '').trim();
    final date = dutchKDate(dp.dutchPayDate);
    final heroSub = place.isEmpty ? date : '$place · $date';
    final allPaid = total > 0 && paid == total;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
        // ── Hero ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: t.bgBrandSubtle,
            borderRadius: PRadius.brMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                heroSub.isEmpty ? dp.title : heroSub,
                style: PTypo.caption.copyWith(
                  color: t.fgTertiary,
                  fontWeight: PFontWeight.semi,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: krwMasked(dp.totalAmount, masked),
                    style: PTypo.h2.copyWith(
                      fontSize: 28,
                      color: t.fgBrand,
                      fontWeight: PFontWeight.bold,
                      letterSpacing: -0.84,
                    ),
                  ),
                  if (!masked)
                    TextSpan(
                      text: wonUnit(),
                      style: PTypo.body.copyWith(
                        color: t.fgBrand,
                        fontWeight: PFontWeight.bold,
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 4),
              Text(
                '${l.dutchPerPersonLabel} ${krwSigned(perPerson, masked, unit: true, mask: '••••')}',
                style: PTypo.caption.copyWith(color: t.fgSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ── 참여자 라벨 ──
        Text(
          l.dutchParticipant,
          style: PTypo.micro.copyWith(
            color: t.fgSecondary,
            fontWeight: PFontWeight.bold,
            letterSpacing: 0.44,
          ),
        ),
        const SizedBox(height: 8),

        // ── 참여자 rows ──
        for (var i = 0; i < dp.participants.length; i++)
          _ParticipantRow(
            p: dp.participants[i],
            // 순서가 아니라 저장된 값 — 참가자를 지웠다 다시 넣어도 안 바뀐다.
            isPayer: dp.participants[i].isPayer,
            masked: masked,
            settled: dp.isSettled,
            onMarkPaid: () => onMarkPaid(dp.participants[i].rowId),
            onRequest: () => _request(context, dp.participants[i]),
          ),

        // ── 모두 지불 시 정산 완료 처리(기존 동작 유지) ──
        if (!dp.isSettled && allPaid) ...[
          const SizedBox(height: 12),
          PButton(
            label: l.dutchSettleAction,
            icon: LucideIcons.checkCheck,
            variant: PButtonVariant.outline,
            size: PButtonSize.sm,
            fullWidth: true,
            onPressed: () {
              onSettle();
              Navigator.of(context).pop();
            },
          ),
        ],

        const SizedBox(height: 16),

        // ── 푸터 액션 (시트 내 인라인) ──
        Row(
          children: [
            PButton.icon(
              icon: LucideIcons.trash2,
              variant: PButtonVariant.ghost,
              dangerous: true,
              tooltip: l.actionDelete,
              onPressed: () async {
                final ok = await showPConfirmDialog(
                  context,
                  title: l.dutchDeleteTitle,
                  message: l.dutchDeleteConfirm(dp.title),
                  confirmLabel: l.actionDelete,
                  destructive: true,
                );
                if (!ok || !context.mounted) return;
                onDelete();
                Navigator.of(context).pop();
              },
            ),
            const Spacer(),
            if (!dp.isSettled) ...[
              PButton(
                label: l.actionClose,
                variant: PButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: PSpace.x4),
              PButton(
                label: l.dutchRequestAll,
                icon: LucideIcons.send,
                onPressed: () => _requestAll(context, dp),
              ),
            ] else
              PButton(
                label: l.actionClose,
                variant: PButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
          ],
        ),
      ],
    );
  }

  // UI-only: 실제 API 호출 없이 안내 스낵바만.
  void _request(BuildContext context, DutchPayParticipant p) {
    final l = AppLocalizations.of(context);
    final name = (p.participantName ?? '').trim();
    showPSnackBar(
      context,
      l.dutchRequestSent(name.isEmpty ? l.dutchParticipant : name),
    );
  }

  void _requestAll(BuildContext context, DutchPay dp) {
    final l = AppLocalizations.of(context);
    final pending = dp.participants.where((p) => !p.isPaid).length;
    showPSnackBar(
      context,
      pending > 0
          ? l.dutchRequestSentBulk(pending)
          : l.dutchAllSettled,
    );
  }
}

/// 참여자 행 — 아바타 + 이름(결제자 뱃지) + 상태문구 ↔ 완료 뱃지 / 요청 버튼.
///
/// 미정산 참여자: 좌측 체크 아이콘 버튼=송금 완료(markPaid) / 우측 '요청'=UI-only.
class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.p,
    required this.isPayer,
    required this.masked,
    required this.settled,
    required this.onMarkPaid,
    required this.onRequest,
  });
  final DutchPayParticipant p;
  final bool isPayer;
  final bool masked;
  final bool settled;
  final VoidCallback onMarkPaid;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final name = (p.participantName ?? '').trim();
    final status = p.isPaid
        ? l.dutchSettled
        : l.dutchNeedsPayment(krwMasked(p.amount, masked, mask: '••••'));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          DutchAvatar(name: name.isEmpty ? '?' : name, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name.isEmpty ? l.dutchNoName : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PTypo.body.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.semi,
                        ),
                      ),
                    ),
                    if (isPayer) ...[
                      const SizedBox(width: 6),
                      PBadge(
                          label: l.dutchPayer, variant: PBadgeVariant.softBrand),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: PTypo.caption.copyWith(
                    color: p.isPaid ? t.statusSuccessFg : t.fgTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 우측 슬롯: 완료 → success 뱃지(dot) / 미정 → 체크(markPaid) + 요청(UI-only).
          if (p.isPaid)
            PBadge(
              label: l.actionDone,
              variant: PBadgeVariant.softSuccess,
              dotColor: t.statusSuccessFg,
            )
          else if (!settled) ...[
            PButton.icon(
              icon: LucideIcons.check,
              size: PButtonSize.sm,
              variant: PButtonVariant.ghost,
              iconColor: t.statusSuccessFg,
              tooltip: l.dutchMarkPaid,
              onPressed: onMarkPaid,
            ),
            PButton(
              label: l.dutchRequest,
              variant: PButtonVariant.outline,
              size: PButtonSize.sm,
              onPressed: onRequest,
            ),
          ] else
            Text(
              l.dutchUnsettled,
              style: PTypo.caption.copyWith(color: t.fgTertiary),
            ),
        ],
      ),
    );
  }
}
