#!/bin/bash

# Verify keystore and signing configuration

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════╗"
echo "║   BizAgent Keystore Verification              ║"
echo "╚════════════════════════════════════════════════╝"
echo -e "${NC}\n"

ERRORS=0
WARNINGS=0

# Check if key.properties exists
echo -e "${BLUE}📋 Checking key.properties...${NC}"

if [ ! -f "android/key.properties" ]; then
    echo -e "${RED}❌ ERROR: android/key.properties not found!${NC}"
    echo "   Run: ./scripts/setup_keystore.sh"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✅ key.properties exists${NC}"
    
    # Parse key.properties
    source android/key.properties
    
    # Check if all required properties are set
    if [ -z "$storePassword" ]; then
        echo -e "${RED}❌ ERROR: storePassword not set${NC}"
        ERRORS=$((ERRORS + 1))
    fi
    
    if [ -z "$keyPassword" ]; then
        echo -e "${RED}❌ ERROR: keyPassword not set${NC}"
        ERRORS=$((ERRORS + 1))
    fi
    
    if [ -z "$keyAlias" ]; then
        echo -e "${RED}❌ ERROR: keyAlias not set${NC}"
        ERRORS=$((ERRORS + 1))
    fi
    
    if [ -z "$storeFile" ]; then
        echo -e "${RED}❌ ERROR: storeFile not set${NC}"
        ERRORS=$((ERRORS + 1))
    else
        # Check if keystore file exists
        echo -e "\n${BLUE}🔐 Checking keystore file...${NC}"
        
        if [ ! -f "$storeFile" ]; then
            echo -e "${RED}❌ ERROR: Keystore not found: $storeFile${NC}"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "${GREEN}✅ Keystore exists: $storeFile${NC}"
            
            # Verify keystore
            echo -e "\n${BLUE}🔍 Verifying keystore...${NC}"
            
            if keytool -list -keystore "$storeFile" -storepass "$storePassword" -alias "$keyAlias" &> /dev/null; then
                echo -e "${GREEN}✅ Keystore is valid${NC}"
                
                # Display keystore info
                echo -e "\n${BLUE}📊 Keystore Information:${NC}"
                keytool -list -v -keystore "$storeFile" -storepass "$storePassword" -alias "$keyAlias" | grep -E "Alias name:|Creation date:|Valid from:|until:"
                
            else
                echo -e "${RED}❌ ERROR: Invalid keystore or password${NC}"
                ERRORS=$((ERRORS + 1))
            fi
        fi
    fi
fi

# Check .gitignore
echo -e "\n${BLUE}🔒 Checking .gitignore...${NC}"

if grep -q "key.properties" "android/.gitignore"; then
    echo -e "${GREEN}✅ key.properties in .gitignore${NC}"
else
    echo -e "${YELLOW}⚠️  WARNING: key.properties NOT in .gitignore${NC}"
    echo "   Add to android/.gitignore to prevent accidental commits"
    WARNINGS=$((WARNINGS + 1))
fi

# Check build.gradle signing config
echo -e "\n${BLUE}🏗️  Checking build.gradle...${NC}"

if grep -q "signingConfigs" "android/app/build.gradle.kts" || grep -q "signingConfigs" "android/app/build.gradle"; then
    echo -e "${GREEN}✅ Signing config found in build.gradle${NC}"
else
    echo -e "${YELLOW}⚠️  WARNING: Signing config not found in build.gradle${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# Summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}                   SUMMARY                      ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! You're ready to build.${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. flutter clean"
    echo "  2. flutter build appbundle --release"
    echo "  3. Upload to Google Play Console"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS warning(s) found (non-critical)${NC}"
    echo "You can proceed with build, but review warnings."
else
    echo -e "${RED}❌ $ERRORS error(s) found${NC}"
    echo "Please fix errors before building release."
    exit 1
fi

echo ""
