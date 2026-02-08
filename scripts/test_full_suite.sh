#!/bin/bash

# Run complete test suite for BizAgent

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════╗"
echo "║   BizAgent Complete Test Suite                 ║"
echo "╚════════════════════════════════════════════════╝"
echo -e "${NC}\n"

START_TIME=$(date +%s)
FAILED=0

# Clean
echo -e "${BLUE}🧹 Step 1/6: Cleaning project...${NC}"
flutter clean
echo -e "${GREEN}✅ Clean complete${NC}\n"

# Get dependencies
echo -e "${BLUE}📦 Step 2/6: Getting dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✅ Dependencies installed${NC}\n"

# Analyze
echo -e "${BLUE}🔍 Step 3/6: Running static analysis...${NC}"
if flutter analyze; then
    echo -e "${GREEN}✅ Analysis passed (0 issues)${NC}\n"
else
    echo -e "${RED}❌ Analysis failed${NC}\n"
    FAILED=1
fi

# Format check
echo -e "${BLUE}✨ Step 4/6: Checking code format...${NC}"
if dart format --set-exit-if-changed .; then
    echo -e "${GREEN}✅ Format check passed${NC}\n"
else
    echo -e "${YELLOW}⚠️  Some files need formatting${NC}"
    echo "Run: dart format ."
    echo ""
fi

# Unit & Widget Tests
echo -e "${BLUE}🧪 Step 5/6: Running unit & widget tests...${NC}"
if flutter test; then
    echo -e "${GREEN}✅ All tests passed${NC}\n"
else
    echo -e "${RED}❌ Some tests failed${NC}\n"
    FAILED=1
fi

# Integration Tests (optional - can be slow)
echo -e "${BLUE}🔗 Step 6/6: Running integration tests...${NC}"
read -p "Run integration tests? (may take several minutes) [y/N]: " RUN_INTEGRATION

if [ "$RUN_INTEGRATION" == "y" ] || [ "$RUN_INTEGRATION" == "Y" ]; then
    if flutter test integration_test/; then
        echo -e "${GREEN}✅ Integration tests passed${NC}\n"
    else
        echo -e "${RED}❌ Integration tests failed${NC}\n"
        FAILED=1
    fi
else
    echo -e "${YELLOW}⏭️  Integration tests skipped${NC}\n"
fi

# Calculate duration
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

# Summary
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}                   SUMMARY                      ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo "Duration: ${MINUTES}m ${SECONDS}s"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          ALL TESTS PASSED! ✅ 🎉              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Your code is ready for:"
    echo "  ✅ Commit & Push"
    echo "  ✅ Pull Request"
    echo "  ✅ Production Build"
    echo ""
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║          SOME TESTS FAILED! ❌                 ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Please fix the failing tests before committing."
    echo ""
    exit 1
fi
