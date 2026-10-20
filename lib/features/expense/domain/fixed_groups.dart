/// 고정 정리 시트가 거래를 묶는 규칙. 웹 `features/expense/lib/fixed-groups.ts` 미러.
///
/// 월세·통신비처럼 **매달 같은 이름으로 나가는 돈**이 고정의 전형이라, 거래를 한 줄씩 보여 주면
/// 열두 달치를 열두 번 눌러야 한다. 행에 보이는 이름(거래처 → 메모 → 카테고리)이 같으면 한 묶음으로
/// 보고, 묶음 하나를 고르면 그 안의 거래가 전부 대상이 된다.
///
/// 합계에 안 잡히는 거래(환불 · 아직 안 온 것 · 카드 이월)는 처음부터 뺀다 — 통계에 나타나지 않는
/// 거래를 정리하라고 보여 줘 봐야 고쳐도 아무 숫자가 안 바뀐다. `countableTx` 한 곳을 지난다.
library;

import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_aggregates.dart';

class TxGroup {
  TxGroup({required this.key, required this.name});

  /// 묶음 식별자 — 이름을 소문자·공백 정리한 값.
  final String key;

  /// 행에 보이는 이름
  final String name;

  /// 이 묶음에 든 거래 id — 고르면 전부 일괄 변경 대상이다
  final List<int> ids = [];
  int get count => ids.length;

  /// 묶음 합계(금액은 늘 양수로 온다)
  int total = 0;

  /// 그 가운데 이미 고정인 거래 수 — 0 이면 전부 변동, count 면 전부 고정
  int fixedCount = 0;
}

String _normalize(String s) =>
    s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

/// 거래 한 건이 행에 내는 이름 — 목록 행과 같은 우선순위다.
String txTitle(Expense e, String fallback) {
  for (final s in [e.merchant, e.description, e.categoryName]) {
    final v = s?.trim();
    if (v != null && v.isNotEmpty) return v;
  }
  return fallback;
}

/// 한 종류(`EXPENSE` | `INCOME`)의 거래를 이름으로 묶는다.
/// 정렬은 건수 많은 순 → 합계 큰 순 — 매달 반복되는 것이 위로 온다.
List<TxGroup> groupForFixed(
  Iterable<Expense> expenses,
  String type,
  String fallbackName,
) {
  final map = <String, TxGroup>{};
  for (final e in countableTx(expenses)) {
    if (e.expenseType != type) continue;
    final name = txTitle(e, fallbackName);
    final key = _normalize(name);
    final g = map.putIfAbsent(key, () => TxGroup(key: key, name: name));
    g.ids.add(e.rowId);
    g.total += e.amount.abs();
    if (e.isFixed) g.fixedCount += 1;
  }
  return map.values.toList()..sort((a, b) {
    final byCount = b.count.compareTo(a.count);
    return byCount != 0 ? byCount : b.total.compareTo(a.total);
  });
}

/// 고른 id 집합 기준으로 묶음이 전부(true) / 일부(null) / 하나도 안(false) 골라졌는지 —
/// 체크박스의 세 모양(tristate)과 같다.
bool? groupCheck(TxGroup g, Set<int> picked) {
  final n = g.ids.where(picked.contains).length;
  if (n == 0) return false;
  return n == g.ids.length ? true : null;
}

/// 묶음을 켜거나 끈 새 집합 — 원래 집합은 건드리지 않는다.
Set<int> toggleGroup(TxGroup g, Set<int> picked, bool on) {
  final next = {...picked};
  if (on) {
    next.addAll(g.ids);
  } else {
    next.removeAll(g.ids);
  }
  return next;
}
