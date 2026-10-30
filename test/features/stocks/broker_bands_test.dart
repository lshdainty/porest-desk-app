// 증권사 공통 맞춤 띠(I-13b 13b-1) — 오늘 시세 · 투자자별 · 나무 장 상태 글 · 주문 가능 줄 · 경고 이름표.
// 결함을 잡는 단언: 값 없는 줄은 그리지 않는다 · 0 은 "0" 옅게 · null 은 "—" · 모르는 장 상태는 항목 없음.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/stocks/data/broker_detail_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/market_state.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_broker_parts.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget Function(BuildContext) build, {
  double width = 360,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width * 3, 2400 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(
          c,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(child: Builder(builder: build)),
      ),
    ),
  );
  await tester.pump();
}

String _plain(Text w) => (w.data ?? w.textSpan?.toPlainText() ?? '')
    .replaceAll('⁠', '')
    .replaceAll('​', '');
Finder _t(String s) =>
    find.byWidgetPredicate((w) => w is Text && _plain(w) == s);

void main() {
  group('오늘 시세 띠', () {
    testWidgets('값 있는 줄만 그리고 상한가 · 하한가는 색이 다르다', (tester) async {
      late List<TodayRow> rows;
      await _pump(tester, (c) {
        rows = todayRowsOf(
          c,
          currency: 'KRW',
          open: 71200,
          volume: 1234567,
          upper: 92300,
          lower: 49700,
        );
        return StocksTodayBand(rows: rows);
      });
      expect(rows.map((r) => r.label), ['시가', '거래량', '상한가', '하한가']);
      expect(_t('고가'), findsNothing, reason: '값 없는 줄은 그리지 않는다');
      expect(_t('1,234,567주'), findsOneWidget);
      expect(rows[2].color, isNot(rows[3].color));
      expect(rows[0].color, isNull);
    });

    testWidgets('여섯 줄이 다 없으면 띠가 없다 · 불러오는 중이면 Skeleton · 실패면 실패 한 벌', (
      tester,
    ) async {
      await _pump(tester, (_) => const StocksTodayBand(rows: []));
      expect(_t('오늘 시세'), findsNothing);
      await _pump(
        tester,
        (_) => const StocksTodayBand(rows: [], loading: true),
      );
      expect(_t('오늘 시세'), findsOneWidget);
      expect(find.byType(PListItem), findsNothing);
      await _pump(
        tester,
        (_) => const StocksTodayBand(rows: [], failTitle: '오늘 시세를 불러오지 못했어요'),
      );
      expect(_t('오늘 시세를 불러오지 못했어요'), findsOneWidget);
      expect(_t('잠시 뒤 다시 시도해주세요.'), findsOneWidget);
    });

    testWidgets('미국은 달러, 가장 나쁜 값(거래량 12자리)도 넘치지 않는다 — 글자 200%', (tester) async {
      await _pump(
        tester,
        (c) => StocksTodayBand(
          rows: todayRowsOf(
            c,
            currency: 'USD',
            open: 408.2,
            high: 12345.67,
            volume: 123456789012,
          ),
        ),
        textScale: 2,
      );
      expect(_t('\$408.20'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('투자자별 매매동향 띠', () {
    List<InvestorTradingDay> days() => [
      const InvestorTradingDay(
        date: '2026-10-29',
        individual: null,
        foreigner: 4321000,
        institution: -987654,
      ),
      const InvestorTradingDay(
        date: '2026-10-28',
        individual: 0,
        foreigner: 12345678,
        institution: 1,
      ),
    ];

    testWidgets('날짜 · 개인 · 외국인 · 기관, 부호 없는 쉼표 숫자, null 은 "—", 0 은 "0"', (
      tester,
    ) async {
      await _pump(
        tester,
        (_) => StocksInvestorBand(
          days: days(),
          loading: false,
          failed: false,
          onRetry: () {},
        ),
      );
      expect(_t('투자자별 매매동향'), findsOneWidget);
      expect(_t('▲ 순매수 · ▼ 순매도 · 주'), findsOneWidget);
      expect(_t('10월 29일'), findsOneWidget);
      expect(_t('—'), findsOneWidget, reason: '당일 잠정 개인은 null');
      expect(_t('0'), findsOneWidget);
      expect(find.textContaining('-'), findsNothing, reason: '음수에도 부호를 쓰지 않는다');
      expect(find.textContaining('4,321,000'), findsOneWidget);
      expect(find.textContaining('987,654'), findsOneWidget);
    });

    testWidgets('빈 목록은 안내 줄 · 실패는 실패 한 벌 · 값이 있으면 실패해도 값을 남긴다', (tester) async {
      await _pump(
        tester,
        (_) => StocksInvestorBand(
          days: const [],
          loading: false,
          failed: false,
          onRetry: () {},
        ),
      );
      expect(_t('집계된 매매동향이 없어요'), findsOneWidget);
      await _pump(
        tester,
        (_) => StocksInvestorBand(
          days: null,
          loading: false,
          failed: true,
          onRetry: () {},
        ),
      );
      expect(_t('투자자별 매매동향을 불러오지 못했어요'), findsOneWidget);
      await _pump(
        tester,
        (_) => StocksInvestorBand(
          days: days(),
          loading: false,
          failed: true,
          onRetry: () {},
        ),
      );
      expect(_t('투자자별 매매동향을 불러오지 못했어요'), findsNothing);
      expect(_t('10월 28일'), findsOneWidget);
    });

    testWidgets('다섯 줄까지만 · 순매수 천만 단위 × 세 줄도 360 · 200% 에서 넘치지 않는다', (
      tester,
    ) async {
      await _pump(
        tester,
        (_) => StocksInvestorBand(
          days: [
            for (var i = 0; i < 8; i++)
              InvestorTradingDay(
                date: '2026-10-${20 + i}',
                individual: 12345678,
                foreigner: -12345678,
                institution: 12345678,
              ),
          ],
          loading: false,
          failed: false,
          onRetry: () {},
        ),
        textScale: 2,
      );
      expect(find.byType(PListItem), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });
  });

  group('나무 장 상태 글', () {
    testWidgets('여덟 가지 상태 + 모르는 값은 null', (tester) async {
      stocksNow = () => DateTime.utc(2026, 10, 29, 4, 5); // 한국 13:05
      addTearDown(() => stocksNow = DateTime.now);
      late AppLocalizations l;
      await _pump(tester, (c) {
        l = AppLocalizations.of(c);
        return const SizedBox();
      });
      expect(namuMarketStateText(l, 'REGULAR')!.open, isTrue);
      expect(namuMarketStateText(l, 'REGULAR')!.text, '장중 · 오후 1:05');
      const expected = {
        'PRE': '프리마켓',
        'AFTER': '애프터마켓',
        'DAYTIME': '주간거래',
        'SINGLE_PRICE': '단일가',
        'HALTED': '일시 마감',
        'BEFORE_OPEN': '개장 전',
        'CLOSED': '장마감',
      };
      expected.forEach((state, text) {
        final r = namuMarketStateText(l, state)!;
        expect(r.text, text, reason: state);
        expect(r.open, isFalse, reason: '열려 있는 것은 정규장뿐');
      });
      expect(namuMarketStateText(l, 'WHAT'), isNull);
      expect(namuMarketStateText(l, null), isNull);
    });
  });

  group('주문 가능 줄', () {
    testWidgets('값 · 가리기 · 실패 "—" · 불러오는 중', (tester) async {
      await _pump(
        tester,
        (c) => PList(
          children: [
            stocksBuyingPowerRow(
              c,
              title: '주문 가능 · 원화',
              state: const AsyncValue3(amount: 200000000),
              masked: false,
              format: (v) => '${v.round()}원',
            ),
            stocksBuyingPowerRow(
              c,
              title: '주문 가능 · 달러',
              state: const AsyncValue3(amount: 12.5),
              masked: true,
              format: (v) => '\$$v',
            ),
            stocksBuyingPowerRow(
              c,
              title: '예수금 · 달러',
              state: const AsyncValue3(failed: true),
              masked: false,
              format: (v) => '',
            ),
          ],
        ),
      );
      expect(_t('200000000원'), findsOneWidget);
      expect(_t('••••'), findsOneWidget);
      expect(_t('—'), findsOneWidget);
      expect(
        const AsyncValue3().hasRow,
        isFalse,
        reason: '값도 로딩도 실패도 아니면 줄을 만들지 않는다',
      );
      expect(const AsyncValue3(loading: true).hasRow, isTrue);
    });
  });

  testWidgets('경고 이름표 — 투자유의(새) · 단기과열 · VI', (tester) async {
    late AppLocalizations l;
    await _pump(tester, (c) {
      l = AppLocalizations.of(c);
      return const SizedBox();
    });
    expect(stocksWarningLabel(l, 'INVESTMENT_ATTENTION'), '투자유의');
    expect(stocksWarningLabel(l, 'SHORT_TERM_OVERHEAT'), '단기과열');
    expect(stocksWarningLabel(l, 'VI'), 'VI 발동');
  });
}
