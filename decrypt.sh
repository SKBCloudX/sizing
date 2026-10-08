#!/bin/bash
# 암호화본 index.html 에서 평문 원본을 복구한다 (비밀번호 필요).
#
#   ./decrypt.sh    -> index.src.html 로 복구 (이미 있으면 decrypted/ 에 둔다)
#
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

ENC="${1:-index.html}"
IMAGE="node:20-slim"

command -v docker >/dev/null || { echo "docker 가 필요합니다." >&2; exit 1; }
[ -f "$ENC" ] || { echo "암호화본이 없습니다: $ENC" >&2; exit 1; }

SALT="$(grep -oE '"staticryptSaltUniqueVariableName":"[0-9a-f]{32}"' "$ENC" | grep -oE '[0-9a-f]{32}' | head -1)"
[ -n "$SALT" ] || { echo "$ENC 에서 salt 를 찾지 못했습니다. StatiCrypt 로 암호화한 파일이 맞습니까?" >&2; exit 1; }

PW="${STATICRYPT_PASSWORD:-}"
if [ -z "$PW" ]; then read -rsp "비밀번호: " PW; echo; fi
[ -n "$PW" ] || { echo "빈 비밀번호는 쓸 수 없습니다." >&2; exit 1; }

tmp="$(mktemp -d "$PWD/.sc-XXXXXX")"; trap 'rm -rf "$tmp"' EXIT
rel="$(basename "$tmp")"
set +e
docker run --rm --network host -v "$PWD:/work" -w /work \
  --user "$(id -u):$(id -g)" -e HOME=/tmp \
  -e STATICRYPT_PASSWORD="$PW" \
  "$IMAGE" npx -y staticrypt@3 "$ENC" --decrypt -c false -s "$SALT" -d "$rel" 2>&1 \
  | grep -vE "npm warn|npm notice" >&2
set -e

dec="$tmp/$(basename "$ENC")"
[ -f "$dec" ] || { echo "복호화 실패 -- 비밀번호가 틀렸을 수 있습니다." >&2; exit 1; }

if [ -e index.src.html ]; then
  mkdir -p decrypted; mv -f "$dec" decrypted/index.src.html
  echo "index.src.html 이 이미 있어 덮지 않았습니다. 복구본: decrypted/index.src.html"
else
  mv -f "$dec" index.src.html
  echo "복구 완료 -> index.src.html  (편집 후 ./encrypt.sh 로 다시 암호화)"
fi
