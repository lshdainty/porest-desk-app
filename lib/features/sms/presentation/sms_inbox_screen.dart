import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_alert.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_swipe_actions.dart';
import 'package:porest_desk_app/shared/widgets/p_empty_state.dart';
import 'package:porest_desk_app/features/sms/data/sms_android.dart';
import 'package:porest_desk_app/features/sms/domain/sms_paste_args.dart';
import 'package:porest_desk_app/features/sms/domain/sms_preview.dart';

/// 아직 기록하지 않은 결제 알림 목록 (안드로이드).
///
/// 알림만 있으면 사용자가 알림을 쓸어 지우는 순간 내용이 사라진다 — 나중에
/// "그거 뭐였지" 하고 찾을 방법이 없다. 받은 것을 여기 쌓아 두고 나중에라도
/// 기록할 수 있게 한다.
///
/// 목록은 기기 안에만 있다. 서버로는 사용자가 확인 화면에서 저장할 때만 올라간다.
///
/// 목록에 보이는 금액·가맹점은 로컬에서 가볍게 훑은 미리보기다([SmsPreview]) —
/// 정확한 파싱은 항목을 눌러 확인 화면으로 갈 때 서버가 한다.
class SmsInboxScreen extends ConsumerStatefulWidget {
  const SmsInboxScreen({super.key});

  @override
  ConsumerState<SmsInboxScreen> createState() => _SmsInboxScreenState();
}

class _SmsInboxScreenState extends ConsumerState<SmsInboxScreen>
    with WidgetsBindingObserver {
  List<SmsInboxEntry>? _entries;
  bool _granted = true;
  bool _notiAccess = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 알림 접근은 설정 앱에 다녀와야 켜진다 — 돌아오면 상태를 다시 읽는다.
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final granted = await SmsAndroid.hasPermissions();
    final notiAccess = await SmsAndroid.hasNotificationAccess();
    final entries = await SmsAndroid.inbox();
    if (!mounted) return;
    setState(() {
      _granted = granted;
      _notiAccess = notiAccess;
      _entries = entries;
    });
  }

  Future<void> _remove(SmsInboxEntry entry) async {
    await SmsAndroid.removeFromInbox(entry.id);
    await _load();
  }

  Future<void> _clear() async {
    await SmsAndroid.clearInbox();
    await _load();
  }

  Future<void> _open(SmsInboxEntry entry) async {
    // 기록에 성공하면 저장 쪽에서 이 항목을 빼 준다. 여기서 미리 지우면
    // 사용자가 시트를 닫고 나왔을 때 문자가 사라져 있다.
    await context.push('/sms-paste',
        extra: SmsPasteArgs(text: entry.text, inboxId: entry.id));
    if (mounted) await _load();
  }

  Future<void> _requestPermission() async {
    await SmsAndroid.requestPermissions();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final entries = _entries;
    final hasEntries = entries != null && entries.isNotEmpty;

    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.smsInboxTitle),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        actions: [
          if (hasEntries)
            PButton(
              label: l.smsInboxClear,
              variant: PButtonVariant.ghost,
              size: PButtonSize.sm,
              onPressed: _clear,
            ),
        ],
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              PSpace.x24, PSpace.x16, PSpace.x24, PSpace.x24),
          children: [
            // 알림 접근이 이 기능의 유일한 스위치다 — 카드사·은행 앱 푸시도,
            // 결제 문자도 전부 이 경로로 읽는다. 꺼져 있으면 아무것도 안 들어온다.
            if (!_notiAccess) ...[
              PAlert(
                title: l.smsNotiAccessOffTitle,
                description: l.smsNotiAccessOffDesc,
                variant: PAlertVariant.warning,
                action: PButton(
                  label: l.smsPermissionEnable,
                  size: PButtonSize.sm,
                  variant: PButtonVariant.secondary,
                  onPressed: SmsAndroid.openNotificationAccessSettings,
                ),
              ),
              const SizedBox(height: PSpace.x16),
            ],
            // 알림 권한은 없어도 감지는 된다(수신함에 쌓인다) — 알림으로 바로
            // 기록하러 가는 동선만 빠지므로 경고가 아니라 안내로 둔다.
            if (_notiAccess && !_granted) ...[
              PAlert(
                title: l.smsPermissionOffTitle,
                description: l.smsPermissionOffDesc,
                variant: PAlertVariant.info,
                action: PButton(
                  label: l.smsPermissionEnable,
                  size: PButtonSize.sm,
                  variant: PButtonVariant.secondary,
                  onPressed: _requestPermission,
                ),
              ),
              const SizedBox(height: PSpace.x16),
            ],
            if (entries == null)
              const SizedBox.shrink()
            else if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: PSpace.x32),
                child: PEmptyState(
                  icon: LucideIcons.creditCard,
                  message: l.smsInboxEmpty,
                  subMessage: l.smsInboxEmptyDesc,
                ),
              )
            else
              ..._buildGrouped(context, entries),
          ],
        ),
      ),
    );
  }

  /// 날짜별로 묶어 헤더 아래 행을 늘어놓는다(가계부 목록과 같은 리듬).
  List<Widget> _buildGrouped(BuildContext context, List<SmsInboxEntry> entries) {
    final l = AppLocalizations.of(context);
    final widgets = <Widget>[];
    String? lastKey;
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final key = DateFormat('yyyy-MM-dd').format(entry.receivedAt);
      if (key != lastKey) {
        if (lastKey != null) widgets.add(const SizedBox(height: PSpace.x20));
        widgets.add(_DateHeader(date: entry.receivedAt));
        widgets.add(const SizedBox(height: PSpace.x4));
        lastKey = key;
      }
      widgets.add(PSwipeActions(
        key: ValueKey(entry.id),
        groupTag: 'sms-inbox',
        actions: [
          PSwipeAction(
            label: l.actionDelete,
            icon: LucideIcons.trash2,
            kind: PSwipeKind.destructive,
            confirmMessage: l.smsInboxRemoveConfirm,
            onSelect: () => _remove(entry),
          ),
        ],
        child: _InboxRow(entry: entry, onOpen: _open, onRemove: _remove),
      ));
    }
    return widgets;
  }
}

