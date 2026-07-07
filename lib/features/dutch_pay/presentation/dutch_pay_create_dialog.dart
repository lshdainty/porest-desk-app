import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_date_input.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart' show Expense;
import 'package:porest_desk_app/features/dutch_pay/application/dutch_pay_providers.dart';
import 'package:porest_desk_app/features/dutch_pay/presentation/dutch_pay_screen.dart' show DutchAvatar;

/// 더치페이 만들기 — 2단계 마법사 (web `DutchCreateDialog` 미러).
///
/// step1: 정산 이름(필수) / 장소(→description) / 총 금액(필수) + 날짜(2:1) →
/// step2: 참여자 체크 선택 ('나' 고정 결제자 + 기존 정산 이름 빈도 추천 + 직접 추가).
/// 저장은 EQUAL 균등 분배(floor, 나머지 첫 참여자). CUSTOM/RATIO 는 거래 연동
/// 고급 시트(`dutch_pay_from_tx_dialog`) 담당 — 이 마법사는 EQUAL 전용.
///
/// [fromExpense] 가 주어지면 step1 을 거래 기반으로 prefill +
/// sourceExpenseRowId 로 연결한다.
void showDutchPayCreateDialog(BuildContext context, {Expense? fromExpense}) {
  final controller = PSheetController();
  final bodyKey = GlobalKey<_BodyState>();
  showPSheet<void>(
    context,
    title: AppLocalizations.of(context).dutchCreate,
    contentBuilder: (ctx, scrollCtrl) => _Body(
      key: bodyKey,
      fromExpense: fromExpense,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => _WizardFooter(controller: controller, bodyKey: bodyKey),
  );
}

/// 참여자 후보 — 이름 + 선택 여부 + '나'/추천 메타.
class _Pick {
  _Pick({required this.name, this.isMe = false, this.recommendCount});
  final String name;
  final bool isMe;

  /// 추천 후보가 '함께 정산한 횟수' — 있으면 note 로 표시. me/수동추가는 null.
  final int? recommendCount;
  bool selected = false;
}

class _Body extends ConsumerStatefulWidget {
  const _Body({
    super.key,
    this.fromExpense,
    required this.scrollController,
    required this.controller,
  });
  final Expense? fromExpense;
  final ScrollController scrollController;
  final PSheetController controller;
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _placeCtrl;
  late final TextEditingController _amountCtrl;
  final TextEditingController _manualCtrl = TextEditingController();
  late DateTime _date;

  int _step = 1; // 1=basics, 2=participants
  bool _submitting = false;

  /// 참여자 후보 — '나' 고정(0번) + 추천(기존 정산 이름 빈도) + 수동 추가.
  final List<_Pick> _picks = [];

  @override
  void initState() {
    super.initState();
    final fe = widget.fromExpense;
    _titleCtrl = TextEditingController(
      text: fe?.merchant?.isNotEmpty == true
          ? fe!.merchant
          : (fe?.description ?? ''),
    );
    _placeCtrl = TextEditingController();
    _amountCtrl = TextEditingController(
      text: fe == null ? '' : fe.amount.abs().toString(),
    );
    if (fe?.expenseDate != null) {
      try {
        _date = DateTime.parse(fe!.expenseDate!.substring(0, 10));
      } catch (_) {
        _date = DateTime.now();
      }
    } else {
      _date = DateTime.now();
    }
    // '나' 고정 결제자 — 선택된 상태로 시작. 표시 라벨은 _PickRow 에서 로케일화.
    final me = _Pick(name: '나', isMe: true)..selected = true;
    _picks.add(me);
    widget.controller.onSubmit = _onPrimary;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _placeCtrl.dispose();
    _amountCtrl.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v);
  }

  int get _total => int.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;

  int get _selectedCount => _picks.where((p) => p.selected).length;

  bool get _step1Valid => _titleCtrl.text.trim().isNotEmpty && _total > 0;
  bool get _step2Valid => _selectedCount >= 2;

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 기존 정산 이름 빈도 기반 추천 — '나' 다음에 1회만 채움.
  void _seedRecommendations() {
    if (_picks.length > 1) return; // 이미 채움
    final items = ref.read(dutchPayListProvider).value ?? const [];
    final freq = <String, int>{};
    for (final d in items) {
      for (final p in d.participants) {
        final n = (p.participantName ?? '').trim();
        if (n.isEmpty || n == '나') continue;
        freq[n] = (freq[n] ?? 0) + 1;
      }
    }
    final sorted = freq.keys.toList()
      ..sort((a, b) => freq[b]!.compareTo(freq[a]!));
    for (final n in sorted.take(6)) {
      _picks.add(_Pick(name: n, recommendCount: freq[n]));
    }
  }

  void _addManual() {
    final name = _manualCtrl.text.trim();
    if (name.isEmpty) return;
    if (_picks.any((p) => p.name == name)) {
      _manualCtrl.clear();
      return;
    }
    setState(() {
      _picks.add(_Pick(name: name)..selected = true);
      _manualCtrl.clear();
    });
  }

  /// footer 의 primary 버튼 — step1 이면 '다음', step2 이면 '정산 만들기'.
  Future<void> _onPrimary() async {
    if (_step == 1) {
      if (!_step1Valid) return;
      _seedRecommendations();
      setState(() => _step = 2);
      widget.controller.setCanSubmit(_step2Valid);
      widget.controller.bump();
      return;
    }
    await _submit();
  }

  void _back() {
    setState(() => _step = 1);
    widget.controller.setCanSubmit(_step1Valid);
    widget.controller.bump();
  }

  Future<void> _submit() async {
    if (_submitting || !_step2Valid) return;
    _setSubmitting(true);
    try {
      final repo = await ref.read(dutchPayRepositoryProvider.future);
      final selected = _picks.where((p) => p.selected).toList();
      final n = selected.length;
      final each = _total ~/ n;
      final rest = _total - each * n;
      final me = ref.read(authProvider).value;
      final payload = [
        for (var i = 0; i < n; i++)
          (
            name: selected[i].isMe ? (me?.userName ?? '나') : selected[i].name,
            userRowId: selected[i].isMe ? me?.rowId : null,
            amount: i == 0 ? each + rest : each,
          ),
      ];
      await repo.create(
        title: _titleCtrl.text.trim(),
        description: _placeCtrl.text.trim().isEmpty
            ? null
            : _placeCtrl.text.trim(),
        totalAmount: _total,
        splitMethod: 'EQUAL',
        dutchPayDate: _fmtDate(_date),
        sourceExpenseRowId: widget.fromExpense?.rowId,
        participants: payload,
      );
      ref.invalidate(dutchPayListProvider);
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      Navigator.of(context).pop();
      showPSnackBar(context, l.dutchCreated);
    } on ApiException catch (e) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      showPSnackBar(context, '${l.dutchActionFailed}: ${e.message}',
          severity: PSnackSeverity.error);
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // footer 가 참조하는 step/검증 상태를 매 build 동기화.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.setCanSubmit(_step == 1 ? _step1Valid : _step2Valid);
      widget.controller.bump();
    });
    return _step == 1 ? _buildStep1(context) : _buildStep2(context);
  }

  // ── Step 1: 정산 기본 정보 ──
  Widget _buildStep1(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
        _StepHeader(label: l.dutchCreate, step: 1, t: t),
        const SizedBox(height: PSpace.md),
        _Label(l.dutchNameLabel, t),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: _titleCtrl,
          autofocus: true,
          placeholder: l.dutchNamePlaceholder,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: PSpace.x12),

        _Label(l.dutchPlaceLabel, t),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: _placeCtrl,
          placeholder: l.dutchPlacePlaceholder,
        ),
        const SizedBox(height: PSpace.x12),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label(l.dutchTotalLabel, t),
                  const SizedBox(height: PSpace.x4),
                  PTextInput(
                    controller: _amountCtrl,
                    numbersOnly: true,
                    style: PTypo.h3,
                    placeholder: '0',
                    suffixText: '원',
                    inputFormatters: [_ThousandsFormatter()],
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(width: PSpace.x8),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label(l.dutchDateLabel, t),
                  const SizedBox(height: PSpace.x4),
                  PDateInput(
                    value: _date,
                    onChanged: (d) {
                      if (d != null) setState(() => _date = d);
                    },
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 2: 참여자 선택 ──
  Widget _buildStep2(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final n = _selectedCount;
    final perPerson = n == 0 ? 0 : _total ~/ n;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
        _StepHeader(label: l.dutchSelectParticipants, step: 2, t: t),
        const SizedBox(height: PSpace.md),
        // 요약: N명 선택 · 1인당 X원
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: t.bgBrandSubtle,
            borderRadius: PRadius.brMd,
          ),
          child: Row(
            children: [
              Text(l.dutchNSelected(n),
                  style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary, fontWeight: PFontWeight.bold)),
              const Spacer(),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: '${l.dutchPerPersonLabel} ',
                    style: PTypo.bodySm.copyWith(color: t.fgSecondary),
                  ),
                  TextSpan(
                    text: krwSigned(perPerson, false, unit: true),
                    style: PTypo.bodySm.copyWith(
                        color: t.fgBrand, fontWeight: PFontWeight.bold),
                  ),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.md),

        // 후보 리스트
        for (var i = 0; i < _picks.length; i++) ...[
          _PickRow(
            pick: _picks[i],
            onToggle: () =>
                setState(() => _picks[i].selected = !_picks[i].selected),
          ),
          if (i < _picks.length - 1) const SizedBox(height: 6),
        ],
        const SizedBox(height: PSpace.md),

        // 직접 추가
        Row(
          children: [
            Expanded(
              child: PTextInput(
                controller: _manualCtrl,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addManual(),
                placeholder: l.dutchAddNamePlaceholder,
                enabled: !_submitting,
              ),
            ),
            const SizedBox(width: 8),
            PButton(
              label: l.dutchAdd,
              icon: LucideIcons.userPlus,
              variant: PButtonVariant.outline,
              size: PButtonSize.sm,
              onPressed: _submitting ? null : _addManual,
            ),
          ],
        ),
      ],
    );
  }
}

