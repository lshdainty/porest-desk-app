# Porest Desk App — 작업 규칙

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

## Git 작업 격리 (필수)

작업 하나당 **토픽 브랜치 + 전용 워크트리**를 만들고 그 안에서만 편집한다.
공유 워킹트리에서 바로 `checkout -b` 하고 작업하지 않는다.

여러 세션·에이전트·사용자가 워킹트리 하나를 공유하면 **같은 파일을 동시에 만지는 순간 서로를 밟는다**
— 브랜치가 바꿔치기돼 커밋이 엉뚱한 곳에 올라가거나, 남의 미커밋 변경이 내 커밋에 편승하거나,
생성 파일(`gen-l10n` 산출물 · i18n JSON)이 뒤섞인다.

```bash
git fetch -q origin
git worktree add -b <브랜치> /home/lshdainty/study/.worktrees/<이름> origin/main
```

- 워크트리는 **레포 밖**에 만든다 — `.claude/` 가 `.gitignore` 에 없는 레포가 있어,
  레포 안에 두면 워크트리 디렉토리가 untracked 로 잡힌다
- **`origin/main` 기준**으로 판다 — 로컬 `main` 기준이면 다른 세션의 미푸시 커밋이 딸려 들어온다
- 머지는 **GitHub API 로** 한다. 워크트리 세션에서 `gh pr merge` 는 로컬 `main` 체크아웃을 시도하다
  `fatal: 'main' is already used by worktree` 로 실패한다

  ```bash
  gh api -X PUT repos/lshdainty/<repo>/pulls/<N>/merge -f merge_method=merge
  gh api -X DELETE repos/lshdainty/<repo>/git/refs/heads/<브랜치>
  ```
- 끝나면 `git worktree remove <경로>` + `git branch -d <브랜치>` 로 정리한다

## 작업 흐름 (요약)

```
1. 작업할 위젯/화면 파악
2. porest-design/specs/components/<name>.md (또는 DESIGN.*.md) 확인 — SoT
3. spec과 현재 코드 diff (PRadius / PorestTokens / 위젯 prop)
4. spec 부재 / 모호 → 사용자에게 결정 요구 (현재 + spec 인용 + 선택지)
5. 결정 → spec 업데이트 (필요 시) → 코드 동기
6. flutter analyze (0 issues) + 시뮬레이터 시각 검증 (라이트/다크 모드)
7. 반복
```

## 참고

- 토큰 / 시스템 워크플로: `porest-design/CLAUDE.md`
- 컴포넌트 spec 작업: `porest-design/specs/CLAUDE.md`
- Git 컨벤션: `porest-design/GIT_CONVENTION.md`
- spec 일람: `porest-design/specs/components/*.md`
- DESIGN prose: `porest-design/DESIGN.md` (공유) / `porest-design/DESIGN.desk.md` (Desk 전용)
- desk-front (React 미러): `porest-desk-front/CLAUDE.md`
