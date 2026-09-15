/// 이체가 성립하는 조건 — **이체를 그리는 모든 화면**이 이 한 벌을 쓴다.
///
/// 거래 시트 · 반복 설정 · 프리셋 편집이 각자 그리면 "어떤 계좌를 고를 수 있나 ·
/// 이자 칸이 언제 뜨나" 가 갈린다. 갈리는 순간 사용자는 시트에서 만든 이체를 반복으로는
/// 못 만들거나, 반복으로 저장해 둔 규칙이 자정에만 거절당한다(배치 실패는 로그만 남는다).
///
/// 서버도 같은 규칙을 본다 — `AssetTransferRules` · `RecurringTransferValidator`.
/// 화면에서 못 고르게 하는 것과 서버가 거절하는 것은 별개다: 옛 앱·API 직접 호출이 남아 있다.
library;

import 'package:porest_desk_app/features/asset/domain/asset.dart';

/// 이체 상대가 될 수 있는 자산.
///
/// 카드는 양쪽 다 뺀다.
/// - **체크카드** — 잔액을 들지 않는다(긁는 즉시 연결 계좌에서 빠진다). 걸면 카드에
///   있을 수 없는 잔액이 생긴다.
/// - **신용카드** — 대금 결제는 전용 기능(자산 상세 → 결제)이 담당한다. 그쪽은 이체와
///   함께 청구 회차를 남기고 자동 결제의 멱등 체크가 그 기록으로 걸린다. 손으로 이체하면
///   기록이 없어 결제일에 자동 결제가 또 돌아 이중 차감된다.
List<Asset> transferEligibleAssets(List<Asset> assets) => assets
    .where((a) => a.assetType != 'CHECK_CARD' && a.assetType != 'CREDIT_CARD')
    .toList(growable: false);

/// 이자 칸을 보일지 — **받는 자산이 대출일 때만**.
///
/// 원금은 부채가 줄어드는 자산 이동이지만 이자는 은행으로 아예 나가는 비용이라,
/// 대출 상환이 아니면 뜻이 없다.
bool isLoanTarget(List<Asset>? assets, int? toAssetRowId) {
  if (assets == null || toAssetRowId == null) return false;
  return assets.where((a) => a.rowId == toAssetRowId).firstOrNull?.assetType ==
      'LOAN';
}

/// 이체가 성립하는 최소 조건 — 양쪽이 있고 서로 다르다.
bool transferPartiesReady(int? fromAssetRowId, int? toAssetRowId) =>
    fromAssetRowId != null &&
    toAssetRowId != null &&
    fromAssetRowId != toAssetRowId;

/// 이체 행의 "누구에게서 누구로" 한 줄.
///
/// 이체는 카테고리가 없다. 그래서 목록·띠가 카테고리나 계좌를 적는 자리에 이걸 적는다 —
/// 출금 계좌만 적으면 돈이 어디로 갔는지가 행에서 사라진다.
///
/// 같은 데이터를 그리는 자리가 앱에 셋(반복 목록 행 · 반복 "다가오는 7일" 행 · 프리셋
/// 목록 행)이다. 셋이 각자 만들던 동안 프리셋만 맞고 반복 둘은 출금 계좌만 보였다
/// (2026-09-15). 웹도 같은 이름의 helper 를 쓴다.
String transferPartiesLabel(String? fromName, String? toName) =>
    '${fromName ?? '-'} → ${toName ?? '-'}';
