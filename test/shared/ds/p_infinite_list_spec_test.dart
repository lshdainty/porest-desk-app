// Infinite List(목록 끝 자리)가 스펙 값(test/fixtures/design_spec/infinite-list.json)대로인지 — 상태 셋(loading · error · end)
// × 라이트 · 다크의 여백 · 글자 · 색 · 원 24 · 다시 시도 단추(small 36 · 위 12), 그리고 동작(1초 뒤 원 · 300 안에서 받기 · 한 번만
// 부르기 · 다시 시도 뒤에는 기다리기 · 끝 글 바꾸기). 웹은 같은 JSON 을 크로미움에서 잰다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/infinite_list/p_infinite_list.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';

import '../../support/design_spec.dart';
import '../../support/spec_check.dart';

final _spec = DesignSpec.load('infinite-list');

Widget _host(Brightness mode, Widget child, {double width = 360}) =>
    MaterialApp(
      theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: child),
        ),
      ),
    );

Finder _key(String name) => find.byKey(ValueKey(name));

void _noop() {}

void main() {
  for (final mode in Brightness.values) {
    for (final status in PInfiniteListStatus.values) {
      testWidgets('${mode.name} ${status.name} — 스펙 값이다', (tester) async {
        final want = _spec.resolve({'status': status.name}, 'enabled');
        final k = SpecCheck(mode, want, '${mode.name} ${status.name}');
        await tester.pumpWidget(
          _host(mode, PInfiniteListEnd(status: status, onRetry: _noop)),
        );
        // 원은 1초가 지나야 보인다
        await tester.pump(const Duration(milliseconds: 1100));
        final root = tester.getRect(_key('infinite-list-end'));
        final padding = tester.widget<Padding>(_key('infinite-list-end'));
        k.px('root.paddingY', (padding.padding as EdgeInsets).top);
        // justifyContent: center — 안의 것이 가운데에 선다
        final inner = switch (status) {
          PInfiniteListStatus.loading => tester.getRect(
            _key('infinite-list-progress'),
          ),
          PInfiniteListStatus.error => tester.getRect(
            _key('infinite-list-message'),
          ),
          PInfiniteListStatus.end => tester.getRect(
            _key('infinite-list-message'),
          ),
        };
        expect(inner.center.dx, closeTo(root.center.dx, 0.5));
        k.m(['root.justifyContent']);

        switch (status) {
          case PInfiniteListStatus.loading:
            k.px('progress.size', inner.width);
            expect(find.byType(PProgressCircle), findsOneWidget);
          case PInfiniteListStatus.error:
          case PInfiniteListStatus.end:
            final style = tester
                .widget<Text>(_key('infinite-list-message'))
                .style!;
            k.typo('message.typography', style);
            k.weight('message.fontWeight', style);
            k.color('message.foreground', style.color!);
        }
        if (status == PInfiniteListStatus.error) {
          final button = tester.getRect(_key('infinite-list-retry'));
          k.px('retryButton.buttonSize', button.height);
          k.px('retryButton.marginTop', button.top - inner.bottom);
          final widget = tester.widget<PButton>(_key('infinite-list-retry'));
          expect(widget.size, PButtonSize.small);
          expect(widget.variant, PButtonVariant.neutralWeak);
          expect(widget.label, '다시 시도');
        }
        // 받는 시점은 동작 묶음(아래)이 잰다
        k.coverage({'sentinel.threshold'});
        expect(k.failures, isEmpty);
      });
    }
  }

  test('받는 시점 300 — 스펙 값', () {
    expect(_spec.resolve({}, 'enabled')['sentinel.threshold'], 300);
    expect(kPInfiniteListReach, 300);
  });

  group('원은 1초가 지나야 보인다', () {
    testWidgets('그 전에는 높이만 지키고 아무것도 그리지 않는다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PInfiniteListEnd(status: PInfiniteListStatus.loading),
        ),
      );
      expect(find.byType(PProgressCircle), findsNothing);
      final quiet = tester.getSize(_key('infinite-list-end'));
      await tester.pump(const Duration(milliseconds: 999));
      expect(find.byType(PProgressCircle), findsNothing);
      await tester.pump(const Duration(milliseconds: 2));
      expect(find.byType(PProgressCircle), findsOneWidget);
      // 보이기 전후 높이가 같다(24 + 위아래 24)
      expect(tester.getSize(_key('infinite-list-end')), quiet);
      expect(quiet.height, 24 + 24 * 2);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('글 · 읽기', () {
    testWidgets('끝 글은 목록마다 바꾼다 — 읽는 말도 같다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PInfiniteListEnd(
            status: PInfiniteListStatus.end,
            endText: '카드를 모두 봤어요.',
          ),
        ),
      );
      expect(find.bySemanticsLabel('카드를 모두 봤어요.'), findsOneWidget);
      expect(find.bySemanticsLabel('모두 봤어요.'), findsNothing);
      handle.dispose();
    });

    testWidgets('기본 끝 글 · 못 불러옴 글은 상태 글로 읽힌다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PInfiniteListEnd(status: PInfiniteListStatus.end),
        ),
      );
      var node = tester.getSemantics(find.bySemanticsLabel('모두 봤어요.'));
      expect(node.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PInfiniteListEnd(status: PInfiniteListStatus.error, onRetry: _noop),
        ),
      );
      node = tester.getSemantics(find.bySemanticsLabel('더 불러오지 못했어요.'));
      expect(node.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });

    testWidgets('다시 시도를 누르면 onRetry — 가장 나쁜 값(글자 200% · 폭 320)도 넘치지 않는다', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      var retries = 0;
      await tester.pumpWidget(
        _host(
          Brightness.dark,
          PInfiniteListEnd(
            status: PInfiniteListStatus.error,
            onRetry: () => retries++,
          ),
          width: 320,
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(_key('infinite-list-retry'));
      expect(retries, 1);
    });
  });

  group('300 안에서 받는다', () {
    /// 높이 [rowHeight] 짜리 줄 [rows] 개 + 목록 끝 자리.
    Widget list({
      required int rows,
      required PInfiniteListStatus status,
      VoidCallback? onReachEnd,
      VoidCallback? onRetry,
      double rowHeight = 100,
      ScrollController? controller,
    }) => _host(
      Brightness.light,
      SizedBox(
        height: 600,
        child: ListView(
          controller: controller,
          cacheExtent: kPInfiniteListReach,
          children: [
            for (var i = 0; i < rows; i++)
              SizedBox(height: rowHeight, child: Text('줄 $i')),
            PInfiniteListEnd(
              status: status,
              onReachEnd: onReachEnd,
              onRetry: onRetry,
            ),
          ],
        ),
      ),
    );

    testWidgets('멀면 부르지 않고, 끝이 화면 아래에서 300 안으로 오면 한 번 부른다', (tester) async {
      var calls = 0;
      final controller = ScrollController();
      addTearDown(controller.dispose);
      // 줄 20개 = 2000, 끝 자리가 2000 에서 시작 — 화면 600 이라 처음 거리는 1400
      await tester.pumpWidget(
        list(
          rows: 20,
          status: PInfiniteListStatus.loading,
          onReachEnd: () => calls++,
          controller: controller,
        ),
      );
      await tester.pump();
      expect(calls, 0);
      // 끝 자리 위쪽 = 2000 − 스크롤. 거리 = 2000 − 스크롤 − 600 ≤ 300 이려면 스크롤 ≥ 1100
      controller.jumpTo(1100);
      await tester.pump();
      await tester.pump();
      expect(calls, 0, reason: '아직 300 밖 — 끝 자리가 그려지기 전');
      controller.jumpTo(1101);
      await tester.pump();
      await tester.pump();
      expect(calls, 1, reason: '거리 299');
      // 더 내려도 다시 부르지 않는다 — 받는 동안 거듭 부르지 않게
      controller.jumpTo(1300);
      await tester.pump();
      await tester.pump();
      expect(calls, 1);
    });

    testWidgets('목록이 자라면(새 쪽이 붙으면) 아직 가까울 때 다시 부른다', (tester) async {
      var calls = 0;
      // 줄 3개 = 300 — 화면 600 안에 다 들어온다
      await tester.pumpWidget(
        list(
          rows: 3,
          status: PInfiniteListStatus.loading,
          onReachEnd: () => calls++,
        ),
      );
      await tester.pump();
      expect(calls, 1, reason: '짧은 목록은 처음부터 가깝다');
      await tester.pump();
      expect(calls, 1, reason: '다시 그려도 부르지 않는다');
      // 새 쪽이 붙어 줄 5개(500) — 끝 자리가 아직 600 + 300 안이다
      await tester.pumpWidget(
        list(
          rows: 5,
          status: PInfiniteListStatus.loading,
          onReachEnd: () => calls++,
        ),
      );
      await tester.pump();
      expect(calls, 2);
    });

    testWidgets('300 밖으로 나갔다 오면 다시 부른다', (tester) async {
      var calls = 0;
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        list(
          rows: 20,
          status: PInfiniteListStatus.loading,
          onReachEnd: () => calls++,
          controller: controller,
        ),
      );
      controller.jumpTo(1200);
      await tester.pump();
      await tester.pump();
      expect(calls, 1);
      controller.jumpTo(0);
      await tester.pump();
      await tester.pump();
      controller.jumpTo(1200);
      await tester.pump();
      await tester.pump();
      expect(calls, 2);
    });

    testWidgets('error · end 일 때는 부르지 않는다', (tester) async {
      var calls = 0;
      for (final status in [
        PInfiniteListStatus.error,
        PInfiniteListStatus.end,
      ]) {
        await tester.pumpWidget(
          list(
            rows: 3,
            status: status,
            onReachEnd: () => calls++,
            onRetry: _noop,
          ),
        );
        await tester.pump();
        await tester.pump();
      }
      expect(calls, 0);
    });

    testWidgets('못 불러온 뒤 다시 시도로 돌아온 loading 은 기다린다 — 다시 시도가 받고 있다', (
      tester,
    ) async {
      var calls = 0;
      final controller = ScrollController();
      addTearDown(controller.dispose);
      Widget at(PInfiniteListStatus s) => list(
        rows: 20,
        status: s,
        onReachEnd: () => calls++,
        onRetry: _noop,
        controller: controller,
      );
      await tester.pumpWidget(at(PInfiniteListStatus.loading));
      controller.jumpTo(1200);
      await tester.pump();
      await tester.pump();
      expect(calls, 1);
      await tester.pumpWidget(at(PInfiniteListStatus.error));
      await tester.pumpWidget(at(PInfiniteListStatus.loading));
      await tester.pump();
      await tester.pump();
      expect(calls, 1, reason: '다시 시도가 받고 있다');
      // 300 밖으로 나갔다 오면 다시 부른다
      controller.jumpTo(0);
      await tester.pump();
      await tester.pump();
      controller.jumpTo(1200);
      await tester.pump();
      await tester.pump();
      expect(calls, 2);
    });
  });
}
