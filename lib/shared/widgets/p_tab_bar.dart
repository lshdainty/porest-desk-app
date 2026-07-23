import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/motion.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';

/// iOS 26+ Liquid Glass 플로팅 하단 네비 — 웹 shared/ui/porest/tabbar.tsx 미러.
/// design chrome.jsx MTabBar / app.css .m-tabbar SoT.
///
/// 규칙:
/// - 플로팅 필: 좌우 14 · bottom 14(+안전영역) · h 66 · radius-full ·
///   surface 82% + backdrop blur(20) · 이중 그림자 + 1px 보더.
/// - compact (tabBarMinimizeBehavior .onScrollDown): [PTabBarCompactController]
///   가 스크롤 방향 누적(아래 20 축소 / 위 28 복원 / 최상단 40 미만 확장)으로
///   판정 — h 48 · 좌우 36 · 라벨 숨김. 축소 상태에서 바를 탭하면 복원.
/// - 모드 전환 안무(토스): [sharedIndexes] 슬롯은 유지, 나머지 0.13s 아웃
///   (가라앉음) → 교체 → 좌→우 40ms 스태거 인.

/// 스크롤 방향 히스테리시스 — 셸 body 의 NotificationListener 에서
/// [onScroll] 로 알림을 흘려주면 [compact] 를 갱신한다.
class PTabBarCompactController extends ChangeNotifier {
  bool compact = false;
  double _acc = 0;
  static const _downAt = 20.0;
  static const _upAt = 28.0;

  void _set(bool v) {
    if (compact == v) return;
    compact = v;
    notifyListeners();
  }

  /// 셸에서: `NotificationListener<ScrollNotification>(onNotification: c.onScroll)`.
  bool onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final st = n.metrics.pixels;
    if (st < 40) {
      _acc = 0;
      _set(false);
      return false;
    }
    if (n is ScrollUpdateNotification) {
      final dy = n.scrollDelta ?? 0;
      if ((dy > 0 && _acc < 0) || (dy < 0 && _acc > 0)) _acc = 0; // 방향 전환 리셋
      _acc += dy;
      if (_acc > _downAt) _set(true);
      if (_acc < -_upAt) _set(false);
    }
    return false;
  }

  void expand() => _set(false);
}

class _PTabBarScope extends InheritedWidget {
  const _PTabBarScope({required this.compact, required super.child});
  final bool compact;

  static bool compactOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_PTabBarScope>()
          ?.compact ??
      false;

  @override
  bool updateShouldNotify(_PTabBarScope oldWidget) =>
      compact != oldWidget.compact;
}

/// 플로팅 탭바가 콘텐츠 하단을 덮지 않도록 셸 화면 스크롤에 줄 보상 여백 —
/// 웹 `.m-app--tabbar .m-scroll > :last-child { padding-bottom: 104px }` 정합
/// (+ 기기 안전영역).
double pTabBarBottomInset(BuildContext context) =>
    104 + MediaQuery.of(context).padding.bottom;

class PTabBar extends StatefulWidget {
  const PTabBar({
    super.key,
    required this.children,
    this.modeKey,
    this.sharedIndexes = const {},
    this.controller,
  });

  /// 5칸 슬롯 위젯 ([PTabBarItem]/[PTabBarFab]/[PTabBarBack]).
  final List<Widget> children;

  /// 모드 식별자 — 바뀌면 공유 슬롯 외 아웃→스태거 인 안무.
  final String? modeKey;

  /// 모드 전환 안무에서 유지되는 슬롯 인덱스(예: 가계부 = {1}).
  final Set<int> sharedIndexes;

  final PTabBarCompactController? controller;

  @override
  State<PTabBar> createState() => _PTabBarState();
}

class _PTabBarState extends State<PTabBar> {
  String? _mode;
  List<Widget> _rendered = const [];
  String _phase = 'idle'; // idle | out | in

  @override
  void initState() {
    super.initState();
    _mode = widget.modeKey;
    _rendered = widget.children;
    widget.controller?.addListener(_onCompact);
  }

  void _onCompact() => setState(() {});

