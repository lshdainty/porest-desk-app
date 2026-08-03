import 'package:flutter/material.dart';

import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/presentation/account_add_dialog.dart';
import 'package:porest_desk_app/features/asset/presentation/asset_detail_dialog.dart';
import 'package:porest_desk_app/features/asset/presentation/card_add_dialog.dart' as card;
import 'package:porest_desk_app/features/asset/presentation/investment_add_dialog.dart' as inv;

/// 자산 다이얼로그 진입점 모음 — 신규 다이얼로그 4종으로 위임만 한다.
///
/// front 와 동일한 구조:
/// - 계좌 추가/편집 → [showAccountAddDialog] / [showAccountEditDialog]
/// - 카드 추가/편집 → [card.showCardAddDialog] / [card.showCardEditDialog]
/// - 투자 추가/편집 → [inv.showInvestmentAddDialog] / [inv.showInvestmentEditDialog]
/// - 자산 상세     → [showAssetDetailRich]

/// 일반 자산 추가 — 계좌·예적금·현금·대출. front `AssetAddDialog` 미러.
void showAssetAddDialog(BuildContext context, {String? presetType}) {
  showAccountAddDialog(context, presetType: presetType);
}

/// 카드 추가 — front `CardAddDialog` 미러.
void showCardAddDialog(BuildContext context) {
  card.showCardAddDialog(context);
}

/// 투자 자산 추가 — front `InvestmentAddDialog` 미러.
void showInvestmentAddDialog(BuildContext context) {
  inv.showInvestmentAddDialog(context);
}

/// 자산 상세 — 잔액 추이 + 최근 거래 + 편집 진입.
/// front `AssetDetailDialog` 미러.
void showAssetDetailDialog(BuildContext context, Asset asset) {
  showAssetDetailRich(context, asset);
}

/// 자산 편집 폼 — assetType 별로 적절한 편집 다이얼로그로 분기.
/// front `AssetEditDialog` 미러.
void showAssetEditForm(BuildContext context, Asset asset) {
  switch (asset.assetType) {
    case 'INVESTMENT':
      inv.showInvestmentEditDialog(context, asset);
    case 'CREDIT_CARD' || 'CHECK_CARD':
      card.showCardEditDialog(context, asset);
    default:
      showAccountEditDialog(context, asset);
  }
}
