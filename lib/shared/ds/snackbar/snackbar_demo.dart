import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/button/p_button.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/snackbar/p_snackbar.dart';

/// 카탈로그(/dev/ds) — 톤 셋 × 액션 있음 · 없음(띠를 제자리에 그렸다 — 닫히지 않는다), 실제로 띄우기(화면 아래 가운데 ·
/// 4초 · 액션 6초 · 한 번에 하나 · 탭 바 위 8 · 안전 영역과 큰 쪽).
class SnackbarDemo extends StatelessWidget {
  const SnackbarDemo({super.key});

  // 톤마다 글 · 액션 — snackbar.md 의 글 규칙(무엇이 됐는지 먼저 · 마침표 · 액션은 동작 이름)
  static const _copy = {
    PSnackbarTone.neutral: (message: '거래를 삭제했어요.', action: '되돌리기'),
    PSnackbarTone.positive: (message: '목표 금액을 모두 모았어요.', action: '목표 보기'),
    PSnackbarTone.critical: (
      message: '관심 종목에 넣지 못했어요. 다시 눌러 주세요.',
      action: '다시 넣기',
    ),
  };

  static void _ignore() {}

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title:
              '톤 — neutral 은 아이콘 없음 · positive 체크 · critical 느낌표. 띠를 제자리에 그렸다(닫히지 않는다)',
          children: [
            for (final tone in PSnackbarTone.values)
              DemoRow(
                label: tone.name,
                children: [
                  PSnackbarView(
                    tone: tone,
                    message: _copy[tone]!.message,
                    closeLabel: '닫기',
                  ),
                ],
              ),
          ],
        ),
        DemoBlock(
          title: '액션 — 하나 · 동작 이름(있으면 6초). 긴 글은 줄을 바꾸고 자르지 않는다',
          children: [
            for (final tone in PSnackbarTone.values)
              DemoRow(
                label: tone.name,
                children: [
                  PSnackbarView(
                    tone: tone,
                    message: _copy[tone]!.message,
                    closeLabel: '닫기',
                    action: PSnackbarAction(
                      label: _copy[tone]!.action,
                      onPressed: _ignore,
                    ),
                  ),
                ],
              ),
            const DemoRow(
              label: '긴 글',
              children: [
                PSnackbarView(
                  message: '1,204건을 가져왔어요. 건너뛴 줄 3건은 가져오기 기록에서 다시 볼 수 있어요.',
                  closeLabel: '닫기',
                  action: PSnackbarAction(label: '기록 보기', onPressed: _ignore),
                ),
              ],
            ),
          ],
        ),
        const DemoBlock(
          title:
              '실제로 띄우기 — 화면 아래 가운데. 4초(액션 6초) · 누르고 있으면 멈춤 · 한 번에 하나. '
              '탭 바 · 홈 표시줄을 켜면 그 위 8(둘 중 큰 쪽)에 선다',
          children: [_LiveFrame()],
        ),
      ],
    );
  }
}

/// 폰 화면 하나 — 호스트가 이 틀 안에서 띠를 띄운다(실제 앱에서는 화면 전체). 틀의 안전 영역은 직접 정한다.
class _LiveFrame extends StatefulWidget {
  const _LiveFrame();

  @override
  State<_LiveFrame> createState() => _LiveFrameState();
}

class _LiveFrameState extends State<_LiveFrame> {
  bool _tabBar = false;
  bool _homeBar = false;

  static const double _frameHeight = 320;
  static const double _tabBarHeight = 66;
  static const double _homeBarInset = 34;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final media = MediaQuery.of(context);
    final inset = _homeBar ? _homeBarInset : 0.0;
    return Container(
      height: _frameHeight,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: c.bgLayerBasement,
        border: Border.all(color: c.strokeNeutralWeak),
        borderRadius: BorderRadius.circular(PRounded.r3),
      ),
      // 틀 안에서만 안전 영역 · 키보드가 다르다 — 기기의 값을 가져오지 않는다
      child: MediaQuery(
        data: media.copyWith(
          padding: EdgeInsets.only(bottom: inset),
          viewPadding: EdgeInsets.only(bottom: inset),
          viewInsets: EdgeInsets.zero,
        ),
        child: PSnackbarHost(
          closeLabel: '닫기',
          child: Builder(
            builder: (context) {
              final snackbar = PSnackbar.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(PSpacing.x3),
                    child: Wrap(
                      spacing: PSpacing.x2,
                      runSpacing: PSpacing.x2,
                      children: [
                        _trigger(
                          '결과 — 4초',
                          () => snackbar.show(message: '거래를 저장했어요.'),
                        ),
                        _trigger(
                          '되돌리기 — 6초',
                          () => snackbar.show(
                            message: '거래를 삭제했어요.',
                            action: PSnackbarAction(
                              label: '되돌리기',
                              onPressed: () => snackbar.show(
                                tone: PSnackbarTone.positive,
                                message: '거래를 되돌렸어요.',
                              ),
                            ),
                          ),
                        ),
                        _trigger(
                          '가벼운 실패',
                          () => snackbar.show(
                            tone: PSnackbarTone.critical,
                            message: '관심 종목에 넣지 못했어요. 다시 눌러 주세요.',
                          ),
                        ),
                        _trigger('닫기', snackbar.dismiss),
                        _trigger(
                          _tabBar ? '탭 바 끄기' : '탭 바 켜기',
                          () => setState(() => _tabBar = !_tabBar),
                        ),
                        _trigger(
                          _homeBar ? '홈 표시줄 끄기' : '홈 표시줄 켜기',
                          () => setState(() => _homeBar = !_homeBar),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (_tabBar)
                    PSnackbarAvoidOverlap(
                      child: Container(
                        height: _tabBarHeight + inset,
                        padding: EdgeInsets.only(bottom: inset),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.bgLayerDefault,
                          border: Border(
                            top: BorderSide(color: c.strokeNeutralWeak),
                          ),
                        ),
                        child: Text(
                          '탭 바 — 띠가 그 위 8 에 선다',
                          style: PTypography.t3.copyWith(
                            color: c.fgNeutralMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _trigger(String label, VoidCallback onPressed) => PButton(
    label: label,
    variant: PButtonVariant.neutralWeak,
    size: PButtonSize.small,
    onPressed: onPressed,
  );
}
