import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_color_picker.dart';
import 'package:porest_desk_app/shared/widgets/p_empty_state.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/calendar/application/calendar_providers.dart';
import 'package:porest_desk_app/features/calendar/domain/event_label.dart';

/// 설정 진입 — 캘린더 라벨 관리 (전 캘린더 공용).
///
/// design `LabelManagerSection` 미러: 안내 카드 + "전체 라벨 N" 리스트
/// (색칩 + 이름 + 삭제) + 추가/편집(이름 + palette 색) + 삭제 확인.
///
/// 백엔드 `EventLabel` 에 icon 필드가 없으므로 design 의 icon picker 는 생략 —
/// 라벨은 "이름 + 색"만 영속한다. 색은 chart palette tone(base hex).
class CalendarLabelsScreen extends ConsumerStatefulWidget {
  const CalendarLabelsScreen({super.key});

  @override
  ConsumerState<CalendarLabelsScreen> createState() =>
      _CalendarLabelsScreenState();
}

class _CalendarLabelsScreenState extends ConsumerState<CalendarLabelsScreen> {
  @override
  void initState() {
    super.initState();
    // 진입 시 갱신 — eventLabels 는 keepAlive 라 다른 클라이언트 변경 반영 위해 무효화.
    Future.microtask(() {
      if (mounted) ref.invalidate(eventLabelsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final labelsAsync = ref.watch(eventLabelsProvider);

    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.calLabelsTitle),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(eventLabelsProvider);
          await ref.read(eventLabelsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: PSpace.x24, vertical: PSpace.x24),
          children: [
            // 안내 카드
            _IntroCard(tokens: t),
            const SizedBox(height: PSpace.x32),

            labelsAsync.when(
              // 추가 버튼은 정적 UI라 로딩에도 진짜를 쓴다 — 개수 텍스트와 행만
              // 데이터 자리. 범용 PListSkeleton(원형 아바타 2줄)은 실제 라벨 행
              // (사각 타일 32 + 이름/사용 수 + 휴지통 + chevron)과 달라 걷어냈다.
              loading: () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const PSkeleton.line(width: 96, height: 14),
                      PButton(
                        label: l.calNewLabel,
                        icon: LucideIcons.plus,
                        variant: PButtonVariant.accent,
                        size: PButtonSize.sm,
                        onPressed: () => _showLabelEditor(context, ref, null),
                      ),
                    ],
                  ),
                  for (int i = 0; i < 4; i++)
                    Container(
                      decoration: i > 0
                          ? BoxDecoration(
                              border:
                                  Border(top: BorderSide(color: t.borderSubtle)),
                            )
                          : null,
                      padding: const EdgeInsets.symmetric(
                          horizontal: PSpace.x8, vertical: 14),
                      child: const Row(
                        children: [
                          PSkeleton(
                              width: 32, height: 32, borderRadius: PRadius.brMd),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PSkeleton.line(width: 120, height: 14),
                                SizedBox(height: 2),
                                PSkeleton.line(width: 72, height: 12),
                              ],
                            ),
                          ),
                          PSkeleton(
                              width: 32, height: 32, borderRadius: PRadius.brMd),
                          SizedBox(width: PSpace.x4),
                          PSkeleton(width: 15, height: 15),
                        ],
                      ),
                    ),
                ],
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: PSpace.x16),
                child: Text('${l.calLabelLoadError}\n$e',
                    style: PTypo.bodySm.copyWith(color: t.statusDanger)),
              ),
              data: (labels) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // label padding 제거(사용자 결정, web 정합) — label·list 한 묶음 gap 0.
                    // 라벨행 우측 텍스트(accent) 추가 버튼 — 프리셋 정합(filled 안내카드 버튼 폐기)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l.calAllLabelsCount(labels.length),
                            style: PTypo.bodySm.copyWith(
                              color: t.fgPrimary,
                              fontWeight: PFontWeight.bold,
                            )),
                        PButton(
                          label: l.calNewLabel,
                          icon: LucideIcons.plus,
                          variant: PButtonVariant.accent,
                          size: PButtonSize.sm,
                          onPressed: () => _showLabelEditor(context, ref, null),
                        ),
                      ],
                    ),
                    if (labels.isEmpty)
                      // 카드 다이어트 — 빈 상태 플랫.
                      PEmptyState(
                        icon: LucideIcons.tag,
                        message: l.calLabelsEmpty,
                        subMessage: l.calLabelsEmptyHint,
                      )
                    else
                      // 카드 다이어트 — 리스트 플랫.
                      Column(
                          children: [
                            for (int i = 0; i < labels.length; i++)
                              _LabelRow(
                                label: labels[i],
                                tokens: t,
                                // web 정합 — divider 는 행 풀폭 borderTop(첫 행 제외, indent 없음).
                                showDivider: i > 0,
                                onTap: () =>
                                    _showLabelEditor(context, ref, labels[i]),
                                onDelete: () =>
                                    _confirmDelete(context, ref, labels[i]),
                              ),
                          ],
                        ),
                  ],
                );
              },
            ),
            const SizedBox(height: PSpace.x32),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.tokens});
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final l = AppLocalizations.of(context);
    return PCard(
      variant: PCardVariant.brand,
      padding: const EdgeInsets.all(PSpace.x16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              // fill 은 다크에서도 primary 고정(bgBrandSolid) — web --bg-brand 정합.
              color: t.bgBrandSolid,
              borderRadius: PRadius.brMd,
            ),
            alignment: Alignment.center,
            child: Icon(LucideIcons.tag, size: 18, color: t.fgOnBrand),
          ),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.calLabelsTitle,
                    style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.bold,
                    )),
                const SizedBox(height: 2),
                Text(l.calLabelsIntro,
                    style: PTypo.caption.copyWith(color: t.fgSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({
    required this.label,
    required this.tokens,
    required this.showDivider,
    required this.onTap,
    required this.onDelete,
  });
  final EventLabel label;
  final PorestTokens tokens;
  final bool showDivider;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final l = AppLocalizations.of(context);
    // 아이콘 색 web 정합 — 다크 light-variant swap(resolveChartColor). solid 스와치는 뮤트해 보임.
    final color = resolveChartColor(context, label.color, fallback: t.fgBrand);
    return Container(
      decoration: showDivider
          ? BoxDecoration(
              border: Border(top: BorderSide(color: t.borderSubtle)),
            )
          : null,
      child: InkWell(
      onTap: onTap,
      child: Padding(
        // web 정합 — 행 padding 14px 8px(사용자 결정).
        padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x8, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: softBg(context, color),
                borderRadius: PRadius.brMd,
              ),
              alignment: Alignment.center,
              // web 정합 — 색 원 대신 라벨색 tag 아이콘(16).
              child: Icon(LucideIcons.tag, size: 16, color: color),
            ),
            // web 정합 — 아이콘↔텍스트 gap 14.
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.labelName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PTypo.body.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.semi,
                      )),
                  const SizedBox(height: 2),
                  // 사용 중 일정 수 — 할일 태그 행 정합.
                  Text(l.calLabelUsage(label.usageCount),
                      style: PTypo.caption.copyWith(
                          color: t.fgTertiary, fontSize: 12.5)),
                ],
              ),
            ),
            PButton.icon(
              icon: LucideIcons.trash2,
              size: PButtonSize.sm,
              // web !text-[--fg-expense] 정합 — statusDanger(원색)는 다크에서 탁함.
              iconColor: t.fgExpense,
              tooltip: l.actionDelete,
              onPressed: onDelete,
            ),
            // 행 탭=편집 진입 표시 — 할일 태그 행 정합.
            Icon(LucideIcons.chevronRight, size: 15, color: t.fgTertiary),
          ],
        ),
      ),
      ),
    );
  }
}

