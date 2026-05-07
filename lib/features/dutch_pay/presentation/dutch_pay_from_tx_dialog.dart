import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/format/krw.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense.dart';
import '../../group/application/group_providers.dart';
import '../application/dutch_pay_providers.dart';

/// 거래 → 더치페이 시작 다이얼로그 (front `DutchPayFromTxDialog` 미러).
void showDutchPayFromTxDialog(BuildContext context, Expense expense) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor:
        Theme.of(context).extension<PorestTokens>()?.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) =>
          _Body(expense: expense, scrollController: scrollCtrl),
    ),
  );
}

enum _Split { equal, ratio, custom }

class _Participant {
  _Participant({
    required this.uid,
    required this.userRowId,
    required this.name,
    required this.isMe,
    this.customAmount = '',
    this.ratio = '1',
  });
  final String uid;
  int? userRowId;
  String name;
  final bool isMe;
  String customAmount;
  String ratio;
}

String _newUid() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

const List<String> _participantPaletteOklch = [
  'oklch(0.55 0.12 55)',
  'oklch(0.50 0.1 230)',
  'oklch(0.50 0.12 340)',
  'oklch(0.50 0.1 140)',
  'oklch(0.55 0.13 25)',
  'oklch(0.50 0.12 290)',
  'oklch(0.52 0.1 215)',
  'oklch(0.55 0.10 90)',
];

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.expense, required this.scrollController});
  final Expense expense;
  final ScrollController scrollController;
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  _Split _split = _Split.equal;
  bool _includeMyself = true;
  final List<_Participant> _others = [];
  final TextEditingController _manualNameCtrl = TextEditingController();
  final TextEditingController _msgCtrl = TextEditingController();
  late final String _expenseDay;
  late final String _expenseDateTime;
  bool _submitting = false;

  // 제어된 입력 컨트롤러 — Participant uid 별로 유지해 매 build 마다 cursor 안 튀게.
  final Map<String, TextEditingController> _amountCtrls = {};
  final Map<String, TextEditingController> _ratioCtrls = {};

  @override
  void initState() {
    super.initState();
    final raw = (widget.expense.expenseDate ?? '').trim();
    final day = raw.length >= 10 ? raw.substring(0, 10) : '';
    _expenseDay = day.isNotEmpty
        ? day
        : DateTime.now().toIso8601String().substring(0, 10);
    if (raw.length >= 16) {
      _expenseDateTime = raw.substring(0, 16).replaceFirst('T', ' ');
    } else {
      _expenseDateTime = _expenseDay;
    }
  }

  @override
  void dispose() {
    _manualNameCtrl.dispose();
    _msgCtrl.dispose();
    for (final c in _amountCtrls.values) {
      c.dispose();
    }
    for (final c in _ratioCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _totalAbs => widget.expense.amount.abs();

  String get _defaultTitle {
    final m = (widget.expense.merchant ?? '').trim();
    if (m.isNotEmpty) return m;
    final d = (widget.expense.description ?? '').trim();
    if (d.isNotEmpty) return d;
    return '더치페이';
  }

  List<_Participant> _composeParticipants(int? meRowId, String meName) {
    if (!_includeMyself) return List.unmodifiable(_others);
    final me = _Participant(
      uid: 'me',
      userRowId: meRowId,
      name: meName,
      isMe: true,
      ratio: '1',
    );
    return [me, ..._others];
  }

  int _perPerson(int total, int n) => n <= 0 ? 0 : total ~/ n;
  int _remainderEqual(int total, int n) => n <= 0 ? 0 : total - _perPerson(total, n) * n;

  int _computeAmount(
    List<_Participant> participants,
    int idx,
    _Participant p,
  ) {
    final n = participants.length;
    if (_split == _Split.equal) {
      final each = _perPerson(_totalAbs, n);
      final rest = _remainderEqual(_totalAbs, n);
      return idx == 0 ? each + rest : each;
    }
    if (_split == _Split.ratio) {
      final sum = participants.fold<double>(
          0, (s, q) => s + (double.tryParse(q.ratio) ?? 0));
      if (sum <= 0) return 0;
      final r = double.tryParse(p.ratio) ?? 0;
      return (_totalAbs * (r / sum)).round();
    }
    // CUSTOM
    if (p.isMe) {
      final othersTotal = _others.fold<int>(
          0, (s, q) => s + (int.tryParse(q.customAmount) ?? 0));
      final remain = _totalAbs - othersTotal;
      return remain < 0 ? 0 : remain;
    }
    return int.tryParse(p.customAmount) ?? 0;
  }

  TextEditingController _amountCtrlFor(_Participant p) {
    final c = _amountCtrls.putIfAbsent(
        p.uid, () => TextEditingController(text: p.customAmount));
    if (c.text != p.customAmount) {
      c.value = TextEditingValue(
        text: p.customAmount,
        selection: TextSelection.collapsed(offset: p.customAmount.length),
      );
    }
    return c;
  }

  TextEditingController _ratioCtrlFor(_Participant p) {
    final c = _ratioCtrls.putIfAbsent(
        p.uid, () => TextEditingController(text: p.ratio));
    if (c.text != p.ratio) {
      c.value = TextEditingValue(
        text: p.ratio,
        selection: TextSelection.collapsed(offset: p.ratio.length),
      );
    }
    return c;
  }

  void _addManual() {
    final name = _manualNameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _others.add(_Participant(
        uid: _newUid(),
        userRowId: null,
        name: name,
        isMe: false,
        customAmount: _perPerson(
                _totalAbs, _includeMyself ? _others.length + 2 : _others.length + 1)
            .toString(),
      ));
      _manualNameCtrl.clear();
    });
  }

  void _addFromSibling(int? userRowId, String name) {
    setState(() {
      _others.add(_Participant(
        uid: _newUid(),
        userRowId: userRowId,
        name: name,
        isMe: false,
        customAmount: _perPerson(
                _totalAbs, _includeMyself ? _others.length + 2 : _others.length + 1)
            .toString(),
      ));
    });
  }

  Future<void> _submit(List<_Participant> participants) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final repo = await ref.read(dutchPayRepositoryProvider.future);
      final amounts = [
        for (var i = 0; i < participants.length; i++)
          _computeAmount(participants, i, participants[i]),
      ];
      final method = switch (_split) {
        _Split.equal => 'EQUAL',
        _Split.ratio => 'RATIO',
        _Split.custom => 'CUSTOM',
      };
      await repo.create(
        title: _defaultTitle,
        description: _msgCtrl.text.trim().isEmpty ? null : _msgCtrl.text.trim(),
        totalAmount: _totalAbs,
        splitMethod: method,
        dutchPayDate: _expenseDay,
        sourceExpenseRowId: widget.expense.rowId,
        participants: [
          for (var i = 0; i < participants.length; i++)
            (
              name: participants[i].name.trim(),
              userRowId: participants[i].userRowId,
              amount: amounts[i],
            ),
        ],
      );
      ref.invalidate(dutchPayListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('더치페이가 생성되었습니다')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final e = widget.expense;
    final me = ref.watch(authProvider).value;
    final meName = me?.userName ?? '나';
    final meRowId = me?.rowId;
    final categoriesAsync = ref.watch(categoriesProvider);
    final cats = categoriesAsync.value ?? const [];
    final cat = e.categoryRowId == null
        ? null
        : cats.where((c) => c.rowId == e.categoryRowId).firstOrNull;
    final fg = cat == null
        ? t.fgBrand
        : parseColor(cat.color, fallback: t.fgBrand);
    final iconData = lucideByName(cat?.icon ?? 'tag');

    final siblingsAsync = ref.watch(siblingMembersProvider);
    final siblings = siblingsAsync.value ?? const [];
    final usedUserIds = _others
        .map((o) => o.userRowId)
        .whereType<int>()
        .toSet();
    final quickAdd = siblings
        .where((m) => !usedUserIds.contains(m.userRowId))
        .where((m) => m.userRowId != meRowId)
        .take(8)
        .toList();

    final participants = _composeParticipants(meRowId, meName);
    final amounts = [
      for (var i = 0; i < participants.length; i++)
        _computeAmount(participants, i, participants[i])
    ];
    final sum = amounts.fold<int>(0, (s, a) => s + a);
    final remainder = _totalAbs - sum;
    final matched = remainder == 0 && participants.isNotEmpty;
    final perPerson = _perPerson(_totalAbs, participants.length);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: t.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                PSpace.x16, PSpace.x12, PSpace.x8, PSpace.x4),
            child: Row(
              children: [
                Expanded(
                  child: Text('더치페이 시작',
                      style: PTypo.h3.copyWith(
                          color: t.fgPrimary,
                          fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  icon: Icon(LucideIcons.x, color: t.fgTertiary, size: 20),
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(
                  PSpace.x16, 0, PSpace.x16, PSpace.x16),
              children: [
                Text(
                  '이 거래를 기준으로 더치페이 정산을 만듭니다. 참여자에게 송금 요청을 보내고, 정산 진행 상황을 추적할 수 있어요.',
                  style: PTypo.bodySm.copyWith(
                      color: t.fgSecondary, height: 1.55),
                ),
                const SizedBox(height: 14),

                // Source card
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: t.bgSurface,
                    border: Border.all(color: t.borderSubtle),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: fg.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Icon(iconData, size: 18, color: fg),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_defaultTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: PTypo.bodySm.copyWith(
                                    color: t.fgPrimary,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(_expenseDateTime,
                                style: PTypo.caption
                                    .copyWith(color: t.fgTertiary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: krw(_totalAbs),
                            style: PTypo.body.copyWith(
                                color: t.fgPrimary,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace'),
                          ),
                          TextSpan(
                            text: '원',
                            style: PTypo.bodySm.copyWith(
                                color: t.fgPrimary,
                                fontWeight: FontWeight.w800),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 분배 방식
                _Section(
                  title: '분배 방식',
                  child: Row(
                    children: [
                      Expanded(
                        child: _SplitCard(
                          icon: LucideIcons.divide,
                          title: 'N분의 1',
                          subtitle: '균등 분배',
                          selected: _split == _Split.equal,
                          onTap: () => setState(() => _split = _Split.equal),
                          tokens: t,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SplitCard(
                          icon: LucideIcons.percent,
                          title: '비율',
                          subtitle: '인원수·기준',
                          selected: _split == _Split.ratio,
                          onTap: () => setState(() => _split = _Split.ratio),
                          tokens: t,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SplitCard(
                          icon: LucideIcons.listOrdered,
                          title: '개별 금액',
                          subtitle: '각자 다르게',
                          selected: _split == _Split.custom,
                          onTap: () =>
                              setState(() => _split = _Split.custom),
                          tokens: t,
                        ),
                      ),
                    ],
                  ),
                ),

                // 나도 포함
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _includeMyself = !_includeMyself),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: t.bgSurface,
                      border: Border.all(color: t.borderSubtle),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _includeMyself
                                ? t.borderBrand
                                : Colors.transparent,
                            border: Border.all(
                              color: _includeMyself
                                  ? t.borderBrand
                                  : t.borderDefault,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.center,
                          child: _includeMyself
                              ? const Icon(LucideIcons.check,
                                  size: 12, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('나도 포함해서 분배',
                              style: PTypo.bodySm.copyWith(
                                  color: t.fgPrimary,
                                  fontWeight: FontWeight.w700)),
                        ),
                        Text('내 몫도 계산됩니다',
                            style: PTypo.caption
                                .copyWith(color: t.fgTertiary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 참여자 헤더
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text('참여자',
                          style: PTypo.caption.copyWith(
                              color: t.fgSecondary,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 6),
                      Text('(${participants.length}명)',
                          style: PTypo.caption
                              .copyWith(color: t.fgTertiary)),
                    ],
                  ),
                ),

                // Participants list
                for (var i = 0; i < participants.length; i++) ...[
                  _ParticipantRow(
                    participant: participants[i],
                    index: i,
                    includeMyself: _includeMyself,
                    splitMethod: _split,
                    amount: amounts[i],
                    amountCtrl: _split == _Split.custom && !participants[i].isMe
                        ? _amountCtrlFor(participants[i])
                        : null,
                    ratioCtrl: _split == _Split.ratio && !participants[i].isMe
                        ? _ratioCtrlFor(participants[i])
                        : null,
                    onRemove: participants[i].isMe
                        ? null
                        : () => setState(() {
                              _others.removeWhere(
                                  (q) => q.uid == participants[i].uid);
                              _amountCtrls.remove(participants[i].uid)
                                  ?.dispose();
                              _ratioCtrls.remove(participants[i].uid)
                                  ?.dispose();
                            }),
                    onCustomChanged: (v) {
                      final cleaned = v.replaceAll(RegExp(r'[^0-9]'), '');
                      setState(() {
                        for (final o in _others) {
                          if (o.uid == participants[i].uid) {
                            o.customAmount = cleaned;
                          }
                        }
                      });
                    },
                    onRatioChanged: (v) {
                      final cleaned = v.replaceAll(RegExp(r'[^0-9.]'), '');
                      setState(() {
                        for (final o in _others) {
                          if (o.uid == participants[i].uid) o.ratio = cleaned;
                        }
                      });
                    },
                    tokens: t,
                  ),
                  if (i < participants.length - 1)
                    const SizedBox(height: 8),
                ],

                const SizedBox(height: 12),

                // 추가 input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualNameCtrl,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addManual(),
                        decoration: const InputDecoration(
                          hintText: '이름 입력 후 추가',
                          isDense: true,
                        ),
                        enabled: !_submitting,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : _addManual,
                      icon: const Icon(LucideIcons.userPlus, size: 14),
                      label: const Text('추가'),
                    ),
                  ],
                ),

                if (quickAdd.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < quickAdd.length; i++)
                        _QuickChip(
                          color: parseColor(
                              _participantPaletteOklch[i % _participantPaletteOklch.length],
                              fallback: t.fgBrand),
                          label: quickAdd[i].userName,
                          onTap: () => _addFromSibling(
                              quickAdd[i].userRowId, quickAdd[i].userName),
                          tokens: t,
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // 요청 메시지
                _Section(
                  title: '요청 메시지 (선택)',
                  child: TextField(
                    controller: _msgCtrl,
                    maxLines: 3,
                    minLines: 3,
                    decoration: const InputDecoration(
                      hintText: '참여자에게 함께 보낼 한마디를 적어주세요',
                    ),
                    enabled: !_submitting,
                  ),
                ),

                if (!matched && participants.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      remainder > 0
                          ? '합계가 총액보다 ${krw(remainder)}원 부족합니다.'
                          : '합계가 총액보다 ${krw(-remainder)}원 초과합니다.',
                      style: PTypo.caption.copyWith(color: t.statusDangerFg),
                    ),
                  ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.fromLTRB(
                PSpace.x12, PSpace.x8, PSpace.x12, PSpace.x12),
            decoration: BoxDecoration(
              color: t.bgSurface,
              border: Border(top: BorderSide(color: t.borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: '1인당 ',
                        style: PTypo.bodySm.copyWith(color: t.fgSecondary),
                      ),
                      TextSpan(
                        text: '${krw(perPerson)}원',
                        style: PTypo.bodySm.copyWith(
                            color: t.fgPrimary,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace'),
                      ),
                    ]),
                  ),
                ),
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 4),
                FilledButton.icon(
                  onPressed: matched && !_submitting
                      ? () => _submit(participants)
                      : null,
                  icon: _submitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.send, size: 14),
                  label: const Text('정산 만들기'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: PTypo.caption.copyWith(
                  color: t.fgSecondary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SplitCard extends StatelessWidget {
  const _SplitCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.tokens,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? tokens.bgBrandSubtle : tokens.bgSurface,
          border: Border.all(
            color:
                selected ? tokens.borderBrand : tokens.borderSubtle,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 14,
                    color: selected
                        ? tokens.fgBrandStrong
                        : tokens.fgPrimary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PTypo.bodySm.copyWith(
                          color: selected
                              ? tokens.fgBrandStrong
                              : tokens.fgPrimary,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle,
                style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
          ],
        ),
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.participant,
    required this.index,
    required this.includeMyself,
    required this.splitMethod,
    required this.amount,
    required this.amountCtrl,
    required this.ratioCtrl,
    required this.onRemove,
    required this.onCustomChanged,
    required this.onRatioChanged,
    required this.tokens,
  });
  final _Participant participant;
  final int index;
  final bool includeMyself;
  final _Split splitMethod;
  final int amount;
  final TextEditingController? amountCtrl;
  final TextEditingController? ratioCtrl;
  final VoidCallback? onRemove;
  final ValueChanged<String> onCustomChanged;
  final ValueChanged<String> onRatioChanged;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final palette = participant.isMe
        ? tokens.fgBrand
        : parseColor(
            _participantPaletteOklch[
                (index - (includeMyself ? 1 : 0) + _participantPaletteOklch.length) %
                    _participantPaletteOklch.length],
            fallback: tokens.fgBrand);
    final firstChar =
        participant.name.isEmpty ? '?' : participant.name.characters.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        border: Border.all(color: tokens.borderSubtle),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: palette.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(firstChar,
                style: PTypo.bodySm.copyWith(
                    color: palette, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(participant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PTypo.bodySm.copyWith(
                          color: tokens.fgPrimary,
                          fontWeight: FontWeight.w600)),
                ),
                if (participant.isMe) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: tokens.fgBrand.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('나',
                        style: PTypo.caption.copyWith(
                            color: tokens.fgBrand,
                            fontWeight: FontWeight.w700,
                            fontSize: 10)),
                  ),
                ],
              ],
            ),
          ),
          if (splitMethod == _Split.custom && !participant.isMe) ...[
            SizedBox(
              width: 110,
              child: TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: '0',
                  suffixText: '원',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onChanged: onCustomChanged,
              ),
            ),
          ] else if (splitMethod == _Split.custom && participant.isMe) ...[
            Text('${krw(amount)}원',
                style: PTypo.bodySm.copyWith(
                    color: tokens.fgPrimary,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace')),
          ] else if (splitMethod == _Split.ratio) ...[
            if (!participant.isMe) ...[
              SizedBox(
                width: 76,
                child: TextField(
                  controller: ratioCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: '1',
                    suffixText: '%',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onChanged: onRatioChanged,
                ),
              ),
              const SizedBox(width: 8),
            ],
            SizedBox(
              width: 80,
              child: Text('${krw(amount)}원',
                  textAlign: TextAlign.right,
                  style: PTypo.bodySm.copyWith(
                      color: tokens.fgPrimary,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace')),
            ),
          ] else ...[
            Text('${krw(amount)}원',
                style: PTypo.bodySm.copyWith(
                    color: tokens.fgPrimary,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace')),
          ],
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: Icon(LucideIcons.x, size: 14, color: tokens.fgTertiary),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              padding: EdgeInsets.zero,
            )
          else
            const SizedBox(width: 28, height: 28),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.color,
    required this.label,
    required this.onTap,
    required this.tokens,
  });
  final Color color;
  final String label;
  final VoidCallback onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: PRadius.brPill,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
        decoration: BoxDecoration(
          color: tokens.bgSurface,
          border: Border.all(color: tokens.borderSubtle),
          borderRadius: PRadius.brPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: PTypo.caption.copyWith(
                    color: tokens.fgPrimary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(LucideIcons.plus, size: 12, color: tokens.fgTertiary),
          ],
        ),
      ),
    );
  }
}
