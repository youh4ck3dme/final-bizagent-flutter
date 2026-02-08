#!/bin/bash

# Validate Google Play Store assets

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════╗"
echo "║   BizAgent Asset Validator                     ║"
echo "║   Google Play Store Requirements               ║"
echo "╚════════════════════════════════════════════════╝"
echo -e "${NC}\n"

ERRORS=0
WARNINGS=0
PASSED=0

ASSETS_DIR="google_play_assets"

# Helper function to check image
check_image() {
    local file=$1
    local expected_width=$2
    local expected_height=$3
    local max_size_mb=$4
    local name=$5
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ $name: NOT FOUND${NC}"
        echo "   Expected: $file"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
    
    echo -e "${GREEN}✅ $name: Found${NC}"
    
    # Check if ImageMagick is installed
    if command -v identify &> /dev/null; then
        # Get dimensions
        dimensions=$(identify -format "%wx%h" "$file" 2>/dev/null)
        width=$(echo $dimensions | cut -d'x' -f1)
        height=$(echo $dimensions | cut -d'x' -f2)
        
        if [ "$width" != "$expected_width" ] || [ "$height" != "$expected_height" ]; then
            echo -e "${RED}   ❌ Dimensions: ${width}x${height} (expected ${expected_width}x${expected_height})${NC}"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "${GREEN}   ✅ Dimensions: ${width}x${height}${NC}"
            PASSED=$((PASSED + 1))
        fi
        
        # Check file size
        size_bytes=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
        size_mb=$(echo "scale=2; $size_bytes / 1024 / 1024" | bc)
        max_bytes=$(echo "$max_size_mb * 1024 * 1024" | bc)
        
        if (( $(echo "$size_bytes > $max_bytes" | bc -l) )); then
            echo -e "${RED}   ❌ Size: ${size_mb}MB (max ${max_size_mb}MB)${NC}"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "${GREEN}   ✅ Size: ${size_mb}MB${NC}"
            PASSED=$((PASSED + 1))
        fi
        
        # Check format
        format=$(identify -format "%m" "$file" 2>/dev/null)
        if [ "$format" != "PNG" ] && [ "$format" != "JPEG" ]; then
            echo -e "${YELLOW}   ⚠️  Format: $format (recommend PNG or JPEG)${NC}"
            WARNINGS=$((WARNINGS + 1))
        else
            echo -e "${GREEN}   ✅ Format: $format${NC}"
            PASSED=$((PASSED + 1))
        fi
    else
        echo -e "${YELLOW}   ⚠️  Install ImageMagick for detailed validation${NC}"
        echo "      brew install imagemagick  # macOS"
        echo "      apt-get install imagemagick  # Ubuntu"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    echo ""
}

# Check App Icon
echo -e "${BLUE}📱 Checking App Icon...${NC}"
check_image "$ASSETS_DIR/icons/app_icon_512.png" 512 512 1 "App Icon (512x512)"

# Check Feature Graphic
echo -e "${BLUE}🖼️  Checking Feature Graphic...${NC}"
check_image "$ASSETS_DIR/feature_graphic/feature_graphic.png" 1024 500 1 "Feature Graphic (1024x500)"

# Check Phone Screenshots
echo -e "${BLUE}📸 Checking Phone Screenshots...${NC}"

SCREENSHOT_DIR="$ASSETS_DIR/screenshots/phone"
SCREENSHOT_COUNT=0

