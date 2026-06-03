import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/format/chart_palette.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/p_badge.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_divider.dart';
import '../../../shared/widgets/p_dropdown_menu.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_skeleton.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../application/calendar_providers.dart';
import '../domain/user_calendar.dart';

/// 설정 진입 — 캘린더 관리·공유 (user_calendar 기반).
///
/// 개인 캘린더 자체를 공유 단위로: 생성(개인~공유)·이름/색 편집·삭제·공유(초대코드/멤버권한)를
/// 모두 이 화면에서 관리. 소유 = isOwner, 공유받음 = 그 외.
class CalendarShareScreen extends ConsumerWidget {
  const CalendarShareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final listAsync = ref.watch(userCalendarListProvider);

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: PButton.icon(
          icon: LucideIcons.arrowLeft,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('캘린더 관리·공유'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        actions: [
          PButton.icon(
            icon: LucideIcons.userPlus,
            tooltip: '초대 코드로 참여',
            onPressed: () => _showJoinDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(userCalendarListProvider);
          await ref.read(userCalendarListProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: PSpace.x20, vertical: PSpace.x24),
          children: [
            _IntroCard(tokens: t, onCreate: () => _showCreateDialog(context, ref)),
            const SizedBox(height: PSpace.x20),
            listAsync.when(
              loading: () => const PListSkeleton(rows: 4, showAvatar: true),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: PSpace.x16),
                child: Text('캘린더 로드 실패\n$e',
                    style: PTypo.bodySm.copyWith(color: t.statusDanger)),
              ),
              data: (calendars) => _CalendarSections(calendars: calendars, tokens: t),
            ),
            const SizedBox(height: PSpace.x16),
            _JoinCard(tokens: t, onJoin: () => _showJoinDialog(context, ref)),
            const SizedBox(height: PSpace.x32),
          ],
        ),
      ),
    );
  }
}

(String, PBadgeVariant, IconData) _roleStyle(String role) => switch (role) {
      'OWNER' => ('소유자', PBadgeVariant.outlineInfo, LucideIcons.crown),
      'EDIT' => ('편집 가능', PBadgeVariant.outlineSuccess, LucideIcons.pencil),
      _ => ('읽기 전용', PBadgeVariant.outline, LucideIcons.eye),
    };

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.tokens, required this.onCreate});
  final PorestTokens tokens;
  final VoidCallback onCreate;

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
            decoration: BoxDecoration(color: t.bgBrand, borderRadius: PRadius.brMd),
            alignment: Alignment.center,
            child: Icon(LucideIcons.users, size: 18, color: t.fgOnBrand),
          ),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('가족·친구와 일정 공유',
                    style: PTypo.bodySm.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.bold)),
                const SizedBox(height: 2),
                Text('캘린더를 만들고 멤버를 초대해 함께 일정을 관리할 수 있어요.',
                    style: PTypo.caption.copyWith(color: t.fgSecondary)),
              ],
            ),
          ),
          const SizedBox(width: PSpace.x8),
          PButton(
            label: '새 캘린더',
            icon: LucideIcons.plus,
            size: PButtonSize.sm,
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}

class _CalendarSections extends StatelessWidget {
  const _CalendarSections({required this.calendars, required this.tokens});
  final List<UserCalendar> calendars;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final owned = calendars.where((c) => c.isOwner).toList();
    final shared = calendars.where((c) => !c.isOwner).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(title: '내 캘린더 · ${owned.length}', tokens: t, calendars: owned, emptyText: '소유한 캘린더가 없어요'),
        const SizedBox(height: PSpace.x20),
        _Section(title: '공유받은 캘린더 · ${shared.length}', tokens: t, calendars: shared, emptyText: '공유받은 캘린더가 없어요'),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.tokens, required this.calendars, required this.emptyText});
  final String title;
  final PorestTokens tokens;
  final List<UserCalendar> calendars;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: PSpace.x8),
          child: Text(title, style: PTypo.bodySm.copyWith(color: t.fgPrimary, fontWeight: PFontWeight.bold)),
        ),
        if (calendars.isEmpty)
          PCard(
            variant: PCardVariant.shadow,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: PSpace.x20),
              child: Center(child: Text(emptyText, style: PTypo.bodySm.copyWith(color: t.fgTertiary))),
            ),
          )
        else
          PCard(
            variant: PCardVariant.shadow,
            child: Column(
              children: [
                for (int i = 0; i < calendars.length; i++) ...[
                  _CalendarRow(calendar: calendars[i], tokens: t),
                  if (i < calendars.length - 1) PDivider(indent: 56),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _CalendarRow extends ConsumerWidget {
  const _CalendarRow({required this.calendar, required this.tokens});
  final UserCalendar calendar;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = tokens;
    final color = resolveChartColor(context, calendar.color, fallback: t.fgBrand);
    final (roleLabel, roleVariant, _) = _roleStyle(calendar.myRole);
    return InkWell(
      onTap: () => _showManageSheet(context, ref, calendar),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: PSpace.x16, vertical: PSpace.x12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: softBg(context, color), borderRadius: PRadius.brMd),
              alignment: Alignment.center,
              child: Icon(LucideIcons.calendar, size: 18, color: color),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(calendar.calendarName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PTypo.body.copyWith(color: t.fgPrimary, fontWeight: PFontWeight.semi)),
                      ),
                      if (calendar.isDefault) ...[
                        const SizedBox(width: 6),
                        const PBadge(label: '기본', variant: PBadgeVariant.secondary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(calendar.memberCount <= 1 ? '나만 사용' : '멤버 ${calendar.memberCount}명',
                      style: PTypo.caption.copyWith(color: t.fgTertiary)),
                ],
              ),
            ),
            if (!calendar.isOwner)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: PBadge(label: roleLabel, variant: roleVariant),
              ),
            Icon(LucideIcons.chevronRight, size: 16, color: t.fgTertiary),
          ],
        ),
      ),
    );
  }
}