/// 날짜 그룹 헤더 — "8월 17일 (월)".
class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final locale = Localizations.localeOf(context).languageCode;
    final label = locale == 'en'
        ? DateFormat('EEE, MMM d', 'en').format(date)
        : DateFormat('M월 d일 (E)', 'ko').format(date);
    return Padding(
      // 날짜 헤더도 행과 같은 지점(페이지 여백 24)에서 시작한다.
      padding: const EdgeInsets.symmetric(vertical: PSpace.x4),
      child: Text(
        label,
        style: PTypo.caption.copyWith(
          color: t.fgTertiary,
          fontWeight: PFontWeight.semi,
        ),
      ),
    );
  }
}

/// 결제 알림 한 건 — 아이콘 + 가맹점 + (발신기관·시각) + 금액.
///
/// 가계부 행(`PExpenseRow`)과 같은 시각 언어를 쓴다. 다만 아직 카테고리가 없어
/// 아이콘은 결제 수단(카드)으로 고정한다. 금액·가맹점은 로컬 미리보기라
/// 못 읽을 수 있고, 그때는 원문 축약으로 대신한다.
class _InboxRow extends StatelessWidget {
  const _InboxRow({
    required this.entry,
    required this.onOpen,
    required this.onRemove,
  });

  final SmsInboxEntry entry;
  final Future<void> Function(SmsInboxEntry) onOpen;
  final Future<void> Function(SmsInboxEntry) onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final preview = SmsPreview.of(entry.text);

    // 제목 = 가맹점. 못 읽으면 원문 첫 줄로 대신한다(빈 자리보다 낫다).
    final title = preview.merchant ?? _firstLine(entry.text);
    final sub = [preview.issuer, DateFormat('HH:mm').format(entry.receivedAt)]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' · ');

    return InkWell(
      onTap: () => onOpen(entry),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        // 좌우는 페이지가 쥔다(24). 행은 상하만 갖는다.
        padding: const EdgeInsets.symmetric(vertical: PSpace.x12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: t.bgBrandSubtle, borderRadius: PRadius.tile(40)),
              alignment: Alignment.center,
              child: Icon(LucideIcons.creditCard, size: 18, color: t.fgBrand),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: PTypo.body.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.semi,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: PTypo.caption.copyWith(color: t.fgTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: PSpace.x8),
            if (preview.amount != null)
              Text(
                krwSigned(preview.amount!, false, sign: '-', unit: true),
                style: PTypo.body.copyWith(
                  color: t.fgExpense,
                  fontWeight: PFontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            // 삭제 — 기록하지 않고 목록에서만 치운다.
            PButton.icon(
              icon: LucideIcons.x,
              size: PButtonSize.sm,
              iconColor: t.fgTertiary,
              tooltip: l.smsInboxRemove,
              onPressed: () => onRemove(entry),
            ),
          ],
        ),
      ),
    );
  }

  String _firstLine(String text) {
    final line = text
        .replaceAll('[Web발신]', '')
        .split(RegExp(r'\R'))
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => text.trim());
    return line.length > 40 ? '${line.substring(0, 40)}…' : line;
  }
}
