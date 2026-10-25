import 'dart:math' as math;

import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 크기 — t2 12/16(기본) · t3 13/18 · t4 14/19.
enum PTagGroupSize { t2, t3, t4 }

/// 톤 — neutralSubtle(흐린 글자, 기본) · neutral(본문 글자 — 앞세울 항목) · brand(아껴 쓴다).
/// `disabled` — 끝낸 줄 안의 설명(`fg-disabled`). 막힌 줄 안의 Tag Group 규칙(tag-group.md "비활성")을 줄이 막히지 않은 끝낸 할 일에도 쓴다.
enum PTagTone { neutralSubtle, neutral, brand, disabled }

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

  /// truncate 에서 줄어드는 정도 — 0 은 줄지 않는다(금액처럼 꼭 보일 항목), 1 이상은 넘친 폭을 '글 폭 × shrink'
  /// 비율로 나눠 함께 준다(CSS flex-shrink 와 같다).
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
/// groo-design `specs/components/tag-group.yaml`(값은 `test/fixtures/design_spec/tag-group.json`). 웹(desk-front
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
      PTagTone.disabled => c.fgDisabled,
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
      body = _TruncateRow(
        items: items,
        style: m.style,
        iconSize: m.icon,
        separatorStyle: separatorStyle,
        itemStyle: itemStyle,
        iconColor: (item) => itemStyle(item).color!,
      );
    }

    return Semantics(
      container: true,
      label: items.map((i) => i.srLabel ?? i.label).join(', '),
      child: ExcludeSemantics(child: body),
    );
  }
}

/// 줄어드는 항목의 글 칸 최소 폭 배율 — 첫 글자 + "…" 가 남는 2.1em(글자 크기 · 글자 설정을 따른다).
@visibleForTesting
const double kTagGroupLabelMinEm = 2.1;

/// 글자(자소 군집) 수 — 두 글자 이하 항목은 최소 폭을 두지 않는다(글 폭 그대로).
int _graphemeCount(String text) => text.trim().characters.length;

/// truncate — 한 줄. 넘친 폭을 줄어드는 항목에 '글 폭 × shrink' 비율로 나눠 함께 줄인다(차례대로가 아니다). 줄어드는 항목도
/// 첫 글자 + "…" 까지만 준다(최소 폭 = 2.1em + 아이콘 + 사이 2, 두 글자 이하는 글 폭 그대로). 모든 항목이 최소 폭까지 줄어도
/// 넘치면 줄 끝이 말줄임 없이 잘린다. 구분은 줄지 않는다. 폭이 모자라지 않으면 글만큼이다.
class _TruncateRow extends StatelessWidget {
  const _TruncateRow({
    required this.items,
    required this.style,
    required this.iconSize,
    required this.separatorStyle,
    required this.itemStyle,
    required this.iconColor,
  });

  final List<PTag> items;
  final TextStyle style;
  final double iconSize;
  final TextStyle separatorStyle;
  final TextStyle Function(PTag) itemStyle;
  final Color Function(PTag) iconColor;

  double _textWidth(BuildContext context, String text, TextStyle s) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: s),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final w = painter.width;
    painter.dispose();
    // 소수 폭에 걸려 "…" 가 붙지 않게 올림한다
    return w.ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final scaler = MediaQuery.textScalerOf(context);
        final separator = _textWidth(
          context,
          tagGroupSeparator,
          separatorStyle,
        );
        final base = <double>[];
        final min = <double>[];
        for (final item in items) {
          final text = _textWidth(context, item.label, itemStyle(item));
          final icon = item.icon != null ? iconSize + PSpacing.x0_5 : 0.0;
          final natural = text + icon;
          base.add(natural);
          final shrinkable = item.shrink > 0 && _graphemeCount(item.label) > 2;
          final floor =
              scaler.scale(style.fontSize!) * kTagGroupLabelMinEm + icon;
          min.add(shrinkable ? math.min(natural, floor) : natural);
        }
        final separators = separator * (items.length - 1);
        final natural = base.fold<double>(0, (a, b) => a + b) + separators;
        var widths = [...base];
        var clipped = false;
        if (box.maxWidth.isFinite && natural > box.maxWidth + 0.001) {
          widths = _shrink(base, min, box.maxWidth - separators);
          final total = widths.fold<double>(0, (a, b) => a + b) + separators;
          clipped = total > box.maxWidth + 0.001;
        }
        final row = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _item(items[i], widths[i]),
              if (i < items.length - 1)
                Text(tagGroupSeparator, softWrap: false, style: separatorStyle),
            ],
          ],
        );
        if (!clipped) return row;
        return ClipRect(
          child: OverflowBox(
            alignment: AlignmentDirectional.centerStart,
            minWidth: 0,
            maxWidth: widths.fold<double>(0, (a, b) => a + b) + separators,
            fit: OverflowBoxFit.deferToChild,
            child: row,
          ),
        );
      },
    );
  }

  /// CSS flex-shrink — 넘친 폭을 줄어드는 항목에 (글 폭 × shrink) 비율로 나눈다. 최소 폭에 닿은 항목은 거기서 멈추고 나머지가
  /// 다시 나눈다.
  List<double> _shrink(List<double> base, List<double> min, double available) {
    final result = [...base];
    final frozen = List<bool>.generate(
      base.length,
      (i) => items[i].shrink <= 0 || min[i] >= base[i],
    );
    while (true) {
      final used = result.fold<double>(0, (a, b) => a + b);
      final over = used - available;
      if (over <= 0.001) break;
      var weight = 0.0;
      for (var i = 0; i < base.length; i++) {
        if (!frozen[i]) weight += items[i].shrink * base[i];
      }
      if (weight == 0) break;
      var hit = false;
      for (var i = 0; i < base.length; i++) {
        if (frozen[i]) continue;
        final target = result[i] - over * items[i].shrink * base[i] / weight;
        if (target < min[i]) {
          result[i] = min[i];
          frozen[i] = true;
          hit = true;
        } else {
          result[i] = target;
        }
      }
      if (!hit) break;
    }
    return result;
  }

  Widget _item(PTag item, double width) {
    final text = Text(
      item.label,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: itemStyle(item),
    );
    Widget icon() => Icon(item.icon, size: iconSize, color: iconColor(item));
    return SizedBox(
      width: width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: PSpacing.x0_5,
        children: [
          if (item.icon != null && !item.iconAfter) icon(),
          Flexible(child: text),
          if (item.icon != null && item.iconAfter) icon(),
        ],
      ),
    );
  }
}
