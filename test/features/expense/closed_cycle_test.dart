// 닫힌 회차 규칙(2026-09-21 확정)의 앱 화면 — 웹과 같은 판정·같은 문구다.
//
//   - 저장 전에 물어볼 회차: 그 회차 결제일이 이미 왔을 때만(닫힘·당일). 서버
//     `CardCycleMath` 와 같은 결제일 규칙이어야 한다 — 어긋나면 물어야 할 자리에서 안
//     묻거나(돈이 말없이 움직인다) 안 물어도 될 자리에서 묻는다.
//   - 확인창 문장: 미리보기를 사람 말로 — 기록만 남아요 / 추가로 빠져요 / 기록만 정리돼요.
//   - 목록 행 "기록만" 배지, 삭제·환불 확인창의 기한 지남 문장.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/core/settings/mask_flags.dart';
import 'package:porest_desk_app/features/expense/domain/card_cycle.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/domain/refund_preview.dart';
import 'package:porest_desk_app/features/expense/presentation/paid_refund_note.dart';
import 'package:porest_desk_app/features/expense/presentation/widgets/expense_row.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

Widget _host(Widget child) => MaterialApp(
  theme: PorestTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Scaffold(body: child),
);

const _expense = Expense(
  rowId: 1,
  categoryRowId: 11,
  categoryName: '식비',
  assetRowId: 9,
  assetName: '현대카드',
  expenseType: 'EXPENSE',
  amount: 25000,
  merchant: '가맹점',
  expenseDate: '2026-08-20T10:00:00',
);

void main() {
  group('카드 회차 결제일', () {
    test('거래 달의 다음 달 결제일이다', () {
      expect(cardCyclePaymentDate('2026-08-20', 12), '2026-09-12');
    });

    test('그 달에 없는 날이면 말일이다', () {
      expect(cardCyclePaymentDate('2027-01-10', 31), '2027-02-28');
    });

    test('12월 거래는 다음 해 1월에 결제된다', () {
      expect(cardCyclePaymentDate('2026-12-05', 12), '2027-01-12');
    });

    test('결제일이 지났거나 오늘이면 묻고, 전이면 묻지 않는다', () {
      expect(isCardCycleDue('2026-08-20', 12, '2026-09-14'), isTrue);
      expect(isCardCycleDue('2026-08-30', 12, '2026-09-12'), isTrue);
      expect(isCardCycleDue('2026-09-13', 12, '2026-09-14'), isFalse);
    });
  });

  group('저장 확인 문장', () {
    late AppLocalizations l;
    setUpAll(() async {
      l = await AppLocalizations.delegate.load(const Locale('ko'));
    });

    test('결제가 끝난 회차 — 기록만 남아요', () {
      final notes = saveConfirmNotes(
        l,
        const RefundPreview(newRecordAmount: 25000),
      );
      expect(notes, [l.expClosedCycleNote]);
    });

    test('결제일 당일 — 추가로 빠지는 금액', () {
      final notes = saveConfirmNotes(
        l,
        const RefundPreview(sameDayExtraPayment: 40000),
      );
      expect(notes.single, contains('40,000'));
    });

    test('결제한 달이 지난 수정 — 기록만 정리돼요', () {
      final notes = saveConfirmNotes(
        l,
        const RefundPreview(reason: 'REFUND_WINDOW_CLOSED'),
      );
      expect(notes, [l.expWindowClosedNote]);
    });

    test('환급만 있으면 종전 감액 문구 그대로', () {
      final notes = saveConfirmNotes(
        l,
        const RefundPreview(applies: true, refundAmount: 2000, reason: 'OK'),
      );
      expect(notes, [l.expPaidReduceNote('2,000')]);
    });

    test('할 말이 없으면 비어 있다 — 묻지 않고 저장한다', () {
      expect(saveConfirmNotes(l, const RefundPreview()), isEmpty);
    });
  });

  group('삭제·환불 확인창 안내 한 줄', () {
    testWidgets('결제한 달이 지났으면 기록만 정리된다고 말한다(R6)', (tester) async {
      await tester.pumpWidget(
        _host(
          PaidRefundNote(
            preview: Future.value(
              const RefundPreview(reason: 'REFUND_WINDOW_CLOSED'),
            ),
            cardHasPaymentAsset: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l = await AppLocalizations.delegate.load(const Locale('ko'));
      expect(find.text(l.expWindowClosedNote), findsOneWidget);
    });

    testWidgets('돌려줄 돈이 있으면 금액을 말한다', (tester) async {
      await tester.pumpWidget(
        _host(
          PaidRefundNote(
            preview: Future.value(
              const RefundPreview(
                applies: true,
                refundAmount: 25000,
                reason: 'RECORD_ONLY_OK',
              ),
            ),
            cardHasPaymentAsset: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('25,000'), findsOneWidget);
    });

    testWidgets('못 물어봤으면 금액 없는 문구로 넘어간다', (tester) async {
      // 위젯이 붙은 뒤에 실패시킨다 — 먼저 실패한 Future 는 받을 이가 없어 테스트가 깨진다.
      final pending = Completer<RefundPreview>();
      await tester.pumpWidget(
        _host(
          PaidRefundNote(preview: pending.future, cardHasPaymentAsset: true),
        ),
      );
      pending.completeError(Exception('timeout'));
      await tester.pumpAndSettle();
      final l = await AppLocalizations.delegate.load(const Locale('ko'));
      expect(find.text(l.expPaidDeleteFallback), findsOneWidget);
    });
  });

  group('목록 행 "기록만" 배지', () {
    Future<void> pumpRow(WidgetTester tester, Expense e) => tester.pumpWidget(
      _host(
        ExpenseRow(
          expense: e,
          category: null,
          flags: const MaskFlags.cardOnly(false),
          interactive: false,
        ),
      ),
    );

    testWidgets('표식이 있으면 단다', (tester) async {
      await pumpRow(
        tester,
        _expense.copyWith(cardSettledThrough: '2026-08-31'),
      );
      expect(find.text('기록만'), findsOneWidget);
    });

    testWidgets('정상 거래에는 없다', (tester) async {
      await pumpRow(tester, _expense);
      expect(find.text('기록만'), findsNothing);
    });

    testWidgets('환불된 거래는 환불됨만 — 합계에서 빠진 쪽이 먼저다', (tester) async {
      await pumpRow(
        tester,
        _expense.copyWith(
          cardSettledThrough: '2026-08-31',
          refundedAt: '2026-09-15T12:00:00',
        ),
      );
      expect(find.text('기록만'), findsNothing);
      expect(find.text('환불됨'), findsOneWidget);
    });
  });
}
