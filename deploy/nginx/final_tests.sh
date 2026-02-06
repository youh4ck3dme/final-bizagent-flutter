#!/bin/bash
# Final acceptance tests for icoatlas.sk + www.bizagent.sk API

BASE_ICOATLAS="https://icoatlas.sk"
BASE_BIZAGENT="https://www.bizagent.sk"
PASS=0
FAIL=0

test_api() {
    local base="$1"
    local name="$2"
    local ico="$3"
    local expected_found="$4"
    
    echo -n "TEST [$name]: ICO $ico ... "
    response=$(curl -s "$base/api/company/proxy-search?ico=$ico")
    found=$(echo "$response" | jq -r '.found')
    
    if [[ "$found" == "$expected_found" ]]; then
        echo "✅ PASS (found=$found)"
        ((PASS++))
    else
        echo "❌ FAIL (expected found=$expected_found, got $found)"
        echo "   Response: $response"
        ((FAIL++))
    fi
}

echo "═══════════════════════════════════════════════════════════"
echo "  ICOAtlas + BizAgent API Tests"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Test both endpoints
for base in "$BASE_ICOATLAS" "$BASE_BIZAGENT"; do
    domain=$(echo "$base" | sed 's|https://||')
    echo "Testing: $domain"
    echo "---"
    
    test_api "$base" "$domain" "31333532" "true"   # ESET exists
    test_api "$base" "$domain" "00000001" "false"  # Non-existent
    
    echo ""
done

# Test NGINX proxy specifically
echo "Testing NGINX proxy (icoatlas.sk → www.bizagent.sk)"
echo "---"
echo -n "TEST: CORS headers ... "
cors=$(curl -s -I "$BASE_ICOATLAS/api/company/proxy-search?ico=31333532" 2>&1 | grep -i "access-control-allow-origin")
[[ "$cors" == *"*"* ]] && echo "✅ PASS" && ((PASS++)) || { echo "❌ FAIL"; ((FAIL++)); }

echo -n "TEST: Health endpoint ... "
health=$(curl -s "$BASE_ICOATLAS/health" | jq -r '.status')
[[ "$health" == "ok" ]] && echo "✅ PASS" && ((PASS++)) || { echo "❌ FAIL"; ((FAIL++)); }

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed"
echo "═══════════════════════════════════════════════════════════"

exit $FAIL
