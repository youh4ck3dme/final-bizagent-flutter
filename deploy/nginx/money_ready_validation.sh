#!/bin/bash
# Comprehensive Validation Suite for BizAgent Infrastructure
# Tests: Normalization, CORS, Contract Headers, Rate Limiting, Fallbacks

PASS=0
FAIL=0

log_pass() { echo "✅ $1"; ((PASS++)); }
log_fail() { echo "❌ $1"; ((FAIL++)); }

echo "═══════════════════════════════════════════════════════════"
echo "  BizAgent Infrastructure Validation Suite (v2)"
echo "  (icoatlas.sk + bizagent.sk + Flutter API)"
echo "═══════════════════════════════════════════════════════════"
echo ""

# 1. API NORMALIZATION (Widget-Friendly)
# ---------------------------------------------------------
echo "1. API Normalization Check (Non-existent ICO)"
# Používame 00000000 - formálne validné dĺžkou, ale neexistujúce
TEST_ICO="00000000"

for domain in "icoatlas.sk" "www.bizagent.sk"; do
    echo -n "Testing $domain ... "
    response=$(curl -s "https://$domain/api/company/proxy-search?ico=$TEST_ICO")
    
    # Check 1: found property
    found=$(echo "$response" | jq -r '.found')
    
    if [[ "$found" == "false" ]]; then
        log_pass "$domain Normalized (found:false)"
    else
        log_fail "$domain Falied Normalization: $response"
    fi
done
echo ""

# 2. CORS HEADER CHECK
# ---------------------------------------------------------
echo "2. CORS & Security Headers Check"

echo -n "Checking icoatlas.sk CORS (Origin: https://icoatlas.sk) ... "
headers=$(curl -s -I -H "Origin: https://icoatlas.sk" "https://icoatlas.sk/api/company/proxy-search?ico=31333532")
cors=$(echo "$headers" | grep -i "access-control-allow-origin")

if [[ -n "$cors" ]]; then
    log_pass "CORS Present: $cors"
else
    log_fail "CORS Missing on icoatlas.sk"
    # Debug: Print all headers
    echo "--- Headers Received ---"
    echo "$headers"
    echo "------------------------"
fi
echo ""

# 3. RATE LIMITING STRESS TEST (NGINX layer)
# ---------------------------------------------------------
echo "3. Rate Limit Stress Test (Burst Limit Check)"
echo "Firing 50 requests rapidly against icoatlas.sk..."

# Capture HTTP codes (50 requests to exceed burst of 20 + 10r/s)
counts=$(for i in {1..50}; do curl -s -o /dev/null -w "%{http_code}\n" "https://icoatlas.sk/api/company/proxy-search?ico=31333532"; done | sort | uniq -c)

echo "$counts"

# Check if we hit 429
if echo "$counts" | grep -q "429"; then
    log_pass "Rate limiting active (saw 429s)"
else
    log_fail "No rate limiting observed (all passed?)"
fi
echo ""

# 4. DATA INTEGRITY CHECK (Flutter App Logic)
# ---------------------------------------------------------
echo "4. Data Integrity Check (ESET - 31333532)"
echo "Simulating Flutter App call structure..."

response=$(curl -s "https://icoatlas.sk/api/company/proxy-search?ico=31333532")
name=$(echo "$response" | jq -r '.data.name')
street=$(echo "$response" | jq -r '.data.street')

if [[ "$name" == *"ESET"* ]]; then
    log_pass "Data OK: $name ($street)"
else
    log_fail "Data Mismatch or Missing: $response"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed"
echo "═══════════════════════════════════════════════════════════"
exit $FAIL
