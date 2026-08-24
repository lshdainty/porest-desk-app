import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/features/memo/domain/memo.dart';
import 'package:porest_desk_app/features/memo/domain/memo_colors.dart';
import 'package:porest_desk_app/features/memo/presentation/memo_actions.dart';
import 'package:porest_desk_app/features/memo/presentation/memo_edit_dialog.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';

/// 메모 상세 시트 — 카드 탭 → 읽기 전용 상세 → 수정 버튼 → 편집 폼.
/// tx_detail_dialog(웹 MemoDetailDialog) 패턴 미러: 톤 hero + 본문 전문 + 뷰 footer.
void showMemoDetailDialog(BuildContext context, Memo memo) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: l.memoDetailTitle,
    contentBuilder: (ctx, scrollCtrl) => _DetailBody(
      memo: memo,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => _DetailFooter(memo: memo, controller: controller),
  ).whenComplete(controller.dispose);
}

class _DetailFooter extends StatelessWidget {
  const _DetailFooter({required this.memo, required this.controller});
  final Memo memo;
  final PSheetController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) {
        final busy = controller.submitting;
        return PViewFooter(
          onDelete: controller.onDelete,
          deleting: busy,
          onEdit: busy
              ? null
              : () {
                  Navigator.of(ctx).pop();
                  showMemoEditDialog(ctx, edit: memo);
                },
        );
      },
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({
    required this.memo,
    required this.scrollController,
    required this.controller,
  });
  final Memo memo;
  final ScrollController scrollController;
  final PSheetController controller;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  @override
  void initState() {
    super.initState();
    widget.controller.onDelete = _delete;
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final ok = await showPConfirmDialog(
      context,
      title: memoActions.deleteConfirmTitle(context, widget.memo),
      message: memoActions.deleteConfirmMessage(context, widget.memo),
      confirmLabel: l.actionDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    widget.controller.setSubmitting(true);
    try {
      // 삭제는 memoActions 가 한다 — 목록 행(스와이프)도 같은 것을 부른다.
      final deleted = await memoActions.delete(context, ref, widget.memo);
      if (deleted && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) widget.controller.setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final memo = widget.memo;
    final bg = memoCardBg(context, memo.color);
    final tagFg = memoTagFg(context, memo.color);
    final swatch = memoSwatch(context, memo.color);
    final hasTitle = (memo.title ?? '').isNotEmpty;
    final tag = (memo.tag ?? '').isNotEmpty ? memo.tag! : '개인';
    final content = (memo.content ?? '').trim();

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
      children: [
        // Hero — 메모 카드와 동일 톤
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: PRadius.brXl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: swatch,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tag,
                      style: PTypo.micro.copyWith(
                        color: tagFg,
                        fontWeight: PFontWeight.semi,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (memo.pinned) ...[
                    Icon(LucideIcons.pin, size: 12, color: swatch),
                    const SizedBox(width: 4),
                    Text(
                      l.memoDetailPinned,
                      style: PTypo.micro.copyWith(
                        color: tagFg,
                        fontWeight: PFontWeight.semi,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                hasTitle ? memo.title! : l.memoUntitled,
                style: PTypo.h4.copyWith(
                  color: hasTitle ? t.fgPrimary : t.fgTertiary,
                  fontWeight: PFontWeight.bold,
                  height: 1.3,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                monthDayTime(memo.modifyAt),
                style: PTypo.micro.copyWith(color: t.fgTertiary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // 본문 전문
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(PSpace.x16),
          decoration: BoxDecoration(
            color: t.bgSurface,
            border: Border.all(color: t.borderSubtle),
            borderRadius: PRadius.brLg,
          ),
          child: Text(
            content.isEmpty ? l.memoDetailNoContent : content,
            style: PTypo.bodySm.copyWith(
              color: content.isEmpty ? t.fgTertiary : t.fgPrimary,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}
