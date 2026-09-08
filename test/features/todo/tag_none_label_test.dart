// '태그 없음' 표기 — 할 일·메모가 **같은 규칙을 같은 모양으로** 쓴다(QA #103).
//
// 종전엔 태그가 없는 항목을 '개인' 이라 그렸다. 서버는 태그를 지울 때 그 항목의
// 태그 문자열을 실제로 비우므로(`TodoTagServiceImpl.deleteTag` ·
// `MemoTagServiceImpl.deleteTag`), 화면이 이름을 지어내면 삭제 확인창이 약속한
// "태그 없음으로 남아요" 와 어긋난다 — '개인' 태그를 지운 사용자가 여전히 '개인'
// 을 본다. 웹은 10차에 sentinel 로 통일했고(`todo-tags.ts` · `memo-tags.ts`)
// 앱 메모 편집기는 9차에 따라갔다. 이 파일이 나머지를 그 자리에 고정한다.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/features/memo/domain/memo.dart';
import 'package:porest_desk_app/features/memo/domain/memo_meta.dart';
import 'package:porest_desk_app/features/todo/domain/todo_meta.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

void main() {
  late AppLocalizations ko;
  late AppLocalizations en;
  setUpAll(() async {
    ko = await AppLocalizations.delegate.load(const Locale('ko'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('묶음 키', () {
    test('태그가 없으면 sentinel — 이름을 지어내지 않는다', () {
      expect(todoTagKey(null), kTodoNoTagKey);
      expect(todoTagKey(''), kTodoNoTagKey);
      expect(todoTagKey('   '), kTodoNoTagKey);
      expect(memoTagKey(const Memo(rowId: 1)), kMemoNoTagKey);
      expect(memoTagKey(const Memo(rowId: 1, tag: '')), kMemoNoTagKey);
    });

    test('태그가 있으면 그 이름 그대로', () {
      expect(todoTagKey('업무'), '업무');
      expect(memoTagKey(const Memo(rowId: 1, tag: '회의록')), '회의록');
    });

    test('sentinel 은 두 화면이 같은 값이고, 사용자가 칠 수 없는 글자다', () {
      // 웹 `todo-tags.test.ts` 가 고정하는 것과 같은 불변식이다.
      expect(kTodoNoTagKey, kMemoNoTagKey);
      expect(kTodoNoTagKey, '\u{FFFF}');
      // trim 으로 사라지지 않는다 — 사라지면 빈 이름과 구분이 안 된다.
      expect(kTodoNoTagKey.trim(), kTodoNoTagKey);
    });
  });

  group('화면 라벨', () {
    test('sentinel 은 문구로 바뀐다 — U+FFFF 가 그대로 나가면 안 된다', () {
      expect(todoTagLabel(ko, kTodoNoTagKey), '태그 없음');
      expect(memoTagLabel(ko, kMemoNoTagKey), '태그 없음');
      expect(todoTagLabel(en, kTodoNoTagKey), 'No tag');
      expect(memoTagLabel(en, kMemoNoTagKey), 'No tag');
    });

    test('두 화면이 같은 말을 쓴다', () {
      expect(todoTagLabel(ko, kTodoNoTagKey), memoTagLabel(ko, kMemoNoTagKey));
      expect(todoTagLabel(en, kTodoNoTagKey), memoTagLabel(en, kMemoNoTagKey));
    });

    test('태그 이름은 그대로 통과한다', () {
      expect(todoTagLabel(ko, '업무'), '업무');
      expect(memoTagLabel(ko, '회의록'), '회의록');
    });

    test("태그 없는 항목을 '개인' 이라 부르지 않는다", () {
      // 이 한 줄이 QA #103 의 증상 그 자체다.
      expect(todoTagLabel(ko, todoTagKey(null)), isNot('개인'));
      expect(memoTagLabel(ko, memoTagKey(const Memo(rowId: 1))), isNot('개인'));
    });
  });
}