// ─── 추가/편집 ──────────────────────────────────────────────

void _showLabelEditor(
  BuildContext context,
  WidgetRef ref,
  EventLabel? existing,
) {
  final l = AppLocalizations.of(context);
  final nameCtrl = TextEditingController(text: existing?.labelName ?? '');
  final controller = PSheetController();
  controller.setCanSubmit((existing?.labelName ?? '').trim().isNotEmpty);
  String selectedColor = existing?.color ?? '#2c70bf';

  Future<void> submit() async {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    controller.setSubmitting(true);
    try {
      final repo = await ref.read(calendarRepositoryProvider.future);
      if (existing == null) {
        await repo.createLabel(labelName: name, color: selectedColor);
      } else {
        await repo.updateLabel(
            id: existing.rowId, labelName: name, color: selectedColor);
      }
      ref.invalidate(eventLabelsProvider);
      if (!context.mounted) return;
      // 시트는 root navigator 소속(p_modal useRootNavigator) — root 명시.
      Navigator.of(context, rootNavigator: true).pop();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      showPSnackBar(context, '${l.calSaveFailed}: ${e.message}',
          severity: PSnackSeverity.error);
    } finally {
      controller.setSubmitting(false);
    }
  }

  controller.onSubmit = submit;

  showPSheet<void>(
    context,
    title: existing == null ? l.calNewLabel : l.calEditLabel,
    // content 높이에 맞춰 렌더 — 짧은 폼이 85% 고정 높이로 뜨지 않게.
    shrinkWrap: true,
    contentBuilder: (ctx, _) => _LabelEditorBody(
      nameController: nameCtrl,
      initialColor: selectedColor,
      controller: controller,
      onColorChanged: (c) => selectedColor = c,
    ),
    footerBuilder: (ctx) =>
        PSheetFooter(controller: controller, submitLabel: l.actionSave),
  );
}

