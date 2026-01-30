#!/bin/bash
# script: scripts/record_ico_fixture.sh
# Usage: ./scripts/record_ico_fixture.sh 36396567

ICO=$1
if [ -z "$ICO" ]; then
  echo "Usage: $0 <ICO>"
  exit 1
fi

GATEWAY_URL=${GATEWAY_URL:-"http://localhost:3000"}
OUTPUT_FILE="test/fixtures/ico_${ICO}.json"

echo "Recording IČO $ICO from $GATEWAY_URL..."

# Add contract header to ensure we get the right schema
curl -s -H "X-ICO-LOOKUP-CONTRACT: 1.0.0" \
     "${GATEWAY_URL}/api/company/${ICO}" | jq . > "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
  echo "Success: Saved to $OUTPUT_FILE"
else
  echo "Error: Failed to record fixture"
  exit 1
fi
