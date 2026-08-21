// PEmptyState 가 부모 정렬과 무관하게 가로 가운데에 서는지.
//
// 관리 화면들은 본문을 Column(crossAxisAlignment: start) 로 쌓는다. 그 안에서 빈 상태가
// 자기 내용 폭만큼만 차지하면 왼쪽에 붙는다 — 캘린더 라벨은 안내 문구가 길어 폭을 거의
// 채우는 바람에 가운데처럼 보였을 뿐이고, 할일 태그처럼 문구가 짧으면 그대로 드러난다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/shared/widgets/p_empty_state.dart';

const _boxWidth = 390.0;

Future<double> _iconCenterX(WidgetTester tester, {String? sub}) async {
  await tester.pumpWidget(MaterialApp(
    theme: PorestTheme.light(),
    home: Scaffold(
      body: SizedBox(
        width: _boxWidth,
        // 실제 관리 화면과 같은 배치 — 헤더 행 + 빈 상태를 start 로 쌓는다.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20, width: _boxWidth),
            PEmptyState(icon: LucideIcons.tag, message: '태그가 없어요', subMessage: sub),
          ],
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return tester.getCenter(find.byIcon(LucideIcons.tag)).dx;
}

void main() {
  testWidgets('문구가 짧아도 아이콘이 가로 가운데', (tester) async {
    expect(await _iconCenterX(tester), closeTo(_boxWidth / 2, 0.5));
  });

  testWidgets('보조 문구가 길어도 가운데는 그대로', (tester) async {
    expect(
      await _iconCenterX(tester, sub: '위 "태그 추가" 버튼으로 만들어보세요'),
      closeTo(_boxWidth / 2, 0.5),
    );
  });
}
