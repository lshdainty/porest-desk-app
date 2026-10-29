// 통계 기간 시트(I-28 28-2) — ds Date Picker 기간: 칸 하나(시작 · 끝 두 칸 없음) · 빠른 기간 칩 · 바닥 "초기화" + "완료".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_range_sheet.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import 'package:groo_damda_app/shared/widgets/p_date_input.dart';

final _today = DateTime(2026, 10, 29, 13);

Future<void> _open(
  WidgetTester tester,
  StatsPeriod current,
  void Function(StatsPeriod?) onResult,
) async {
  tester.view.physicalSize = const Size(780, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => onResult(
              await showStatsRangeSheet(context, current, today: _today),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Finder _done() => find.widgetWithText(PButton, '완료');

void main() {
  final month = StatsPeriod.thisMonth(_today);

  group('statsPeriodOfRange', () {
    test('바뀐 게 없으면 지금 값 그대로(구분을 잃지 않는다)', () {
      final p = statsPeriodOfRange(month, month.from, month.to, _today);
      expect(identical(p, month), isTrue);
    });
    test('오늘이 든 달 · 분기 · 해를 덮으면 그 구분', () {
      final custom = StatsPeriod(
        seg: StatsSeg.custom,
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
      );
      expect(
        statsPeriodOfRange(
          custom,
          DateTime(2026, 10),
          DateTime(2026, 10, 31),
          _today,
        ).seg,
        StatsSeg.month,
      );
      expect(
        statsPeriodOfRange(
          custom,
          DateTime(2026, 10),
          DateTime(2026, 12, 31),
          _today,
        ).seg,
        StatsSeg.quarter,
      );
      expect(
        statsPeriodOfRange(
          custom,
          DateTime(2026),
          DateTime(2026, 12, 31),
          _today,
        ).seg,
        StatsSeg.year,
      );
    });
    test('지난 달 · 아무 기간은 직접(이번 달 글을 달지 않는다)', () {
      expect(
        statsPeriodOfRange(
          month,
          DateTime(2026, 9),
          DateTime(2026, 9, 30),
          _today,
        ).seg,
        StatsSeg.custom,
      );
      expect(
        statsPeriodOfRange(
          month,
          DateTime(2026, 10, 3),
          DateTime(2026, 10, 9),
          _today,
        ).seg,
        StatsSeg.custom,
      );
    });
  });

  group('showStatsRangeSheet', () {
    testWidgets('칸 하나 — 날짜 입력칸 두 개와 월 · 분기 · 년 · 직접 탭이 없다', (tester) async {
      await _open(tester, month, (_) {});
      expect(find.byType(PDatePicker), findsOneWidget);
      expect(find.byType(PDateInput), findsNothing);
      expect(find.text('분기'), findsNothing);
      expect(find.text('직접'), findsNothing);
    });

    testWidgets('빠른 기간 칩 일곱 · 바닥 "초기화" + "완료"', (tester) async {
      await _open(tester, month, (_) {});
      for (final n in [
        '이번 달',
        '최근 7일',
        '최근 30일',
        '최근 3개월',
        '최근 6개월',
        '최근 1년',
        '올해',
      ]) {
        expect(find.text(n), findsOneWidget, reason: n);
      }
      expect(find.widgetWithText(PButton, '초기화'), findsOneWidget);
      expect(_done(), findsOneWidget);
    });

    testWidgets('초기화하면 완료가 막힌다 · 칩 최근 7일 → 오늘을 넣은 7일', (tester) async {
      StatsPeriod? got;
      await _open(tester, month, (p) => got = p);
      expect(tester.widget<PButton>(_done()).onPressed, isNotNull);
      await tester.tap(find.widgetWithText(PButton, '초기화'));
      await tester.pumpAndSettle();
      expect(tester.widget<PButton>(_done()).onPressed, isNull);
      await tester.tap(find.text('최근 7일'));
      await tester.pumpAndSettle();
      await tester.tap(_done());
      await tester.pumpAndSettle();
      expect(got!.seg, StatsSeg.custom);
      expect(got!.from, DateTime(2026, 10, 23));
      expect(got!.to, DateTime(2026, 10, 29));
    });

    testWidgets('완료 없이 닫으면 null — 고르던 것은 버린다', (tester) async {
      StatsPeriod? got = month;
      await _open(tester, month, (p) => got = p);
      await tester.tap(find.text('최근 7일'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(got, isNull);
    });
  });
}
