import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// 그려진 글의 줄이 바뀐 자리 — 줄 끝 바로 앞 글자(공백 · 줄바꿈 제외)가 낱말 안이면 낱말 중간에서 끊긴 것이다.
/// [finder] 가 가리키는 Text 하나를 읽는다. 낱말 단위 줄바꿈(v114 keepAll)이 지켜졌는지 보는 데 쓴다.
List<String> midWordBreaks(WidgetTester tester, Finder finder) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: finder, matching: find.byType(RichText)).first,
  );
  final text = paragraph.text.toPlainText();
  // 줄이 바뀌는 자리 — 캐럿의 세로 위치가 아래로 내려가는 첫 글자
  final ends = <int>[];
  double? lastY;
  for (var i = 0; i < text.length; i++) {
    final y = paragraph
        .getOffsetForCaret(TextPosition(offset: i), Rect.zero)
        .dy;
    if (lastY != null && y > lastY + 1) ends.add(i);
    lastY = y;
  }
  final bad = <String>[];
  for (final end in ends) {
    final before = text[end - 1];
    final after = text[end];
    // 줄이 공백 뒤(또는 앞)에서 바뀌면 낱말 사이다
    if (before == ' ' || before == '\n' || after == ' ') continue;
    bad.add(
      '${text.substring(end - 2 < 0 ? 0 : end - 2, end)}|${text.substring(end, end + 2 > text.length ? text.length : end + 2)}',
    );
  }
  return bad;
}
