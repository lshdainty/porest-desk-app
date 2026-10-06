#!/usr/bin/env bash
#
# porest-design 이 내보내는 파일을 이 레포로 가져온다 — 손으로 고치지 않는다.
#
#   lib/app/theme/porest_tokens.g.dart  ← scripts/build-dart-tokens.mjs (DESIGN.desk.md)
#   test/fixtures/design_spec/*.json    ← scripts/build-spec-json.mjs  (컴포넌트 스펙 값, 라이트 · 다크)
#
# 웹(desk-front)의 `npm run design:sync` 와 같은 원본 · 같은 시점을 가져온다.
#
# 스펙 값은 위젯이 아니라 테스트가 읽는다. 위젯은 생성 토큰(PSpacing · PRounded · PColors …)
# 으로 값을 적고, 테스트가 위젯의 값이 스펙 JSON 과 같은지 본다 — 웹은 같은 JSON 을 코드가
# 바로 가져다 쓰지만 Dart 는 JSON 을 컴파일 때 읽지 못한다.
#
# porest-design 은 옆 폴더(../porest-design)라고 본다. 다르면 PORESTDESIGN_DIR 로 알려 준다.
#
# 사용: scripts/sync_design.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="DESIGN.desk.md"

DESIGN_DIR="${PORESTDESIGN_DIR:-../porest-design}"
case "${DESIGN_DIR}" in
  /*) ;;
  *) DESIGN_DIR="${ROOT}/${DESIGN_DIR}" ;;
esac
if [ ! -f "${DESIGN_DIR}/${SOURCE}" ]; then
  echo "porest-design 을 찾지 못했다: ${DESIGN_DIR}" >&2
  exit 1
fi

# 이 레포의 Dart 는 fvm 으로 핀을 맞춘다(CLAUDE.md 검증 명령). fvm 이 없는 곳에서는 맨몸 dart.
if command -v fvm >/dev/null 2>&1; then
  DART=(fvm dart)
else
  DART=(dart)
fi

TOKENS="${ROOT}/lib/app/theme/porest_tokens.g.dart"
SPEC_DIR="${ROOT}/test/fixtures/design_spec"

# 원본 경로가 머리 주석에 그대로 찍히므로 porest-design 안에서 상대 경로로 돌린다
(cd "${DESIGN_DIR}" && node scripts/build-dart-tokens.mjs --source "${SOURCE}") > "${TOKENS}"

rm -rf "${SPEC_DIR}"
mkdir -p "${SPEC_DIR}"
(cd "${DESIGN_DIR}" && node scripts/build-spec-json.mjs --source "${SOURCE}" --out "${SPEC_DIR}")

# CI(verify)가 dart format --set-exit-if-changed 로 lib 를 본다
(cd "${ROOT}" && "${DART[@]}" format "${TOKENS}" >/dev/null)

echo "porest-design(${SOURCE}) → lib/app/theme/porest_tokens.g.dart · test/fixtures/design_spec"