class _JoinCard extends StatelessWidget {
  const _JoinCard({required this.tokens, required this.onJoin});
  final PorestTokens tokens;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return PCard(
      variant: PCardVariant.shadow,
      padding: const EdgeInsets.all(PSpace.x16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: t.bgMuted, borderRadius: PRadius.brMd),
            alignment: Alignment.center,
            child: Icon(LucideIcons.link, size: 18, color: t.fgSecondary),
          ),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('초대 코드로 참여',
                    style: PTypo.bodySm.copyWith(color: t.fgPrimary, fontWeight: PFontWeight.bold)),
                const SizedBox(height: 2),
                Text('공유받은 초대 코드를 입력해 캘린더에 참여하세요.',
                    style: PTypo.caption.copyWith(color: t.fgSecondary)),
              ],
            ),
          ),
          const SizedBox(width: PSpace.x8),
          PButton(label: '참여', variant: PButtonVariant.secondary, size: PButtonSize.sm, onPressed: onJoin),
        ],
      ),
    );
  }
}

// ─── 새 캘린더 만들기 ────────────────────────────────────────

void _showCreateDialog(BuildContext context, WidgetRef ref) {
  final nameCtrl = TextEditingController();
  final controller = PSheetController();
  var selectedColor = '#2c70bf';

  Future<void> submit() async {
    if (nameCtrl.text.trim().isEmpty) return;
    controller.setSubmitting(true);
    try {
      final repo = await ref.read(userCalendarRepositoryProvider.future);
      await repo.create(calendarName: nameCtrl.text.trim(), color: selectedColor);
      ref.invalidate(userCalendarListProvider);
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      showPSnackBar(context, '실패: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      controller.setSubmitting(false);
    }
  }

  controller.onSubmit = submit;

  showPSheet<void>(
    context,
    title: '새 캘린더',
    contentBuilder: (ctx, scrollCtrl) {
      final t = ctx.tokens;
      return StatefulBuilder(
        builder: (ctx, setSheet) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(PSpace.x16, 0, PSpace.x16, PSpace.x16),
          children: [
            Text('이름', style: PTypo.caption.copyWith(color: t.fgSecondary)),
            const SizedBox(height: PSpace.x4),
            PTextInput(
              controller: nameCtrl,
              placeholder: '예: 가족, 업무, 운동 일정',
              onChanged: (v) => controller.setCanSubmit(v.trim().isNotEmpty),
            ),
            const SizedBox(height: PSpace.x12),
            Text('색상', style: PTypo.caption.copyWith(color: t.fgSecondary)),
            const SizedBox(height: PSpace.x8),
            _ColorSwatchRow(selected: selectedColor, onSelect: (hex) => setSheet(() => selectedColor = hex)),
          ],
        ),
      );
    },
    footerBuilder: (ctx) => PSheetFooter(controller: controller, submitLabel: '만들기'),
  );
}

// ─── 초대 코드로 참여 ───────────────────────────────────────

