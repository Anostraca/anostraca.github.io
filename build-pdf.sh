#!/usr/bin/env bash
# Generate CV PDFs (CZ + EN) from the page's print stylesheet into dist/ (git-ignored,
# not published). Set CV_PHONE to include a phone number in the PDFs only:
#   CV_PHONE="+420 123 456 789" ./build-pdf.sh
set -euo pipefail
cd "$(dirname "$0")"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
PORT="${PORT:-8767}"
PROFILE="$(mktemp -d)"
python3 -m http.server "$PORT" --bind 127.0.0.1 >/dev/null 2>&1 &
SERVER=$!
trap 'kill "$SERVER" 2>/dev/null || true; rm -rf "$PROFILE"' EXIT
for _ in 1 2 3 4 5 6 7 8 9 10; do
  kill -0 "$SERVER" 2>/dev/null || { echo "local server failed to start (port $PORT busy?)" >&2; exit 1; }
  curl -fs -o /dev/null "http://127.0.0.1:$PORT/index.html" && break
  sleep 0.5
done
mkdir -p dist
EXTRA=""
if [ -n "${CV_PHONE:-}" ]; then
  EXTRA="&phone=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$CV_PHONE")"
fi
render() {
  "$CHROME" --headless=new --disable-gpu --user-data-dir="$PROFILE" --no-pdf-header-footer \
    --print-to-pdf="$2" "http://127.0.0.1:$PORT/?lang=$1&theme=light$EXTRA" >/dev/null 2>&1
}
render cs dist/CV_Jiri_Grmolec_CZ.pdf
render en dist/CV_Jiri_Grmolec_EN.pdf
echo "PDFs written to dist/"
