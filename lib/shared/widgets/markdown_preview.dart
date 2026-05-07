import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// 가벼운 마크다운 라이크 미리보기 — 외부 패키지 없이 line-based 처리.
///
/// 지원:
/// - `# H1` / `## H2` / `### H3`
/// - `- item` / `* item` / `- [ ] item` / `- [x] item` (체크리스트)
/// - `> quote`
/// - 인라인 `**bold**` / `*italic*` / `` `code` ``
/// - 빈 줄은 단락 구분
class MarkdownPreview extends StatelessWidget {
  const MarkdownPreview(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (text.trim().isEmpty) return const SizedBox.shrink();
    final lines = text.split('\n');
    final children = <Widget>[];
    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }
      // Headings
      if (line.startsWith('# ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: Text(line.substring(2),
              style: PTypo.h3.copyWith(color: t.fgPrimary)),
        ));
        continue;
      }
      if (line.startsWith('## ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: Text(line.substring(3),
              style: PTypo.h4.copyWith(color: t.fgPrimary)),
        ));
        continue;
      }
      if (line.startsWith('### ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: Text(line.substring(4),
              style: PTypo.body
                  .copyWith(color: t.fgPrimary, fontWeight: PFontWeight.bold)),
        ));
        continue;
      }
      // Quote
      if (line.startsWith('> ')) {
        children.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          decoration: BoxDecoration(
            border: Border(
                left: BorderSide(color: t.borderBrand, width: 3)),
            color: t.bgMuted,
          ),
          child: _inline(line.substring(2), tokens: t, italic: true),
        ));
        continue;
      }
      // Checklist
      final checked = RegExp(r'^[-*]\s\[(x|X|\s)\]\s(.+)$').firstMatch(line);
      if (checked != null) {
        final isDone = checked.group(1)!.toLowerCase() == 'x';
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  isDone ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 14,
                  color: isDone ? t.statusSuccess : t.fgTertiary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _inline(checked.group(2)!,
                    tokens: t,
                    decoration:
                        isDone ? TextDecoration.lineThrough : null),
              ),
            ],
          ),
        ));
        continue;
      }
      // Bullet list
      if (line.startsWith('- ') || line.startsWith('* ')) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 6),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                      color: t.fgTertiary, shape: BoxShape.circle),
                ),
              ),
              Expanded(child: _inline(line.substring(2), tokens: t)),
            ],
          ),
        ));
        continue;
      }
      // Plain paragraph
      children.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: _inline(line, tokens: t),
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _inline(
    String s, {
    required PorestTokens tokens,
    bool italic = false,
    TextDecoration? decoration,
  }) {
    final spans = <InlineSpan>[];
    final base = PTypo.bodySm.copyWith(
      color: tokens.fgPrimary,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      decoration: decoration,
    );
    // 매우 단순한 토큰 파서: ** ** / * * / ` `
    var i = 0;
    while (i < s.length) {
      // bold
      if (s.startsWith('**', i)) {
        final end = s.indexOf('**', i + 2);
        if (end != -1) {
          spans.add(TextSpan(
              text: s.substring(i + 2, end),
              style: base.copyWith(fontWeight: PFontWeight.bold)));
          i = end + 2;
          continue;
        }
      }
      // code
      if (s[i] == '`') {
        final end = s.indexOf('`', i + 1);
        if (end != -1) {
          spans.add(TextSpan(
              text: s.substring(i + 1, end),
              style: base.copyWith(
                fontFamily: 'JetBrainsMono',
                fontSize: PFontSize.caption,
                background: Paint()..color = tokens.bgMuted,
              )));
          i = end + 1;
          continue;
        }
      }
      // italic (single *)
      if (s[i] == '*' && (i + 1 < s.length && s[i + 1] != '*')) {
        final end = s.indexOf('*', i + 1);
        if (end != -1) {
          spans.add(TextSpan(
              text: s.substring(i + 1, end),
              style: base.copyWith(fontStyle: FontStyle.italic)));
          i = end + 1;
          continue;
        }
      }
      // plain run until next special
      var end = i;
      while (end < s.length) {
        final ch = s[end];
        if (ch == '*' || ch == '`') break;
        end++;
      }
      if (end > i) {
        spans.add(TextSpan(text: s.substring(i, end), style: base));
        i = end;
      } else {
        spans.add(TextSpan(text: s[i], style: base));
        i++;
      }
    }
    return RichText(text: TextSpan(children: spans));
  }
}
