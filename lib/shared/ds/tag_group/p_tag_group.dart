import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/text/keep_all.dart';

/// 크기 — t2 12/16(기본) · t3 13/18 · t4 14/19.
enum PTagGroupSize { t2, t3, t4 }

/// 톤 — neutralSubtle(흐린 글자, 기본) · neutral(본문 글자 — 앞세울 항목) · brand(아껴 쓴다).
enum PTagTone { neutralSubtle, neutral, brand }

/// 굵기 — regular 400(기본) · bold 700(앞세울 항목 하나).
enum PTagWeight { regular, bold }

/// 넘칠 때 — wrap(낱말 단위로 줄을 바꾼다, 기본) · truncate(한 줄 — 항목마다 말줄임).
enum PTagGroupOverflow { wrap, truncate }

/// 항목 하나 — 글 + 아이콘 하나(앞 또는 뒤). 톤 · 굵기를 주지 않으면 묶음의 값.
class PTag {
  const PTag(
    this.label, {
    this.icon,
    this.iconAfter = false,
    this.tone,
    this.weight,
    this.shrink = 1,
    this.srLabel,
  });

  final String label;
  final IconData? icon;

  /// 아이콘을 글 뒤에(suffix).
  final bool iconAfter;
  final PTagTone? tone;
  final PTagWeight? weight;

  /// truncate 에서 줄어드는지 — 0 은 줄지 않는다(금액처럼 꼭 보일 항목). 앱은 0 · 0 아님 둘로 나눈다.
  final int shrink;

  /// 읽을 글 — 뜻이 있는 아이콘(갈래 = 분할 · 눈 = 조회)의 뜻("분할 2건"). 없으면 [label].
  final String? srLabel;
}

/// 크기마다의 글자 · 아이콘 크기(tag-group.yaml).
@visibleForTesting
({TextStyle style, double icon}) tagGroupMetrics(PTagGroupSize size) =>
    switch (size) {
      PTagGroupSize.t2 => (style: PTypography.t2, icon: 12),
      PTagGroupSize.t3 => (style: PTypography.t3, icon: 13),
      PTagGroupSize.t4 => (style: PTypography.t4, icon: 14),
    };

/// 구분 — 줄이 안 바뀌는 공백(U+00A0) · 가운뎃점(U+00B7) · 공백. 앞 항목에 붙어 줄 끝에 남는다.
const String tagGroupSeparator = ' · ';

/// Tag Group — 시간 · 개수 · 길이 같은 메타 정보를 " · " 로 잇는 묶음. 구조는 SEED Tag Group(2026-10-03), 수치 원본은
/// porest-design `specs/components/tag-group.yaml`(값은 `test/fixtures/design_spec/tag-group.json`). 웹(desk-front
/// `src/shared/ds/tag-group`)과 같은 값이다.
///
/// 누르지 않는다. 구분은 fg-disabled · 400 으로 글보다 한 단계 흐리다(장식). 기본은 낱말 단위 줄바꿈(이음 문자로 낱말
/// 안에서 끊지 않는다), truncate 는 한 줄 — 넘치면 항목 글이 각자 말줄임하고 구분은 줄지 않는다.
/// 묶음 하나의 의미 노드에 항목을 ", " 로 이어 읽는다("식비, 신한카드, 오후 2:10") — 구분 · 아이콘은 읽지 않는다.
class PTagGroup extends StatelessWidget {
  const PTagGroup({
    super.key,
    required this.items,
    this.size = PTagGroupSize.t2,
    this.tone = PTagTone.neutralSubtle,
    this.weight = PTagWeight.regular,
    this.overflow = PTagGroupOverflow.wrap,
  });

  final List<PTag> items;
  final PTagGroupSize size;
  final PTagTone tone;
  final PTagWeight weight;
  final PTagGroupOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = tagGroupMetrics(size);
    Color colorOf(PTagTone t) => switch (t) {
      PTagTone.neutralSubtle => c.fgNeutralSubtle,
      PTagTone.neutral => c.fgNeutral,
      PTagTone.brand => c.fgBrand,
    };
    TextStyle itemStyle(PTag item) => m.style.copyWith(
      color: colorOf(item.tone ?? tone),
      fontWeight: (item.weight ?? weight) == PTagWeight.bold
          ? FontWeight.w700
          : FontWeight.w400,
    );
    final separatorStyle = m.style.copyWith(
      color: c.fgDisabled,
      fontWeight: FontWeight.w400,
    );
    Widget icon(PTag item) =>
        Icon(item.icon, size: m.icon, color: itemStyle(item).color);

    final Widget body;
    if (overflow == PTagGroupOverflow.wrap) {
      body = Text.rich(
        TextSpan(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (items[i].icon != null && !items[i].iconAfter)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: PSpacing.x0_5),
                    child: icon(items[i]),
                  ),
                ),
              TextSpan(
                text: keepAll(items[i].label),
                style: itemStyle(items[i]),
              ),
              if (items[i].icon != null && items[i].iconAfter)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(left: PSpacing.x0_5),
                    child: icon(items[i]),
                  ),
                ),
              if (i < items.length - 1)
                TextSpan(text: tagGroupSeparator, style: separatorStyle),
            ],
          ],
        ),
        style: m.style,
      );
    } else {
      Widget itemWidget(PTag item) {
        final text = Text(
          item.label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: itemStyle(item),
        );
        final row = Row(
          mainAxisSize: MainAxisSize.min,
          spacing: PSpacing.x0_5,
          children: [
            if (item.icon != null && !item.iconAfter) icon(item),
            item.shrink == 0 ? text : Flexible(child: text),
            if (item.icon != null && item.iconAfter) icon(item),
          ],
        );
        return item.shrink == 0 ? row : Flexible(child: row);
      }

      body = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            itemWidget(items[i]),
            if (i < items.length - 1)
              Text(tagGroupSeparator, style: separatorStyle),
          ],
        ],
      );
    }

    return Semantics(
      container: true,
      label: items.map((i) => i.srLabel ?? i.label).join(', '),
      child: ExcludeSemantics(child: body),
    );
  }
}