if [ -d "$SCREENSHOT_DIR" ]; then
    for screenshot in "$SCREENSHOT_DIR"/*.png "$SCREENSHOT_DIR"/*.jpg; do
        if [ -f "$screenshot" ]; then
            SCREENSHOT_COUNT=$((SCREENSHOT_COUNT + 1))
            echo -e "${GREEN}✅ Screenshot $SCREENSHOT_COUNT: $(basename "$screenshot")${NC}"
            
            # Check if ImageMagick is available
            if command -v identify &> /dev/null; then
                dimensions=$(identify -format "%wx%h" "$screenshot" 2>/dev/null)
                width=$(echo $dimensions | cut -d'x' -f1)
                height=$(echo $dimensions | cut -d'x' -f2)
                
                # Calculate aspect ratio
                aspect=$(echo "scale=2; $width / $height" | bc)
                
                # Check if 16:9 or 9:16
                is_16_9=$(echo "$aspect >= 1.7 && $aspect <= 1.8" | bc)
                is_9_16=$(echo "$aspect >= 0.55 && $aspect <= 0.6" | bc)
                
                if [ "$is_16_9" -eq 1 ] || [ "$is_9_16" -eq 1 ]; then
                    echo -e "${GREEN}   ✅ Aspect ratio: OK (${width}x${height})${NC}"
                else
                    echo -e "${YELLOW}   ⚠️  Aspect ratio: ${width}x${height} (recommend 16:9 or 9:16)${NC}"
                    WARNINGS=$((WARNINGS + 1))
                fi
                
                # Check minimum dimension
                if [ "$width" -lt 320 ] || [ "$height" -lt 320 ]; then
                    echo -e "${RED}   ❌ Too small: min 320px on shortest side${NC}"
                    ERRORS=$((ERRORS + 1))
                fi
            fi
            
            echo ""
        fi
    done
else
    echo -e "${RED}❌ Screenshot directory not found: $SCREENSHOT_DIR${NC}"
    ERRORS=$((ERRORS + 1))
fi

if [ $SCREENSHOT_COUNT -lt 2 ]; then
    echo -e "${RED}❌ Insufficient screenshots: $SCREENSHOT_COUNT (minimum 2 required)${NC}"
    ERRORS=$((ERRORS + 1))
elif [ $SCREENSHOT_COUNT -gt 8 ]; then
    echo -e "${YELLOW}⚠️  Too many screenshots: $SCREENSHOT_COUNT (maximum 8)${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✅ Screenshot count: $SCREENSHOT_COUNT (2-8 required)${NC}"
    PASSED=$((PASSED + 1))
fi

echo ""

# Check Store Listings
echo -e "${BLUE}📝 Checking Store Listing Texts...${NC}"

check_text_file() {
    local file=$1
    local max_length=$2
    local name=$3
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ $name: NOT FOUND${NC}"
        echo "   Expected: $file"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
    
    content=$(cat "$file")
    length=${#content}
    
    if [ $length -eq 0 ]; then
        echo -e "${RED}❌ $name: EMPTY${NC}"
        ERRORS=$((ERRORS + 1))
    elif [ $length -gt $max_length ]; then
        echo -e "${RED}❌ $name: TOO LONG (${length}/${max_length} chars)${NC}"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}✅ $name: ${length}/${max_length} chars${NC}"
        PASSED=$((PASSED + 1))
    fi
}

# Slovak
echo -e "\n${BLUE}🇸🇰 Slovak (sk-SK):${NC}"
check_text_file "$ASSETS_DIR/store_listings/sk_SK/title.txt" 50 "Title"
check_text_file "$ASSETS_DIR/store_listings/sk_SK/short_description.txt" 80 "Short Description"
check_text_file "$ASSETS_DIR/store_listings/sk_SK/full_description.txt" 4000 "Full Description"

# English
echo -e "\n${BLUE}🇺🇸 English (en-US):${NC}"
check_text_file "$ASSETS_DIR/store_listings/en_US/title.txt" 50 "Title"
check_text_file "$ASSETS_DIR/store_listings/en_US/short_description.txt" 80 "Short Description"
check_text_file "$ASSETS_DIR/store_listings/en_US/full_description.txt" 4000 "Full Description"

# Summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}                   SUMMARY                      ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Passed: $PASSED${NC}"
echo -e "${YELLOW}⚠️  Warnings: $WARNINGS${NC}"
echo -e "${RED}❌ Errors: $ERRORS${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║       ALL ASSETS READY FOR UPLOAD! ✅          ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Go to Google Play Console"
    echo "  2. Upload assets from: $ASSETS_DIR/"
    echo "  3. Fill in store listing"
    echo "  4. Submit for review"
else
    echo -e "${RED}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║         PLEASE FIX ERRORS FIRST! ❌            ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "See errors above and fix before uploading."
    exit 1
fi

echo ""
