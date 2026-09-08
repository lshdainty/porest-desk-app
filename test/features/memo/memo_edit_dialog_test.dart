// 메모 본문을 지우고 저장하면 **지워진다** (QA 2026-09-08 #99).
//
// QA 재현: 앱 → 메모 열기 → 본문 지우고 저장 → 다시 열면 본문이 그대로. 원인은
// 앱이 null 인 칸을 키째 뺀 것이다 — 서버가 2026-09-07 부터 "키 없음=유지" 로 읽기
// 시작하면서(desk-back #321) 종전에 우연히 지워지던 것이 지워지지 않게 됐다.
//
// 에뮬레이터를 쓸 수 없는 환경이라(QA #23) 저장 페이로드를 위젯 테스트로 고정한다.
// 리포지토리 단위 검증은 `test/features/put_clear_payload_test.dart` 에 있고,
// 여기서는 **화면이 실제로 그 값을 넘기는지**를 본다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/core/network/patch.dart';
import 'package:porest_desk_app/features/memo/application/memo_providers.dart';
import 'package:porest_desk_app/features/memo/data/memo_repository.dart';
import 'package:porest_desk_app/features/memo/domain/memo.dart';
import 'package:porest_desk_app/features/memo/presentation/memo_edit_dialog.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';

const _memo = Memo(
  rowId: 3,
  title: 'QA 메모',
  content: '지워질 본문',
  tag: '개인',
  color: '#2c70bf',
  isPinned: 'N',
);

/// update 로 넘어간 인자를 잡는 가짜 레포지토리.
class _CapturingRepo extends MemoRepository {
  _CapturingRepo() : super(Dio());

  Patch<String> content = const Patch.keep();
  String? title;

  @override
  Future<Memo> update({
    required int id,
    String? title,
    Patch<String> content = const Patch.keep(),
    String? tag,
    String? color,
  }) async {
    this.title = title;
    this.content = content;
    return _memo;
  }
}

Finder _field(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Finder _submitButton(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

Future<_CapturingRepo> _openEdit(WidgetTester tester) async {
  final repo = _CapturingRepo();
  // 시트 본문은 ListView 다 — 좁은 화면에서는 본문 칸이 아예 안 만들어진다.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [memoRepositoryProvider.overrideWith((ref) async => repo)],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showMemoEditDialog(ctx, edit: _memo),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('본문을 지우고 저장하면 content 가 명시적 null 로 실린다', (tester) async {
    final repo = await _openEdit(tester);
    expect(find.text('지워질 본문'), findsOneWidget);

    await tester.enterText(_field(l.memoContentPlaceholder), '');
    await tester.pumpAndSettle();
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(
      repo.content.present,
      isTrue,
      reason: 'content 키가 빠지면 서버가 옛 본문을 지킨다 — QA #99 의 그 증상이다',
    );
    expect(repo.content.value, isNull);
  });

  testWidgets('본문을 고쳐 저장하면 고친 값이 실린다', (tester) async {
    final repo = await _openEdit(tester);

    await tester.enterText(_field(l.memoContentPlaceholder), '새 본문');
    await tester.pumpAndSettle();
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.content.present, isTrue);
    expect(repo.content.value, '새 본문');
  });

  testWidgets('제목은 비울 수 없다 — 저장이 인라인 에러로 막힌다', (tester) async {
    final repo = await _openEdit(tester);

    await tester.enterText(_field(l.memoFieldTitle), '');
    await tester.pumpAndSettle();
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(find.text(l.memoTitleRequired), findsOneWidget);
    expect(repo.title, isNull, reason: '저장 자체가 안 나가야 한다');
  });
}
