import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/settings/hide_amounts_cards.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';

/// 한 화면의 마스킹 판정을 한 덩어리로 들고 다니는 값.
///
/// 화면 카드 하나(`bool masked`)만 흘리면 그 화면의 모든 금액이 같이 가려진다. 거래
/// 종류(수입·지출·이체)로 쪼개려면 금액마다 자기 종류로 판정해야 하는데, 위젯 트리
/// 아래쪽에서 provider 를 다시 읽게 하면 리스트 행마다 watch 가 생긴다. 화면 최상단에서
/// 한 번 읽어 이 값으로 흘린다.
///
/// 판정은 **합집합**이다 — 화면 카드가 켜졌거나 그 금액의 종류 카드가 켜졌으면 가린다.
/// 카드는 "가리기" 스위치라 켰는데 아무 일도 안 일어나는 조합이 있으면 안 되고, 켜는
/// 방향으로만 넓어지므로 이미 가려진 게 풀리는 경우도 생기지 않는다.
class MaskFlags {
  const MaskFlags({
    required this.card,
    required this.expense,
    required this.income,
    required this.transfer,
  });

  /// 종류를 안 쓰는 자리용 — 화면 카드만 본다.
  const MaskFlags.cardOnly(this.card)
      : expense = false,
        income = false,
        transfer = false;

  /// 이 화면의 카드가 켜졌는가.
  final bool card;
  final bool expense;
  final bool income;
  final bool transfer;

  bool of(MaskKind kind) =>
      card ||
      switch (kind) {
        MaskKind.expense => expense,
        MaskKind.income => income,
        MaskKind.transfer => transfer,
        // 수입−지출을 그대로 찍는 값 — 둘 중 하나만 가려도 나머지가 뺄셈으로 드러난다.
        MaskKind.net => expense || income,
      };

  /// 거래 한 건 — 종류는 부호가 아니라 타입으로 가른다(환불이 음수 지출이라 부호로는 샌다).
  bool ofType(String? expenseType) => of(kindOfExpense(expenseType));

  /// 종류가 정해지지 않는 금액(잔액·한도 등) — 화면 카드만 본다.
  bool get plain => card;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaskFlags &&
          other.card == card &&
          other.expense == expense &&
          other.income == income &&
          other.transfer == transfer;

  // Provider 가 값이 같으면 리빌드를 안 하도록 — 리스트 행마다 watch 하는 자리라
  // identity 비교로 두면 설정이 바뀔 때마다 전부 다시 그린다.
  @override
  int get hashCode => Object.hash(card, expense, income, transfer);
}

/// 화면 카드 + 종류 카드 3장을 한 번에 읽는다.
final maskFlagsProvider = Provider.family<MaskFlags, String>((ref, card) {
  return MaskFlags(
    card: ref.watch(hideCardProvider(card)),
    expense: ref.watch(hideCardProvider('kind.expense')),
    income: ref.watch(hideCardProvider('kind.income')),
    transfer: ref.watch(hideCardProvider('kind.transfer')),
  );
});
