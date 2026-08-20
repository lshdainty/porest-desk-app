#!/usr/bin/env bash
#
# 릴리스 노트 — 커밋 제목을 사람이 읽는 목록으로 정리한다.
#
# 앱 업데이트 화면과 GitHub 릴리스 본문이 같은 글을 쓴다. 예전엔 `git log` 결과를
# 그대로 넣어서 `fix(footer): 필터 초기화·카드 상세 닫기를 secondary 채움 버튼으로`
# 같은 줄이 사용자 화면에 그대로 떴다. 타입·스코프는 우리끼리 쓰는 표시라 받는
# 사람에게는 읽을 거리를 가릴 뿐이다.
#
# 하는 일은 셋이다.
#   1. feat·fix 만 남긴다 — ci·docs·test·chore·refactor 는 우리 사정이다.
#   2. 타입별로 묶는다 — 새 기능 / 버그 수정.
#   3. `type(scope):` 접두사를 떼고 문장만 남긴다.
#
# 사용: scripts/release_notes.sh <git-range>
#   예: scripts/release_notes.sh v1.12.0..HEAD
#
# 범위 대신 `-` 를 주면 커밋 제목을 stdin 으로 받는다 — 손으로 확인해 볼 때 쓴다.
#   예: printf 'fix(a): 가\nchore: 나\n' | scripts/release_notes.sh -
#
# 걸러 낸 뒤 아무것도 안 남으면 원본 제목을 그대로 쓴다 — 빈 화면보다 낫다.
set -euo pipefail

RANGE="${1:?usage: release_notes.sh <git-range>}"

# 한 릴리스에 담을 최대 줄 수. 넘치면 화면이 스크롤만 길어지고 아무도 안 읽는다.
MAX_LINES="${RELEASE_NOTES_MAX:-40}"

if [ "${RANGE}" = "-" ]; then
  SUBJECTS=$(cat)
else
  SUBJECTS=$(git log --no-merges --pretty='%s' "${RANGE}")
fi

FORMATTED=$(printf '%s\n' "${SUBJECTS}" | awk -v max="${MAX_LINES}" '
  # `feat(scope)!: 제목` · `fix: 제목` 을 타입과 본문으로 가른다.
  match($0, /^(feat|fix)(\([^)]*\))?!?:[[:space:]]*/) {
    type = substr($0, 1, 3) == "fix" ? "fix" : "feat"
    body = substr($0, RSTART + RLENGTH)
    if (body == "") next
    key = type "\034" body
    if (key in seen) next          # 같은 제목이 두 번(리버트·재적용) 나오면 한 번만
    seen[key] = 1
    if (++n > max) next
    if (type == "feat") feats[++fc] = body
    else                fixes[++xc] = body
  }
  END {
    out = 0
    if (fc) {
      print "새 기능"
      for (i = 1; i <= fc; i++) print "- " feats[i]
      out = 1
    }
    if (xc) {
      if (out) print ""
      print "버그 수정"
      for (i = 1; i <= xc; i++) print "- " fixes[i]
    }
  }
')

if [ -n "${FORMATTED}" ]; then
  printf '%s\n' "${FORMATTED}"
else
  # feat·fix 가 하나도 없는 릴리스(문서·설정만 바뀐 경우). 원본이라도 보여 준다.
  printf '%s\n' "${SUBJECTS}" | head -n "${MAX_LINES}" | sed 's/^/- /'
fi
