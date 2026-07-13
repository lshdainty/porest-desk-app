import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_floating_action_button.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/features/dutch_pay/application/dutch_pay_providers.dart';
import 'package:porest_desk_app/features/dutch_pay/domain/dutch_pay.dart';
import 'package:porest_desk_app/features/dutch_pay/presentation/dutch_pay_create_dialog.dart';
import 'package:porest_desk_app/features/dutch_pay/presentation/dutch_pay_detail_sheet.dart';

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
    final l = AppLocalizations.of(context);
    final listAsync = ref.watch(dutchPayListProvider);
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;

    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.dutchTitle),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      floatingActionButton: PFloatingActionButton(
        icon: LucideIcons.plus,
        tooltip: l.dutchCreate,
        onPressed: () => showDutchPayCreateDialog(context),
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(dutchPayListProvider);
          await ref.read(dutchPayListProvider.future);
        },
        child: listAsync.when(
          loading: () => _DutchPaySkeleton(
            tokens: t,
            tab: _tab,
            onTabChanged: (v) => setState(() => _tab = v),
          ),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(PSpace.x16),
            children: [
              Text('${l.dutchLoadFailed}\n$e',
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
    final l = AppLocalizations.of(context);
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
          PSpace.x24, PSpace.x16, PSpace.x24, 96),
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

        // ── 탭 3종 (중립 세그 — container sm, 콘텐츠 너비) ──
        Align(
          alignment: Alignment.centerLeft,
          child: PTabs<_DutchTab>(
            value: _tab,
            onChanged: (v) => setState(() => _tab = v),
            variant: PTabsVariant.container,
            size: PTabsSize.sm,
            expand: false,
            items: [
              PTabItem(value: _DutchTab.active, label: '${l.dutchTabActive} · ${active.length}'),
              PTabItem(value: _DutchTab.past, label: '${l.dutchTabPast} · ${past.length}'),
              PTabItem(value: _DutchTab.friends, label: l.dutchTabFriends),
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
    final l = AppLocalizations.of(context);
    switch (_tab) {
      case _DutchTab.active:
        if (active.isEmpty) {
          return [
            _DutchEmpty(
              icon: LucideIcons.receipt,
              title: l.dutchEmptyActiveTitle,
              sub: l.dutchEmptyActiveSub,
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
            _DutchEmpty(
              icon: LucideIcons.checkCheck,
              title: l.dutchEmptyPastTitle,
              sub: l.dutchEmptyPastSub,
            ),
          ];
        }
        // 카드 다이어트 — 플랫 행 리듬 (구분선 없음).
        return [
          for (final dp in past)
            _PastRow(
              dp: dp,
              masked: masked,
              showDivider: false,
              onTap: () => _openDetail(dp),
            ),
        ];
      case _DutchTab.friends:
        if (friends.isEmpty) {
          return [
            _DutchEmpty(
              icon: LucideIcons.users,
              title: l.dutchEmptyFriendsTitle,
              sub: l.dutchEmptyFriendsSub,
            ),
          ];
        }
        // 카드 다이어트 — 플랫 행 리듬 (구분선 없음).
        return [
          for (final f in friends)
            _FriendRow(agg: f, masked: masked, showDivider: false),
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
      final l = AppLocalizations.of(context);
      showPSnackBar(context, '${l.dutchActionFailed}: ${e.message}',
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
      final l = AppLocalizations.of(context);
      showPSnackBar(context, '${l.dutchSettleFailed}: ${e.message}',
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
      final l = AppLocalizations.of(context);
      showPSnackBar(context, '${l.dutchDeleteFailed}: ${e.message}',
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
  return formatDay(DateTime(2000, m, d)).md;
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
    final l = AppLocalizations.of(context);
    final label = isReceive ? l.dutchToReceive : l.dutchToSend;
    final icon =
        isReceive ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight;
    final footer = isReceive ? l.dutchFromPeople(count) : l.dutchToPeople(count);

    // 요약 — design DutchScreen Hero keep(raised) 정합 (카드 다이어트 제외 대상).
    return PCard(
      variant: PCardVariant.raised,
      padding: const EdgeInsets.all(18),
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
                  wonUnit(),
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
    final l = AppLocalizations.of(context);
    final total = dp.participants.length;
    final paid = dp.participants.where((p) => p.isPaid).length;
    final progress = total == 0 ? 0.0 : paid / total;
    final perPerson = total == 0 ? 0 : dp.totalAmount ~/ total;
    final place = (dp.description ?? '').trim();
    final date = dutchKDate(dp.dutchPayDate);
    final sub = place.isEmpty ? date : '$place · $date';

    // 카드 다이어트 — design SessionCard(.p-card)는 모바일 플랫: 행 리듬(12/10)로.
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
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
                          text: wonUnit(),
                          style: PTypo.bodySm.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.bold,
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${l.dutchPerPersonLabel} ${krwSigned(perPerson, masked, unit: true, mask: '••••')}',
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
                // track + fill 양끝 round (웹 정합). 고정폭 _AvatarStack 덕에 바 길이 일정.
                child: Container(
                  height: 6,
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: t.bgSunken,
                    borderRadius: PRadius.brFull,
                  ),
                  child: FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    heightFactor: 1, // 없으면 fill 높이 0으로 collapse → 안 칠해짐
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.fgBrand,
                        borderRadius: PRadius.brFull,
                      ),
                    ),
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
      ),
    );
  }
}

/// 참여자 아바타 겹침 스택 — 28px, 최대 4개 고정폭(88), 미지불 dim.
/// 인원수 무관하게 폭 고정 → 진행바 길이 항상 동일. 5+면 3개 + +N 배지.
class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.participants});
  final List<DutchPayParticipant> participants;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    const max = 4; // 최대 4 슬롯 고정
    const size = 28.0;
    const step = 20.0; // 28 - 8 overlap
    const fixedWidth = size + step * (max - 1); // 88 — 고정폭(바 길이 일정)
    final overflow = participants.length > max;
    final shown =
        (overflow ? participants.take(max - 1) : participants.take(max)).toList();
    final extra = participants.length - shown.length;
    return SizedBox(
      width: fixedWidth,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: step * i,
              child: DutchAvatar(
                name: shown[i].participantName ?? '?',
                size: size,
                dimmed: !shown[i].isPaid,
                borderColor: t.bgSurface,
              ),
            ),
          if (extra > 0)
            Positioned(
              left: step * shown.length,
              child: Container(
                width: size,
                height: size,
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
    final l = AppLocalizations.of(context);
    final n = dp.participants.length;
    final date = dutchKDate(dp.dutchPayDate);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
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
                    n > 0 ? '$date · ${l.dutchNPeople(n)}' : date,
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
    final l = AppLocalizations.of(context);
    final settled = agg.net == 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
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
                  l.dutchSettledTogetherCount(agg.sessions),
                  style: PTypo.caption.copyWith(color: t.fgTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (settled)
            Text(
              l.dutchSettled,
              style: PTypo.caption.copyWith(color: t.fgTertiary),
            )
          else
            Text(
              krwSigned(agg.net, masked, sign: '+', unit: true),
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
  const _DutchPaySkeleton({
    required this.tokens,
    required this.tab,
    required this.onTabChanged,
  });
  final PorestTokens tokens;
  final _DutchTab tab;
  final ValueChanged<_DutchTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x24, PSpace.x16, PSpace.x24, 96),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // ── 요약 2카드 (데이터) — _SummaryCard 구조/shadow 정합 ──
        Row(
          children: const [
            Expanded(child: _SummaryCardSkeleton()),
            SizedBox(width: PSpace.sm),
            Expanded(child: _SummaryCardSkeleton()),
          ],
        ),
        const SizedBox(height: PSpace.md),

        // ── 탭 세그먼트 (정적 틀) — 실제 PTabs container sm 렌더 ──
        Align(
          alignment: Alignment.centerLeft,
          child: PTabs<_DutchTab>(
            value: tab,
            onChanged: onTabChanged,
            variant: PTabsVariant.container,
            size: PTabsSize.sm,
            expand: false,
            items: [
              PTabItem(value: _DutchTab.active, label: l.dutchTabActive),
              PTabItem(value: _DutchTab.past, label: l.dutchTabPast),
              PTabItem(value: _DutchTab.friends, label: l.dutchTabFriends),
            ],
          ),
        ),
        const SizedBox(height: PSpace.md),

        // ── 진행 중 탭 콘텐츠 (데이터) — _SessionCard 구조 정합 ──
        for (var i = 0; i < 3; i++) ...[
          const _SessionCardSkeleton(),
          if (i < 2) const SizedBox(height: PSpace.x12),
        ],
      ],
    );
  }
}

/// _SummaryCard placeholder — shadow surface(border 없음) + 아이콘박스/라벨/금액/푸터.
class _SummaryCardSkeleton extends StatelessWidget {
  const _SummaryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
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
              const PSkeleton(width: 28, height: 28),
              const SizedBox(width: 8),
              PSkeleton.line(width: 44, height: 13),
            ],
          ),
          const SizedBox(height: 10),
          PSkeleton.line(width: 88, height: 22),
          const SizedBox(height: 6),
          PSkeleton.line(width: 56, height: 11),
        ],
      ),
    );
  }
}

/// _SessionCard placeholder — 플랫 행(12/10) + 제목/금액 + 아바타스택/진행바/비율.
class _SessionCardSkeleton extends StatelessWidget {
  const _SessionCardSkeleton();

  @override
  Widget build(BuildContext context) {
    // 카드 다이어트 — 실제 _SessionCard 와 동일 플랫 리듬.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PSpace.x12, horizontal: 10),
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
                    const PSkeleton.line(width: 120),
                    const SizedBox(height: 4),
                    PSkeleton.line(width: 80, height: 13),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const PSkeleton.line(width: 72),
                  const SizedBox(height: 4),
                  PSkeleton.line(width: 56, height: 11),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              PSkeleton.circle(size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: PSkeleton(
                  height: 6,
                  borderRadius: PRadius.brFull,
                ),
              ),
              const SizedBox(width: 10),
              PSkeleton.line(width: 28, height: 13),
            ],
          ),
        ],
      ),
    );
  }
}
