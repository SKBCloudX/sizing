#!/bin/bash
# 사이징 페이지를 GitHub Pages 용으로 (재)암호화한다.
#
#   1) index.src.html (평문 원본) 을 편집
#   2) ./encrypt.sh            -> index.html (암호화본) 생성
#   3) git add index.html && commit && push
#
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

SRC="${1:-index.src.html}"
OUT="index.html"
IMAGE="node:20-slim"

command -v docker >/dev/null || { echo "docker 가 필요합니다." >&2; exit 1; }
[ -f "$SRC" ] || { echo "평문 원본이 없습니다: $SRC  (암호화본만 있다면 ./decrypt.sh 로 먼저 복구)" >&2; exit 1; }

PW="${STATICRYPT_PASSWORD:-}"
if [ -z "$PW" ]; then
  read -rsp "비밀번호: " PW; echo
  read -rsp "비밀번호 확인: " PW2; echo
  [ "$PW" = "$PW2" ] || { echo "비밀번호가 일치하지 않습니다." >&2; exit 1; }
fi
[ -n "$PW" ] || { echo "빈 비밀번호는 쓸 수 없습니다." >&2; exit 1; }

tmp="$(mktemp -d "$PWD/.sc-XXXXXX")"; trap 'rm -rf "$tmp"' EXIT
rel="$(basename "$tmp")"
docker run --rm --network host -v "$PWD:/work" -w /work \
  --user "$(id -u):$(id -g)" -e HOME=/tmp \
  -e STATICRYPT_PASSWORD="$PW" \
  "$IMAGE" npx -y staticrypt@3 "$SRC" --short -c false --remember false -d "$rel" 2>&1 \
  | grep -vE "npm warn|npm notice|password is less than" || true

enc="$tmp/$(basename "$SRC")"
[ -f "$enc" ] || { echo "암호화 실패." >&2; exit 1; }
mv -f "$enc" "$OUT"
echo "암호화 완료 -> $OUT   (git add $OUT && commit && push 하면 Pages 에 반영)"
