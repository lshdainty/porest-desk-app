// 할 일 편집 시트 — 태그 표기(QA #103·#105) + 하위 할 일의 부모.
//
// ① 태그 없는 할 일을 '개인' 이라 부르지 않는다. 종전엔 편집기가 빈 `category` 를
//    '개인' 으로 채워 열었고, 제목만 고쳐 저장해도 그 이름이 실려 **서버가 '개인'
//    태그를 새로 만들었다**(`TodoServiceImpl.resolveCategoryTag`). 삭제 확인창은
//    "태그 없음으로 남아요" 라고 약속해 놓고 화면이 그 말을 어긴 상태였다.
// ② '태그 없음' 선택지가 없어 **한 번 붙은 태그를 앱에서 뗄 수 없었다.** 뗄 수
//    있으려면 키를 빼지 말고 명시적 null 을 실어야 한다(PUT 은 "키 없음=유지").
//
// 에뮬레이터를 쓸 수 없는 환경이라(QA #23) 저장 페이로드를 위젯 테스트로 고정한다.
// 리포지토리 단위 검증은 `test/features/put_clear_payload_test.dart` 에 있고,
// 여기서는 **화면이 실제로 그 값을 넘기는지**를 본다. 메모 편집기 테스트
// (`test/features/memo/memo_edit_dialog_test.dart`)와 같은 모양이다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/core/network/patch.dart';
import 'package:porest_desk_app/features/todo/application/todo_providers.dart';
import 'package:porest_desk_app/features/todo/data/todo_repository.dart';
import 'package:porest_desk_app/features/todo/domain/todo.dart';
import 'package:porest_desk_app/features/todo/domain/todo_tag.dart';
import 'package:porest_desk_app/features/todo/presentation/todo_edit_dialog.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';

const _todo = Todo(rowId: 7, title: 'QA 할 일', category: '개인');
const _untagged = Todo(rowId: 8, title: '태그 없는 할 일');

TodoTag _tag(int rowId, String name) =>
    TodoTag(rowId: rowId, tagName: name, userRowId: 1);

/// update·create 로 넘어간 인자를 잡는 가짜 레포지토리.
class _CapturingRepo extends TodoRepository {
  _CapturingRepo() : super(Dio());

  Patch<String> category = const Patch.keep();
  String? title;
  bool created = false;
  String? createdCategory;

  @override
  Future<Todo> update({
    required int id,
    required String title,
    Patch<String> content = const Patch.keep(),
    String? priority,
    Patch<String> category = const Patch.keep(),
    Patch<String> dueDate = const Patch.keep(),
  }) async {
    this.title = title;
    this.category = category;
    return _todo;
  }

  @override
  Future<Todo> create({
    required String title,
    String? content,
    String? priority,
    String? category,
    String? dueDate,
    String? type,
  }) async {
    created = true;
    createdCategory = category;
    return _todo;
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
  Todo? edit = _todo,
  List<TodoTag> tags = const [],
  bool tagsFail = false,
  List<Todo> subtasks = const [],
}) async {
  final repo = _CapturingRepo();
  // 시트 본문이 세로로 길다 — 좁은 화면에서는 아래 칸이 아예 안 만들어진다.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        todoRepositoryProvider.overrideWith((ref) async => repo),
        todoTagListProvider.overrideWith(
          (ref) async => tagsFail ? throw Exception('할 일 태그 조회 실패') : tags,
        ),
        todoSubtasksProvider.overrideWith((ref, id) async => subtasks),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showTodoEditDialog(ctx, edit: edit),
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

  group('태그 표기 (QA #103)', () {
    testWidgets('선택지가 서버 목록에서 온다 — 하드코딩 기본 태그는 없다', (tester) async {
      await _openEdit(
        tester,
        edit: _untagged,
        tags: [_tag(11, '업무'), _tag(12, '집안일')],
      );
      await _openTagSelect(tester);

      expect(find.text('업무'), findsOneWidget);
      expect(find.text('집안일'), findsOneWidget);
      // 이 계정에 없는 이름 — 뜨면 앱이 이름을 지어낸 것이다.
      expect(find.text('개인'), findsNothing);
    });

    testWidgets('서버에 없는 지금 태그도 남는다 — 편집하다 태그를 잃지 않는다', (tester) async {
      // 할 일은 '개인' 을 들고 있는데 계정 태그는 '업무' 뿐 (백필 전 옛 행).
      await _openEdit(tester, tags: [_tag(11, '업무')]);
      await _openTagSelect(tester);

      expect(find.text('개인'), findsWidgets);
      expect(find.text('업무'), findsOneWidget);
    });

    testWidgets('태그가 0개여도 select 가 비지 않는다', (tester) async {
      await _openEdit(tester, edit: _untagged);
      await _openTagSelect(tester);

      expect(find.text(l.todoTagNone), findsWidgets);
    });

    testWidgets('조회가 실패해도 죽지 않고 지금 태그를 지킨다', (tester) async {
      final repo = await _openEdit(tester, tagsFail: true);
      expect(tester.takeException(), isNull);

      await _openTagSelect(tester);
      expect(find.text('개인'), findsWidgets);

      // 닫고 그대로 저장 — 조회 실패가 태그를 지우면 안 된다.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      await tester.tap(_submitButton(l.actionEdit));
      await tester.pumpAndSettle();

      expect(repo.category.present, isTrue);
      expect(repo.category.value, '개인');
    });

    testWidgets('"태그 없음" 을 고르면 category 가 명시적 null 로 실린다', (tester) async {
      final repo = await _openEdit(tester, tags: [_tag(11, '업무')]);
      await _openTagSelect(tester);

      await tester.tap(find.text(l.todoTagNone).last);
      await tester.pumpAndSettle();
      await tester.tap(_submitButton(l.actionEdit));
      await tester.pumpAndSettle();

      expect(
        repo.category.present,
        isTrue,
        reason: 'category 키가 빠지면 서버가 옛 태그를 지킨다 — 앱에서 태그를 못 뗀다',
      );
      expect(repo.category.value, isNull);
    });

    testWidgets('태그 없는 할 일을 그대로 저장해도 이름이 지어지지 않는다', (tester) async {
      // 옛 코드는 빈 category 를 '개인' 으로 채워 저장했다 — 서버가 그 이름의
      // 태그를 새로 만드는 경로다(QA #105).
      final repo = await _openEdit(
        tester,
        edit: _untagged,
        tags: [_tag(11, '업무')],
      );
      await tester.tap(_submitButton(l.actionEdit));
      await tester.pumpAndSettle();

      expect(repo.category.present, isTrue);
      expect(repo.category.value, isNull);
    });

    testWidgets('새 할 일의 기본값도 태그 없음이다', (tester) async {
      final repo = await _openEdit(tester, edit: null, tags: [_tag(11, '업무')]);

      await tester.enterText(_field(l.todoTitlePlaceholder), '새 할 일');
      await tester.pumpAndSettle();
      await tester.tap(_submitButton(l.calAdd));
      await tester.pumpAndSettle();

      expect(repo.created, isTrue);
      expect(repo.createdCategory, isNull);
    });
  });
}
