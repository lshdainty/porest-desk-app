// 지시서 88 — 알림 작은 아이콘 = 한 색(흰) 나무 실루엣 벡터 drawable.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'logo_paths.dart';

void main() {
  const res = 'android/app/src/main/res';
  final xml = File('$res/drawable/ic_stat_groo.xml').readAsStringSync();

  test('24dp 벡터 · path 네 개는 svg 그대로 · 한 색(흰)', () {
    expect(xml, contains('android:width="24dp"'));
    expect(xml, contains('android:height="24dp"'));
    final paths = readVectorPaths(xml);
    expect(paths.map((p) => p.$2).toList(), grooTreePaths.values.toList());
    expect(paths.map((p) => p.$1).toSet(), {'#FFFFFF'});
  });

  test('실루엣이 24dp 안에 들어간다(변환을 적용한 모서리)', () {
    final s = double.parse(
      RegExp(r'scaleX="([\d.]+)"').firstMatch(xml)!.group(1)!,
    );
    final tx = double.parse(
      RegExp(r'translateX="(-?[\d.]+)"').firstMatch(xml)!.group(1)!,
    );
    final ty = double.parse(
      RegExp(r'translateY="(-?[\d.]+)"').firstMatch(xml)!.group(1)!,
    );
    // 나무 bbox(svg 좌표): x 163~284 중 잎 끝 147~301 보기 상자, y 183~349
    final x0 = tx + s * 147, x1 = tx + s * 301;
    final y0 = ty + s * 183, y1 = ty + s * 349;
    expect(x0, greaterThanOrEqualTo(0));
    expect(x1, lessThanOrEqualTo(24));
    expect(y0, closeTo(0, 0.01));
    expect(y1, closeTo(24, 0.01));
  });

  test('알림 초기화가 새 drawable 이름을 쓴다', () {
    final dart = File(
      'lib/core/update/update_notification.dart',
    ).readAsStringSync();
    expect(
      dart,
      contains("AndroidInitializationSettings('@drawable/ic_stat_groo')"),
    );
    expect(dart, isNot(contains("'@mipmap/ic_launcher'")));
    final kt = File(
      'android/app/src/main/kotlin/com/porest/desk/porest_desk_app/PaymentNotificationListener.kt',
    ).readAsStringSync();
    expect(kt, contains('setSmallIcon(R.drawable.ic_stat_groo)'));
    expect(kt, isNot(contains('ic_menu_edit')));
  });

  test('알림 채널 · 작업 이름은 그대로다', () {
    final dart = File(
      'lib/core/update/update_notification.dart',
    ).readAsStringSync();
    expect(dart, contains('porest_update'));
  });
}
