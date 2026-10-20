#!/usr/bin/env bash
#
# groo-design 이 내보내는 파일을 이 레포로 가져온다 — 손으로 고치지 않는다.
#
#   lib/app/theme/groo_tokens.g.dart  ← scripts/build-dart-tokens.mjs (DESIGN.desk.md)
#   test/fixtures/design_spec/*.json    ← scripts/build-spec-json.mjs  (컴포넌트 스펙 값, 라이트 · 다크)
#
# 웹(desk-front)의 `npm run design:sync` 와 같은 원본 · 같은 시점을 가져온다.
#
# 스펙 값은 위젯이 아니라 테스트가 읽는다. 위젯은 생성 토큰(PSpacing · PRounded · PColors …)
# 으로 값을 적고, 테스트가 위젯의 값이 스펙 JSON 과 같은지 본다 — 웹은 같은 JSON 을 코드가
# 바로 가져다 쓰지만 Dart 는 JSON 을 컴파일 때 읽지 못한다.
#
# groo-design 은 옆 폴더(../groo-design)라고 본다. 다르면 PORESTDESIGN_DIR 로 알려 준다.
#
# 사용: scripts/sync_design.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="DESIGN.desk.md"

DESIGN_DIR="${PORESTDESIGN_DIR:-../groo-design}"
case "${DESIGN_DIR}" in
  /*) ;;
  *) DESIGN_DIR="${ROOT}/${DESIGN_DIR}" ;;
esac
if [ ! -f "${DESIGN_DIR}/${SOURCE}" ]; then
  echo "groo-design 을 찾지 못했다: ${DESIGN_DIR}" >&2
  exit 1
fi

# 이 레포의 Dart 는 fvm 으로 핀을 맞춘다(CLAUDE.md 검증 명령). fvm 이 없는 곳에서는 맨몸 dart.
if command -v fvm >/dev/null 2>&1; then
  DART=(fvm dart)
else
  DART=(dart)
fi

TOKENS="${ROOT}/lib/app/theme/groo_tokens.g.dart"
SPEC_DIR="${ROOT}/test/fixtures/design_spec"

# 원본 경로가 머리 주석에 그대로 찍히므로 groo-design 안에서 상대 경로로 돌린다
(cd "${DESIGN_DIR}" && node scripts/build-dart-tokens.mjs --source "${SOURCE}") > "${TOKENS}"

rm -rf "${SPEC_DIR}"
mkdir -p "${SPEC_DIR}"
(cd "${DESIGN_DIR}" && node scripts/build-spec-json.mjs --source "${SOURCE}" --out "${SPEC_DIR}")

# 기관 색 표(institution-colors.json)는 Dart 가 컴파일 때 JSON 을 읽지 못해 Dart 상수로 내보낸다 — 손으로 옮겨 적지 않는다
INSTITUTION_COLORS="${ROOT}/lib/shared/ds/institution_colors/institution_colors.g.dart"
node -e '
const fs = require("fs");
const spec = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
const lit = JSON.stringify({ data: { entries: spec.data.entries } }, null, 2).replace(/\$/g, "\\$");
process.stdout.write(
  "// GENERATED — scripts/sync_design.sh 가 institution-colors.json 에서 만든다. 손으로 고치지 않는다.\n" +
  "// source: " + spec.design.file + " · sha256 " + spec.design.sha256 + "\n\n" +
  "/// 기관 색 표(스펙 JSON 의 data.entries) — `PInstitutionTable.fromSpecJson` 이 읽는다.\n" +
  "const Map<String, dynamic> kInstitutionColorsSpec = " + lit + ";\n"
);
' "${SPEC_DIR}/institution-colors.json" > "${INSTITUTION_COLORS}"
(cd "${ROOT}" && "${DART[@]}" format "${INSTITUTION_COLORS}" >/dev/null)

# 카테고리 아이콘 세트(category-icons.json — Icon Picker 의 범위 148개 · 13 묶음)도 같은 방식으로 Dart 상수로 내보낸다.
# 표(data)는 JSON 그대로, 그림 표(id → LucideIcons 상수)는 id 에서 기계적으로 만든다 — kebab → camelCase(숫자는 그대로:
# gamepad-2 → gamepad2). 아이콘은 글꼴 줄이라 코드로 IconData 를 만들지 않고 상수를 이름으로 적는다(글꼴 줄이기가 쓴 것만 남긴다).
# 고른 칸의 선 2.5 는 variable 글꼴 w500(`<이름>500`)이다. 상수 이름이 패키지에 없으면 컴파일(analyze)이 막는다.
CATEGORY_ICONS="${ROOT}/lib/shared/ds/icon_picker/category_icons.g.dart"
mkdir -p "$(dirname "${CATEGORY_ICONS}")"
node -e '
const fs = require("fs");
const spec = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
const data = { name: spec.data.name, default: spec.data.default, groups: spec.data.groups, entries: spec.data.entries };
const lit = JSON.stringify({ data }, null, 2).replace(/\$/g, "\\$");
const camel = (id) => id.replace(/-([a-z0-9])/g, (_, c) => c.toUpperCase());
const ids = spec.data.entries.map((e) => e.id);
if (!ids.includes(spec.data.default)) ids.push(spec.data.default);
const glyphs = (suffix) => ids.map((id) => "  \x27" + id + "\x27: LucideIcons." + camel(id) + suffix + ",").join("\n");
process.stdout.write(
  "// GENERATED — scripts/sync_design.sh 가 category-icons.json 에서 만든다. 손으로 고치지 않는다.\n" +
  "// source: " + spec.design.file + " · sha256 " + spec.design.sha256 + "\n\n" +
  "import \x27package:flutter/widgets.dart\x27;\n" +
  "import \x27package:lucide_icons_flutter/lucide_icons.dart\x27;\n\n" +
  "/// 카테고리 아이콘 세트(스펙 JSON 의 data) — `kCategoryIcons` 가 읽는다.\n" +
  "const Map<String, dynamic> kCategoryIconsSpec = " + lit + ";\n\n" +
  "/// id(lucide 이름) → 그림(선 2).\n" +
  "const Map<String, IconData> kCategoryIconGlyphs = {\n" + glyphs("") + "\n};\n\n" +
  "/// id → 그림(선 2.5 — 고른 칸).\n" +
  "const Map<String, IconData> kCategoryIconGlyphsBold = {\n" + glyphs("500") + "\n};\n"
);
' "${SPEC_DIR}/category-icons.json" > "${CATEGORY_ICONS}"
(cd "${ROOT}" && "${DART[@]}" format "${CATEGORY_ICONS}" >/dev/null)

# CI(verify)가 dart format --set-exit-if-changed 로 lib 를 본다
(cd "${ROOT}" && "${DART[@]}" format "${TOKENS}" >/dev/null)

echo "groo-design(${SOURCE}) → lib/app/theme/groo_tokens.g.dart · test/fixtures/design_spec · institution_colors.g.dart · category_icons.g.dart"
