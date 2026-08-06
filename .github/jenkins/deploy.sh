#!/usr/bin/env bash
#
# porest-desk-app 배포 — Jenkins 에서 실행한다.
#
#   deploy.sh <channel: dev|prod> <version: X.Y.Z>
#
# GitHub Actions 가 빌드해서 Release 에 붙여 둔 APK·IPA 를 받아 서버에 놓는다.
# 레포가 공개라 다운로드에 토큰이 필요 없다 — 이 스크립트는 자격증명을 쓰지 않는다.
#
# 운영 반영 승인은 이 스크립트가 아니라 Jenkins job 의 input 단계에서 받는다.
# 여기까지 왔다는 건 이미 승인된 것이다.
#
set -euo pipefail

CHANNEL="${1:?channel(dev|prod) 이 필요합니다}"
VERSION="${2:?version(X.Y.Z) 이 필요합니다}"

REPO="${APK_REPO:-lshdainty/porest-desk-app}"
BASE="${APK_BASE_PATH:-/home/porest/porest/apk}"

case "$CHANNEL" in
  # dev 는 태그를 재사용해서 항상 최신 하나만 있다. prod 는 버전마다 태그가 따로 있다.
  dev)  TAG="dev" ;;
  prod) TAG="v${VERSION}" ;;
  *) echo "channel 은 dev 또는 prod 여야 합니다: ${CHANNEL}" >&2; exit 1 ;;
esac

DEST="${BASE}/${CHANNEL}"
mkdir -p "$DEST"

# 받다가 실패하면 서버에 반쪽짜리가 남지 않게, 임시 폴더에 다 받고 나서 옮긴다.
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fetch() {
  echo "  ← $1"
  curl -fsSL --retry 3 -o "${WORK}/$1" \
    "https://github.com/${REPO}/releases/download/${TAG}/$1"
}

echo "릴리스 ${TAG} 에서 받는 중 (${REPO})"
fetch "porest-desk-${VERSION}.apk"
fetch "porest-desk-${VERSION}.ipa"
fetch "version.json"

# 항상 같은 이름으로도 하나 둔다 — 링크를 버전마다 바꾸지 않아도 되게.
cp "${WORK}/porest-desk-${VERSION}.apk" "${WORK}/porest-desk-latest.apk"
cp "${WORK}/porest-desk-${VERSION}.ipa" "${WORK}/porest-desk-latest.ipa"

# Jenkins 컨테이너가 root 로 돌아서 그냥 두면 파일이 root 소유로 남는다. 배포 디렉토리의
# 소유자를 그대로 물려받게 한다 — 계정을 여기 박아 두지 않아도 서버 설정을 따라간다.
# (chown 은 root 만 할 수 있으니 root 가 아닐 때는 건드리지 않는다)
OWNER=()
if [ "$(id -u)" = 0 ]; then
  OWNER=(-o "$(stat -c '%u' "$DEST")" -g "$(stat -c '%g' "$DEST")")
fi

echo "배치: ${DEST}"
install -m 644 "${OWNER[@]}" "${WORK}"/*.apk "${WORK}"/*.ipa "$DEST/"
# version.json 을 마지막에 놓는다 — 파일이 다 놓이기 전에 앱이 새 버전을 보고 404 를 맞는 창을 없앤다.
install -m 644 "${OWNER[@]}" "${WORK}/version.json" "$DEST/"

echo "완료: ${CHANNEL} ← ${TAG} (${VERSION})"
ls -lh "$DEST"
