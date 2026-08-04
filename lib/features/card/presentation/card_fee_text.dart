import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/features/card/domain/card_catalog.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

/// 연회비 표기 — **"정보 없음"과 "무료"를 구분한다.**
///
/// `annual_fee_amount` 는 DB 에서 NOT NULL DEFAULT 0 이라 미수집분도 0 으로 내려온다.
/// 예전에는 화면 네 곳이 전부 그걸 `cardNone`("없음")으로 찍어서, 연회비를 안 받는
/// 카드처럼 보였다. 2026-08 실측으로 9,466 장 중 5,399 장이 미수집 상태다
/// (카드사 공시 PDF 는 연회비를 주지 않는다).
///
/// 지금은 백엔드가 `amount == 0 && label 없음` 이면 `annualFee` 자체를 null 로 내린다.
/// 그래서 여기서는
///   - `fee == null`  → 정보 없음
///   - `amount > 0`   → 금액(또는 label)
///   - 그 외          → 확인된 0원이므로 "무료"
/// 로 갈린다.
///
/// [preferLabel] 은 화면 성격에 따라 다르다. 상세는 `국내전용 15,000원 / 해외겸용
/// 20,000원` 같은 원문 label 이 유용하고, 목록은 짧은 금액이 낫다.
/// [domesticPrefix] 는 금액만 있을 때 `국내전용` 을 앞에 붙인다(상세 시트 표기 유지).
String cardFeeValue(
  AppLocalizations l,
  CardAnnualFee? fee, {
  bool preferLabel = true,
  bool domesticPrefix = false,
}) {
  if (fee == null) return l.cardFeeUnknown;

  final label = fee.label;
  final hasLabel = label != null && label.isNotEmpty;
  final amount = fee.amount ?? 0;

  if (preferLabel && hasLabel) return label;
  if (amount > 0) {
    final money = krwSigned(amount, false, unit: true);
    return domesticPrefix ? l.cardFeeDomesticOnly(money) : money;
  }
  if (hasLabel) return label;
  return l.cardFeeFree;
}
