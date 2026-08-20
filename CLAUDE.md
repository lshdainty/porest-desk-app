# Porest Desk App — 작업 규칙

> **워크스페이스 공통 규칙**(Git 작업 격리 · 스테이징 범위 · 태그·릴리스)은
> 상위 `/home/lshdainty/study/CLAUDE.md` 에 있다. Claude Code 가 디렉토리 워크업으로
> 자동 로드하므로 여기에 복사하지 않는다 — 복사본은 원문이 바뀌어도 따라오지 않는다.

## WHY (목적)

`porest-design`의 디자인 시스템 spec을 **단일 source of truth(SoT)** 로 두고, desk-app(Flutter) 코드를 그 spec에 정확히 맞추기 위한 작업 규칙. spec 정합이 어긋나면 사용자 화면이 어긋나 작업이 빙빙 돌게 됨 — 그걸 사전에 막는다.

## WHAT (산출물)

`porest-design`에 정의된 디자인 시스템을 Flutter/Dart로 구현한 모바일 클라이언트:
- `lib/shared/widgets/p_<name>.dart` — porest-design `specs/components/<name>.md` SoT 미러 (shadcn 패턴, P prefix)
- `lib/app/theme/tokens.dart` / `colors.dart` / `radius.dart` / `spacing.dart` / `typography.dart` — porest-design 토큰 미러 (Flutter ThemeExtension)
- `lib/features/**/*.dart` — 위 위젯을 사용한 화면 — spec 위반 inline override 금지

## HOW (작업 규칙 — 절대 4 규칙)

### 1. 모든 컴포넌트는 porest-design spec 기준
- `lib/shared/widgets/p_<name>.dart`는 `porest-design/specs/components/<name>.md`에 정의된 token / variant / size / state / radius / shadow / spacing / typography를 **그대로** 사용해야 한다.
- spec과 다르게 보이는 게 디자인적으로 더 좋아 보여도 임의 변경 금지.
- CSS variable은 Flutter에 없으므로 토큰 → `PRadius` / `PSpace` / `PorestTokens` 등 동일 의미 Dart 상수로 매핑.

### 2. spec에 없는 건 사용자에게 결정 요구
- 작업 중 spec에 정의되지 않은 토큰 / 변형 / 규칙이 필요할 때:
  1. **현재 상황** (어떤 화면에서 어떤 토큰이 필요한지)
  2. **spec 인용** (현재 spec이 명시하는 값 + 누락 부분)
  3. **선택지** (A: spec 그대로 유지 / B: spec에 신규 추가 / C: 기존 토큰 재사용 …)

   를 정리해 사용자에게 보여주고 **결정을 요구**한다. 임의 결정 금지.

### 3. spec 업데이트 → 컴포넌트 수정 순서
- 사용자가 신규 spec 추가/수정을 결정하면:
  1. **`porest-design/specs/components/<name>.md` 또는 `DESIGN.*.md`를 먼저** 수정 (SoT 갱신)
  2. 그 다음 desk-app의 `p_<name>.dart` / 사용처를 동기
  3. desk-front(React)도 같은 spec을 미러하므로 함께 정합 (별도 PR 가능)

   spec 없이 코드부터 바꾸지 않는다.

### 4. 반복
- 새로 발견된 위반 또는 누락이 있으면 (1)→(2)→(3) 반복. spec ↔ 코드 일치가 영구 게이트.

## 금지 사항

- **위젯 사용 시 inline prop으로 spec 토큰을 override 금지** — 예:
  - `PButton(borderRadius: BorderRadius.circular(10))` ❌ (Button spec은 `radius-sm` 4px 고정)
  - `PTextInput(height: 60)` ❌ (Input spec sizes 표 외 값 금지)
  - 정당한 inline은 spec 외 영역 (padding, margin, position, color 등 spec이 호출처 결정으로 명시한 부분)만.

- **`PorestPalette` 직접 참조 금지** — semantic 토큰(`tokens.fgBrand`, `tokens.bgSurface` 등) 사용. 예외는 chart palette, bank colors 같이 spec이 raw palette 인용을 명시한 영역만.

- **`shared/widgets/` 외부에 raw Material 위젯으로 컴포넌트 복제 금지** — `FilledButton`/`TextField`/`Switch` 등 직접 사용 금지. 반드시 `shared/widgets/p_<name>` 통과.