void _showJoinDialog(BuildContext context, WidgetRef ref) {
  final codeCtrl = TextEditingController();
  final controller = PSheetController();

  Future<void> submit() async {
    if (codeCtrl.text.trim().isEmpty) return;
    controller.setSubmitting(true);
    try {
      final repo = await ref.read(userCalendarRepositoryProvider.future);
      final joined = await repo.joinByCode(codeCtrl.text.trim().toUpperCase());
      ref.invalidate(userCalendarListProvider);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      showPSnackBar(context, '"${joined.calendarName}" 캘린더에 참여했어요', severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      showPSnackBar(context, '참여 실패: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      controller.setSubmitting(false);
    }
  }

  controller.onSubmit = submit;

  showPSheet<void>(
    context,
    title: '초대 코드로 참여',
    contentBuilder: (ctx, scrollCtrl) {
      final t = ctx.tokens;
      return ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(PSpace.x16, 0, PSpace.x16, PSpace.x16),
        children: [
          Text('초대 코드', style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: codeCtrl,
            placeholder: '예: ABC123',
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))],
            onChanged: (v) => controller.setCanSubmit(v.trim().isNotEmpty),
          ),
        ],
      );
    },
    footerBuilder: (ctx) => PSheetFooter(controller: controller, submitLabel: '참여'),
  );
}

// ─── 관리 (편집/공유/멤버/삭제) ──────────────────────────────

void _showManageSheet(BuildContext context, WidgetRef ref, UserCalendar calendar) {
  showPSheet<void>(
    context,
    title: '${calendar.calendarName} · 관리',
    contentBuilder: (ctx, scrollCtrl) => _ManageBody(calendar: calendar, scrollController: scrollCtrl),
  );
}

class _ManageBody extends ConsumerStatefulWidget {
  const _ManageBody({required this.calendar, required this.scrollController});
  final UserCalendar calendar;
  final ScrollController scrollController;

  @override
  ConsumerState<_ManageBody> createState() => _ManageBodyState();
}

class _ManageBodyState extends ConsumerState<_ManageBody> {
  late final TextEditingController _nameCtrl;
  late String _color;
  bool _saving = false;

