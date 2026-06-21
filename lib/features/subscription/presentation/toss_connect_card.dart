import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';
import 'package:porest_desk_app/features/subscription/data/subscription_repository.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';

/// 증권 데이터 연동 — 토스증권 API 키 연결 카드. (porest-design `TossApiConnect` 미러)
///
/// 구독(Pro) 상태에서 계정 설정 '구독·결제' 아래에 인라인으로 노출.
/// 본인 Client ID/Secret 등록 → 보유 주식·시세 자동 수집(서버 암호화 저장).
class TossConnectCard extends ConsumerStatefulWidget {
  const TossConnectCard({super.key});

  @override
  ConsumerState<TossConnectCard> createState() => _TossConnectCardState();
}

class _TossConnectCardState extends ConsumerState<TossConnectCard> {
  final _idCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _secretCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<void> Function(SubscriptionRepository repo) action,
    String okMsg,
    String errMsg,
  ) async {
    setState(() => _busy = true);
    try {
      final repo = await ref.read(subscriptionRepositoryProvider.future);
      await action(repo);
      ref.invalidate(myFeaturesProvider);
      ref.invalidate(tossCredentialStatusProvider);
      if (mounted) {
        showPSnackBar(context, okMsg, severity: PSnackSeverity.success);
      }
    } catch (_) {
      if (mounted) {
        showPSnackBar(context, errMsg, severity: PSnackSeverity.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cred = ref.watch(tossCredentialStatusProvider).asData?.value;
    final connected = cred?.connected ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: PSpace.x8),
          child: Text(
            '증권 데이터 연동',
            style: TextStyle(
              fontFamily: PTypo.sans,
              fontSize: PFontSize.caption,
              fontWeight: PFontWeight.bold,
              color: t.fgPrimary,
            ),
          ),
        ),
        PCard(
          variant: PCardVariant.bordered,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PSpace.x16,
                  PSpace.x16,
                  PSpace.x16,
                  14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: t.bgBrandSubtle,
                        borderRadius: PRadius.brMd,
                      ),
                      alignment: Alignment.center,
                      child: Icon(LucideIcons.link, size: 18, color: t.fgBrand),
                    ),
                    const SizedBox(width: PSpace.x12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '토스증권 연결',
                            style: TextStyle(
                              fontFamily: PTypo.sans,
                              fontSize: 15,
                              fontWeight: PFontWeight.bold,
                              color: t.fgPrimary,
                              letterSpacing: -0.15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '본인 API 키를 등록하면 보유 주식·시세를 자동으로 가져와요',
                            style: PTypo.caption.copyWith(
                              color: t.fgSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (connected) ...[
                      const SizedBox(width: PSpace.x8),
                      const PBadge(
                        label: '연결됨',
                        variant: PBadgeVariant.softSuccess,
                      ),
                    ],
                  ],
                ),
              ),
              // 본문
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PSpace.x16,
                  0,
                  PSpace.x16,
                  PSpace.x16,
                ),
                child: connected ? _connectedBody(t, cred) : _formBody(t),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _connectedBody(PorestTokens t, TossCredentialStatus? cred) {
    final verifiedAt = cred?.verifiedAt;
    final sub = verifiedAt != null && verifiedAt.length >= 10
        ? '마지막 검증 · ${verifiedAt.substring(0, 10)}'
        : '보유 주식·시세 자동 수집 중';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: t.bgSunken, borderRadius: PRadius.brMd),
      child: Row(
        children: [
          Icon(LucideIcons.circleCheck, size: 18, color: t.statusSuccessFg),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '토스증권 API 키 연결됨',
                  style: TextStyle(
                    fontFamily: PTypo.sans,
                    fontSize: 13,
                    fontWeight: PFontWeight.semi,
                    color: t.fgPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(sub, style: PTypo.micro.copyWith(color: t.fgTertiary)),
              ],
            ),
          ),
          const SizedBox(width: PSpace.x8),
          PButton(
            label: '연결 해제',
            variant: PButtonVariant.outline,
            size: PButtonSize.sm,
            onPressed: _busy
                ? null
                : () => _run(
                    (repo) => repo.disconnectTossCredential(),
                    '토스증권 연결을 해제했어요',
                    '해제에 실패했어요',
                  ),
          ),
        ],
      ),
    );
  }

  Widget _formBody(PorestTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Client ID', style: _fieldLabel(t)),
        const SizedBox(height: PSpace.x4),
        PTextInput(controller: _idCtrl, placeholder: '토스증권 개발자센터 발급 Client ID'),
        const SizedBox(height: PSpace.x12),
        Text('Client Secret', style: _fieldLabel(t)),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: _secretCtrl,
          placeholder: 'Client Secret',
          obscureText: true,
        ),
        const SizedBox(height: PSpace.x12),
        PButton(
          label: _busy ? '연결 중…' : '연결하기',
          fullWidth: true,
          onPressed: _busy
              ? null
              : () {
                  final id = _idCtrl.text.trim();
                  final secret = _secretCtrl.text.trim();
                  if (id.isEmpty || secret.isEmpty) return;
                  _run(
                    (repo) => repo.registerTossCredential(id, secret),
                    '토스증권 계정을 연결했어요',
                    '인증정보가 올바르지 않아요',
                  );
                },
        ),
        const SizedBox(height: PSpace.x8),
        Text(
          '키는 서버에 암호화되어 저장되며 본인만 사용합니다. 발급은 토스증권 개발자센터에서.',
          style: PTypo.micro.copyWith(color: t.fgTertiary, height: 1.5),
        ),
      ],
    );
  }

  TextStyle _fieldLabel(PorestTokens t) => TextStyle(
    fontFamily: PTypo.sans,
    fontSize: PFontSize.caption,
    fontWeight: PFontWeight.semi,
    color: t.fgSecondary,
  );
}
