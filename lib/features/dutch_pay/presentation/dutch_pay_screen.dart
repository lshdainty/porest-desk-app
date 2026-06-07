import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/chart_palette.dart';
import '../../../core/format/krw.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_floating_action_button.dart';
import '../../../shared/widgets/p_skeleton.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../application/dutch_pay_providers.dart';
import '../domain/dutch_pay.dart';
import 'dutch_pay_create_dialog.dart';
import 'dutch_pay_detail_sheet.dart';

/// 더치페이 — 토스 톤 요약 2카드 + 진행/완료/친구 탭 (web `DutchScreen` mobile 미러).
///
/// 모델은 기존 [DutchPay] 그대로 사용: 진행/완료=isSettled, 참여자=participants.
/// '받을 돈' = 미정산 세션의 미지불 참여자 amount 합. '보낼 돈' 데이터는 현행
/// 모델에 없어 0 처리(카드 구조만 유지). 데이터는 list() 1회 fetch 후 클라 집계.
class DutchPayScreen extends ConsumerStatefulWidget {
  const DutchPayScreen({super.key});
  @override
  ConsumerState<DutchPayScreen> createState() => _DutchPayScreenState();
}

/// 탭 3종 — 진행 중 / 완료 / 친구.
enum _DutchTab { active, past, friends }

