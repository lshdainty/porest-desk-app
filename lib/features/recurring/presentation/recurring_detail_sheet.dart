import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/format/format_locale.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/recurring/domain/recurring_transaction.dart';
import 'package:porest_desk_app/features/recurring/presentation/recurring_screen.dart';
import 'package:porest_desk_app/features/recurring/presentation/recurring_settings_drawer.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_detail.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';

/// 반복 거래 상세 시트 — 행 탭 → 읽기 전용 상세 → footer 에서 삭제·수정.
///
/// 목록 행의 `⋮` 메뉴를 대신한다. 메뉴는 액션만 주고 무엇이 예정돼 있는지는 못 보여줬다.
/// 여기서는 **다음 예정일**을 추가 시트와 같은 계산(`previewNextDates`)으로 미리 보여준다 —
/// 둘이 갈라지면 "추가할 때 본 날짜"와 "상세에서 보는 날짜"가 달라진다.
void showRecurringDetailSheet(
  BuildContext context, {
  required RecurringTransaction item,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  final l = AppLocalizations.of(context);
  showPSheet<void>(
    context,
    title: l.navRecurring,
    // 내용이 짧다 — 0.85 기본을 쓰면 아래가 텅 빈 채로 뜬다. content 높이로 접는다.
    shrinkWrap: true,
    contentBuilder: (ctx, _) => _Body(item: item),
    footerBuilder: (ctx) => _Footer(
      onEdit: () {
        Navigator.of(ctx).pop();
        onEdit();
      },
      onDelete: () {
        Navigator.of(ctx).pop();
        onDelete();
      },
    ),
  );
}

class _Body extends ConsumerWidget {
  const _Body({required this.item});
  final RecurringTransaction item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final isExpense = item.expenseType == 'EXPENSE';
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final cat = categories
        .where((c) => c.rowId == item.categoryRowId)
        .cast<dynamic>()
        .firstOrNull;
    final fg = resolveChartColor(context, cat?.color, fallback: t.fgBrand);
    final bg = softBg(context, fg);

    // 다음 예정일 — 서버가 준 nextExecutionDate 부터 센다. 그게 없으면(종료됐거나
    // 아직 계산 전) 미리보기를 그리지 않는다. 오늘부터 세면 서버와 어긋난다.
    final base = item.nextExecutionDate == null
        ? null
        : DateTime.tryParse(item.nextExecutionDate!);
    final nextDates = base == null
        ? const <DateTime>[]
        : previewNextDates(
            base,
            item.frequency,
            // 모델 dayOfWeek 는 Mon=1..Sun=7, previewNextDates 는 Sun=0..Sat=6.
            (item.dayOfWeek ?? 1) % 7,
            item.dayOfMonth ?? base.day,
            3,
          );

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
            decoration:
                BoxDecoration(color: bg, borderRadius: PRadius.tile(32)),
            child: Icon(lucideByName(cat?.icon), size: 16, color: fg),
          ),
          title: recurringDisplayTitle(l, item),
          amount: Text(
            krwSigned(item.amount.abs(), false,
                sign: isExpense ? '-' : '+', unit: true),
            style: PTypo.displayMd.copyWith(
              color: isExpense ? t.fgExpense : t.fgIncome,
              fontWeight: PFontWeight.bold,
            ),
          ),
          meta: recurringSummaryText(l, item),
        ),
        PDetailFieldGroup(
          children: [
            PDetailField(
              label: l.expCategory,
              child: Text(item.categoryName ?? '-', style: PTypo.bodySm),
            ),
            PDetailField(
              label: l.recurringAssetCard,
              child: Text(item.assetName ?? l.recurringNoAccount,
                  style: PTypo.bodySm),
            ),
            if (item.maxOccurrences != null)
              PDetailField(
                label: l.recurringByCount,
                child: Text(
                    l.recurringOccurrences(
                        item.executedCount, item.maxOccurrences!),
                    style: PTypo.bodySm),
              ),
          ],
        ),
        // 다음 예정일 — 추가 시트와 같은 표현(필 칩). 무엇이 언제 잡혀 있는지
        // 여기서 바로 보이지 않으면 목록으로 나가 다음 실행일만 보고 짐작해야 한다.
        if (nextDates.isNotEmpty)
          PDetailSection(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.calendar, size: 13, color: t.fgPrimary),
                const SizedBox(width: 5),
                Text(l.recurringNextDates),
              ],
            ),
            child: Wrap(
              spacing: PSpace.x8,
              runSpacing: PSpace.x8,
              children: [
                for (final d in nextDates)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: t.bgSunken,
                      borderRadius: PRadius.brFull,
                    ),
                    child: Text(
                      // 추가 시트 칩과 같은 표기.
                      localeIsEn()
                          ? formatDay(d).md
                          : '${d.month.toString().padLeft(2, '0')}월 ${d.day.toString().padLeft(2, '0')}일',
                      style: PTypo.caption.copyWith(
                          color: t.fgPrimary, fontWeight: PFontWeight.semi),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.onEdit,
    required this.onDelete,
  });
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // [삭제][수정] — spec drawer.md "footer 액션은 최대 2개".
    // 정지/시작은 행을 밀면 나온다. 예전엔 `⋮` 메뉴를 대신하느라 여기에 셋을
    // 뒀는데, 스와이프가 그 자리를 맡으면서 footer 는 2개로 돌아왔다.
    return PViewFooter(
      onDelete: onDelete,
      deleteLabel: l.actionDelete,
      onEdit: onEdit,
      editLabel: l.actionEdit,
    );
  }
}
