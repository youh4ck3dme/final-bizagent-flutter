#!/bin/bash

# BizAgent Keystore Setup Wizard
# This script guides you through keystore creation and configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════╗"
echo "║   BizAgent Keystore Setup Wizard              ║"
echo "║   Production Signing Configuration             ║"
echo "╚════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo -e "${RED}❌ ERROR: keytool not found!${NC}"
    echo "keytool is part of Java JDK. Please install:"
    echo "  - Ubuntu/Debian: sudo apt-get install openjdk-17-jdk"
    echo "  - macOS: brew install openjdk@17"
    echo "  - Windows: Download from https://adoptium.net/"
    exit 1
fi

echo -e "${GREEN}✅ keytool found${NC}\n"

# Configuration
KEYSTORE_NAME="bizagent-release.keystore"
KEY_ALIAS="bizagent-release"
KEYSTORE_DIR="$HOME/.android/keystores"
KEYSTORE_PATH="$KEYSTORE_DIR/$KEYSTORE_NAME"
KEY_PROPERTIES_PATH="android/key.properties"
VALIDITY_DAYS=10000

# Create keystore directory if it doesn't exist
mkdir -p "$KEYSTORE_DIR"

echo -e "${BLUE}📋 Keystore Configuration:${NC}"
echo "  Location: $KEYSTORE_PATH"
echo "  Alias: $KEY_ALIAS"
echo "  Validity: $VALIDITY_DAYS days (~27 years)"
echo ""

# Check if keystore already exists
if [ -f "$KEYSTORE_PATH" ]; then
    echo -e "${YELLOW}⚠️  WARNING: Keystore already exists!${NC}"
    echo "  Location: $KEYSTORE_PATH"
    echo ""
    read -p "Do you want to create a new keystore? This will OVERWRITE the existing one! (yes/no): " OVERWRITE
    
    if [ "$OVERWRITE" != "yes" ]; then
        echo -e "${BLUE}ℹ️  Using existing keystore${NC}"
    else
        echo -e "${YELLOW}⚠️  Creating new keystore (old one will be backed up)${NC}"
        BACKUP_PATH="${KEYSTORE_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$KEYSTORE_PATH" "$BACKUP_PATH"
        echo -e "${GREEN}✅ Old keystore backed up to: $BACKUP_PATH${NC}"
    fi
fi

