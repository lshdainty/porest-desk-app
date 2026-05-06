import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/app.dart';

void main() {
  testWidgets('boots mobile shell with home tab selected', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PorestDeskApp()),
    );
    await tester.pumpAndSettle();

    // 헤더 타이틀 + 탭 라벨 양쪽에 '홈'
    expect(find.text('홈'), findsAtLeastNWidgets(1));
    // 5칸 탭바: 홈/가계부/통계/전체 라벨 + 중앙 FAB
    expect(find.text('가계부'), findsOneWidget);
    expect(find.text('통계'), findsOneWidget);
    expect(find.text('전체'), findsOneWidget);
    // Dashboard 본문이 보이는지
    expect(find.text('홈 / Dashboard'), findsOneWidget);
  });
}
