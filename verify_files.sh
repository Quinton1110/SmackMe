#!/bin/bash

# SmackMe - File Verification Script
# Checks that all necessary files are present

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR/SmackMeRebuild"

echo "🔍 Verifying SmackMe project files..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track errors
ERRORS=0

# Check Swift files
echo "📝 Checking Swift source files..."
SWIFT_FILES=(
    "AppDelegate.swift"
    "Models/GameModels.swift"
    "Models/GameEngine.swift"
    "Controllers/MainMenuViewController.swift"
    "Controllers/GameViewController.swift"
    "Utilities/GestureManager.swift"
    "Utilities/AudioManager.swift"
)

for file in "${SWIFT_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗${NC} $file - MISSING"
        ((ERRORS++))
    fi
done

# Check Info.plist
echo ""
echo "⚙️  Checking configuration files..."
if [ -f "Info.plist" ]; then
    echo -e "${GREEN}✓${NC} Info.plist"
else
    echo -e "${RED}✗${NC} Info.plist - MISSING"
    ((ERRORS++))
fi

# Check Assets directory
echo ""
echo "🎨 Checking assets..."
if [ -d "Assets.xcassets" ]; then
    PNG_COUNT=$(find Assets.xcassets -name "*.png" | wc -l | tr -d ' ')
    echo -e "${GREEN}✓${NC} Assets.xcassets ($PNG_COUNT PNG files)"

    if [ "$PNG_COUNT" -lt 40 ]; then
        echo -e "${YELLOW}⚠${NC}  Warning: Only $PNG_COUNT PNG files found (expected 50+)"
    fi
else
    echo -e "${RED}✗${NC} Assets.xcassets directory - MISSING"
    ((ERRORS++))
fi

# Check Sounds directory
echo ""
echo "🔊 Checking audio files..."
if [ -d "Sounds" ]; then
    WAV_COUNT=$(find Sounds -name "*.wav" | wc -l | tr -d ' ')
    MP3_COUNT=$(find Sounds -name "*.mp3" | wc -l | tr -d ' ')
    TOTAL_AUDIO=$((WAV_COUNT + MP3_COUNT))
    echo -e "${GREEN}✓${NC} Sounds directory ($WAV_COUNT WAV, $MP3_COUNT MP3 files)"

    if [ "$TOTAL_AUDIO" -lt 80 ]; then
        echo -e "${YELLOW}⚠${NC}  Warning: Only $TOTAL_AUDIO audio files found (expected 90+)"
    fi
else
    echo -e "${RED}✗${NC} Sounds directory - MISSING"
    ((ERRORS++))
fi

# Check documentation
echo ""
echo "📚 Checking documentation..."
if [ -f "README.md" ]; then
    echo -e "${GREEN}✓${NC} README.md"
else
    echo -e "${YELLOW}⚠${NC}  README.md - Missing (recommended)"
fi

if [ -f "CREATE_PROJECT.md" ]; then
    echo -e "${GREEN}✓${NC} CREATE_PROJECT.md"
else
    echo -e "${YELLOW}⚠${NC}  CREATE_PROJECT.md - Missing (recommended)"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ All critical files present!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Read CREATE_PROJECT.md for setup instructions"
    echo "2. Create an Xcode project and add these files"
    echo "3. Build and deploy to your iPhone"
else
    echo -e "${RED}❌ $ERRORS critical file(s) missing${NC}"
    echo "Please ensure all files are in the correct locations"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

exit $ERRORS
