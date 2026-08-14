import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_alert.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_empty_state.dart';
import 'package:porest_desk_app/features/sms/data/sms_android.dart';
import 'package:porest_desk_app/features/sms/domain/sms_paste_args.dart';

/// 아직 기록하지 않은 수신 결제 문자 목록 (안드로이드).
///
/// 알림만 있으면 사용자가 알림을 쓸어 지우는 순간 문자가 사라진다 — 나중에
/// "그거 뭐였지" 하고 찾을 방법이 없다. 받은 문자를 여기 쌓아 두고 나중에라도
/// 기록할 수 있게 한다.
///
/// 목록은 기기 안에만 있다. 서버로는 사용자가 확인 화면에서 저장할 때만 올라간다.
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
          if (entries != null && entries.isNotEmpty)
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
          padding: const EdgeInsets.all(PSpace.x16),
          children: [
            if (!_granted) ...[
              PAlert(
                title: l.smsPermissionOffTitle,
                description: l.smsPermissionOffDesc,
                variant: PAlertVariant.warning,
                action: PButton(
                  label: l.smsPermissionEnable,
                  size: PButtonSize.sm,
                  variant: PButtonVariant.secondary,
                  onPressed: _requestPermission,
                ),
              ),
              const SizedBox(height: PSpace.x16),
            ],
            // 카드사가 문자 대신 앱 푸시로 보내는 경우가 늘어 이쪽도 필요하다.
            // 문자 권한과 별개라 따로 안내한다.
            if (!_notiAccess) ...[
              PAlert(
                title: l.smsNotiAccessOffTitle,
                description: l.smsNotiAccessOffDesc,
                variant: PAlertVariant.info,
                action: PButton(
                  label: l.smsPermissionEnable,
                  size: PButtonSize.sm,
                  variant: PButtonVariant.secondary,
                  onPressed: SmsAndroid.openNotificationAccessSettings,
                ),
              ),
              const SizedBox(height: PSpace.x16),
            ],
            if (entries == null)
              const SizedBox.shrink()
            else if (entries.isEmpty)
              PEmptyState(
                icon: LucideIcons.messageSquare,
                message: l.smsInboxEmpty,
                subMessage: l.smsInboxEmptyDesc,
              )
            else
              for (final entry in entries) ...[
                _InboxTile(entry: entry, onOpen: _open, onRemove: _remove),
                const SizedBox(height: PSpace.x8),
              ],
          ],
        ),
      ),
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({
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

    return PCard(
      variant: PCardVariant.bordered,
      onTap: () => onOpen(entry),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('M/d HH:mm').format(entry.receivedAt),
                  style: PTypo.caption.copyWith(color: t.fgTertiary),
                ),
                const SizedBox(height: PSpace.x4),
                Text(
                  entry.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: PTypo.bodySm.copyWith(color: t.fgPrimary),
                ),
              ],
            ),
          ),
          PButton.icon(
            icon: LucideIcons.x,
            tooltip: l.smsInboxRemove,
            onPressed: () => onRemove(entry),
          ),
        ],
      ),
    );
  }
}
