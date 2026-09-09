import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/network/patch.dart';
import 'package:porest_desk_app/features/dashboard/application/dashboard_providers.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_color_picker.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_section_label.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';
import 'package:porest_desk_app/shared/widgets/p_switch.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/memo/application/memo_providers.dart';
import 'package:porest_desk_app/features/constellation/application/constellation_providers.dart';
import 'package:porest_desk_app/features/memo/domain/memo.dart';
import 'package:porest_desk_app/features/memo/domain/memo_colors.dart';
import 'package:porest_desk_app/features/memo/domain/memo_tag.dart';

void showMemoEditDialog(BuildContext context, {Memo? edit}) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: edit == null ? l.memoNew : l.memoEditTitle,
    contentBuilder: (ctx, scrollCtrl) =>
        _Body(edit: edit, scrollController: scrollCtrl, controller: controller),
    footerBuilder: (ctx) =>
        PSheetFooter(controller: controller, submitLabel: l.actionSave),
  );
}

class _Body extends ConsumerStatefulWidget {
  const _Body({
    this.edit,
    required this.scrollController,
    required this.controller,
  });
  final Memo? edit;
  final ScrollController scrollController;
  final PSheetController controller;
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;

  /// 고른 태그 이름 — null 이면 태그 없음. 목록은 서버 마스터가 SoT 라
  /// 앱이 이름을 지어내지 않는다(옛 하드코딩 7종은 QA #98 에서 걷어 냈다).
  late String? _tag;
  late String _color;
  late bool _pinned;
  bool _submitting = false;
  bool _titleError = false;
  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _contentCtrl = TextEditingController(text: e?.content ?? '');
    final tag = e?.tag?.trim() ?? '';
    _tag = tag.isEmpty ? null : tag;
    _color = memoColorOrDefault(e?.color);
    _pinned = e?.pinned ?? false;
    widget.controller.onSubmit = _submit;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v);
  }

  // 저장 버튼은 항상 활성 — 제목 검증은 submit 시 인라인 에러로 처리(web 동작 미러).
  bool get _canSubmit => !_submitting;

  /// 태그 선택지 — 서버 마스터 목록 + 지금 값(목록에 없으면 맨 앞에 보존).
  ///
  /// 목록이 비거나(태그를 하나도 안 만든 계정) 조회가 실패해도 select 는 비지
  /// 않는다: "태그 없음" 항목이 build 에서 늘 앞에 붙고, 편집 중인 메모가 들고
  /// 있던 태그는 여기서 살아남는다. `AsyncValue.value` 는 로딩·에러에서 null 이라
  /// `const []` 로 접는데, 그 덕에 조회가 실패해도 **지금 값이 지워지지 않는다** —
  /// 못 고르게 될 뿐이다. 옛 코드처럼 없는 태그('개인')를 끼워 넣으면 저장할 때
  /// 서버가 그 이름의 마스터를 새로 만들어, 사용자가 지운 태그가 되살아난다.
  List<String> _tagChoices() {
    final server = ref.watch(memoTagListProvider).value ?? const <MemoTag>[];
    final names = [for (final t in server) t.tagName];
    final current = _tag;
    return [if (current != null && !names.contains(current)) current, ...names];
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = true);
      return;
    }
    final content = _contentCtrl.text.trim();
    _setSubmitting(true);
    try {
      final repo = await ref.read(memoRepositoryProvider.future);
      final pinChanged = (widget.edit?.pinned ?? false) != _pinned;
      if (_isEdit) {
        await repo.update(
          id: widget.edit!.rowId,
          title: title,
          // 본문을 지우고 저장하면 지워져야 한다 — 키를 빼면 서버가 옛 본문을 지킨다.
          content: Patch.set(content.isEmpty ? null : content),
          // 태그도 이 화면이 비울 수 있는 칸이다 — "태그 없음" 을 고르면 키를
          // 빼지 말고 명시적 null 로 실어야 서버가 지운다(QA #99 와 같은 이유).
          tag: Patch.set(_tag),
          color: _color,
        );
        // pin 은 별도 토글 엔드포인트 — 변경 시에만 호출.
        if (pinChanged) await repo.pin(widget.edit!.rowId);
      } else {
        final created = await repo.create(
          title: title,
          content: content.isEmpty ? null : content,
          tag: _tag,
          color: _color,
        );
        if (_pinned) await repo.pin(created.rowId);
      }
      ref.invalidate(memoListProvider);
      // 홈 위젯(메모 개수·최근 메모)의 원본 — 셸 상주라 스스로 안 받는다.
      ref.invalidate(dashboardSummaryProvider);
      // 별자리 게이미피케이션 — 메모 작성 별빛(+1, 일 2회) 반영
      invalidateConstellation(ref);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException {
      if (!mounted) return;
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(_canSubmit);
    });
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
      children: [
        // 제목 (필수).
        PSectionLabel(l.memoFieldTitle),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: _titleCtrl,
          placeholder: l.memoFieldTitle,
          autofocus: !_isEdit,
          errorText: _titleError ? l.memoTitleRequired : null,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: PFontWeight.bold),
          onChanged: (_) {
            if (_titleError) setState(() => _titleError = false);
          },
        ),
        const SizedBox(height: PSpace.x16),

        // 내용.
        PSectionLabel(l.memoFieldContent),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: _contentCtrl,
          placeholder: l.memoContentPlaceholder,
          maxLines: 12,
          minLines: 8,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: PSpace.x16),

        // 태그 + 고정 2열.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PSectionLabel(l.memoFieldTag),
                  const SizedBox(height: PSpace.x4),
                  PSelect<String?>(
                    value: _tag,
                    title: l.memoFieldTag,
                    // 값이 null 이면 trigger 가 placeholder 를 띄운다 — 그 자리에
                    // 항목과 같은 문구를 넣어 "태그 없음" 이 골라진 상태로 읽힌다.
                    placeholder: l.memoTagNone,
                    items: [
                      PSelectItem<String?>(value: null, label: l.memoTagNone),
                      for (final tag in _tagChoices())
                        PSelectItem<String?>(value: tag, label: tag),
                    ],
                    onChanged: (v) => setState(() => _tag = v),
                  ),
                ],
              ),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PSectionLabel(l.memoPin),
                  const SizedBox(height: PSpace.x4),
                  SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        PSwitch(
                          value: _pinned,
                          semanticLabel: l.memoPinToTop,
                          onChanged: (v) => setState(() => _pinned = v),
                        ),
                        Expanded(
                          child: Text(
                            l.memoPinToTop,
                            style: PTypo.body.copyWith(color: t.fgPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x16),

        // 색상 — chart palette base hex 저장.
        PSectionLabel(l.memoFieldColor),
        const SizedBox(height: PSpace.x8),
        PColorPicker(
          selected: _color,
          onChanged: (c) => setState(() => _color = c),
        ),
      ],
    );
  }
}
