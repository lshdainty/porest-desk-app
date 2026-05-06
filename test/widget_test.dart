import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/app.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/auth/user.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/domain/asset_summary.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';

void main() {
  testWidgets('logged-in user lands on home shell', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_FakeAuth.new),
          // 테스트는 백엔드를 띄우지 않으므로 데이터 provider 를 빈 값으로 직접 채움
          categoriesProvider
              .overrideWith((_) => Future.value(<ExpenseCategory>[])),
          assetsProvider.overrideWith((_) => Future.value(<Asset>[])),
          assetSummaryProvider
              .overrideWith((_, _) => Future.value(const AssetSummary())),
          monthExpensesProvider
              .overrideWith((_, _) => Future.value(<Expense>[])),
        ],
        child: const PorestDeskApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('홈'), findsAtLeastNWidgets(1));
    expect(find.text('가계부'), findsAtLeastNWidgets(1));
    expect(find.text('통계'), findsOneWidget);
    expect(find.text('전체'), findsAtLeastNWidgets(1));
    // Dashboard hero
    expect(find.text('순자산'), findsOneWidget);
    expect(find.text('자산'), findsAtLeastNWidgets(1));
  });
}

class _FakeAuth extends AuthNotifier {
  @override
  Future<User?> build() async => const User(
        rowId: 1,
        userId: 'tester',
        userName: 'Tester',
        userEmail: 'tester@example.com',
      );
}
