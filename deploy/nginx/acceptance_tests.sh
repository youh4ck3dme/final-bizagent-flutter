#!/bin/bash
# acceptance_tests.sh - ICOAtlas API Tests
# Spustenie: chmod +x acceptance_tests.sh && ./acceptance_tests.sh

BASE="https://icoatlas.sk"
PASS=0
FAIL=0

test_case() {
    local name="$1"
    local expected_code="$2"
    local expected_content="$3"
    shift 3
    
    echo -n "TEST: $name ... "
    response=$(curl -s -w "\n%{http_code}" "$@")
    body=$(echo "$response" | sed '$d')
    code=$(echo "$response" | tail -1)
    
    if [[ "$code" == "$expected_code" ]] && [[ "$body" == *"$expected_content"* ]]; then
        echo "✅ PASS"
        ((PASS++))
    else
        echo "❌ FAIL (got $code, expected $expected_code)"
        echo "   Body: $body"
        ((FAIL++))
    fi
}

echo "═══════════════════════════════════════════════════════════"
echo "  ICOAtlas API Acceptance Tests"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Test 1: HTTP → HTTPS Redirect
echo -n "TEST: HTTP redirect ... "
redirect=$(curl -s -o /dev/null -w "%{http_code}" http://icoatlas.sk/health)
[[ "$redirect" == "301" ]] && echo "✅ PASS" && ((PASS++)) || { echo "❌ FAIL ($redirect)"; ((FAIL++)); }

# Test 2: Health check
test_case "Health endpoint" "200" '"status":"ok"' "$BASE/health"

# Test 3: Existujúce IČO (ESET)
test_case "Valid ICO (ESET)" "200" '"found":true' "$BASE/api/company/proxy-search?ico=31333532"

# Test 4: Neexistujúce IČO
test_case "Nonexistent ICO" "200" '"found":false' "$BASE/api/company/proxy-search?ico=99999999"

# Test 5: Neplatné IČO
test_case "Invalid ICO format" "400" '"found":false' "$BASE/api/company/proxy-search?ico=ABC"

# Test 6: CORS Preflight
echo -n "TEST: CORS preflight ... "
cors=$(curl -s -I -X OPTIONS "$BASE/api/company/proxy-search" \
    -H "Origin: https://random-widget.com" \
    -H "Access-Control-Request-Method: GET" 2>&1 | grep -i "access-control-allow-origin")
[[ "$cors" == *"*"* ]] && echo "✅ PASS" && ((PASS++)) || { echo "❌ FAIL"; ((FAIL++)); }

# Test 7: Security headers
echo -n "TEST: Security headers ... "
headers=$(curl -s -I "$BASE/" 2>&1)
if echo "$headers" | grep -qi "x-frame-options" && echo "$headers" | grep -qi "x-content-type-options"; then
    echo "✅ PASS"
    ((PASS++))
else
    echo "❌ FAIL"
    ((FAIL++))
fi

# Test 8: No X-XSS-Protection (deprecated)
echo -n "TEST: No X-XSS-Protection ... "
xss=$(curl -s -I "$BASE/" 2>&1 | grep -i "x-xss-protection")
[[ -z "$xss" ]] && echo "✅ PASS" && ((PASS++)) || { echo "❌ FAIL (header present)"; ((FAIL++)); }

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed"
echo "═══════════════════════════════════════════════════════════"

exit $FAIL
