import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';
import 'package:porest_desk_app/features/subscription/data/subscription_repository.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';

/// 증권 구독·토스 연결 설정. 구독해야 증권 메뉴가 열리고(결제 없는 self-grant),
/// 구독자가 본인 토스 키를 등록하면 API 로 본인 보유·시세를 가져온다.
class SecuritiesSettingsScreen extends ConsumerStatefulWidget {
  const SecuritiesSettingsScreen({super.key});

  @override
  ConsumerState<SecuritiesSettingsScreen> createState() => _SecuritiesSettingsScreenState();
}

class _SecuritiesSettingsScreenState extends ConsumerState<SecuritiesSettingsScreen> {
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
      Future<void> Function(SubscriptionRepository repo) action, String okMsg, String errMsg) async {
    setState(() => _busy = true);
    try {
      final repo = await ref.read(subscriptionRepositoryProvider.future);
      await action(repo);
      ref.invalidate(myFeaturesProvider);
      ref.invalidate(mySubscriptionProvider);
      ref.invalidate(tossCredentialStatusProvider);
      if (mounted) showPSnackBar(context, okMsg, severity: PSnackSeverity.success);
    } catch (_) {
      if (mounted) showPSnackBar(context, errMsg, severity: PSnackSeverity.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final features = ref.watch(myFeaturesProvider).asData?.value;
    final sub = ref.watch(mySubscriptionProvider).asData?.value;
    final cred = ref.watch(tossCredentialStatusProvider).asData?.value;
    final hasSecurities = features?.hasSecurities ?? false;
    final isActive = sub?.isActive ?? false;
    final connected = cred?.connected ?? false;

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('증권 구독·연결'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(PSpace.x16, PSpace.x16, PSpace.x16, PSpace.x24),
        children: [
          // 구독 카드
          PCard(
            padding: const EdgeInsets.all(PSpace.x20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('증권 구독',
                          style: TextStyle(fontFamily: PTypo.sans, fontSize: 16, fontWeight: PFontWeight.bold, color: t.fgPrimary)),
                    ),
                    if (isActive)
                      const PBadge(label: '구독중', variant: PBadgeVariant.secondary)
                    else if (sub != null)
                      PBadge(label: sub.status == 'EXPIRED' ? '만료' : '해지', variant: PBadgeVariant.secondary),
                  ],
                ),
                const SizedBox(height: 4),
                Text('구독하면 증권(시세·호가·보유) 메뉴가 열려요',
                    style: PTypo.caption.copyWith(color: t.fgTertiary)),
                const SizedBox(height: PSpace.x16),
                if (isActive && sub != null) ...[
                  _kv('플랜', sub.planName, t),
                  if (sub.currentPeriodEnd != null) ...[
                    const SizedBox(height: PSpace.x8),
                    _kv('다음 갱신', sub.currentPeriodEnd!.substring(0, 10), t),
                  ],
                  const SizedBox(height: PSpace.x12),
                  PButton(
                    label: '구독 해지',
                    variant: PButtonVariant.danger,
                    onPressed: _busy ? null : () => _run(
                      (repo) => repo.cancelSubscription(),
                      '구독을 해지했어요', '해지에 실패했어요'),
                  ),
                ] else
                  PButton(
                    label: '구독하기',
                    fullWidth: true,
                    onPressed: _busy ? null : () => _run(
                      (repo) => repo.subscribe("SECURITIES"),
                      '증권 구독이 시작되었어요', '구독에 실패했어요'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x16),

          // 토스 연결 카드 — 구독중일 때만
          if (hasSecurities)
            PCard(
              padding: const EdgeInsets.all(PSpace.x20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('토스증권 연결',
                            style: TextStyle(fontFamily: PTypo.sans, fontSize: 16, fontWeight: PFontWeight.bold, color: t.fgPrimary)),
                      ),
                      if (connected) const PBadge(label: '연결됨', variant: PBadgeVariant.secondary),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('본인 API 키를 등록하면 보유 주식·시세를 자동으로 가져와요',
                      style: PTypo.caption.copyWith(color: t.fgTertiary)),
                  const SizedBox(height: PSpace.x16),
                  if (connected)
                    PButton(
                      label: '연결 해제',
                      variant: PButtonVariant.danger,
                      onPressed: _busy ? null : () => _run(
                        (repo) => repo.disconnectTossCredential(),
                        '토스증권 연결을 해제했어요', '해제에 실패했어요'),
                    )
                  else ...[
                    PTextInput(controller: _idCtrl, placeholder: 'Client ID'),
                    const SizedBox(height: PSpace.x12),
                    PTextInput(controller: _secretCtrl, placeholder: 'Client Secret', obscureText: true),
                    const SizedBox(height: PSpace.x12),
                    PButton(
                      label: '연결하기',
                      fullWidth: true,
                      onPressed: _busy
                          ? null
                          : () {
                              final id = _idCtrl.text.trim();
                              final secret = _secretCtrl.text.trim();
                              if (id.isEmpty || secret.isEmpty) return;
                              _run(
                                (repo) => repo.registerTossCredential(id, secret),
                                '토스증권 계정을 연결했어요', '인증정보가 올바르지 않아요');
                            },
                    ),
                    const SizedBox(height: PSpace.x8),
                    Text('키는 서버에 암호화되어 저장되며 본인만 사용합니다. 발급은 토스증권 개발자센터에서.',
                        style: PTypo.micro.copyWith(color: t.fgTertiary, height: 1.5)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, PorestTokens t) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: PTypo.bodySm.copyWith(color: t.fgTertiary)),
          Text(v, style: PTypo.bodySm.copyWith(color: t.fgPrimary, fontWeight: PFontWeight.semi)),
        ],
      );
}