/// 참여자 체크 행 — checkbox + 아바타 + 이름·note. 선택 시 brand-tint 배경.
class _PickRow extends StatelessWidget {
  const _PickRow({required this.pick, required this.onToggle});
  final _Pick pick;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final noteText = pick.isMe
        ? l.dutchPayer
        : (pick.recommendCount != null
            ? l.dutchSettledTogetherCount(pick.recommendCount!)
            : null);
    return InkWell(
      onTap: onToggle,
      borderRadius: PRadius.brMd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: pick.selected ? t.bgBrandSubtle : Colors.transparent,
          borderRadius: PRadius.brMd,
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: pick.selected ? t.bgBrandSolid : Colors.transparent,
                border: Border.all(
                  color: pick.selected ? t.bgBrandSolid : t.borderDefault,
                  width: 2,
                ),
                borderRadius: PRadius.brSm,
              ),
              alignment: Alignment.center,
              child: pick.selected
                  ? const Icon(LucideIcons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            DutchAvatar(name: pick.name, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pick.isMe ? l.dutchMe : pick.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                  if (noteText != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      noteText,
                      style: PTypo.micro.copyWith(color: t.fgTertiary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 마법사 단계 표시 — '제목' + 'N/2' 칩.
class _StepHeader extends StatelessWidget {
  const _StepHeader(
      {required this.label, required this.step, required this.t});
  final String label;
  final int step;
  final PorestTokens t;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: PTypo.body.copyWith(
                  color: t.fgPrimary, fontWeight: PFontWeight.bold)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: t.bgSunken,
            borderRadius: PRadius.brFull,
          ),
          child: Text('$step / 2',
              style: PTypo.micro.copyWith(
                  color: t.fgSecondary, fontWeight: PFontWeight.bold)),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, this.t);
  final String text;
  final PorestTokens t;
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: PTypo.caption.copyWith(color: t.fgSecondary));
  }
}

/// 천단위 콤마 입력 포맷터 — 표시는 1,234,567 / 값 파싱은 콤마 제거.
class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final formatted = krw(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// 마법사 footer — step1: 다음/취소, step2: 정산 만들기/이전.
class _WizardFooter extends StatelessWidget {
  const _WizardFooter({required this.controller, required this.bodyKey});
  final PSheetController controller;
  final GlobalKey<_BodyState> bodyKey;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) {
        final state = bodyKey.currentState;
        final step = state?._step ?? 1;
        final canNext = controller.canSubmit;
        if (step == 1) {
          return Row(
            children: [
              const Spacer(),
              PButton(
                label: l.actionCancel,
                variant: PButtonVariant.ghost,
                onPressed: controller.submitting
                    ? null
                    : () => Navigator.of(ctx).pop(),
              ),
              const SizedBox(width: PSpace.x4),
              PButton(
                label: l.dutchNext,
                icon: LucideIcons.arrowRight,
                onPressed:
                    canNext && !controller.submitting ? controller.onSubmit : null,
              ),
            ],
          );
        }
        return Row(
          children: [
            PButton(
              label: l.dutchPrev,
              variant: PButtonVariant.ghost,
              flush: PButtonFlush.left,
              onPressed: controller.submitting ? null : state?._back,
            ),
            const Spacer(),
            PButton(
              label: l.dutchCreate,
              icon: LucideIcons.check,
              loading: controller.submitting,
              onPressed:
                  canNext && !controller.submitting ? controller.onSubmit : null,
            ),
          ],
        );
      },
    );
  }
}
