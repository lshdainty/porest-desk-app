// 앱 ProviderScope 의 재시도 — Riverpod 기본(최대 10회)을 끄고, 읽기의 저절로 다시 시도는 네트워크 층이 10초 안에서 맡는다
// (skeleton.md "요청 제한 10초", 03E-021).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/session_scope.dart';

void main() {
  test('appProviderRetry 는 다시 하지 않는다', () {
    for (var i = 0; i < 12; i++) {
      expect(appProviderRetry(i, Exception('boom')), isNull);
    }
  });

  testWidgets('SessionScope 아래에서 실패한 제공자는 기다려도 다시 만들어지지 않는다(기본이면 10회)', (
    tester,
  ) async {
    var builds = 0;
    final failing = FutureProvider<int>((ref) async {
      builds++;
      throw Exception('boom');
    });
    final seen = <AsyncValue<int>>[];
    await tester.pumpWidget(
      SessionScope(
        child: Consumer(
          builder: (context, ref, _) {
            seen.add(ref.watch(failing));
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    // 기본 재시도라면 0.2초부터 두 배씩 — 40초 안에 열 번 더 만든다
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(builds, 1);
    expect(seen.last.hasError, isTrue);
  });
}
