import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_detail_dialog.dart';

export 'package:groo_damda_app/features/asset/presentation/asset_form_sheet.dart'
    show showAssetAddFlow, showAssetEditForm;

/// 자산 폼 진입점 모음 — 추가 · 수정 폼은 `asset_form_sheet.dart` 가 한 시트에서 단계로 연다(I-17).
/// - 추가 → [showAssetAddFlow] (1단계 종류 고르기부터)
/// - 수정 → [showAssetEditForm] (자산에서 종류를 재서 2단계로 바로)
/// - 자산 상세 → [showAssetDetailDialog]

/// 자산 상세 — 잔액 추이 + 최근 거래 + 편집 진입.
/// front `AssetDetailDialog` 미러.
void showAssetDetailDialog(BuildContext context, Asset asset) {
  showAssetDetailRich(context, asset);
}
