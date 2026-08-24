import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';
import 'package:porest_desk_app/features/subscription/data/subscription_repository.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';

/// 증권사 한 곳의 연결 카드 — 키 등록 / 해제 / 기본 시세 소스 지정.
///
/// **증권사 이름을 코드에 박지 않는다.** 표시명·발급처·입력 라벨은 서버가 주는
/// [BrokerConnection] 에서 온다. 증권사가 늘어도 앱 배포 없이 목록에 나타나고,
/// 같은 자리를 회사마다 다르게 부르는 문제(토스 Client ID / 나무 App Key)도 여기서 풀린다.
class BrokerConnectCard extends ConsumerStatefulWidget {
  const BrokerConnectCard({
    super.key,
    required this.connection,
    required this.showPrimaryAction,
  });

  final BrokerConnection connection;

  /// 기본 시세 소스 지정 버튼 노출 여부. 연결이 하나뿐이면 고를 게 없어 감춘다.
  final bool showPrimaryAction;

  @override
  ConsumerState<BrokerConnectCard> createState() => _BrokerConnectCardState();
}

class _BrokerConnectCardState extends ConsumerState<BrokerConnectCard> {
  final _keyCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _keyCtrl.dispose();
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
      ref.invalidate(brokerConnectionsProvider);
      if (mounted) {
        showPSnackBar(context, okMsg, severity: PSnackSeverity.success);
      }
    } on ApiException {
      // 서버 에러는 ErrorToastInterceptor 가 띄운다.
    } catch (_) {
      // API 가 아닌 예외는 인터셉터가 못 잡는다 — 여기서 알린다.
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
    final c = widget.connection;

    return PCard(
      variant: PCardVariant.bordered,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(t, c),
          Padding(
            padding: const EdgeInsets.fromLTRB(PSpace.x16, 0, PSpace.x16, PSpace.x16),
            child: c.connected ? _connectedBody(t, c) : _formBody(t, c),
          ),
        ],
      ),
    );
  }

  Widget _header(PorestTokens t, BrokerConnection c) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(PSpace.x16, PSpace.x16, PSpace.x16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: t.bgBrandSubtle, borderRadius: PRadius.brMd),
            alignment: Alignment.center,
            child: Icon(LucideIcons.link, size: 18, color: t.fgBrand),
          ),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.displayName,
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
                  l.subBrokerConnectDesc,
                  style: PTypo.caption.copyWith(color: t.fgSecondary, height: 1.5),
                ),
              ],
            ),
          ),
          if (c.primary) ...[
            const SizedBox(width: PSpace.x8),
            PBadge(label: l.subBrokerPrimary, variant: PBadgeVariant.softBrand),
          ] else if (c.connected) ...[
            const SizedBox(width: PSpace.x8),
            PBadge(label: l.subConnected, variant: PBadgeVariant.softSuccess),
          ],
        ],
      ),
    );
  }

  Widget _connectedBody(PorestTokens t, BrokerConnection c) {
    final l = AppLocalizations.of(context);
    final verifiedAt = c.verifiedAt;
    final sub = verifiedAt != null && verifiedAt.length >= 10
        ? l.subBrokerLastVerified(verifiedAt.substring(0, 10))
        : l.subBrokerCollecting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                      l.subBrokerKeyConnected(c.displayName),
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
                label: l.assetUnlink,
                variant: PButtonVariant.outline,
                size: PButtonSize.sm,
                onPressed: _busy
                    ? null
                    : () => _run(
                          (repo) => repo.disconnectBrokerCredential(c.broker),
                          l.subBrokerDisconnected(c.displayName),
                          l.subDisconnectFailed,
                        ),
              ),
            ],
          ),
        ),
        // 연결이 둘 이상일 때만 고를 의미가 있다.
        if (widget.showPrimaryAction && !c.primary) ...[
          const SizedBox(height: PSpace.x12),
          PButton(
            label: l.subBrokerUseAsPrimary,
            variant: PButtonVariant.outline,
            fullWidth: true,
            onPressed: _busy
                ? null
                : () => _run(
                      (repo) => repo.setPrimaryBroker(c.broker),
                      l.subBrokerPrimaryChanged(c.displayName),
                      l.subBrokerPrimaryFailed,
                    ),
          ),
          const SizedBox(height: PSpace.x8),
          Text(
            l.subBrokerPrimaryNotice,
            style: PTypo.micro.copyWith(color: t.fgTertiary, height: 1.5),
          ),
        ],
      ],
    );
  }

  Widget _formBody(PorestTokens t, BrokerConnection c) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨은 서버가 준다 — 회사마다 같은 자리를 다르게 부른다.
        Text(c.keyLabel, style: _fieldLabel(t)),
        const SizedBox(height: PSpace.x4),
        PTextInput(controller: _keyCtrl, placeholder: c.keyLabel),
        const SizedBox(height: PSpace.x12),
        Text(c.secretLabel, style: _fieldLabel(t)),
        const SizedBox(height: PSpace.x4),
        PTextInput(controller: _secretCtrl, placeholder: c.secretLabel, obscureText: true),
        const SizedBox(height: PSpace.x12),
        PButton(
          label: _busy ? l.subConnecting : l.subConnect,
          fullWidth: true,
          onPressed: _busy
              ? null
              : () {
                  final key = _keyCtrl.text.trim();
                  final secret = _secretCtrl.text.trim();
                  if (key.isEmpty || secret.isEmpty) return;
                  _run(
                    (repo) => repo.registerBrokerCredential(c.broker, key, secret),
                    l.subBrokerConnected(c.displayName),
                    l.subBrokerInvalidCred,
                  );
                },
        ),
        const SizedBox(height: PSpace.x8),
        Text(
          l.subBrokerKeyNotice(c.displayName),
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
