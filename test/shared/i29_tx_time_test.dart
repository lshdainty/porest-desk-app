// I-29 웹 · 앱 같은 장면 — P2 거래 시각 규칙(웹 txTimeLabel 과 같다).
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/expense/presentation/widgets/expense_row.dart';

void main() {
  test('P2 거래 시각 — HH:mm, 00:00 · 날짜만 · 없음이면 숨긴다', () {
    expect(txTimeLabel('2026-10-28T12:30:00'), '12:30');
    expect(txTimeLabel('2026-10-28T00:00:00'), isNull);
    expect(txTimeLabel('2026-10-28'), isNull);
    expect(txTimeLabel(null), isNull);
  });
}