  UserCalendar get cal => widget.calendar;
  bool get isOwner => cal.isOwner;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: cal.calendarName);
    _color = cal.color ?? '#2c70bf';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveMeta() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final repo = await ref.read(userCalendarRepositoryProvider.future);
      await repo.update(id: cal.rowId, calendarName: _nameCtrl.text.trim(), color: _color);
      ref.invalidate(userCalendarListProvider);
      if (mounted) showPSnackBar(context, '캘린더를 수정했어요', severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (mounted) showPSnackBar(context, '실패: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _regenerate() async {
    try {
      final repo = await ref.read(userCalendarRepositoryProvider.future);
      await repo.regenerateInviteCode(cal.rowId);
      ref.invalidate(userCalendarListProvider);
      if (mounted) showPSnackBar(context, '초대 코드를 새로 만들었어요', severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (mounted) showPSnackBar(context, '실패: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: cal.inviteCode ?? ''));
    if (mounted) showPSnackBar(context, '초대 코드를 복사했어요', severity: PSnackSeverity.success);
  }

  Future<void> _changeRole(CalendarMember member, String permission) async {
    try {
      final repo = await ref.read(userCalendarRepositoryProvider.future);
      await repo.changeMemberRole(cal.rowId, member.rowId, permission);
      ref.invalidate(calendarMembersProvider(cal.rowId));
      ref.invalidate(userCalendarListProvider);
    } on ApiException catch (e) {
      if (mounted) showPSnackBar(context, '실패: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  Future<void> _removeMember(CalendarMember member) async {
    final ok = await showPConfirmDialog(
      context,
      title: '멤버 내보내기',
      message: '${member.userName} 님을 캘린더에서 내보내시겠어요?',
      confirmLabel: '내보내기',
      destructive: true,
    );
    if (!ok) return;
    try {
      final repo = await ref.read(userCalendarRepositoryProvider.future);
      await repo.removeMember(cal.rowId, member.rowId);
      ref.invalidate(calendarMembersProvider(cal.rowId));
      ref.invalidate(userCalendarListProvider);
    } on ApiException catch (e) {
      if (mounted) showPSnackBar(context, '실패: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  Future<void> _delete() async {
    final ok = await showPConfirmDialog(
      context,
      title: '캘린더 삭제',
      message: '"${cal.calendarName}" 캘린더를 삭제하시겠어요? 일정은 기본 캘린더로 이동하고 모든 멤버의 접근 권한이 사라집니다.',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!ok) return;
    try {
      final repo = await ref.read(userCalendarRepositoryProvider.future);
      await repo.delete(cal.rowId);
      ref.invalidate(userCalendarListProvider);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) showPSnackBar(context, '삭제 실패: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final membersAsync = ref.watch(calendarMembersProvider(cal.rowId));
    final myId = ref.watch(authProvider).value?.rowId;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
        if (isOwner) ...[
          Text('이름', style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          PTextInput(controller: _nameCtrl, placeholder: '캘린더 이름', onChanged: (_) => setState(() {})),
          const SizedBox(height: PSpace.x12),
          Text('색상', style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x8),
          _ColorSwatchRow(selected: _color, onSelect: (hex) => setState(() => _color = hex)),
          const SizedBox(height: PSpace.x12),
          Align(
            alignment: Alignment.centerLeft,
            child: PButton(
              label: '변경 저장',
              size: PButtonSize.sm,
              variant: PButtonVariant.accent,
              onPressed: (_saving ||
                      (_nameCtrl.text.trim() == cal.calendarName && _color == (cal.color ?? '#2c70bf')))
                  ? null
                  : _saveMeta,
            ),
          ),
          const SizedBox(height: PSpace.x16),
          Text('초대 코드', style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          Row(
            children: [
              Expanded(
                child: PTextInput(
                  controller: TextEditingController(text: cal.inviteCode ?? ''),
                  enabled: false,
                ),
              ),
              const SizedBox(width: PSpace.x8),
              PButton.icon(icon: LucideIcons.copy, tooltip: '복사', onPressed: _copyCode),
              PButton.icon(icon: LucideIcons.refreshCw, tooltip: '재생성', onPressed: _regenerate),
            ],
          ),
          const SizedBox(height: PSpace.x16),
        ],
        Text('멤버', style: PTypo.caption.copyWith(color: t.fgSecondary)),
        const SizedBox(height: PSpace.x8),
        membersAsync.when(
          loading: () => const PListSkeleton(rows: 2, showAvatar: true),
          error: (e, _) => Text('멤버 로드 실패', style: PTypo.caption.copyWith(color: t.statusDanger)),
          data: (members) => Column(
            children: [
              for (final m in members)
                _MemberRow(
                  member: m,
                  tokens: t,
                  isMe: m.userRowId == myId,
                  canManage: isOwner && m.permission != 'OWNER' && m.userRowId != myId,
                  onChangeRole: (perm) => _changeRole(m, perm),
                  onRemove: () => _removeMember(m),
                ),
            ],
          ),
        ),
        if (isOwner && !cal.isDefault) ...[
          const SizedBox(height: PSpace.x16),
          PButton(
            label: '캘린더 삭제',
            icon: LucideIcons.trash2,
            variant: PButtonVariant.secondary,
            dangerous: true,
            onPressed: _delete,
          ),
        ],
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.tokens,
    required this.isMe,
    required this.canManage,
    required this.onChangeRole,
    required this.onRemove,
  });
  final CalendarMember member;
  final PorestTokens tokens;
  final bool isMe;
  final bool canManage;
  final void Function(String permission) onChangeRole;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final (roleLabel, roleVariant, roleIcon) = _roleStyle(member.permission);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PSpace.x8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: roleVariant == PBadgeVariant.outline ? t.bgSunken : softBg(context, _roleColor(context, member.permission)),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(roleIcon, size: 16, color: _roleColor(context, member.permission)),
          ),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(member.userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: PTypo.body.copyWith(color: t.fgPrimary, fontWeight: PFontWeight.semi))),
                    if (isMe) ...[const SizedBox(width: 6), Text('(나)', style: PTypo.caption.copyWith(color: t.fgTertiary))],
                  ],
                ),
                if ((member.userEmail ?? '').isNotEmpty)
                  Text(member.userEmail!, maxLines: 1, overflow: TextOverflow.ellipsis, style: PTypo.caption.copyWith(color: t.fgTertiary)),
              ],
            ),
          ),
          if (canManage)
            PDropdownMenu(
              iconColor: t.fgTertiary,
              entries: [
                if (member.permission != 'EDIT')
                  PDropdownItem(label: '편집 가능으로', onTap: () => onChangeRole('EDIT')),
                if (member.permission != 'READ')
                  PDropdownItem(label: '읽기 전용으로', onTap: () => onChangeRole('READ')),
                PDropdownItem(label: '내보내기', onTap: onRemove, destructive: true),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: PBadge(label: roleLabel, variant: roleVariant),
            ),
        ],
      ),
    );
  }

  Color _roleColor(BuildContext context, String role) {
    final t = context.tokens;
    return switch (role) {
      'OWNER' => t.statusInfo,
      'EDIT' => t.statusSuccess,
      _ => t.fgTertiary,
    };
  }
}

class _ColorSwatchRow extends StatelessWidget {
  const _ColorSwatchRow({required this.selected, required this.onSelect});
  final String selected;
  final void Function(String hex) onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Wrap(
      spacing: PSpace.x8,
      runSpacing: PSpace.x8,
      children: [
        for (final p in kChartPairs)
          GestureDetector(
            onTap: () => onSelect(p.baseHex),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: p.base,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == p.baseHex ? t.fgPrimary : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
