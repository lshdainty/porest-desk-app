// 메모 편집 시트 — 본문 비우기(QA #99) + 태그 선택지 출처(QA #98).
//
// ① 본문을 지우고 저장하면 **지워진다**. 원인은 앱이 null 인 칸을 키째 뺀 것이다 —
//    서버가 2026-09-07 부터 "키 없음=유지" 로 읽기 시작하면서(desk-back #321)
//    종전에 우연히 지워지던 것이 지워지지 않게 됐다.
// ② 태그 선택지는 **서버 마스터 목록**에서 온다(desk-back #323). 종전엔 앱이 7종을
//    하드코딩해 계정에 없는 태그를 골라 저장했고, 그러면 서버가 그 이름의 마스터를
//    새로 만들어 사용자가 지운 태그가 되살아난다(QA #88).
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
import 'package:porest_desk_app/features/memo/domain/memo_tag.dart';
import 'package:porest_desk_app/features/memo/presentation/memo_edit_dialog.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';

const _memo = Memo(
  rowId: 3,
  title: 'QA 메모',
  content: '지워질 본문',
  tag: '개인',
  color: '#2c70bf',
  isPinned: 'N',
);

const _untagged = Memo(rowId: 4, title: '태그 없는 메모', isPinned: 'N');

MemoTag _tag(int rowId, String name) =>
    MemoTag(rowId: rowId, tagName: name, userRowId: 1);

/// update 로 넘어간 인자를 잡는 가짜 레포지토리.
class _CapturingRepo extends MemoRepository {
  _CapturingRepo() : super(Dio());

  Patch<String> content = const Patch.keep();
  Patch<String> tag = const Patch.keep();
  String? title;
  bool created = false;
  String? createdTag;

  @override
  Future<Memo> update({
    required int id,
    String? title,
    Patch<String> content = const Patch.keep(),
    Patch<String> tag = const Patch.keep(),
    String? color,
  }) async {
    this.title = title;
    this.content = content;
    this.tag = tag;
    return _memo;
  }

  @override
  Future<Memo> create({
    String? title,
    String? content,
    String? tag,
    String? color,
  }) async {
    created = true;
    createdTag = tag;
    return _memo;
  }
}

Finder _field(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Finder _submitButton(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

/// 태그 select 를 펼친다 — 항목은 OverlayPortal 안에 뜬다.
Future<void> _openTagSelect(WidgetTester tester) async {
  await tester.tap(find.byType(PSelect<String?>));
  await tester.pumpAndSettle();
}

Future<_CapturingRepo> _openEdit(
  WidgetTester tester, {
  Memo? edit = _memo,
  List<MemoTag> tags = const [],
  bool tagsFail = false,
}) async {
  final repo = _CapturingRepo();
  // 시트 본문은 ListView 다 — 좁은 화면에서는 본문 칸이 아예 안 만들어진다.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        memoRepositoryProvider.overrideWith((ref) async => repo),
        memoTagListProvider.overrideWith(
          (ref) async => tagsFail ? throw Exception('메모 태그 조회 실패') : tags,
        ),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showMemoEditDialog(ctx, edit: edit),
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

  group('태그 선택지 (QA #98)', () {
    testWidgets('선택지가 서버 목록에서 온다 — 하드코딩 7종은 없다', (tester) async {
      await _openEdit(tester, tags: [_tag(11, '업무'), _tag(12, '회의록')]);
      await _openTagSelect(tester);

      expect(find.text('업무'), findsOneWidget);
      expect(find.text('회의록'), findsOneWidget);
      // 옛 kMemoTags 에만 있고 이 계정에는 없는 이름 — 뜨면 서버 목록이 아니다.
      expect(find.text('가계부'), findsNothing);
      expect(find.text('고정비'), findsNothing);
    });

    testWidgets('서버에 없는 지금 태그도 남는다 — 편집하다 태그를 잃지 않는다', (tester) async {
      // 메모는 '개인' 을 들고 있는데 계정 태그는 '회의록' 뿐 (백필 전 옛 메모).
      await _openEdit(tester, tags: [_tag(11, '회의록')]);
      await _openTagSelect(tester);

      expect(find.text('개인'), findsWidgets);
      expect(find.text('회의록'), findsOneWidget);
    });

    testWidgets('태그가 0개여도 select 가 비지 않는다', (tester) async {
      await _openEdit(tester, edit: _untagged);
      await _openTagSelect(tester);

      // 항목이 "태그 없음" 하나뿐이어도 메뉴는 뜬다 — 빈 목록이면 select 가
      // 아무것도 못 그려 화면이 막힌다.
      expect(find.text(l.memoTagNone), findsWidgets);
    });

    testWidgets('조회가 실패해도 죽지 않고 지금 태그를 지킨다', (tester) async {
      final repo = await _openEdit(tester, tagsFail: true);
      expect(tester.takeException(), isNull);

      await _openTagSelect(tester);
      expect(find.text('개인'), findsWidgets);

      // 닫고 그대로 저장 — 조회 실패가 태그를 지우면 안 된다.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();

      expect(repo.tag.present, isTrue);
      expect(repo.tag.value, '개인');
    });

    testWidgets('"태그 없음" 을 고르면 tag 가 명시적 null 로 실린다', (tester) async {
      final repo = await _openEdit(tester, tags: [_tag(11, '업무')]);
      await _openTagSelect(tester);

      await tester.tap(find.text(l.memoTagNone).last);
      await tester.pumpAndSettle();
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();

      expect(
        repo.tag.present,
        isTrue,
        reason: 'tag 키가 빠지면 서버가 지금 이름으로 태그를 다시 이어 준다',
      );
      expect(repo.tag.value, isNull);
    });

    testWidgets('태그 없는 메모를 그대로 저장해도 이름이 지어지지 않는다', (tester) async {
      // 옛 코드는 빈 태그를 '개인' 으로 채워 저장했다 — 사용자가 지운 태그가
      // 서버에서 그 이름으로 되살아나는 경로다(QA #88).
      final repo = await _openEdit(
        tester,
        edit: _untagged,
        tags: [_tag(11, '업무')],
      );
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();

      expect(repo.tag.present, isTrue);
      expect(repo.tag.value, isNull);
    });

    testWidgets('새 메모의 기본값도 태그 없음이다', (tester) async {
      final repo = await _openEdit(tester, edit: null, tags: [_tag(11, '업무')]);

      await tester.enterText(_field(l.memoFieldTitle), '새 메모');
      await tester.pumpAndSettle();
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();

      expect(repo.created, isTrue);
      expect(repo.createdTag, isNull);
    });
  });
}
