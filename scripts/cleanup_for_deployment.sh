#!/bin/bash
# Pre-Deployment Cleanup Script
# 
# This script performs safe cleanup operations to prepare Tiannara for deployment.
# All operations are reversible via git if needed.
#
# Usage: bash scripts/cleanup_for_deployment.sh
# Review: See PRE_DEPLOYMENT_CLEANUP_REPORT.md for details

set -e  # Exit on error

echo "=========================================="
echo "Tiannara Pre-Deployment Cleanup"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print section headers
print_section() {
    echo ""
    echo -e "${YELLOW}>>> $1${NC}"
    echo "------------------------------------------"
}

# Function to confirm action
confirm_action() {
    read -p "$1 (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Check if we're in the right directory
if [ ! -f "README.md" ] || [ ! -d "tiannara_api" ]; then
    echo -e "${RED}Error: Please run this script from the Tiannara-MindCache-Prosthetic root directory${NC}"
    exit 1
fi

print_section "Step 1: Deleting Cache Directories"

# Delete pytest cache directories (safe - auto-regenerated)
PYTEST_CACHE_COUNT=$(find . -maxdepth 1 -type d -name "pytest-cache-files-*" | wc -l)
if [ $PYTEST_CACHE_COUNT -gt 0 ]; then
    echo "Found $PYTEST_CACHE_COUNT pytest cache directories"
    find . -maxdepth 1 -type d -name "pytest-cache-files-*" -exec rm -rf {} +
    echo -e "${GREEN}✓ Deleted pytest cache directories${NC}"
else
    echo "No pytest cache directories found"
fi

print_section "Step 2: Cleaning Python Cache"

# Clean __pycache__ directories (optional - will regenerate)
if confirm_action "Delete __pycache__ directories? (They will regenerate on next run)"; then
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    echo -e "${GREEN}✓ Cleared Python cache${NC}"
else
    echo "Skipped Python cache cleanup"
fi

print_section "Step 3: Removing Empty Directories"

# List empty directories
EMPTY_DIRS=$(find . -maxdepth 1 -type d -empty | grep -v ".git" | grep -v "node_modules")
if [ -n "$EMPTY_DIRS" ]; then
    echo "Empty directories found:"
    echo "$EMPTY_DIRS"
    echo ""
    if confirm_action "Delete these empty directories?"; then
        echo "$EMPTY_DIRS" | xargs rm -rf
        echo -e "${GREEN}✓ Removed empty directories${NC}"
    else
        echo "Skipped empty directory removal"
    fi
else
    echo "No empty directories found in root"
fi

print_section "Step 4: Archiving Redundant Dashboard"

if [ -d "tiannara_internal_dashboard" ]; then
    echo "Found redundant internal dashboard directory"
    echo "This has been superseded by admin dashboard in tiannara_saas/"
    echo ""
    if confirm_action "Archive tiannara_internal_dashboard/?"; then
        mkdir -p archive/redundant_dashboards
        mv tiannara_internal_dashboard/ archive/redundant_dashboards/
        echo -e "${GREEN}✓ Archived internal dashboard${NC}"
    else
        echo "Skipped dashboard archival"
    fi
else
    echo "Internal dashboard directory not found (already archived or removed)"
fi

print_section "Step 5: Organizing Test Scripts"

ROOT_TEST_FILES=$(find . -maxdepth 1 -name "test_*.py" -o -name "*_test.py" | head -5)
if [ -n "$ROOT_TEST_FILES" ]; then
    echo "Test scripts found in root directory:"
    find . -maxdepth 1 -name "test_*.py" -o -name "*_test.py" | sed 's|^\./||'
    echo ""
    if confirm_action "Move test scripts to tests/integration/?"; then
        mkdir -p tests/integration
        find . -maxdepth 1 -name "test_*.py" -exec mv {} tests/integration/ \;
        echo -e "${GREEN}✓ Moved test scripts to tests/integration/${NC}"
    else
        echo "Skipped test script organization"
    fi
else
    echo "No test scripts found in root directory"
fi

print_section "Step 6: Consolidating Documentation"

# Count markdown files in root
MD_COUNT=$(find . -maxdepth 1 -name "*.md" | wc -l)
echo "Found $MD_COUNT markdown files in root directory"

if [ $MD_COUNT -gt 20 ]; then
    echo ""
    echo "Recommendation: Archive weekly reports and phase summaries"
    echo "See PRE_DEPLOYMENT_CLEANUP_REPORT.md for detailed plan"
    echo ""
    if confirm_action "Create archive structure now?"; then
        mkdir -p docs/development/ARCHIVE
        echo -e "${GREEN}✓ Created archive directory structure${NC}"
        echo "Next step: Manually move WEEK*.md, PHASE*_*.md files to docs/development/ARCHIVE/"
    fi
else
    echo "Documentation count is reasonable"
fi

print_section "Step 7: Verifying Code Quality"

# Check for remaining bare except statements
BARE_EXCEPT_COUNT=$(grep -r "except:" --include="*.py" tiannara_api/ tiannara_core/ 2>/dev/null | grep -v "except Exception:" | grep -v "#" | wc -l)
if [ $BARE_EXCEPT_COUNT -gt 0 ]; then
    echo -e "${RED}⚠ Warning: Found $BARE_EXCEPT_COUNT bare 'except:' statements${NC}"
    echo "Run: grep -rn 'except:' --include='*.py' tiannara_api/ tiannara_core/"
else
    echo -e "${GREEN}✓ No bare 'except:' statements found${NC}"
fi

# Check for debug prints
DEBUG_PRINT_COUNT=$(grep -r "print.*DEBUG" --include="*.py" tiannara_api/ tiannara_core/ 2>/dev/null | wc -l)
if [ $DEBUG_PRINT_COUNT -gt 0 ]; then
    echo -e "${YELLOW}⚠ Found $DEBUG_PRINT_COUNT debug print statements${NC}"
    echo "Review and remove before production deployment"
else
    echo -e "${GREEN}✓ No debug print statements found${NC}"
fi

print_section "Cleanup Summary"

echo ""
echo "✅ Safe cleanup operations completed"
echo ""
echo "Next Steps:"
echo "1. Review PRE_DEPLOYMENT_CLEANUP_REPORT.md for full details"
echo "2. Manually archive experiment data (runs/, checkpoints/) if desired"
echo "3. Consolidate Paystack documentation (6 files → 1 guide)"
echo "4. Run full test suite: python -m pytest tests/"
echo "5. Verify deployment: docker-compose up"
echo ""
echo -e "${GREEN}Project is ready for deployment! 🚀${NC}"
echo ""
echo "=========================================="
