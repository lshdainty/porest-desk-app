import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_names.dart';

/// 생성물(tool/gen_lucide_icons.py) 정합 — 피커가 보여주는 모든 이름이 실제로
/// 렌더 가능해야 한다(fallback(tag)로 새면 웹에서 고른 아이콘이 앱에서 안 보임).
void main() {
  test('kLucideIconNames 전부가 fallback 없이 매핑된다', () {
    const fallback = LucideIcons.tag;
    final unmapped = <String>[];
    for (final name in kLucideIconNames) {
      final icon = lucideByName(name, fallback: fallback);
      if (icon == fallback && name != 'tag') unmapped.add(name);
    }
    expect(unmapped, isEmpty, reason: '매핑 누락: ${unmapped.take(20)}');
  });

  test('웹 카테고리에서 쓰는 kebab 이름이 해석된다', () {
    const webNames = [
      'utensils',
      'coffee',
      'bus',
      'shopping-bag',
      'home',
      'heart-pulse',
      'ticket',
      'receipt-text',
      'book-open',
      'piggy-bank',
      'arrow-down-to-line',
      'hand-coins',
      'paw-print',
      'building-2',
      'trending-up',
    ];
    for (final n in webNames) {
      expect(
        lucideByName(n),
        isNot(LucideIcons.tag),
        reason: '$n 이 fallback 으로 샘',
      );
    }
  });

  test('알 수 없는 이름·빈 값은 fallback', () {
    expect(lucideByName('definitely-not-an-icon'), LucideIcons.tag);
    expect(lucideByName(null), LucideIcons.tag);
    expect(lucideByName(''), LucideIcons.tag);
  });
}
