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
import 'package:porest_desk_app/shared/widgets/p_divider.dart';
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
              horizontal: PSpace.x20, vertical: PSpace.x24),
          children: [
            // 안내 카드
            _IntroCard(
              tokens: t,
              onAdd: () => _showLabelEditor(context, ref, null),
            ),
            const SizedBox(height: PSpace.x20),

            labelsAsync.when(
              loading: () => const PListSkeleton(rows: 4, showAvatar: true),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: PSpace.x16),
                child: Text('${l.calLabelLoadError}\n$e',
                    style: PTypo.bodySm.copyWith(color: t.statusDanger)),
              ),
              data: (labels) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: PSpace.x8),
                      child: Text(l.calAllLabelsCount(labels.length),
                          style: PTypo.bodySm.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.bold,
                          )),
                    ),
                    if (labels.isEmpty)
                      PCard(
                        variant: PCardVariant.shadow,
                        child: PEmptyState(
                          icon: LucideIcons.tag,
                          message: l.calLabelsEmpty,
                          subMessage: l.calLabelsEmptyHint,
                        ),
                      )
                    else
                      PCard(
                        variant: PCardVariant.shadow,
                        child: Column(
                          children: [
                            for (int i = 0; i < labels.length; i++) ...[
                              _LabelRow(
                                label: labels[i],
                                tokens: t,
                                onTap: () =>
                                    _showLabelEditor(context, ref, labels[i]),
                                onDelete: () =>
                                    _confirmDelete(context, ref, labels[i]),
                              ),
                              if (i < labels.length - 1) PDivider(indent: 60),
                            ],
                          ],
                        ),
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
  const _IntroCard({required this.tokens, required this.onAdd});
  final PorestTokens tokens;
  final VoidCallback onAdd;

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
              color: t.bgBrand,
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
          const SizedBox(width: PSpace.x8),
          PButton(
            label: l.calNewLabel,
            icon: LucideIcons.plus,
            size: PButtonSize.sm,
            onPressed: onAdd,
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
    required this.onTap,
    required this.onDelete,
  });
  final EventLabel label;
  final PorestTokens tokens;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final l = AppLocalizations.of(context);
    final color = solidSwatchColor(context, label.color, fallback: t.fgBrand);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x16, vertical: PSpace.x12),
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
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Text(label.labelName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PTypo.body.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.semi,
                  )),
            ),
            PButton.icon(
              icon: LucideIcons.trash2,
              size: PButtonSize.sm,
              iconColor: t.statusDanger,
              tooltip: l.actionDelete,
              onPressed: onDelete,
            ),
          ],
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
      Navigator.of(context).pop();
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
    contentBuilder: (ctx, scrollCtrl) => _LabelEditorBody(
      scrollController: scrollCtrl,
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
    required this.scrollController,
    required this.nameController,
    required this.initialColor,
    required this.controller,
    required this.onColorChanged,
  });
  final ScrollController scrollController;
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
    return ListView(
      controller: widget.scrollController,
      padding:
          const EdgeInsets.fromLTRB(PSpace.x16, 0, PSpace.x16, PSpace.x16),
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
              Container(
                width: 36,
                height: 36,
                decoration:
                    BoxDecoration(color: swatch, shape: BoxShape.circle),
              ),
              const SizedBox(width: PSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.calPreview,
                        style: PTypo.micro.copyWith(color: t.fgTertiary)),
                    const SizedBox(height: 2),
                    Text(preview.isEmpty ? l.calNewLabel : preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PTypo.body.copyWith(
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
