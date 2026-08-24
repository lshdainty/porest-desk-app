import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/core/format/now_tick.dart';

/// 상대시각이 화면을 열어 둔 채로도 흐르는지 — 앱만 "방금" 에 얼어붙던 자리.
void main() {
  test('해상도는 60초 — 웹 useNow 의 DEFAULT_INTERVAL_MS 와 같아야 한다', () {
    // 값이 갈리면 같은 알림이 웹 "3분 전" · 앱 "2분 전" 으로 보인다.
    expect(nowTickInterval, const Duration(minutes: 1));
  });

  group('alignedNow — 웹 alignedNow() 정합', () {
    test('초·밀리초가 눈금으로 내림된다', () {
      // 해상도만 맞추고 위상을 안 맞추면, 앱은 화면을 연 순간부터 웹은 페이지를 연
      // 순간부터 1분을 세어 같은 알림이 앱 "2분 전" · 웹 "3분 전" 이 된다.
      expect(alignedNow().millisecondsSinceEpoch % nowTickInterval.inMilliseconds, 0);
    });

    test('같은 눈금 안에서는 몇 번을 불러도 같은 값이다 — 화면마다 위상이 갈리지 않는다', () {
      expect(alignedNow(), alignedNow());
    });

    test('지금보다 미래를 내지 않는다', () {
      expect(alignedNow().isAfter(DateTime.now()), isFalse);
    });
  });

  testWidgets('틱이 돌고, 화면이 사라지면 타이머도 정리된다', (tester) async {
    var builds = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            ref.watch(nowTickProvider);
            builds++;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(builds, 1);

    // 값이 바뀌는지는 여기서 못 본다 — 기준 시각은 실제 시계를 눈금으로 내린 값이라
    // fake async 로 1분을 감아도 **실시간**이 같은 분 안이면 같은 값이 나온다.
    // 그게 정렬의 목적이고, 그때 리빌드가 안 걸리는 편이 맞다.
    // 값의 규칙은 위 alignedNow 테스트가 건다. 여기서 거는 건 타이머가 새지 않는다는 것 하나다.
    await tester.pump(nowTickInterval);
    await tester.pump(nowTickInterval);

    // 보는 화면이 사라지면 provider 가 dispose 되고 타이머도 취소돼야 한다.
    // 안 그러면 테스트 종료 시 binding 이 "A Timer is still pending" 으로 잡는다 —
    // 이 테스트가 통과하는 것 자체가 정리 검증이다(timer.cancel() 을 지우면 실패한다).
    await tester.pumpWidget(const ProviderScope(child: SizedBox.shrink()));
    await tester.pump();
  });
}
