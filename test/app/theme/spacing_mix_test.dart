import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 옛 `PSpace.xN`(N px)과 새 `PSpacing.xN`(N × 4 px)은 이름이 같고 값이 다르다 —
/// 한 파일에 둘이 섞이면 `x4` 가 4px 인지 16px 인지 글만 봐서는 모른다(01A-022 B).
/// 화면 파일은 치환 스크립트로 파일 단위 한꺼번에 옮기므로 섞인 파일이 새로 생기면 안 된다.
///
/// 아래 [_alreadyMixed] 는 이 테스트를 넣기 전에 이미 섞여 있던 파일이다(I-01 이 카드 · 띠 틀을
/// 새 이름으로 짜면서 생겼다). 화면 이관 때 파일을 통째로 옮기며 목록에서 뺀다. 더 늘리지 않는다.
const _alreadyMixed = <String>{
  'lib/features/stocks/presentation/stocks_screen.dart',
};

final _old = RegExp(r'\bPSpace\.');
final _new = RegExp(r'\bPSpacing\.');

Set<String> _mixedFiles() {
  final mixed = <String>{};
  for (final dir in ['lib', 'test']) {
    for (final e in Directory(dir).listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      // 이 파일은 두 이름을 글로 적는다
      if (e.path.endsWith('spacing_mix_test.dart')) continue;
      final text = e.readAsStringSync();
      if (_old.hasMatch(text) && _new.hasMatch(text)) mixed.add(e.path);
    }
  }
  return mixed;
}

void main() {
  test('한 파일에 PSpace. 와 PSpacing. 이 함께 있지 않다 — 기존 파일 말고는', () {
    final fresh = _mixedFiles().difference(_alreadyMixed);
    expect(
      fresh,
      isEmpty,
      reason:
          '옛 PSpace(px)와 새 PSpacing(×4px)이 한 파일에 섞였다. 파일 단위로 치환 스크립트를 돌려 한쪽으로 모은다 '
          '(대응표: DESIGN.desk.md 간격 절).\n${fresh.join('\n')}',
    );
  });

  test('목록의 파일은 아직 섞여 있다 — 옮겼으면 목록에서 뺀다', () {
    final stale = _alreadyMixed.difference(_mixedFiles());
    expect(
      stale,
      isEmpty,
      reason:
          '더는 섞이지 않은 파일이 _alreadyMixed 에 남아 있다. 목록에서 뺀다.\n${stale.join('\n')}',
    );
  });
}
