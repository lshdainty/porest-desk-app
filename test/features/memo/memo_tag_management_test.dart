// 메모 태그 관리 화면 — 앱만 쓰는 사람도 태그를 만들 수 있어야 한다.
//
// 서버엔 `POST/PUT/DELETE /memo-tag` 가 다 있는데 앱 리포지토리엔 목록 조회만
// 있었다. 그래서 **메모 편집기의 선택지를 늘릴 길이 웹에만 있었다** — 태그 목록의
// SoT 는 서버 마스터이고(QA #98) 앱은 그 마스터를 못 늘렸다.
//
// 화면은 할 일 태그 관리(`todo_tag_management_screen.dart`)를 그대로 미러링한다.
// 여기서 고정하는 것은 **화면이 리포지토리의 어느 메서드를 무슨 인자로 부르는지**다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/memo/application/memo_providers.dart';
import 'package:porest_desk_app/features/memo/data/memo_tag_repository.dart';
import 'package:porest_desk_app/features/memo/domain/memo_tag.dart';
import 'package:porest_desk_app/features/memo/presentation/memo_tag_management_screen.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';

MemoTag _tag(int rowId, String name, {String? color, int usage = 0}) => MemoTag(
  rowId: rowId,
  tagName: name,
  userRowId: 1,
  color: color,
  usageCount: usage,
);

class _CapturingRepo extends MemoTagRepository {
  _CapturingRepo() : super(Dio());

  String? createdName;
  String? createdColor;
  int? updatedId;
  String? updatedName;
  int? deletedId;

  @override
  Future<MemoTag> create({required String tagName, String? color}) async {
    createdName = tagName;
    createdColor = color;
    return _tag(99, tagName, color: color);
  }

  @override
  Future<MemoTag> update({
    required int id,
    required String tagName,
    String? color,
  }) async {
    updatedId = id;
    updatedName = tagName;
    return _tag(id, tagName, color: color);
  }

  @override
  Future<void> delete(int id) async {
    deletedId = id;
  }
}

Finder _field(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Finder _button(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

Future<_CapturingRepo> _open(
  WidgetTester tester, {
  List<MemoTag> tags = const [],
}) async {
  final repo = _CapturingRepo();
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        memoTagRepositoryProvider.overrideWith((ref) async => repo),
        memoTagListProvider.overrideWith((ref) async => tags),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const MemoTagManagementScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('태그 목록과 사용 건수를 그린다', (tester) async {
    await _open(tester, tags: [_tag(11, '회의록', usage: 3)]);

    expect(find.text('회의록'), findsOneWidget);
    expect(find.text(l.mtagUsage(3)), findsOneWidget);
  });

  testWidgets('태그가 없으면 빈 상태를 그린다', (tester) async {
    await _open(tester);

    expect(find.text(l.mtagEmpty), findsOneWidget);
  });

  testWidgets('새 태그를 만들면 create 가 불린다 — 앱만 써도 태그를 만들 수 있다', (tester) async {
    final repo = await _open(tester);

    await tester.tap(_button(l.memoNewTag));
    await tester.pumpAndSettle();
    await tester.enterText(_field(l.memoTagNamePlaceholder), '아이디어');
    await tester.pumpAndSettle();
    await tester.tap(_button(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.createdName, '아이디어');
    // 색은 화면이 늘 고른 값을 들고 있다 — 팔레트 기본값이라도 실려야 한다.
    expect(repo.createdColor, isNotNull);
  });

  testWidgets('행을 탭해 이름을 고치면 update 가 그 rowId 로 불린다', (tester) async {
    final repo = await _open(tester, tags: [_tag(11, '회의록')]);

    await tester.tap(find.text('회의록'));
    await tester.pumpAndSettle();
    await tester.enterText(_field(l.memoTagNamePlaceholder), '회의 기록');
    await tester.pumpAndSettle();
    await tester.tap(_button(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.updatedId, 11);
    expect(repo.updatedName, '회의 기록');
    expect(repo.createdName, isNull, reason: '수정인데 새로 만들면 태그가 둘로 늘어난다');
  });

  testWidgets('삭제 확인 문구가 사용 건수를 말한다', (tester) async {
    await _open(tester, tags: [_tag(11, '회의록', usage: 4)]);

    expect(
      l.memoDeleteTagConfirm('회의록', 4).contains('4'),
      isTrue,
      reason: '건수를 못 넣으면 몇 개가 태그 없음으로 남는지 알 수 없다',
    );
    // 문구가 약속하는 결과 — 서버도 그렇게 동작한다(`MemoTagServiceImpl.deleteTag`).
    expect(l.memoDeleteTagConfirm('회의록', 4).contains('태그 없음'), isTrue);
  });
}
