import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/fixed_groups.dart';

var _seq = 0;
Expense tx({
  String? merchant,
  String? description,
  String? categoryName = '주거',
  String type = 'EXPENSE',
  int amount = 1000,
  bool isFixed = false,
  String? refundedAt,
}) => Expense(
  rowId: ++_seq,
  expenseType: type,
  amount: amount,
  merchant: merchant,
  description: description,
  categoryName: categoryName,
  expenseDate: '2020-01-05T09:00:00',
  isFixed: isFixed,
  refundedAt: refundedAt,
);

void main() {
  group('groupForFixed — 같은 이름의 거래를 한 묶음으로', () {
    test('거래처가 같으면 대소문자·공백이 달라도 한 묶음이다', () {
      final g = groupForFixed(
        [
          tx(merchant: '집주인', amount: 700000),
          tx(merchant: ' 집주인 ', amount: 700000),
          tx(merchant: '스타벅스', amount: 5000),
        ],
        'EXPENSE',
        '기타',
      );
      expect(g, hasLength(2));
      expect(g[0].name, '집주인');
      expect(g[0].count, 2);
      expect(g[0].total, 1400000);
    });

    test('이름은 거래처 → 메모 → 카테고리 → 대체 이름 순이다 — 행에 보이는 것과 같다', () {
      final g = groupForFixed(
        [
          tx(merchant: 'A', description: '메모', categoryName: '카테'),
          tx(description: '메모', categoryName: '카테'),
          tx(categoryName: '카테'),
          tx(categoryName: null),
        ],
        'EXPENSE',
        '기타',
      );
      expect(g.map((x) => x.name).toList()..sort(), ['A', '기타', '메모', '카테']);
    });

    test('지출과 수입을 섞지 않는다', () {
      final rows = [
        tx(merchant: '회사', type: 'INCOME', amount: 3000000),
        tx(merchant: '회사', amount: 10),
      ];
      expect(groupForFixed(rows, 'INCOME', '기타').first.total, 3000000);
      expect(groupForFixed(rows, 'EXPENSE', '기타').first.total, 10);
    });

    test('합계에 안 잡히는 환불된 거래는 뺀다', () {
      final g = groupForFixed(
        [
          tx(merchant: '집주인'),
          tx(merchant: '집주인', refundedAt: '2020-01-06T09:00:00'),
        ],
        'EXPENSE',
        '기타',
      );
      expect(g.first.count, 1);
    });

    test('이미 고정인 거래 수를 센다', () {
      final g = groupForFixed(
        [
          tx(merchant: '집주인', isFixed: true),
          tx(merchant: '집주인'),
          tx(merchant: '집주인'),
        ],
        'EXPENSE',
        '기타',
      );
      expect(g.first.count, 3);
      expect(g.first.fixedCount, 1);
    });

    test('건수 많은 순, 같으면 합계 큰 순으로 정렬한다', () {
      final g = groupForFixed(
        [
          tx(merchant: '한번', amount: 9000000),
          tx(merchant: '두번', amount: 1),
          tx(merchant: '두번', amount: 1),
          tx(merchant: '큰한번', amount: 9999999),
        ],
        'EXPENSE',
        '기타',
      );
      expect(g.map((x) => x.name), ['두번', '큰한번', '한번']);
    });
  });

  group('묶음 선택', () {
    final g = groupForFixed(
      [tx(merchant: 'A'), tx(merchant: 'A'), tx(merchant: 'A')],
      'EXPENSE',
      '기타',
    ).first;

    test('고른 것이 없으면 false, 전부면 true, 일부면 null(체크박스의 세 모양)', () {
      expect(groupCheck(g, {}), false);
      expect(groupCheck(g, {g.ids.first}), isNull);
      expect(groupCheck(g, g.ids.toSet()), true);
    });

    test('묶음을 켜면 안의 거래가 전부 들어가고, 끄면 전부 빠진다 — 다른 묶음은 그대로', () {
      const other = 99999;
      final on = toggleGroup(g, {other}, true);
      expect(on, {...g.ids, other});
      expect(toggleGroup(g, on, false), {other});
    });

    test('원래 집합을 바꾸지 않는다', () {
      final base = <int>{};
      toggleGroup(g, base, true);
      expect(base, isEmpty);
    });
  });
}
