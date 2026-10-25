// 이름 칸 판정 — 웹 `name-policy.ts` 와 같은 사례(필수 · 길이 · 중복, 자기 자신 뺀 비교 · 앞뒤 공백).
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/shared/forms/name_policy.dart';

void main() {
  test('비거나 공백뿐이면 required', () {
    expect(nameIssue('', 12), NameIssue.required);
    expect(nameIssue('   ', 12), NameIssue.required);
  });

  test('12자까지 통과 · 13자는 tooLong(앞뒤 공백은 안 센다)', () {
    expect(nameIssue('가' * 12, 12), isNull);
    expect(nameIssue('  ${'가' * 12}  ', 12), isNull);
    expect(nameIssue('가' * 13, 12), NameIssue.tooLong);
  });

  test('같은 이름은 duplicate · 앞뒤 공백 뗀 완전 일치만', () {
    expect(nameIssue('업무', 12, ['집안일', '업무']), NameIssue.duplicate);
    expect(nameIssue(' 업무 ', 12, ['업무']), NameIssue.duplicate);
    expect(nameIssue('업무 ', 12, ['업무 일']), isNull);
    expect(
      nameIssue('Work', 12, ['work']),
      isNull,
      reason: '대소문자는 거짓 차단을 피해 따로 보지 않는다',
    );
  });

  test('길이 판정이 중복 판정보다 먼저다', () {
    expect(nameIssue('가' * 13, 12, ['가' * 13]), NameIssue.tooLong);
  });
}