# Generate keystore if it doesn't exist
if [ ! -f "$KEYSTORE_PATH" ]; then
    echo -e "\n${BLUE}🔐 Step 1/4: Generate Keystore${NC}"
    echo "You will be prompted for:"
    echo "  1. Keystore password (choose a strong password!)"
    echo "  2. Key password (use the same as keystore password)"
    echo "  3. Your details (name, organization, etc.)"
    echo ""
    
    # Prompt for passwords
    read -sp "Enter keystore password: " STORE_PASS
    echo ""
    read -sp "Confirm keystore password: " STORE_PASS_CONFIRM
    echo ""
    
    if [ "$STORE_PASS" != "$STORE_PASS_CONFIRM" ]; then
        echo -e "${RED}❌ ERROR: Passwords don't match!${NC}"
        exit 1
    fi
    
    if [ ${#STORE_PASS} -lt 6 ]; then
        echo -e "${RED}❌ ERROR: Password must be at least 6 characters!${NC}"
        exit 1
    fi
    
    echo ""
    read -sp "Enter key password (press Enter to use same as keystore): " KEY_PASS
    echo ""
    
    if [ -z "$KEY_PASS" ]; then
        KEY_PASS="$STORE_PASS"
    fi
    
    echo -e "\n${BLUE}📝 Distinguished Name (DN) Information:${NC}"
    echo "This information will be embedded in your certificate."
    echo ""
    
    read -p "Your name (CN): " CN
    read -p "Organizational Unit (OU) [Development]: " OU
    OU=${OU:-Development}
    read -p "Organization (O) [EB-EU s.r.o.]: " ORG
    ORG=${ORG:-"EB-EU s.r.o."}
    read -p "City/Locality (L) [Banská Bystrica]: " CITY
    CITY=${CITY:-"Banská Bystrica"}
    read -p "State/Province (ST) [Slovakia]: " STATE
    STATE=${STATE:-Slovakia}
    read -p "Country Code (C) [SK]: " COUNTRY
    COUNTRY=${COUNTRY:-SK}
    
    DNAME="CN=$CN, OU=$OU, O=$ORG, L=$CITY, ST=$STATE, C=$COUNTRY"
    
    echo ""
    echo -e "${YELLOW}🔨 Generating keystore...${NC}"
    echo "This may take a few moments..."
    echo ""
    
    # Generate keystore
    keytool -genkey -v \
        -keystore "$KEYSTORE_PATH" \
        -alias "$KEY_ALIAS" \
        -keyalg RSA \
        -keysize 2048 \
        -validity $VALIDITY_DAYS \
        -storepass "$STORE_PASS" \
        -keypass "$KEY_PASS" \
        -dname "$DNAME"
    
    echo ""
    echo -e "${GREEN}✅ Keystore generated successfully!${NC}"
    
else
    echo -e "\n${BLUE}🔐 Step 1/4: Keystore Exists${NC}"
    echo -e "${GREEN}✅ Using existing keystore${NC}"
    
    # Prompt for passwords for existing keystore
    read -sp "Enter keystore password: " STORE_PASS
    echo ""
    read -sp "Enter key password (or press Enter if same as keystore): " KEY_PASS
    echo ""
    
    if [ -z "$KEY_PASS" ]; then
        KEY_PASS="$STORE_PASS"
    fi
    
    # Verify keystore
    if ! keytool -list -keystore "$KEYSTORE_PATH" -storepass "$STORE_PASS" &> /dev/null; then
        echo -e "${RED}❌ ERROR: Invalid keystore password!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Keystore verified${NC}"
fi

# Update key.properties
echo -e "\n${BLUE}📝 Step 2/4: Update key.properties${NC}"

cat > "$KEY_PROPERTIES_PATH" << EOF
# Android Signing Configuration
# Generated by setup_keystore.sh on $(date)
# IMPORTANT: DO NOT commit this file to git!

storePassword=$STORE_PASS
keyPassword=$KEY_PASS
keyAlias=$KEY_ALIAS
storeFile=$KEYSTORE_PATH
EOF

echo -e "${GREEN}✅ key.properties updated${NC}"
echo "  Location: $KEY_PROPERTIES_PATH"

# Verify .gitignore
echo -e "\n${BLUE}🔒 Step 3/4: Verify .gitignore${NC}"

GITIGNORE_ANDROID="android/.gitignore"

if grep -q "key.properties" "$GITIGNORE_ANDROID"; then
    echo -e "${GREEN}✅ key.properties already in .gitignore${NC}"
else
    echo "" >> "$GITIGNORE_ANDROID"
    echo "# Signing configs" >> "$GITIGNORE_ANDROID"
    echo "key.properties" >> "$GITIGNORE_ANDROID"
    echo "*.keystore" >> "$GITIGNORE_ANDROID"
    echo "*.jks" >> "$GITIGNORE_ANDROID"
    echo -e "${GREEN}✅ Added key.properties to .gitignore${NC}"
fi

# Display keystore info
echo -e "\n${BLUE}📊 Step 4/4: Keystore Information${NC}"

keytool -list -v -keystore "$KEYSTORE_PATH" -storepass "$STORE_PASS" -alias "$KEY_ALIAS" | grep -A 5 "Alias name:"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              SETUP COMPLETE! ✅                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT SECURITY NOTES:${NC}"
echo ""
echo "1. 🔐 BACKUP YOUR KEYSTORE:"
echo "   Location: $KEYSTORE_PATH"
echo "   Backup to: Google Drive, 1Password, or encrypted USB"
echo "   ${RED}If you lose this file, you CANNOT update your app!${NC}"
echo ""
echo "2. 🔑 SAVE YOUR PASSWORDS:"
echo "   Store in a password manager (1Password, LastPass, etc.)"
echo "   ${RED}Never commit passwords to git!${NC}"
echo ""
echo "3. 📋 KEYSTORE DETAILS:"
echo "   Location: $KEYSTORE_PATH"
echo "   Alias: $KEY_ALIAS"
echo "   Config: $KEY_PROPERTIES_PATH"
echo ""
echo "4. 🚀 NEXT STEPS:"
echo "   - Run: ./scripts/verify_keystore.sh (to verify setup)"
echo "   - Run: flutter build appbundle --release"
echo "   - Upload AAB to Google Play Console"
echo ""
echo -e "${BLUE}Need help? Email: support@bizagent.app${NC}"
echo ""
