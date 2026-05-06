import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/app.dart';

void main() {
  testWidgets('boots placeholder home', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PorestDeskApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Porest Desk'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Phase'), findsAtLeastNWidgets(1));
  });
}