class _DutchPayScreenState extends ConsumerState<DutchPayScreen> {
  _DutchTab _tab = _DutchTab.active;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final listAsync = ref.watch(dutchPayListProvider);
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: PButton.icon(
          icon: LucideIcons.arrowLeft,
          onPressed: () => context.pop(),
        ),
        title: const Text('더치페이'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      floatingActionButton: PFloatingActionButton(
        icon: LucideIcons.plus,
        tooltip: '정산 만들기',
        onPressed: () => showDutchPayCreateDialog(context),
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(dutchPayListProvider);
          await ref.read(dutchPayListProvider.future);
        },
        child: listAsync.when(
          loading: () => _DutchPaySkeleton(tokens: t),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(PSpace.x16),
            children: [
              Text('더치페이 로드 실패\n$e',
                  style: PTypo.bodySm.copyWith(color: t.statusDanger)),
            ],
          ),
          data: (items) => _buildBody(context, t, items, settings.hideAmounts),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PorestTokens t,
    List<DutchPay> items,
    bool masked,
  ) {
    final active = items.where((d) => !d.isSettled).toList()
      ..sort((a, b) =>
          (b.dutchPayDate ?? '').compareTo(a.dutchPayDate ?? ''));
    final past = items.where((d) => d.isSettled).toList()
      ..sort((a, b) =>
          (b.dutchPayDate ?? '').compareTo(a.dutchPayDate ?? ''));

    // ── 받을 돈: 미정산 세션의 미지불 참여자 amount 합 + 인원수 ──
    var owedToMe = 0;
    var owedCount = 0;
    for (final d in active) {
      for (final p in d.participants) {
        if (!p.isPaid) {
          owedToMe += p.amount;
          owedCount++;
        }
      }
    }
    // 보낼 돈 — 현행 모델에 데이터 없음(0 처리, 카드 구조만 유지).
    const iOwe = 0;
    const iOweCount = 0;

    // ── 친구 집계: participantName 기준 클라 집계 ──
    final friends = _aggregateFriends(items);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, PSpace.x16, PSpace.x16, 96),
      children: [
        // ── 요약 2카드 ──
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                kind: _SummaryKind.receive,
                amount: owedToMe,
                count: owedCount,
                masked: masked,
                t: t,
              ),
            ),
            const SizedBox(width: PSpace.sm),
            Expanded(
              child: _SummaryCard(
                kind: _SummaryKind.send,
                amount: iOwe,
                count: iOweCount,
                masked: masked,
                t: t,
              ),
            ),
          ],
        ),
        const SizedBox(height: PSpace.md),

        // ── 탭 3종 (중립 세그 — sunken 바 + active raised surface, 콘텐츠 너비) ──
        Align(
          alignment: Alignment.centerLeft,
          child: _DutchSegTabs(
            value: _tab,
            onChanged: (v) => setState(() => _tab = v),
            options: [
              (_DutchTab.active, '진행 중 · ${active.length}'),
              (_DutchTab.past, '완료 · ${past.length}'),
              (_DutchTab.friends, '친구'),
            ],
          ),
        ),
        const SizedBox(height: PSpace.md),

        // ── 탭별 콘텐츠 ──
        ..._buildTab(context, t, active, past, friends, masked),
      ],
    );
  }

  List<Widget> _buildTab(
    BuildContext context,
    PorestTokens t,
    List<DutchPay> active,
    List<DutchPay> past,
    List<_FriendAgg> friends,
    bool masked,
  ) {
    switch (_tab) {
      case _DutchTab.active:
        if (active.isEmpty) {
          return [
            const _DutchEmpty(
              icon: LucideIcons.receipt,
              title: '진행 중인 정산이 없어요',
              sub: '+ 버튼으로 새 정산을 만들어보세요.',
            ),
          ];
        }
        return [
          for (var i = 0; i < active.length; i++) ...[
            _SessionCard(
              dp: active[i],
              masked: masked,
              onTap: () => _openDetail(active[i]),
            ),
            if (i < active.length - 1) const SizedBox(height: PSpace.x12),
          ],
        ];
      case _DutchTab.past:
        if (past.isEmpty) {
          return [
            const _DutchEmpty(
              icon: LucideIcons.checkCheck,
              title: '완료된 정산이 없어요',
              sub: '정산을 마치면 여기에 모입니다.',
            ),
          ];
        }
        return [
          PCard(
            variant: PCardVariant.bordered,
            padding: const EdgeInsets.symmetric(horizontal: PSpace.x16),
            child: Column(
              children: [
                for (var i = 0; i < past.length; i++)
                  _PastRow(
                    dp: past[i],
                    masked: masked,
                    showDivider: i > 0,
                    onTap: () => _openDetail(past[i]),
                  ),
              ],
            ),
          ),
        ];
      case _DutchTab.friends:
        if (friends.isEmpty) {
          return [
            const _DutchEmpty(
              icon: LucideIcons.users,
              title: '함께 정산한 친구가 없어요',
              sub: '정산에 참여자를 추가하면 여기에 모입니다.',
            ),
          ];
        }
        return [
          PCard(
            variant: PCardVariant.bordered,
            padding: const EdgeInsets.symmetric(horizontal: PSpace.x16),
            child: Column(
              children: [
                for (var i = 0; i < friends.length; i++)
                  _FriendRow(
                    agg: friends[i],
                    masked: masked,
                    showDivider: i > 0,
                  ),
              ],
            ),
          ),
        ];
    }
  }

  void _openDetail(DutchPay dp) {
    showDutchPayDetailSheet(
      context,
      dpId: dp.rowId,
      onMarkPaid: (pid) => _markPaid(dp.rowId, pid),
      onSettle: () => _settle(dp.rowId),
      onDelete: () => _delete(dp),
    );
  }

  /// participantName(빈/null 제외) 기준 집계 — N회 함께 + 미지불 net.
  List<_FriendAgg> _aggregateFriends(List<DutchPay> items) {
    final map = <String, _FriendAgg>{};
    for (final d in items) {
      for (final p in d.participants) {
        final name = (p.participantName ?? '').trim();
        if (name.isEmpty) continue;
        final agg = map.putIfAbsent(name, () => _FriendAgg(name: name));
        agg.sessions++;
        // 미정산 세션의 미지불 참여자 amount = 그 친구가 내게 보낼(=내가 받을) 돈.
        if (!d.isSettled && !p.isPaid) agg.net += p.amount;
      }
    }
    final list = map.values.toList()
      ..sort((a, b) {
        if (a.net != b.net) return b.net.compareTo(a.net);
        return b.sessions.compareTo(a.sessions);
      });
    return list;
  }

  Future<void> _markPaid(int dpId, int pid) async {
    try {
      final repo = await ref.read(dutchPayRepositoryProvider.future);
      await repo.markPaid(dpId, pid);
      ref.invalidate(dutchPayListProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '실패: ${e.message}',
          severity: PSnackSeverity.error);
    }
  }

  Future<void> _settle(int id) async {
    try {
      final repo = await ref.read(dutchPayRepositoryProvider.future);
      await repo.settle(id);
      ref.invalidate(dutchPayListProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '정산 실패: ${e.message}',
          severity: PSnackSeverity.error);
    }
  }

  Future<void> _delete(DutchPay dp) async {
    try {
      final repo = await ref.read(dutchPayRepositoryProvider.future);
      await repo.delete(dp.rowId);
      ref.invalidate(dutchPayListProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '삭제 실패: ${e.message}',
          severity: PSnackSeverity.error);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// 친구 집계 모델
// ─────────────────────────────────────────────────────────────

class _FriendAgg {
  _FriendAgg({required this.name});
  final String name;
  int sessions = 0;
  int net = 0; // 그 친구에게서 받을 돈(미지불 amount 합). 보낼 데이터 없어 ≥0.
}

// ─────────────────────────────────────────────────────────────
// 날짜 포맷 — 'YYYY-MM-DD'(또는 datetime) → 'M월 D일'
// ─────────────────────────────────────────────────────────────

String dutchKDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final s = iso.length >= 10 ? iso.substring(0, 10) : iso;
  final parts = s.split('-');
  if (parts.length < 3) return iso;
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (m == null || d == null) return iso;
  return '$m월 $d일';
}

// ─────────────────────────────────────────────────────────────
// 중립 세그 탭 — sunken 바 위에 active 만 raised surface(bg-surface + shadow).
// brand 색을 쓰지 않는 중립 토글(클로드 더치페이 탭 미러). 콘텐츠 너비.
// ─────────────────────────────────────────────────────────────

class _DutchSegTabs extends StatelessWidget {
  const _DutchSegTabs({
    required this.value,
    required this.onChanged,
    required this.options,
  });
  final _DutchTab value;
  final ValueChanged<_DutchTab> onChanged;
  final List<(_DutchTab, String)> options;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.bgSunken,
        borderRadius: PRadius.brMd,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (tab, label) in options)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: tab == value ? t.bgSurface : Colors.transparent,
                  borderRadius: PRadius.brSm,
                  boxShadow: tab == value ? t.shadowSm : null,
                ),
                child: Text(
                  label,
                  style: PTypo.caption.copyWith(
                    color: tab == value ? t.fgPrimary : t.fgSecondary,
                    fontWeight: PFontWeight.semi,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 아바타 팔레트 — 이름 기반 chart 10색 순환 (라이트/다크 자동 swap).
// ─────────────────────────────────────────────────────────────

/// 이름을 안정적 인덱스로 해싱해 chart 10색 중 하나 반환.
Color dutchAvatarColor(BuildContext context, String name) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  var h = 0;
  for (final c in name.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  final pair = kChartPairs[h % kChartPairs.length];
  return isDark ? pair.light : pair.base;
}

/// 28/36/40px 원형 아바타 — 이름 첫 글자 + 팔레트 18% 틴트 배경.
class DutchAvatar extends StatelessWidget {
  const DutchAvatar({
    super.key,
    required this.name,
    this.size = 36,
    this.dimmed = false,
    this.borderColor,
  });
  final String name;
  final double size;
  final bool dimmed;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final color = dutchAvatarColor(context, name);
    final ch = name.trim().isEmpty
        ? '?'
        : name.trim().characters.first.toUpperCase();
    return Opacity(
      opacity: dimmed ? 0.5 : 1,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: borderColor == null
              ? null
              : Border.all(color: borderColor!, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          ch,
          style: PTypo.caption.copyWith(
            color: Colors.white,
            fontWeight: PFontWeight.bold,
            fontSize: size * 0.38,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 요약 2카드 — 받을 돈 / 보낼 돈
// ─────────────────────────────────────────────────────────────

enum _SummaryKind { receive, send }

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.kind,
    required this.amount,
    required this.count,
    required this.masked,
    required this.t,
  });
  final _SummaryKind kind;
  final int amount;
  final int count;
  final bool masked;
  final PorestTokens t;

  @override
  Widget build(BuildContext context) {
    final isReceive = kind == _SummaryKind.receive;
    final accent = isReceive ? t.statusSuccessFg : t.statusWarningFg;
    final chipTint = isReceive ? t.statusSuccessSubtle : t.statusWarningSubtle;
    final label = isReceive ? '받을 돈' : '보낼 돈';
    final icon =
        isReceive ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight;
    final footer = isReceive ? '$count명에게서' : '$count명에게';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: PRadius.brLg,
        boxShadow: t.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: chipTint,
                  borderRadius: PRadius.brSm,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 15, color: accent),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: PTypo.caption.copyWith(
                  color: t.fgTertiary,
                  fontWeight: PFontWeight.semi,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  krwMasked(amount, masked),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PTypo.h3.copyWith(
                    fontSize: 20,
                    color: accent,
                    fontWeight: PFontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (!masked) ...[
                const SizedBox(width: 1),
                Text(
                  '원',
                  style: PTypo.bodySm.copyWith(
                    color: accent,
                    fontWeight: PFontWeight.semi,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            footer,
            style: PTypo.micro.copyWith(color: t.fgTertiary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 진행 중 — SessionCard (아바타 스택 + 진행바)
// ─────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.dp,
    required this.masked,
    required this.onTap,
  });
  final DutchPay dp;
  final bool masked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final total = dp.participants.length;
    final paid = dp.participants.where((p) => p.isPaid).length;
    final progress = total == 0 ? 0.0 : paid / total;
    final perPerson = total == 0 ? 0 : dp.totalAmount ~/ total;
    final place = (dp.description ?? '').trim();
    final date = dutchKDate(dp.dutchPayDate);
    final sub = place.isEmpty ? date : '$place · $date';

    return PCard(
      variant: PCardVariant.bordered,
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dp.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PTypo.bodyLg.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.bold,
                        letterSpacing: -0.24,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PTypo.caption.copyWith(color: t.fgTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: krwMasked(dp.totalAmount, masked),
                        style: PTypo.bodyLg.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (!masked)
                        TextSpan(
                          text: '원',
                          style: PTypo.bodySm.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.bold,
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '1인 ${krwMasked(perPerson, masked, mask: '••••')}원',
                    style: PTypo.micro.copyWith(color: t.fgTertiary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _AvatarStack(participants: dp.participants),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: PRadius.brFull,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: t.bgSunken,
                    valueColor: AlwaysStoppedAnimation<Color>(t.fgBrand),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$paid/$total',
                style: PTypo.caption.copyWith(
                  color: t.fgSecondary,
                  fontWeight: PFontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 참여자 아바타 겹침 스택 — 28px, marginLeft -8, 미지불 dim.
class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.participants});
  final List<DutchPayParticipant> participants;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    const max = 4;
    final shown = participants.take(max).toList();
    final extra = participants.length - shown.length;
    return SizedBox(
      height: 28,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < shown.length; i++)
            Transform.translate(
              offset: Offset(i == 0 ? 0 : -8.0 * i, 0),
              child: DutchAvatar(
                name: shown[i].participantName ?? '?',
                size: 28,
                dimmed: !shown[i].isPaid,
                borderColor: t.bgSurface,
              ),
            ),
          if (extra > 0)
            Transform.translate(
              offset: Offset(-8.0 * shown.length, 0),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: t.bgSunken,
                  shape: BoxShape.circle,
                  border: Border.all(color: t.bgSurface, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$extra',
                  style: PTypo.micro.copyWith(
                    color: t.fgSecondary,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 완료 — PastRow
// ─────────────────────────────────────────────────────────────

class _PastRow extends StatelessWidget {
  const _PastRow({
    required this.dp,
    required this.masked,
    required this.showDivider,
    required this.onTap,
  });
  final DutchPay dp;
  final bool masked;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final n = dp.participants.length;
    final date = dutchKDate(dp.dutchPayDate);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: showDivider
            ? BoxDecoration(
                border: Border(top: BorderSide(color: t.borderSubtle)),
              )
            : null,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: t.statusSuccessSubtle,
                borderRadius: PRadius.brMd,
              ),
              alignment: Alignment.center,
              child: Icon(LucideIcons.check,
                  size: 16, color: t.statusSuccessFg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dp.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PTypo.body.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    n > 0 ? '$date · $n명' : date,
                    style: PTypo.caption.copyWith(color: t.fgTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              krwMasked(dp.totalAmount, masked),
              style: PTypo.body.copyWith(
                color: t.fgPrimary,
                fontWeight: PFontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 친구 — FriendRow
// ─────────────────────────────────────────────────────────────

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.agg,
    required this.masked,
    required this.showDivider,
  });
  final _FriendAgg agg;
  final bool masked;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final settled = agg.net == 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: showDivider
          ? BoxDecoration(
              border: Border(top: BorderSide(color: t.borderSubtle)),
            )
          : null,
      child: Row(
        children: [
          DutchAvatar(name: agg.name, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agg.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PTypo.body.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.semi,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${agg.sessions}회 정산 함께',
                  style: PTypo.caption.copyWith(color: t.fgTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (settled)
            Text(
              '정산 완료',
              style: PTypo.caption.copyWith(color: t.fgTertiary),
            )
          else
            Text(
              '+${krwMasked(agg.net, masked)}원',
              style: PTypo.body.copyWith(
                color: t.statusSuccessFg,
                fontWeight: PFontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 빈 상태 — 56px 원형 아이콘 + 문구 (메모/할일 패턴 정합).
// ─────────────────────────────────────────────────────────────

class _DutchEmpty extends StatelessWidget {
  const _DutchEmpty({
    required this.icon,
    required this.title,
    required this.sub,
  });
  final IconData icon;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: t.bgSunken,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: t.fgTertiary),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: PTypo.body.copyWith(
              fontSize: PFontSize.bodyMd,
              color: t.fgPrimary,
              fontWeight: PFontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: PTypo.bodySm.copyWith(color: t.fgTertiary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 로딩 skeleton
// ─────────────────────────────────────────────────────────────

class _DutchPaySkeleton extends StatelessWidget {
  const _DutchPaySkeleton({required this.tokens});
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, PSpace.x16, PSpace.x16, 96),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Row(
          children: [
            for (var i = 0; i < 2; i++) ...[
              Expanded(
                child: Container(
                  height: 96,
                  decoration: BoxDecoration(
                    color: t.bgSurface,
                    borderRadius: PRadius.brLg,
                    boxShadow: t.shadowSm,
                  ),
                ),
              ),
              if (i < 1) const SizedBox(width: PSpace.sm),
            ],
          ],
        ),
        const SizedBox(height: PSpace.md),
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: t.bgSunken,
            borderRadius: PRadius.brMd,
            border: Border.all(color: t.borderDefault),
          ),
        ),
        const SizedBox(height: PSpace.md),
        for (var i = 0; i < 3; i++) ...[
          PCard(
            variant: PCardVariant.bordered,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const PSkeleton.line(width: 120),
                          const SizedBox(height: 4),
                          PSkeleton.line(width: 80, height: 12),
                        ],
                      ),
                    ),
                    const PSkeleton.line(width: 72),
                  ],
                ),
                const SizedBox(height: 16),
                PSkeleton(
                  width: double.infinity,
                  height: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
          if (i < 2) const SizedBox(height: PSpace.x12),
        ],
      ],
    );
  }
}
