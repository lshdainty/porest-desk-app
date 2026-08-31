import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/features/stocks/presentation/namu_stocks_view.dart';
import 'package:porest_desk_app/features/stocks/presentation/toss_stocks_view.dart';
import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';

/// 증권 화면 셸 — 헤더와 증권사 선택을 소유하고 본문만 갈아 끼운다.
///
/// **증권사별 화면을 억지로 합치지 않는다.** 두 증권사가 주는 데이터가 겹치지 않는다 —
/// 토스엔 랭킹·시장지표·호가가 있고 나무엔 체결추이·투자자별·채권·금현물이 있다. 한 화면에
/// 합치면 절반이 "이 증권사는 미지원" 이 되므로 본문을 증권사별로 나눠 각자 관리한다.
///
/// 가계부 자산은 반대다 — 필요한 게 시세뿐이라 사용자가 고른 기본 소스 하나로 통합돼 있다.
class StocksScreen extends ConsumerStatefulWidget {
  const StocksScreen({super.key});

  @override
  ConsumerState<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends ConsumerState<StocksScreen> {
  String? _broker;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);

    // 개인키 미연결 시 전 화면 연결 유도 (mock 노출 금지). 증권사 API 는 시세 포함 모든
    // 조회가 개인키 토큰을 요구하므로, 어느 증권사든 하나는 연결돼 있어야 조회가 된다.
    final featuresAsync = ref.watch(myFeaturesProvider);
    final features = featuresAsync.asData?.value;
    final connected = features?.connectedBrokers ?? const <String>[];

    if (!featuresAsync.isLoading && connected.isEmpty) {
      return const _ConnectGate();
    }

    // 연결된 증권사 중에서 고른다. 저장된 선택이 끊겼으면 기본 소스 → 첫 연결 순으로 되돌린다.
    final active = connected.contains(_broker)
        ? _broker!
        : (connected.contains(features?.primaryBroker)
              ? features!.primaryBroker!
              : (connected.isEmpty ? '' : connected.first));

    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.moreItemStocks),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 연결이 하나뿐이면 고를 게 없다 — 탭을 감춘다.
          if (connected.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpace.x24,
                PSpace.x12,
                PSpace.x24,
                0,
              ),
              child: PTabs<String>(
                value: active,
                onChanged: (v) => setState(() => _broker = v),
                variant: PTabsVariant.container,
                size: PTabsSize.sm,
                expand: true,
                items: [
                  for (final b in connected)
                    PTabItem(value: b, label: _brokerLabel(l, b)),
                ],
              ),
            ),
          Expanded(child: _body(active)),
        ],
      ),
    );
  }

  Widget _body(String broker) {
    // 모르는 증권사 코드는 서버가 앞서 나갔다는 뜻이다 — 빈 화면 대신 안내를 띄운다.
    return switch (broker) {
      'TOSS' => const TossStocksView(),
      'NAMU' => const NamuStocksView(),
      _ => const _UnsupportedBroker(),
    };
  }

  /// 탭 라벨. 앱이 아는 증권사는 자기 번역을, 모르면 코드를 그대로 쓴다 —
  /// 서버가 증권사를 먼저 늘려도 탭이 비지 않는다.
  String _brokerLabel(AppLocalizations l, String broker) => switch (broker) {
    'TOSS' => l.brokerToss,
    'NAMU' => l.brokerNamu,
    _ => broker,
  };
}

/// 앱이 모르는 증권사 — 서버가 앞서 나간 구간.
class _UnsupportedBroker extends StatelessWidget {
  const _UnsupportedBroker();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PSpace.x24),
        child: Text(
          l.stocksBrokerUnsupported,
          textAlign: TextAlign.center,
          style: PTypo.bodySm.copyWith(color: t.fgTertiary),
        ),
      ),
    );
  }
}

/// 개인키 미연결: 전 화면 연결 유도.
class _ConnectGate extends StatelessWidget {
  const _ConnectGate();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.moreItemStocks),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(PSpace.x24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.lock, size: 32, color: t.fgTertiary),
              const SizedBox(height: PSpace.x12),
              Text(
                l.stocksConnectPrompt,
                style: PTypo.body.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.semi,
                ),
              ),
              const SizedBox(height: PSpace.x4),
              Text(
                l.stocksConnectDescRealtime,
                textAlign: TextAlign.center,
                style: PTypo.bodySm.copyWith(color: t.fgTertiary),
              ),
              const SizedBox(height: PSpace.x16),
              PButton(
                label: l.stocksConnectInSettings,
                variant: PButtonVariant.outline,
                size: PButtonSize.sm,
                // 연결은 이제 증권사 연동 화면에서 한다.
                onPressed: () => context.push('/settings/securities'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
