// 붙들기 — 누른 줄을 고정 시간 동안 그 자리에 남긴다(QA #29). 요청이 끝나는 때가 아니라 시간으로 푼다.
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/shared/scroll/hold_ids.dart';

void main() {
  test('기본 700ms — 따닥 막기 600ms 보다 길다', () {
    expect(kListHold, const Duration(milliseconds: 700));
    expect(kListHold.inMilliseconds, greaterThan(600));
  });

  test('붙들면 알리고, 시간이 지나면 풀리며 다시 알린다', () async {
    final h = HoldIds(duration: const Duration(milliseconds: 40));
    var n = 0;
    h.addListener(() => n++);
    h.hold(7);
    expect(h.contains(7), isTrue);
    expect(n, 1);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    expect(h.contains(7), isFalse);
    expect(n, 2);
    h.dispose();
  });

  test('다시 붙들면 시간이 새로 시작한다', () async {
    final h = HoldIds(duration: const Duration(milliseconds: 80));
    h.hold(1);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    h.hold(1);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(h.contains(1), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(h.contains(1), isFalse);
    h.dispose();
  });

  test('dispose 뒤에는 타이머가 알리지 않는다', () async {
    final h = HoldIds(duration: const Duration(milliseconds: 30));
    h.hold(1);
    h.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 60));
  });
}
