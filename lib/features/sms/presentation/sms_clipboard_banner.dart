import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:porest_desk_app/core/storage/prefs_provider.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_alert.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/features/sms/data/clipboard_hint.dart';
import 'package:porest_desk_app/features/sms/domain/sms_prefilter.dart';

/// 홈 상단 — 복사한 결제 문자를 기록하도록 권하는 배너.
///
/// 문자를 복사해 놓고 앱을 열었을 때 "여기 붙여넣으세요" 를 찾아 헤매지 않게 한다.
/// 이 배너가 없으면 사용자는 더보기 메뉴까지 들어가야 한다.
///
/// **클립보드 내용은 여기서 읽지 않는다.** iOS 는 읽을 때마다 붙여넣기 배너를
/// 띄우므로, 띄울지 말지는 내용 접근이 없는 힌트로 판단하고([readClipboardHint])
/// 실제 읽기는 사용자가 눌렀을 때 한 번만 한다.
///
/// 안드로이드에서는 아무것도 그리지 않는다 — 힌트 API 가 없어 배너를 띄우려면
/// 내용을 읽어야 하고, 문자를 직접 수신할 수 있어 우회로가 필요 없다.
class SmsClipboardBanner extends ConsumerStatefulWidget {
  const SmsClipboardBanner({super.key});

  @override
  ConsumerState<SmsClipboardBanner> createState() => _SmsClipboardBannerState();
}

class _SmsClipboardBannerState extends ConsumerState<SmsClipboardBanner>
    with WidgetsBindingObserver {
  /// 지금 배너를 띄울 근거가 된 클립보드 상태. null 이면 배너를 그리지 않는다.
  int? _changeCount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshHint();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 문자 앱에서 복사하고 돌아오는 흐름이 가장 흔하다 — 돌아올 때마다 다시 본다.
    // 내용을 읽는 게 아니라 힌트만 보는 것이라 OS 배너는 뜨지 않는다.
    if (state == AppLifecycleState.resumed) _refreshHint();
  }

  Future<void> _refreshHint() async {
    final hint = await readClipboardHint();
    if (!mounted) return;

    if (hint == null || !hint.hasText) {
      if (_changeCount != null) setState(() => _changeCount = null);
      return;
    }
    // 사용자가 이미 닫은 복사본이면 다시 권하지 않는다.
    final prefs = await ref.read(prefsProvider.future);
    if (!mounted) return;
    final dismissed = prefs.getInt(_dismissedKey);
    final next = dismissed == hint.changeCount ? null : hint.changeCount;
    if (next != _changeCount) setState(() => _changeCount = next);
  }

  Future<void> _dismiss() async {
    final current = _changeCount;
    setState(() => _changeCount = null);
    if (current == null) return;
    final prefs = await ref.read(prefsProvider.future);
    await prefs.setInt(_dismissedKey, current);
  }

  /// 배너를 눌렀을 때 — 이때 처음으로 클립보드를 실제로 읽는다.
  Future<void> _open() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final text = data?.text;

    if (text == null || text.trim().isEmpty) {
      showPSnackBar(
        context,
        l.smsClipboardEmpty,
        severity: PSnackSeverity.warning,
      );
      await _dismiss();
      return;
    }
    // 결제 문자가 아니면 서버로 보내지 않는다 — 붙여넣기 화면에서 사용자가
    // 직접 고칠 수 있도록 원문은 들고 간다.
    if (!looksLikePaymentSms(text)) {
      showPSnackBar(
        context,
        l.smsNotRecognized,
        severity: PSnackSeverity.warning,
      );
      await _dismiss();
      return;
    }
    await _dismiss();
    if (!mounted) return;
    context.push('/sms-paste', extra: text);
  }

  @override
  Widget build(BuildContext context) {
    if (_changeCount == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PAlert(
        title: l.smsClipboardBannerTitle,
        description: l.smsClipboardBannerDesc,
        variant: PAlertVariant.info,
        onDismiss: _dismiss,
        action: PButton(
          label: l.smsClipboardBannerAction,
          size: PButtonSize.sm,
          variant: PButtonVariant.secondary,
          onPressed: _open,
        ),
      ),
    );
  }
}

/// 마지막으로 사용자가 닫은 클립보드 changeCount — 같은 복사본을 또 권하지 않으려고.
const String _dismissedKey = 'pd-sms-clip-dismissed';
