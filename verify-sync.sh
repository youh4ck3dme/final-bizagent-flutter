#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-3000}"
ICO="${1:-${ICO:-46359371}}"
BASE="http://localhost:${PORT}"
URL="${BASE}/api/public/ico/lookup?ico=${ICO}"

echo "🔍 Starting BizAgent Sync Verification (Port 3000)..."
echo "--------------------------------------------------------"
echo "🚀 Testing REAL DATA for IČO: ${ICO}"
echo "🔗 URL: ${URL}"

# Fetch headers + body (no silent HTML failures)
TMP_HEADERS="$(mktemp)"
TMP_BODY="$(mktemp)"
HTTP_CODE="$(curl -sS -D "$TMP_HEADERS" -o "$TMP_BODY" -w "%{http_code}" "$URL" || true)"

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "❌ HTTP ${HTTP_CODE} from ${URL}"
  echo "---- HEADERS ----"
  cat "$TMP_HEADERS" || true
  echo "---- BODY (first 60 lines) ----"
  sed -n '1,60p' "$TMP_BODY" || true
  exit 1
fi

CONTENT_TYPE="$(grep -i '^content-type:' "$TMP_HEADERS" | head -1 | tr -d '\r' | awk -F': ' '{print $2}')"
if [[ -z "${CONTENT_TYPE}" ]] || [[ "${CONTENT_TYPE}" != *"application/json"* ]]; then
  echo "❌ Not JSON response (content-type: ${CONTENT_TYPE:-unknown})"
  echo "---- HEADERS ----"
  cat "$TMP_HEADERS" || true
  echo "---- BODY (first 60 lines) ----"
  sed -n '1,60p' "$TMP_BODY" || true
  exit 1
fi

# Parse JSON + assert meta presence
export TMP_BODY
node <<'NODE'
const fs = require("fs");

const bodyPath = process.env.TMP_BODY;
const raw = fs.readFileSync(bodyPath, "utf8").trim();

let j;
try {
  j = JSON.parse(raw);
} catch (e) {
  console.error("❌ JSON parse failed. First 200 chars:");
  console.error(raw.slice(0, 200));
  process.exit(1);
}

const summary = j.summary ?? j;
const meta = summary?.meta;

if (!meta || meta.qualityScore === undefined || !meta.updatedAt) {
  console.error("❌ Meta missing or incomplete!");
  console.error("meta =", meta);
  process.exit(2);
}

const name =
  summary?.company?.name ||
  summary?.name ||
  j?.company?.name ||
  "(unknown)";

console.log("✅ API Response Valid:");
console.log("   Name:", name);
console.log("   Meta:", meta);
console.log("   Success: Meta data present.");
NODE

echo "--------------------------------------------------------"
echo "✨ SUCCESS: API is stable and meta contract holds."

rm -f "$TMP_HEADERS" "$TMP_BODY"
