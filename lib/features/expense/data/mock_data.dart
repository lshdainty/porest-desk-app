import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../domain/expense.dart';

/// porest-desk-front `data.ts` 의 11종 카테고리 매핑.
const mockCategories = <Category>[
  Category(id: 'food', name: '식비', icon: LucideIcons.utensils,
      color: Color(0xFFC65D57), bg: Color(0xFFFFEAE8)),
  Category(id: 'cafe', name: '카페·간식', icon: LucideIcons.coffee,
      color: Color(0xFF856854), bg: Color(0xFFF7ECE0)),
  Category(id: 'transport', name: '교통', icon: LucideIcons.car,
      color: Color(0xFF58A3C5), bg: Color(0xFFE7F6FF)),
  Category(id: 'shopping', name: '쇼핑', icon: LucideIcons.shoppingBag,
      color: Color(0xFFAE927A), bg: Color(0xFFFCF7F1)),
  Category(id: 'living', name: '생활', icon: LucideIcons.home,
      color: Color(0xFF6B6C43), bg: Color(0xFFF6F7EC)),
  Category(id: 'medical', name: '의료', icon: LucideIcons.cross,
      color: Color(0xFFC65D57), bg: Color(0xFFFFEAE8)),
  Category(id: 'leisure', name: '여가', icon: LucideIcons.gamepad,
      color: Color(0xFFD1A550), bg: Color(0xFFFEF3DE)),
  Category(id: 'bill', name: '공과금', icon: LucideIcons.fileText,
      color: Color(0xFF58A3C5), bg: Color(0xFFE7F6FF)),
  Category(id: 'edu', name: '교육', icon: LucideIcons.book,
      color: Color(0xFF96B66D), bg: Color(0xFFE9F7E3)),
  Category(id: 'saving', name: '저축', icon: LucideIcons.piggyBank,
      color: Color(0xFF96B66D), bg: Color(0xFFE9F7E3)),
  Category(id: 'income', name: '수입', icon: LucideIcons.trendingUp,
      color: Color(0xFF6B6C43), bg: Color(0xFFF6F7EC)),
];

const mockAssets = <Asset>[
  Asset(id: 'cash', name: '현금', type: 'cash', balance: 120000),
  Asset(id: 'shinhan', name: '신한 더모아', type: 'card'),
  Asset(id: 'samsung', name: '삼성 iD GLOBAL', type: 'card'),
  Asset(id: 'kakaobank', name: '카카오뱅크 통장', type: 'account', balance: 4_320_000),
  Asset(id: 'hana', name: '하나 적금', type: 'account', balance: 12_000_000),
  Asset(id: 'kospi', name: 'KODEX 200', type: 'investment', balance: 5_400_000),
];

/// 이번 달 더미 거래 6일치, 16개 — 화면 검증용.
List<Expense> mockExpensesForCurrentMonth() {
  final now = DateTime.now();
  String d(int day) =>
      '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  // 가능한 일자 (이번 달 길이를 넘지 않도록 클램프)
  int last = DateTime(now.year, now.month + 1, 0).day;
  int day(int x) => x.clamp(1, last);

  return [
    Expense(id: 'e1', date: d(day(1)), amount: 8500, type: TxType.expense,
        categoryId: 'food', assetId: 'shinhan', merchant: '김밥천국', description: '점심'),
    Expense(id: 'e2', date: d(day(1)), amount: 4500, type: TxType.expense,
        categoryId: 'cafe', assetId: 'shinhan', merchant: '스타벅스'),
    Expense(id: 'e3', date: d(day(2)), amount: 1450, type: TxType.expense,
        categoryId: 'transport', assetId: 'cash', merchant: '서울 버스'),
    Expense(id: 'e4', date: d(day(2)), amount: 32000, type: TxType.expense,
        categoryId: 'food', assetId: 'samsung', merchant: '백반집', description: '저녁 회식'),
    Expense(id: 'e5', date: d(day(5)), amount: 2_900_000, type: TxType.income,
        categoryId: 'income', assetId: 'kakaobank', description: '월급'),
    Expense(id: 'e6', date: d(day(5)), amount: 200000, type: TxType.transfer,
        categoryId: 'saving', assetId: 'hana', description: '적금 이체'),
    Expense(id: 'e7', date: d(day(8)), amount: 15800, type: TxType.expense,
        categoryId: 'shopping', assetId: 'samsung', merchant: '올리브영'),
    Expense(id: 'e8', date: d(day(8)), amount: 4500, type: TxType.expense,
        categoryId: 'cafe', assetId: 'shinhan', merchant: '투썸'),
    Expense(id: 'e9', date: d(day(8)), amount: 12000, type: TxType.expense,
        categoryId: 'leisure', assetId: 'samsung', merchant: 'CGV', description: '영화'),
    Expense(id: 'e10', date: d(day(12)), amount: 65000, type: TxType.expense,
        categoryId: 'living', assetId: 'kakaobank', merchant: '쿠팡', description: '생활용품'),
    Expense(id: 'e11', date: d(day(12)), amount: 18000, type: TxType.expense,
        categoryId: 'food', assetId: 'shinhan', merchant: '맥도날드'),
    Expense(id: 'e12', date: d(day(15)), amount: 89000, type: TxType.expense,
        categoryId: 'bill', assetId: 'kakaobank', merchant: 'KT', description: '통신비'),
    Expense(id: 'e13', date: d(day(15)), amount: 12500, type: TxType.expense,
        categoryId: 'food', assetId: 'cash', merchant: '편의점'),
    Expense(id: 'e14', date: d(day(20)), amount: 3500, type: TxType.expense,
        categoryId: 'transport', assetId: 'cash'),
    Expense(id: 'e15', date: d(day(20)), amount: 28000, type: TxType.expense,
        categoryId: 'medical', assetId: 'samsung', merchant: '약국'),
    Expense(id: 'e16', date: d(day(22)), amount: 7800, type: TxType.expense,
        categoryId: 'cafe', assetId: 'shinhan', merchant: '스타벅스', description: '아이스 아메리카노'),
  ];
}
