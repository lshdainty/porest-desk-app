import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/app/theme/spacing.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/app/theme/typography.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/features/subscription/presentation/broker_connect_card.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_back_button.dart';
import 'package:groo_damda_app/shared/widgets/p_empty_state.dart';
import 'package:groo_damda_app/shared/widgets/p_skeleton.dart';

/// 증권사 연동 화면.
///
/// 예전에는 토스 키 입력이 계정 설정 안에 인라인 카드로 덩그러니 있었다. 증권사가 둘 이상이
/// 되면 그 자리에 카드를 쌓을 수 없어 화면으로 분리했다.
///
/// **목록은 서버가 준다.** 미연결 증권사까지 내려오므로 증권사가 늘어도 앱 배포 없이 나타난다.
class SecuritiesLinkScreen extends ConsumerWidget {
  const SecuritiesLinkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final connectionsAsync = ref.watch(brokerConnectionsProvider);

    return Scaffold(
      backgroundColor: context.colors.bgLayerBasement,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.settingsSecuritiesLink),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: PScreenBandBody(
        child: connectionsAsync.when(
          loading: () => const _LoadingList(),
          error: (_, _) => Center(
            child: PEmptyState(
              icon: LucideIcons.unplug,
              message: l.securitiesLoadError,
            ),
          ),
          data: (connections) => _List(connections: connections),
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.connections});

  final List<BrokerConnection> connections;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    // 연결이 하나뿐이면 기본 소스를 고를 게 없다 — 버튼을 감춘다.
    final connectedCount = connections.where((c) => c.connected).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PSpace.x24,
        PSpace.x16,
        PSpace.x24,
        PSpace.x24,
      ),
      children: [
        Text(
          l.settingsSecuritiesLinkDesc,
          style: PTypo.caption.copyWith(color: t.fgSecondary, height: 1.6),
        ),
        const SizedBox(height: PSpace.x16),
        for (final c in connections) ...[
          BrokerConnectCard(
            connection: c,
            showPrimaryAction: connectedCount > 1,
          ),
          const SizedBox(height: PSpace.x12),
        ],
      ],
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PSpace.x24,
        PSpace.x16,
        PSpace.x24,
        PSpace.x24,
      ),
      children: const [
        PSkeleton(height: 180),
        SizedBox(height: PSpace.x12),
        PSkeleton(height: 180),
      ],
    );
  }
}
