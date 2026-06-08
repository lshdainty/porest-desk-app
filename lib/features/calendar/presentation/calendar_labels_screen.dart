import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/chart_palette.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/p_back_button.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_color_picker.dart';
import '../../../shared/widgets/p_divider.dart';
import '../../../shared/widgets/p_empty_state.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_skeleton.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../application/calendar_providers.dart';
import '../domain/event_label.dart';

/// 설정 진입 — 캘린더 라벨 관리 (전 캘린더 공용).
///
/// design `LabelManagerSection` 미러: 안내 카드 + "전체 라벨 N" 리스트
/// (색칩 + 이름 + 삭제) + 추가/편집(이름 + palette 색) + 삭제 확인.
///
/// 백엔드 `EventLabel` 에 icon 필드가 없으므로 design 의 icon picker 는 생략 —
/// 라벨은 "이름 + 색"만 영속한다. 색은 chart palette tone(base hex).
class CalendarLabelsScreen extends ConsumerWidget {
  const CalendarLabelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final labelsAsync = ref.watch(eventLabelsProvider);

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: const Text('캘린더 라벨'),
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
                child: Text('라벨 로드 실패\n$e',
                    style: PTypo.bodySm.copyWith(color: t.statusDanger)),
              ),
              data: (labels) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: PSpace.x8),
                      child: Text('전체 라벨 · ${labels.length}',
                          style: PTypo.bodySm.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.bold,
                          )),
                    ),
                    if (labels.isEmpty)
                      PCard(
                        variant: PCardVariant.shadow,
                        child: const PEmptyState(
                          icon: LucideIcons.tag,
                          message: '라벨이 없어요',
                          subMessage: '위 "새 라벨" 버튼으로 만들어보세요',
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
                Text('캘린더 라벨',
                    style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.bold,
                    )),
                const SizedBox(height: 2),
                Text('모든 캘린더에서 공용으로 쓰는 라벨이에요. 일정 등록 시 선택할 수 있어요.',
                    style: PTypo.caption.copyWith(color: t.fgSecondary)),
              ],
            ),
          ),
          const SizedBox(width: PSpace.x8),
          PButton(
            label: '새 라벨',
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
              tooltip: '삭제',
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
      showPSnackBar(context, '저장 실패: ${e.message}',
          severity: PSnackSeverity.error);
    } finally {
      controller.setSubmitting(false);
    }
  }

  controller.onSubmit = submit;

  showPSheet<void>(
    context,
    title: existing == null ? '새 라벨' : '라벨 편집',
    contentBuilder: (ctx, scrollCtrl) => _LabelEditorBody(
      scrollController: scrollCtrl,
      nameController: nameCtrl,
      initialColor: selectedColor,
      controller: controller,
      onColorChanged: (c) => selectedColor = c,
    ),
    footerBuilder: (ctx) =>
        PSheetFooter(controller: controller, submitLabel: '저장'),
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
                    Text('미리보기',
                        style: PTypo.micro.copyWith(color: t.fgTertiary)),
                    const SizedBox(height: 2),
                    Text(preview.isEmpty ? '새 라벨' : preview,
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
        Text('이름', style: PTypo.caption.copyWith(color: t.fgSecondary)),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: widget.nameController,
          placeholder: '예: 중요, 마감일, 회의',
          onChanged: (v) {
            widget.controller.setCanSubmit(v.trim().isNotEmpty);
            setState(() {});
          },
        ),
        const SizedBox(height: PSpace.x16),

        // 색상
        Text('색상', style: PTypo.caption.copyWith(color: t.fgSecondary)),
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
  final ok = await showPConfirmDialog(
    context,
    title: '라벨 삭제',
    message:
        '"${label.labelName}" 라벨을 삭제하시겠어요? 이 라벨이 지정된 일정은 라벨 없음 상태가 됩니다.',
    confirmLabel: '삭제',
    destructive: true,
  );
  if (!ok || !context.mounted) return;
  try {
    final repo = await ref.read(calendarRepositoryProvider.future);
    await repo.deleteLabel(label.rowId);
    ref.invalidate(eventLabelsProvider);
  } on ApiException catch (e) {
    if (!context.mounted) return;
    showPSnackBar(context, '삭제 실패: ${e.message}',
        severity: PSnackSeverity.error);
  }
}