- **신규 화면/위젯 작성 시 P 위젯 시각을 자체 `Container` + `Decoration` 으로 모방 금지** — Card/Chip/Button/Input 등의 시각 (bgSurface + border + radius + shadow 조합) 이 필요하면 **반드시 `PCard` / `PChip` / `PButton` / `PTextInput` 등 P 위젯 사용**. 자체 `InkWell + Container(BoxDecoration)` 로 비슷한 시각을 직조하면 spec 변경 시 누락 발생 + SoT 단일성 깨짐.
  - 예 ❌: `Container(decoration: BoxDecoration(color: t.bgSurface, border: Border.all(color: t.borderSubtle), borderRadius: PRadius.brLg))` — PCard(bordered) 모방
  - 예 ✓: `PCard(variant: PCardVariant.bordered, child: ...)` — SoT 사용
  - P 위젯에 필요한 variant/prop 이 부족하면 spec 변경 + P 위젯 확장 (HOW 절차 1→2→3).

- **`color_parse.dart`/`chart_palette.dart` 헬퍼 우회 금지** — chart palette 카테고리 색은 `resolveChartColor(context, hex)` 통과 (라이트/다크 자동 swap).

## 작업 흐름 (요약)

```
1. 작업할 위젯/화면 파악
2. porest-design/specs/components/<name>.md (또는 DESIGN.*.md) 확인 — SoT
3. spec과 현재 코드 diff (PRadius / PorestTokens / 위젯 prop)
4. spec 부재 / 모호 → 사용자에게 결정 요구 (현재 + spec 인용 + 선택지)
5. 결정 → spec 업데이트 (필요 시) → 코드 동기
6. `fvm flutter analyze lib/` (0 issues) + 시뮬레이터 시각 검증 (라이트/다크 모드)
7. 반복
```

## 커밋에 `Release-Note:` 를 단다

`feat` · `fix` 커밋에는 **사용자용 한 줄**을 트레일러로 단다. 앱 업데이트 화면과 GitHub
릴리스 본문이 이 문장을 그대로 쓴다(`scripts/release_notes.sh`).

```
fix(swipe): 스냅 임계값 단위를 트레이 기준으로 환산한다

...본문...

Release-Note: 행을 밀 때 어중간하게 열리던 문제를 고쳤어요
```

커밋 제목을 사용자 말투로 쓰지 않는다. 제목은 `git log` · `blame` · 리뷰에서 개발자가
읽는 자리다. 두 독자에게 한 문장을 쓰게 하면 양쪽 다 어중간해진다 — 그래서 자리를 나눈다.

- **말투는 앱 문구와 같게.** 앱이 "고른 내용이 사라져요" · "이미 기록된 거래는 그대로
  남아요" 로 말하므로 노트도 `~어요` 로 쓴다. 사용자가 무엇을 **할 수 있게 됐는지** /
  무엇이 **고쳐졌는지**를 쓴다. 클래스 이름 · 파일 이름 · 토큰 이름은 쓰지 않는다.
- **`Release-Note: skip`** — `feat`·`fix` 로 찍혔지만 쓰는 사람 눈에는 아무 일도 안
  일어난 변경(내부 정리, 테스트 보강)에 쓴다. 그 커밋은 노트에서 빠진다.
- 안 달아도 CI 는 안 깨진다. 제목에서 `type(scope):` 를 떼어 쓰는 폴백이 있다 — 다만
  개발자 말투가 그대로 사용자에게 나간다.

## 검증 명령

`fvm` 을 빼면 안 된다. 맨몸 `flutter` 는 fvm global(3.41.9)을 잡는데 이 레포 핀은
`.fvmrc` 3.44.9 다 — 로컬만 통과하고 CI 에서 깨진다. CI 도 같은 3.44.9 로 못 박혀 있다
(`.github/workflows/ci-main.yml` 의 `FLUTTER_VERSION`).

범위도 `lib/` 다. CI 가 `flutter analyze lib/` 로 돌리므로 범위를 넓히면 CI 가 보지 않는
곳까지 붙잡히고, 좁히면 CI 에서 터진다. deprecation info 도 analyze 를 실패시킨다.

```bash
. ~/.config/flutter-env.sh     # 비대화형 셸은 .zshrc 를 로드하지 않는다
fvm flutter pub get
fvm flutter analyze lib/
fvm flutter test
```

## 참고

- 토큰 / 시스템 워크플로: `porest-design/CLAUDE.md`
- 컴포넌트 spec 작업: `porest-design/specs/CLAUDE.md`
- Git 컨벤션: `porest-design/GIT_CONVENTION.md`
- spec 일람: `porest-design/specs/components/*.md`
- DESIGN prose: `porest-design/DESIGN.md` (공유) / `porest-design/DESIGN.desk.md` (Desk 전용)
- desk-front (React 미러): `porest-desk-front/CLAUDE.md`
