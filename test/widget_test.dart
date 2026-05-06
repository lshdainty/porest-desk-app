import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/app.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/auth/user.dart';

void main() {
  testWidgets('logged-in user lands on home shell', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_FakeAuth.new),
        ],
        child: const PorestDeskApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('홈'), findsAtLeastNWidgets(1));
    expect(find.text('가계부'), findsOneWidget);
    expect(find.text('통계'), findsOneWidget);
    expect(find.text('전체'), findsOneWidget);
    expect(find.text('홈 / Dashboard'), findsOneWidget);
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