  @override
  void didUpdateWidget(covariant PTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onCompact);
      widget.controller?.addListener(_onCompact);
    }
    if (widget.modeKey == _mode) {
      _rendered = widget.children;
      return;
    }
    // 모드 전환 — 이전 슬롯 유지한 채 아웃 → 교체 → 스태거 인.
    _mode = widget.modeKey;
    setState(() => _phase = 'out');
    Future.delayed(const Duration(milliseconds: 130), () {
      if (!mounted) return;
      setState(() {
        _rendered = widget.children;
        _phase = 'in';
      });
      Future.delayed(const Duration(milliseconds: 420), () {
        if (mounted) setState(() => _phase = 'idle');
      });
    });
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onCompact);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final mq = MediaQuery.of(context);
    final compact = widget.controller?.compact ?? false;

    final bar = AnimatedContainer(
      duration: PMotion.base,
      curve: PMotion.standard,
      height: compact ? 48 : 66,
      margin: EdgeInsets.only(
        left: compact ? 36 : 14,
        right: compact ? 36 : 14,
        bottom: (compact ? 12 : 14) + mq.padding.bottom,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AnimatedContainer(
            duration: PMotion.base,
            curve: PMotion.standard,
            padding: compact
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: t.bgSurface.withValues(alpha: compact ? 0.68 : 0.82),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: t.borderSubtle.withValues(alpha: 0.7),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2E0A1024),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
                BoxShadow(
                  color: Color(0x140A1024),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < _rendered.length; i++)
                  Expanded(
                    child: _PhasedSlot(
                      phase: widget.sharedIndexes.contains(i) ? 'idle' : _phase,
                      index: i,
                      child: _rendered[i],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return _PTabBarScope(
      compact: compact,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: compact ? widget.controller?.expand : null,
        child: bar,
      ),
    );
  }
}

/// 모드 전환 안무 래퍼 — out: 가라앉음 / in: index*40ms 스태거 등장.
class _PhasedSlot extends StatefulWidget {
  const _PhasedSlot({
    required this.phase,
    required this.index,
    required this.child,
  });
  final String phase;
  final int index;
  final Widget child;

  @override
  State<_PhasedSlot> createState() => _PhasedSlotState();
}

class _PhasedSlotState extends State<_PhasedSlot> {
  bool _entered = true;

  @override
  void didUpdateWidget(covariant _PhasedSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != 'in' && widget.phase == 'in') {
      _entered = false;
      Future.delayed(Duration(milliseconds: widget.index * 40), () {
        if (mounted) setState(() => _entered = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final out = widget.phase == 'out';
    final hiddenIn = widget.phase == 'in' && !_entered;
    final hidden = out || hiddenIn;
    return IgnorePointer(
      ignoring: out,
      child: AnimatedSlide(
        duration: Duration(milliseconds: out ? 130 : 240),
        curve: PMotion.standard,
        offset: hidden ? const Offset(0, 0.14) : Offset.zero,
        child: AnimatedScale(
          duration: Duration(milliseconds: out ? 130 : 240),
          curve: PMotion.standard,
          scale: hidden ? 0.9 : 1,
          child: AnimatedOpacity(
            duration: Duration(milliseconds: out ? 130 : 240),
            curve: PMotion.standard,
            opacity: hidden ? 0 : 1,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class PTabBarItem extends StatelessWidget {
  const PTabBarItem({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final compact = _PTabBarScope.compactOf(context);
    final color = selected ? t.fgBrandStrong : t.fgTertiary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color),
          if (!compact) ...[
            const SizedBox(height: 3),
            Text(
              label,
              style: PTypo.micro.copyWith(
                fontSize: 10.5,
                color: color,
                fontWeight: selected ? PFontWeight.semi : PFontWeight.medium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 중앙 + 버튼 — 다크에서도 primary 고정(bgBrandSolid).
class PTabBarFab extends StatelessWidget {
  const PTabBarFab({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final compact = _PTabBarScope.compactOf(context);
    final size = compact ? 36.0 : 44.0;
    return Center(
      child: AnimatedContainer(
        duration: PMotion.base,
        curve: PMotion.standard,
        width: size,
        height: size,
        margin: EdgeInsets.only(top: compact ? 0 : 0),
        decoration: BoxDecoration(
          color: t.bgBrandSolid,
          shape: BoxShape.circle,
          boxShadow: t.shadowSm,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Center(
              child: Icon(LucideIcons.plus, color: t.fgOnBrand, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

/// money 모드 ← 버튼 — sunken 필.
class PTabBarBack extends StatelessWidget {
  const PTabBarBack({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final compact = _PTabBarScope.compactOf(context);
    final size = compact ? 32.0 : 36.0;
    return Center(
      child: AnimatedContainer(
        duration: PMotion.base,
        curve: PMotion.standard,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: t.bgSunken,
          shape: BoxShape.circle,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Center(
              child: Icon(
                LucideIcons.arrowLeft,
                size: 18,
                color: t.fgSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
