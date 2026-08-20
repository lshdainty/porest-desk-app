import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/presentation/asset_edit_dialog.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/actions/item_actions.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';

/// 자산 하나에 할 수 있는 일 — 상세 시트와 목록 행이 같은 것을 부른다.
///
/// 삭제는 원래 편집 폼 세 곳(계좌·카드·투자)의 State 안에 각각 있었다. 셋이 거의
/// 같은 코드였는데 투자만 평가액 무효화가 한 줄 더 있어서, 나머지 둘에 같은 줄이
/// 필요해지는 날 한 곳만 고쳐질 수밖에 없는 모양이었다. 삭제가 상세로 올라오면서
/// 그 코드를 옮겨야 했고, 옮기는 김에 셋을 하나로 합쳤다.
const assetActions = AssetActions();

/// 자산 종류 — l10n 키와 무효화 범위가 이걸로 갈린다.
enum _AssetKind { account, card, invest }

class AssetActions implements ItemActions<Asset> {
  const AssetActions();

  @override
  bool canDelete(Asset a) => true;

  @override
  bool canEdit(Asset a) => true;

  @override
  String deleteConfirmTitle(BuildContext context, Asset a) {
    final l = AppLocalizations.of(context);
    return switch (_kindOf(a)) {
      _AssetKind.account => l.assetAccountDelete,
      _AssetKind.card => l.assetCardDelete,
      _AssetKind.invest => l.assetInvestDelete,
    };
  }

  @override
  String deleteConfirmMessage(BuildContext context, Asset a) {
    final l = AppLocalizations.of(context);
    return switch (_kindOf(a)) {
      _AssetKind.account => l.assetAccountDeleteConfirm(a.assetName),
      _AssetKind.card => l.assetCardDeleteConfirm(a.assetName),
      _AssetKind.invest => l.assetInvestDeleteConfirm(a.assetName),
    };
  }

  @override
  Future<bool> delete(BuildContext context, WidgetRef ref, Asset a) async {
    final l = AppLocalizations.of(context);
    final kind = _kindOf(a);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.delete(a.rowId);
      ref.invalidate(assetsProvider);
      // 투자는 잔액이 보유수량 × 시세라, 자산만 무효화하면 지워진 종목의 평가액이
      // 캐시에 남아 합계가 어긋난다.
      if (kind == _AssetKind.invest) {
        ref.invalidate(investmentValuationMapProvider);
      }
      if (context.mounted) {
        showPSnackBar(
          context,
          switch (kind) {
            _AssetKind.account => l.assetAccountDeleted,
            _AssetKind.card => l.assetCardDeleted,
            _AssetKind.invest => l.assetInvestDeleted,
          },
          severity: PSnackSeverity.success,
        );
      }
      return true;
    } on ApiException catch (err) {
      if (context.mounted) {
        showPSnackBar(
          context,
          '${l.assetDeleteFailed}: ${err.message}',
          severity: PSnackSeverity.error,
        );
      }
      return false;
    }
  }

  @override
  Future<void> edit(BuildContext context, WidgetRef ref, Asset a) async {
    showAssetEditForm(context, a);
  }

  /// [showAssetEditForm] 의 분기와 같은 기준 — 편집 폼이 갈리는 대로 삭제 문구도 갈린다.
  _AssetKind _kindOf(Asset a) => switch (a.assetType) {
    'INVESTMENT' => _AssetKind.invest,
    'CREDIT_CARD' || 'CHECK_CARD' => _AssetKind.card,
    _ => _AssetKind.account,
  };
}
