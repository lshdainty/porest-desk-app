import 'package:flutter/widgets.dart';

/// 비율 — 여덟 가지(aspect-ratio.yaml). SEED 의 일곱(1:1 · 2:1 · 16:9 · 4:3 · 6:7 · 4:5 · 2:3)에 카드 1.586 을 더했다.
/// 기본은 4:3 이다. 이 밖의 비율(옛 3:4 · 21:9 · 임의의 숫자)은 없다 — 비율이 늘면 한 화면의 상자가 제각각이 된다.
///
/// 이름은 스펙의 이름(`"4:3"` → [r4x3], `card` → [card])이다. [spec] 이 스펙 JSON 의 `"W / H"` 글, [ratio] 가 W ÷ H 다
/// (웹 CSS `aspect-ratio` 와 같은 값 — 앱은 Flutter `AspectRatio` 에 이 값을 준다).
enum PAspectRatioValue {
  /// 1:1 — 정사각. 지도 미리보기 · 정사각 동영상
  r1x1('1:1', '1 / 1', 1),

  /// 2:1 — 넓은 띠
  r2x1('2:1', '2 / 1', 2),

  /// 16:9 — 동영상 · 바깥 페이지(iframe)
  r16x9('16:9', '16 / 9', 16 / 9),

  /// 4:3 — 기본(SEED)
  r4x3('4:3', '4 / 3', 4 / 3),

  /// 6:7 — 조금 세로
  r6x7('6:7', '6 / 7', 6 / 7),

  /// 4:5 — 세로
  r4x5('4:5', '4 / 5', 4 / 5),

  /// 2:3 — 긴 세로
  r2x3('2:3', '2 / 3', 2 / 3),

  /// 카드 1.586 — ISO 카드 85.6 × 53.98. 카드 모양 자리(카드 그림이 아닌 것 — 카드 그림은 Image Frame)
  card('card', '1.586 / 1', 1.586);

  const PAspectRatioValue(this.id, this.spec, this.ratio);

  /// 스펙의 이름 — `"1:1"` · … · `card`.
  final String id;

  /// 스펙 JSON 의 비율 글 — `"W / H"`.
  final String spec;

  /// 폭 ÷ 높이.
  final double ratio;
}

/// Aspect Ratio — 폭이 정해지면 비율로 높이가 정해지는 상자 하나. 구조는 SEED Aspect Ratio(2026-10-04), 수치 원본은
/// groo-design `specs/components/aspect-ratio.yaml`(값은 `test/fixtures/design_spec/aspect-ratio.json` — 테스트가
/// 위젯이 그 값과 같은지 본다). 웹(desk-front `src/shared/ds/aspect-ratio`)과 같은 값이다.
///
/// 폭은 부모가 정하고(부모 폭이 0 이면 상자도 0) 높이는 폭 ÷ [ratio] 다 — 내용이 오기 전에 자리를 잡으므로 내용이 와도
/// 줄이 밀리지 않는다. 모서리 0 · 바탕 · 테두리 · 그림자 · 불러오는 동안 · 대체 그림이 없고, 넘친 자식은 자른다.
/// 자식 하나가 상자를 채운다(웹 absolute · inset 0 — 앱은 상자 크기의 꽉 찬 제약을 준다). 동영상 · 그림은 쓰는 쪽이
/// `BoxFit.cover` 로 가운데를 남겨 자른다(웹 `object-fit: cover`), 지도 · 바깥 페이지는 상자 크기 그대로.
///
/// 역할 · 이름이 없다 — 자식이 말한다. 누르지 않고 초점이 서지 않는다(누르면 무언가 되는 자리는 감싼 버튼이 상태를
/// 가진다).
///
/// 그림(사진 · 카드 그림 · 규정 그림)은 이것이 아니라 Image Frame 이다 — 이것은 동영상 · 지도 · 차트처럼 그림이 아닌
/// 자리에 쓴다. 한 화면의 상자는 한두 비율로 맞춘다.
class PAspectRatio extends StatelessWidget {
  const PAspectRatio({
    super.key,
    this.ratio = PAspectRatioValue.r4x3,
    required this.child,
  });

  /// 비율 — 기본 4:3. 여덟 가지만 있다.
  final PAspectRatioValue ratio;

  /// 상자를 채우는 자식 하나.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AspectRatio(
        aspectRatio: ratio.ratio,
        child: SizedBox.expand(child: child),
      ),
    );
  }
}
