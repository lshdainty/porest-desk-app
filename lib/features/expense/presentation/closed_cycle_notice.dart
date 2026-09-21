import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/presentation/asset_edit_route.dart';
import 'package:porest_desk_app/features/expense/domain/card_cycle.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_toast.dart';

/// 결제가 끝난 회차에 걸린 거래를 바꿀 때 하는 말 — 확인창 **한 문구**와 결과 토스트.
///
/// 닫힌 회차에 걸린 변경은 기록만 바뀌고 통장은 그대로다(D1). 예전엔 서버에 "얼마가
/// 돌아오나" 를 미리 물어 문장을 다섯 갈래로 골랐다. 이제 돌려주는 일이 없으니 묻지
/// 않는다 — 삭제·환불·환불 취소·저장·스와이프가 모두 같은 문장을 쓴다(웹과 한 벌).

/// 확인창에 덧붙일 한 줄 — 열린 회차면 null.
String? closedCycleNote(AppLocalizations l, ClosedCycleSpan span) =>
    switch (span) {
      ClosedCycleSpan.full => l.expClosedCycleLine,
      ClosedCycleSpan.partial => l.expClosedCyclePartLine,
      ClosedCycleSpan.none => null,
    };

/// 거래 하나가 지금 닫힌 회차에 걸렸나 — 그 거래의 날짜·할부·카드로 본다.
ClosedCycleSpan closedCycleSpanOfExpense(Expense e, Asset? asset) =>
    closedCycleSpanFor(
      asset,
      dateKey: e.expenseDate,
      installmentMonths: e.installmentMonths,
    );

/// 확인창 본문 — 기본 문장 뒤에 닫힌 회차 한 줄을 문단으로 붙인다.
String withClosedCycleNote(
  AppLocalizations l,
  String message,
  ClosedCycleSpan span,
) {
  final note = closedCycleNote(l, span);
  return note == null ? message : '$message\n\n$note';
}

/// [잔액 고치기] 가 갈 결제계좌 — 닫힌 회차에 걸린 신용카드 거래이고 결제계좌가
/// 있을 때만(D9). 없으면 null.
///
/// 닫힌 회차의 변경은 통장을 안 움직인다. 카드사가 실제로 돈을 돌려줬다면 사용자가
/// 그 계좌의 잔액을 고쳐야 한다 — 그 수정 폼으로 바로 보내는 바로가기다.
int? fixBalanceTargetOf(Expense e, Asset? asset) {
  if (closedCycleSpanOfExpense(e, asset) == ClosedCycleSpan.none) return null;
  return asset?.paymentAssetRowId;
}

/// 바꾼 뒤의 결과 토스트 — 미리 낸 돈이 계좌로 돌아왔으면 그 금액을 말한다(D4).
///
/// 미리보기는 없다. 열린 회차에서 미리 낸 돈이 남을 때만 서버가 결제계좌로 돌려주고,
/// 그 금액이 응답에 실려 온다 — 사후에 한 번 알린다(스와이프 삭제 포함).
///
/// [fixBalanceAssetId] 가 있으면(닫힌 회차 거래의 환불·삭제·고쳐 쓰기, D9) 토스트에
/// [잔액 고치기] 를 단다 — 돌려받은 돈이 없어도 "기록만 바뀌고 계좌 잔액은 그대로" 를
/// 말하며 띄운다. 둘 다 없으면 조용히 끝난다.
///
/// [host] 는 시트·행보다 오래 사는 context 다 — 지운 뒤 시트가 닫히고 행이 사라져도
/// 토스트는 떠야 하고, 버튼은 그 뒤에 눌린다.
void showChangeResultToast(
  BuildContext host, {
  required int? refundedAmount,
  int? fixBalanceAssetId,
}) {
  if (!host.mounted) return;
  final l = AppLocalizations.of(host);
  final refunded = refundedAmount ?? 0;
  final String message;
  if (refunded > 0) {
    message = l.expRefundedToast(krwSigned(refunded, false, unit: true));
  } else if (fixBalanceAssetId != null) {
    message = l.expRecordOnlyChangedToast;
  } else {
    return;
  }
  PToast.show(
    host,
    message: message,
    tone: refunded > 0 ? PToastTone.success : PToastTone.info,
    // 누를 버튼이 있으면 조금 더 오래 둔다 — 3초는 읽고 누르기에 짧다.
    duration: Duration(seconds: fixBalanceAssetId != null ? 6 : 3),
    actionLabel: fixBalanceAssetId != null ? l.expFixBalance : null,
    onAction: fixBalanceAssetId == null
        ? null
        : () => pushAssetEdit(host, fixBalanceAssetId),
  );
}

/// 토스트·확인창을 띄울 오래 사는 context — 루트 내비게이터의 것.
///
/// 시트 안의 context 는 시트가 닫히면 풀리고, 목록 행의 context 는 지운 행과 함께
/// 사라진다. 루트 내비게이터는 앱과 함께 산다(스와이프 확인창도 같은 자리를 쓴다).
BuildContext hostContextOf(BuildContext context) =>
    Navigator.maybeOf(context, rootNavigator: true)?.context ?? context;
