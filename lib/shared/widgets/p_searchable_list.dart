import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/shared/widgets/p_search_field.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';

/// specs/components/searchable-list.md 미러.
///
/// 상단 검색 input + 하단 결과 list. 카드 카탈로그/은행/증권사 등 **대량 옵션
/// + 검색 필요** 시나리오. row = thumbnail + 주제목/부제목 + 옵션 우측.
/// active row = `bgBrandSubtle` + 주제목 강조.
class PSearchableListItem<T> {
  const PSearchableListItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.thumbnail,
    this.trailing,
    this.disabled = false,
  });

  final T value;
  final String title;
  final String? subtitle;

  /// 좌측 thumbnail — 호출처가 색 swatch/이미지/avatar 결정.
  final Widget? thumbnail;

  /// 우측 옵션 (badge/상태).
  final Widget? trailing;

  final bool disabled;
}

enum PSearchableListSize { sm, md, lg }

class PSearchableList<T> extends StatefulWidget {
  const PSearchableList({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.filter,
    this.searchPlaceholder = '검색',
    this.size = PSearchableListSize.md,
    this.maxHeight,
    this.loading = false,
    this.emptyText = '검색 결과가 없어요',
    this.autoFocus = false,
  });

  final List<PSearchableListItem<T>> items;
  final T? value;
  final ValueChanged<T> onChanged;

  /// (item, query) → matches. 호출처가 어떤 필드를 검색할지 결정.
  final bool Function(PSearchableListItem<T> item, String query) filter;

  final String searchPlaceholder;
  final PSearchableListSize size;

  /// 결과 컨테이너 max-height. 미지정 시 size별 기본값(200/260/320).
  final double? maxHeight;

  final bool loading;
  final String emptyText;
  final bool autoFocus;

  @override
  State<PSearchableList<T>> createState() => _PSearchableListState<T>();
}

class _PSearchableListState<T> extends State<PSearchableList<T>> {
  final _ctrl = TextEditingController();
  String _query = '';

  (double padX, double padY, double thumbW, double thumbH, double gap, double maxH)
      get _metrics => switch (widget.size) {
            PSearchableListSize.sm => (12, 8, 32, 20, 10, 200),
            PSearchableListSize.md => (12, 10, 44, 28, 12, 260),
            PSearchableListSize.lg => (16, 14, 56, 36, 14, 320),
          };

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (padX, padY, thumbW, thumbH, gap, defaultMaxH) = _metrics;
    final maxH = widget.maxHeight ?? defaultMaxH;
    final filtered = _query.isEmpty
        ? widget.items
        : widget.items.where((i) => widget.filter(i, _query)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PSearchField(
          hint: widget.searchPlaceholder,
          controller: _ctrl,
          autofocus: widget.autoFocus,
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: BoxConstraints(maxHeight: maxH),
          decoration: BoxDecoration(
            color: t.bgSurface,
            borderRadius: PRadius.brMd,
            border: Border.all(color: t.borderSubtle),
          ),
          child: ClipRRect(
            borderRadius: PRadius.brMd,
            child: widget.loading
                ? _loadingSkeleton(thumbW, thumbH, padX, padY, gap)
                : (filtered.isEmpty
                    ? _empty(t)
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: filtered.length,
                        separatorBuilder: (context, idx) => Divider(
                            height: 1, thickness: 1, color: t.borderSubtle),
                        itemBuilder: (context, idx) =>
                            _row(filtered[idx], padX, padY, thumbW, thumbH, gap),
                      )),
          ),
        ),
      ],
    );
  }

  Widget _row(
    PSearchableListItem<T> item,
    double padX,
    double padY,
    double thumbW,
    double thumbH,
    double gap,
  ) {
    final t = context.tokens;
    final selected = item.value == widget.value;
    return Material(
      color: selected ? t.bgBrandSubtle : Colors.transparent,
      child: InkWell(
        onTap: item.disabled ? null : () => widget.onChanged(item.value),
        child: Opacity(
          opacity: item.disabled ? 0.7 : 1,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padX, vertical: padY),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (item.thumbnail != null) ...[
                  SizedBox(
                    width: thumbW,
                    height: thumbH,
                    child: ClipRRect(
                      borderRadius: PRadius.brSm,
                      child: item.thumbnail,
                    ),
                  ),
                  SizedBox(width: gap),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: PFontSize.bodySm,
                          fontWeight: selected
                              ? PFontWeight.semi
                              : PFontWeight.medium,
                          color: selected ? t.fgBrandStrong : t.fgPrimary,
                        ),
                      ),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: PTypo.sans,
                            fontSize: PFontSize.micro,
                            fontWeight: PFontWeight.regular,
                            color: t.fgTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (item.trailing != null) ...[
                  const SizedBox(width: 8),
                  item.trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(PorestTokens t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            widget.emptyText,
            style: TextStyle(
              fontFamily: PTypo.sans,
              fontSize: PFontSize.caption,
              color: t.fgTertiary,
            ),
          ),
        ),
      );

  Widget _loadingSkeleton(
      double thumbW, double thumbH, double padX, double padY, double gap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: padX, vertical: padY),
          child: Row(
            children: [
              PSkeleton(width: thumbW, height: thumbH),
              SizedBox(width: gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PSkeleton.line(width: 160, height: 14),
                    const SizedBox(height: 4),
                    PSkeleton.line(width: 100, height: 11),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
