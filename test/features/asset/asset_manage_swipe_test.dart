// 계좌·카드 관리 행의 스와이프 — 셰브론을 지우고 트레이를 붙였다.
//
// 눈으로 확인하기 어려운 조합이라 테스트로 고정한다. 특히 <b>안 일어나야 하는 일</b>:
// 삭제를 눌러도 확인 없이는 지워지지 않는다. 스와이프는 삭제까지의 거리를 줄이므로
// 줄인 만큼을 확인 단계로 되돌려 두지 않으면 밀다가 자산이 사라진다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/presentation/account_card_manage_screen.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

const _account = Asset(
  rowId: 8,
  assetName: '주거래 통장',
  assetType: 'BANK_ACCOUNT',
  balance: 1200000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
);

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async => [_account]),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        // 트레이 자동 닫힘은 앱 루트(app.dart)가 쥔다 — 테스트도 같은 조상을 준다.
        home: const SlidableAutoCloseBehavior(
          child: AccountCardManageScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 트레이가 열릴 만큼 왼쪽으로 민다.
Future<void> _swipeOpen(WidgetTester tester) async {
  await tester.drag(find.text('주거래 통장'), const Offset(-250, 0));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('행 우측 셰브론이 없다', (tester) async {
    await _pump(tester);
    expect(find.text('주거래 통장'), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
  });

  testWidgets('밀면 수정·삭제가 드러난다', (tester) async {
    await _pump(tester);

    // 접혀 있을 땐 안 보인다.
    expect(find.text('수정'), findsNothing);
    expect(find.text('삭제'), findsNothing);

    await _swipeOpen(tester);

    expect(find.text('수정'), findsOneWidget);
    expect(find.text('삭제'), findsOneWidget);
  });

  testWidgets('삭제는 확인을 거친다 — 누른다고 바로 지워지지 않는다', (tester) async {
    await _pump(tester);
    await _swipeOpen(tester);

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    // 확인 다이얼로그가 떴을 뿐 아직 아무것도 지워지지 않았다.
    // (repository 를 주지 않았으므로 실제로 호출됐다면 여기서 터진다)
    expect(find.text('이 계좌를 삭제하시겠습니까? 연결된 거래는 유지됩니다.'),
        findsOneWidget);
  });

  testWidgets('끝까지 밀어도 실행되지 않는다 — 트레이만 열린다', (tester) async {
    await _pump(tester);

    await tester.drag(find.text('주거래 통장'), const Offset(-2000, 0));
    await tester.pumpAndSettle();

    // 확인 다이얼로그가 뜨지 않았다 = 삭제가 실행되지 않았다.
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('주거래 통장'), findsOneWidget);
  });
}