class _LabelEditorBody extends StatefulWidget {
  const _LabelEditorBody({
    required this.nameController,
    required this.initialColor,
    required this.controller,
    required this.onColorChanged,
  });
  final TextEditingController nameController;
  final String initialColor;
  final PSheetController controller;
  final ValueChanged<String> onColorChanged;

  @override
  State<_LabelEditorBody> createState() => _LabelEditorBodyState();
}

class _LabelEditorBodyState extends State<_LabelEditorBody> {
  late String _color;

  @override
  void initState() {
    super.initState();
    _color = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final swatch = solidSwatchColor(context, _color, fallback: t.fgBrand);
    final preview = widget.nameController.text.trim();
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // 미리보기
        Container(
          padding: const EdgeInsets.all(PSpace.x16),
          decoration: BoxDecoration(
            color: softBg(context, swatch),
            borderRadius: PRadius.brMd,
          ),
          child: Row(
            children: [
              // 웹 정합 — 40 radius-md 타일 + tag 아이콘 (원형 아님).
              Container(
                width: 40,
                height: 40,
                decoration:
                    BoxDecoration(color: swatch, borderRadius: PRadius.brMd),
                alignment: Alignment.center,
                child: Icon(LucideIcons.tag, size: 18, color: t.fgOnBrand),
              ),
              const SizedBox(width: PSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.calPreview,
                        // 웹 badge(11)/600 정합 — 색은 중립(tertiary) 유지.
                        style: PTypo.micro.copyWith(
                            color: t.fgTertiary,
                            fontWeight: PFontWeight.semi,
                            letterSpacing: 0.22)),
                    const SizedBox(height: 2),
                    Text(preview.isEmpty ? l.calNewLabel : preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        // 웹 body-lg(16)/700 정합 — 색은 중립(primary) 유지.
                        style: PTypo.bodyLg.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.bold,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x16),

        // 이름
        Text(l.calFieldName,
            style: PTypo.caption.copyWith(color: t.fgSecondary)),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: widget.nameController,
          placeholder: l.calLabelNamePlaceholder,
          onChanged: (v) {
            widget.controller.setCanSubmit(v.trim().isNotEmpty);
            setState(() {});
          },
        ),
        const SizedBox(height: PSpace.x16),

        // 색상
        Text(l.calFieldColor,
            style: PTypo.caption.copyWith(color: t.fgSecondary)),
        const SizedBox(height: PSpace.x8),
        PColorPicker(
          selected: _color,
          onChanged: (hex) {
            setState(() => _color = hex);
            widget.onColorChanged(hex);
          },
        ),
        ],
      ),
    );
  }
}

// ─── 삭제 ──────────────────────────────────────────────────

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  EventLabel label,
) async {
  final l = AppLocalizations.of(context);
  final ok = await showPConfirmDialog(
    context,
    title: l.calDeleteLabelTitle,
    message: l.calDeleteLabelConfirm(label.labelName),
    confirmLabel: l.actionDelete,
    destructive: true,
  );
  if (!ok || !context.mounted) return;
  try {
    final repo = await ref.read(calendarRepositoryProvider.future);
    await repo.deleteLabel(label.rowId);
    ref.invalidate(eventLabelsProvider);
  } on ApiException catch (e) {
    if (!context.mounted) return;
    showPSnackBar(context, '${l.calDeleteFailed}: ${e.message}',
        severity: PSnackSeverity.error);
  }
}
