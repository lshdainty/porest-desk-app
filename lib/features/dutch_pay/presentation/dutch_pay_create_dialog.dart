import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/krw.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../expense/domain/expense.dart' show Expense;
import '../../group/application/group_providers.dart';
import '../../group/domain/group_member.dart';
import '../application/dutch_pay_providers.dart';

/// 더치페이 만들기 시트.
///
/// [fromExpense] 가 주어지면 해당 거래를 기반으로 (title=가맹점/메모, totalAmount=금액,
/// date=expenseDate) 미리 채워지며 sourceExpenseRowId 로 연결된다 — front
/// `DutchPayFromTxDialog` 미러.
void showDutchPayCreateDialog(BuildContext context, {Expense? fromExpense}) {
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: fromExpense == null ? '더치페이 만들기' : '거래에서 더치페이',
    contentBuilder: (ctx, scrollCtrl) => _Body(
      fromExpense: fromExpense,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) =>
        PSheetFooter(controller: controller, submitLabel: '만들기'),
  );
}

class _Pname {
  _Pname({required this.name});
  String name;
  int amount = 0;
}

class _Body extends ConsumerStatefulWidget {
  const _Body({
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
  late final TextEditingController _amountCtrl;
  String _split = 'EQUAL';
  late DateTime _date;
  final List<_Pname> _participants = [
    _Pname(name: ''),
    _Pname(name: ''),
  ];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final fe = widget.fromExpense;
    _titleCtrl = TextEditingController(
      text: fe?.merchant?.isNotEmpty == true
          ? fe!.merchant
          : (fe?.description ?? ''),
    );
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
    widget.controller.onSubmit = _submit;
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  int get _total => int.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;

  bool get _canSubmit {
    if (_submitting) return false;
    if (_titleCtrl.text.trim().isEmpty) return false;
    if (_total <= 0) return false;
    if (_participants.where((p) => p.name.trim().isNotEmpty).length < 2) {
      return false;
    }
    if (_split == 'CUSTOM') {
      final sum = _participants.fold<int>(0, (s, p) => s + p.amount);
      if (sum != _total) return false;
    }
    return true;
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 같은 그룹 멤버에서 다중 선택해 참여자 추가 (#291).
  Future<void> _showSiblingPicker(BuildContext context) async {
    final selected = <int>{};
    final controller = PSheetController();
    List<SiblingMember> resolvedMembers = const [];
    List<SiblingMember>? picked;

    controller.onSubmit = () async {
      if (selected.isEmpty) return;
      picked = resolvedMembers
          .where((m) => selected.contains(m.userRowId))
          .toList();
      if (context.mounted) Navigator.of(context).pop();
    };

    await showPSheet<void>(
      context,
      title: '그룹 멤버에서 추가',
      contentBuilder: (sheetCtx, scrollCtrl) {
        return Consumer(builder: (ctx, ref, _) {
          final async = ref.watch(siblingMembersProvider);
          final t = ctx.tokens;
          return StatefulBuilder(builder: (ctx, setSheetState) {
            return async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(PSpace.x16),
                child: Text('멤버 로드 실패: $e',
                    style: PTypo.caption.copyWith(color: t.statusDanger)),
              ),
              data: (members) {
                resolvedMembers = members;
                if (members.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: PSpace.x32),
                    child: Center(
                      child: Text('같은 그룹의 다른 멤버가 없습니다',
                          style: PTypo.caption.copyWith(color: t.fgTertiary)),
                    ),
                  );
                }
                return ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(
                      PSpace.x8, 0, PSpace.x8, PSpace.x16),
                  itemCount: members.length,
                  itemBuilder: (_, i) {
                    final m = members[i];
                    final isSel = selected.contains(m.userRowId);
                    return CheckboxListTile(
                      value: isSel,
                      title: Text(m.userName),
                      subtitle: m.userEmail == null
                          ? null
                          : Text(m.userEmail!,
                              style: PTypo.caption
                                  .copyWith(color: t.fgTertiary)),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setSheetState(() {
                        if (v == true) {
                          selected.add(m.userRowId);
                        } else {
                          selected.remove(m.userRowId);
                        }
                        controller.setCanSubmit(selected.isNotEmpty);
                        controller.bump();
                      }),
                    );
                  },
                );
              },
            );
          });
        });
      },
      footerBuilder: (sheetCtx) => AnimatedBuilder(
        animation: controller,
        builder: (ctx, _) => Row(
          children: [
            const Spacer(),
            TextButton(
              onPressed: controller.submitting
                  ? null
                  : () => Navigator.of(ctx).pop(),
              child: const Text('취소'),
            ),
            const SizedBox(width: PSpace.x8),
            FilledButton(
              onPressed: controller.canSubmit && !controller.submitting
                  ? controller.onSubmit
                  : null,
              child: Text('${selected.length}명 추가'),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      // 빈 슬롯부터 채우고 부족하면 새 슬롯 추가.
      for (final m in picked!) {
        final empty = _participants.firstWhere(
          (p) => p.name.trim().isEmpty,
          orElse: () {
            final p = _Pname(name: '');
            _participants.add(p);
            return p;
          },
        );
        empty.name = m.userName;
      }
    });
  }

  Future<void> _submit() async {
    _setSubmitting(true);
    try {
      final repo = await ref.read(dutchPayRepositoryProvider.future);
      final names =
          _participants.where((p) => p.name.trim().isNotEmpty).toList();
      final n = names.length;
      List<({String? name, int? userRowId, int amount})> payload;
      if (_split == 'EQUAL') {
        final each = _total ~/ n;
        final rest = _total - each * n;
        payload = [
          for (int i = 0; i < n; i++)
            (
              name: names[i].name.trim(),
              userRowId: null,
              amount: i == 0 ? each + rest : each
            ),
        ];
      } else {
        payload = [
          for (final p in names)
            (name: p.name.trim(), userRowId: null, amount: p.amount),
        ];
      }
      await repo.create(
        title: _titleCtrl.text.trim(),
        totalAmount: _total,
        splitMethod: _split,
        dutchPayDate: _fmtDate(_date),
        sourceExpenseRowId: widget.fromExpense?.rowId,
        participants: payload,
      );
      ref.invalidate(dutchPayListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: ${e.message}')),
      );
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final sumCustom =
        _participants.fold<int>(0, (s, p) => s + p.amount);
    final remainder = _total - sumCustom;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(_canSubmit);
    });

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
          Text('제목',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(hintText: '예: 회식 더치페이'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PSpace.x12),

          Text('총 금액',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: PTypo.h3.copyWith(color: t.fgPrimary),
            decoration: const InputDecoration(hintText: '0'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PSpace.x12),

          Text('분할 방법',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x8),
          _SplitSeg(
              value: _split,
              onChanged: (v) => setState(() => _split = v),
              tokens: t),
          const SizedBox(height: PSpace.x12),

          Text('날짜',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (d != null) setState(() => _date = d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: t.bgMuted,
                borderRadius: PRadius.brMd,
                border: Border.all(color: t.borderDefault),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.calendar,
                      size: 16, color: t.fgSecondary),
                  const SizedBox(width: 6),
                  Text(_fmtDate(_date),
                      style: PTypo.bodySm
                          .copyWith(color: t.fgPrimary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: PSpace.x16),

          Row(
            children: [
              Text('참여자',
                  style: PTypo.caption.copyWith(
                      color: t.fgSecondary,
                      fontWeight: PFontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showSiblingPicker(context),
                icon: const Icon(LucideIcons.users, size: 14),
                label: const Text('멤버에서'),
              ),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _participants.add(_Pname(name: ''))),
                icon: const Icon(LucideIcons.plus, size: 14),
                label: const Text('추가'),
              ),
            ],
          ),
          if (_split == 'EQUAL' && _total > 0)
            Builder(builder: (_) {
              final n =
                  _participants.where((p) => p.name.trim().isNotEmpty).length;
              if (n < 2) return const SizedBox.shrink();
              final each = _total ~/ n;
              final rest = _total - each * n;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  rest == 0
                      ? '1인당 ${krw(each)}원'
                      : '1인당 ${krw(each)}원 (첫 사람 +${krw(rest)}원)',
                  style: PTypo.caption.copyWith(color: t.fgSecondary),
                ),
              );
            }),
          for (int i = 0; i < _participants.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: TextField(
                      decoration: InputDecoration(
                          hintText: '참여자 ${i + 1}', isDense: true),
                      controller: TextEditingController(text: _participants[i].name)
                        ..selection = TextSelection.collapsed(
                            offset: _participants[i].name.length),
                      onChanged: (v) => _participants[i].name = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_split == 'CUSTOM')
                    Expanded(
                      flex: 4,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(
                            hintText: '0', isDense: true, suffixText: '원'),
                        onChanged: (v) => setState(() {
                          _participants[i].amount = int.tryParse(v) ?? 0;
                        }),
                      ),
                    ),
                  if (_participants.length > 2)
                    IconButton(
                      onPressed: () =>
                          setState(() => _participants.removeAt(i)),
                      icon: Icon(LucideIcons.x,
                          size: 14, color: t.fgTertiary),
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                          width: 28, height: 28),
                    ),
                ],
              ),
            ),

          if (_split == 'CUSTOM' && _total > 0) ...[
            const SizedBox(height: PSpace.x8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: remainder == 0
                    ? t.statusSuccessSubtle
                    : t.statusDangerSubtle,
                borderRadius: PRadius.brSm,
              ),
              child: Text(
                remainder == 0
                    ? '합계 일치'
                    : (remainder > 0 ? '$remainder원 부족' : '${-remainder}원 초과'),
                style: PTypo.caption.copyWith(
                    color: remainder == 0
                        ? t.statusSuccessFg
                        : t.statusDangerFg,
                    fontWeight: PFontWeight.bold),
              ),
            ),
          ],
      ],
    );
  }
}

class _SplitSeg extends StatelessWidget {
  const _SplitSeg(
      {required this.value, required this.onChanged, required this.tokens});
  final String value;
  final ValueChanged<String> onChanged;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    const opts = [('EQUAL', 'N분의 1'), ('CUSTOM', '직접 입력')];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration:
          BoxDecoration(color: tokens.bgMuted, borderRadius: PRadius.brMd),
      child: Row(
        children: [
          for (final o in opts)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(o.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: o.$1 == value
                        ? tokens.bgSurface
                        : Colors.transparent,
                    borderRadius: PRadius.brSm,
                  ),
                  child: Text(o.$2,
                      textAlign: TextAlign.center,
                      style: PTypo.bodySm.copyWith(
                          color: o.$1 == value
                              ? tokens.fgPrimary
                              : tokens.fgTertiary,
                          fontWeight: o.$1 == value
                              ? PFontWeight.bold
                              : PFontWeight.medium)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
