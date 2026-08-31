import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/preset/domain/expense_template.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_detail.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';

/// 프리셋 상세 시트 — 행 탭 → 읽기 전용 상세 → footer 에서 삭제·수정.
///
/// 모바일 행에서 `✎`·`🗑` 를 걷어냈다. 탭이 그 자리를 대신하는 비제스처 경로다 —
/// 스와이프만 남기면 제스처 없이는 아무것도 못 한다(spec swipe-actions.md · WCAG 2.1.1).
///
/// 프리셋에는 예정일이 없다(`ExpenseTemplate` 은 useCount·lastUsedAt 만 갖는다).
/// 반복 거래 상세와 달리 "다음 예정일" 섹션이 없고 지금 저장된 내용만 보여준다.
void showPresetDetailSheet(
  BuildContext context, {
  required ExpenseTemplate template,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  final l = AppLocalizations.of(context);
  showPSheet<void>(
    context,
    title: l.presetDetailTitle,
    // 내용이 짧다 — 기본 0.85 를 쓰면 아래가 텅 빈 채로 뜬다.
    shrinkWrap: true,
    contentBuilder: (ctx, _) => _Body(template: template),
    footerBuilder: (ctx) => PViewFooter(
      onDelete: () {
        Navigator.of(ctx).pop();
        onDelete();
      },
      deleteLabel: l.actionDelete,
      onEdit: () {
        Navigator.of(ctx).pop();
        onEdit();
      },
      editLabel: l.actionEdit,
    ),
  );
}

class _Body extends ConsumerWidget {
  const _Body({required this.template});
  final ExpenseTemplate template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final isExpense = template.expenseType == 'EXPENSE';
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final cat = template.categoryRowId == null
        ? null
        : categories
              .where((c) => c.rowId == template.categoryRowId)
              .cast<dynamic>()
              .firstOrNull;
    final fg = resolveChartColor(context, cat?.color, fallback: t.fgBrand);
    final bg = softBg(context, fg);
    // 금액 고정이 아니면 쓸 때마다 입력한다 — 값이 없는 게 정상이다.
    final locked = template.lockAmount == 'Y';

    // shrinkWrap 시트라 ListView 가 아니라 Column 이다(showPSheet 문서).
    return Padding(
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PDetailHero(
            icon: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: PRadius.tile(32),
              ),
              child: Icon(
                lucideByName(cat?.icon ?? 'bookmark'),
                size: 16,
                color: fg,
              ),
            ),
            title: template.templateName,
            amount: Text(
              locked && template.amount != null
                  ? krwSigned(
                      template.amount!.abs(),
                      false,
                      sign: isExpense ? '-' : '+',
                      unit: true,
                    )
                  : l.presetAmountEmpty,
              style: PTypo.displayMd.copyWith(
                color: locked
                    ? (isExpense ? t.fgExpense : t.fgIncome)
                    : t.fgTertiary,
                fontWeight: PFontWeight.bold,
              ),
            ),
            meta:
                '${l.presetStatUses} ${l.presetUsesCount(template.useCount ?? 0)}',
          ),
          PDetailFieldGroup(
            children: [
              PDetailField(
                label: l.presetTypeLabel,
                child: Text(
                  isExpense ? l.expTypeExpense : l.expTypeIncome,
                  style: PTypo.bodySm,
                ),
              ),
              PDetailField(
                label: l.expCategory,
                child: Text(template.categoryName ?? '-', style: PTypo.bodySm),
              ),
              PDetailField(
                label: l.presetAssetCard,
                child: Text(template.assetName ?? '-', style: PTypo.bodySm),
              ),
              if (template.merchant?.isNotEmpty == true)
                PDetailField(
                  label: l.presetMerchant,
                  child: Text(template.merchant!, style: PTypo.bodySm),
                ),
              if (template.description?.isNotEmpty == true)
                PDetailField(
                  label: l.expDescription,
                  child: Text(template.description!, style: PTypo.bodySm),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
