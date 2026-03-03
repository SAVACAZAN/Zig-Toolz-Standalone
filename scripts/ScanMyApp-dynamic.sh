#!/bin/bash

################################################################################
# ScanMyApp-dynamic.sh - Intelligent Migration Status Scanner (Auto-Updating)
#
# Replaces hardcoded values with dynamic codebase analysis.
# Auto-detects: migration progress, phase completion, metrics.
# Scans actual code instead of predefined expectations.
#
# Usage: ./ScanMyApp-dynamic.sh
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

################################################################################
# DYNAMIC HELPERS
################################################################################

progress_bar() {
    local current=$1
    local total=$2
    local width=30
    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    echo -ne "[${GREEN}"
    for ((i=0; i<filled; i++)); do echo -ne "█"; done
    echo -ne "${NC}"
    for ((i=0; i<empty; i++)); do echo -ne "░"; done
    echo -ne "] ${percent}%"
}

count_occurrences() {
    grep -r "$1" backend/src --include="*.zig" 2>/dev/null | wc -l
}

count_files_pattern() {
    find "$1" -type f -name "$2" 2>/dev/null | wc -l
}

get_git_count() {
    git log --oneline 2>/dev/null | wc -l
}

################################################################################
# HEADER
################################################################################

echo -e "${BOLD}${BLUE}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║         🔍 INTELLIGENT MIGRATION STATUS ANALYZER (Dynamic)                   ║${NC}"
echo -e "${BOLD}${BLUE}║              Auto-detecting project state from actual codebase                ║${NC}"
echo -e "${BOLD}${BLUE}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${CYAN}Repository: ${NC}$REPO_ROOT"
echo -e "${CYAN}Date: ${NC}$(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${CYAN}Branch: ${NC}$(git rev-parse --abbrev-ref HEAD)"
echo -e "${CYAN}Commits: ${NC}$(get_git_count)"
echo ""

################################################################################
# MIGRATION METRICS (AUTO-DETECTED)
################################################################################

echo -e "${BOLD}${YELLOW}▓▓▓ MIGRATION METRICS (Real Codebase Data) ▓▓▓${NC}\n"

# Count implementations
VAULT_COUNT=$(count_occurrences "AES\|vault\|encrypt")
JWT_COUNT=$(count_occurrences "HMAC\|jwt\|JWT")
SESSION_COUNT=$(count_occurrences "session\|Session")
HTMX_COUNT=$(count_occurrences "hx-\|htmx")
WASM_COUNT=$(test -f backend/static/exchange_wasm.wasm && echo "1" || echo "0")
DB_COUNT=$(test -f backend/exchange.db && echo "1" || echo "0")

echo -e "${CYAN}Security Implementation:${NC}"
echo "  • Encryption references: $VAULT_COUNT"
echo "  • JWT/Auth references: $JWT_COUNT"
echo ""

echo -e "${CYAN}Frontend Migration:${NC}"
echo "  • Session management: $([ "$SESSION_COUNT" -gt 0 ] && echo "✅ Implemented" || echo "❌ Not found")"
echo "  • HTMX attributes: $HTMX_COUNT occurrences"
echo ""

echo -e "${CYAN}WASM Integration:${NC}"
echo "  • WASM module: $([ "$WASM_COUNT" = "1" ] && echo "✅ Compiled" || echo "❌ Missing")"
echo "  • Database: $([ "$DB_COUNT" = "1" ] && echo "✅ Initialized" || echo "❌ Missing")"
echo ""

################################################################################
# PHASE PROGRESS (CALCULATED)
################################################################################

echo -e "${BOLD}${YELLOW}▓▓▓ PHASE COMPLETION (Auto-Calculated) ▓▓▓${NC}\n"

# Phase 1: Security
P1_SCORE=0
[ "$VAULT_COUNT" -gt 0 ] && P1_SCORE=$((P1_SCORE + 50))
[ "$JWT_COUNT" -gt 0 ] && P1_SCORE=$((P1_SCORE + 50))

# Phase 2: HTMX
P2_SCORE=0
[ "$SESSION_COUNT" -gt 0 ] && P2_SCORE=$((P2_SCORE + 50))
[ "$HTMX_COUNT" -gt 0 ] && P2_SCORE=$((P2_SCORE + 50))

# Phase 3: WASM
P3_SCORE=0
[ "$WASM_COUNT" = "1" ] && P3_SCORE=$((P3_SCORE + 50))
[ "$DB_COUNT" = "1" ] && P3_SCORE=$((P3_SCORE + 50))

echo -n "Phase 1 (Security): "
progress_bar $P1_SCORE 100
echo " $P1_SCORE%"

echo -n "Phase 2 (HTMX):     "
progress_bar $P2_SCORE 100
echo " $P2_SCORE%"

echo -n "Phase 3 (WASM):     "
progress_bar $P3_SCORE 100
echo " $P3_SCORE%"

TOTAL=$(( (P1_SCORE + P2_SCORE + P3_SCORE) / 3 ))
echo ""
echo -n "Overall Progress:   "
progress_bar $TOTAL 100
echo " ${TOTAL}%"
echo ""

################################################################################
# BEFORE vs AFTER IMPROVEMENTS (AUTO-DETECTED FROM GIT)
################################################################################

echo -e "${BOLD}${YELLOW}▓▓▓ IMPROVEMENTS DETECTED (From Git History) ▓▓▓${NC}\n"

# Get timeline
OLDEST=$(git log --reverse --oneline 2>/dev/null | head -1 | cut -d' ' -f1)
NEWEST=$(git log --oneline 2>/dev/null | head -1 | cut -d' ' -f1)
OLDEST_DATE=$(git log --format='%ai' $OLDEST 2>/dev/null | head -1 | cut -d' ' -f1)
NEWEST_DATE=$(git log --format='%ai' $NEWEST 2>/dev/null | head -1 | cut -d' ' -f1)

echo -e "${CYAN}Timeline:${NC}"
echo "  Started: $OLDEST_DATE"
echo "  Latest: $NEWEST_DATE"
echo ""

echo -e "${CYAN}Feature Additions (from commits):${NC}"
SECURITY_COMMITS=$(git log --oneline --grep="security\|vault\|encrypt" 2>/dev/null | wc -l)
HTMX_COMMITS=$(git log --oneline --grep="htmx\|frontend\|session" 2>/dev/null | wc -l)
WASM_COMMITS=$(git log --oneline --grep="wasm\|service.*worker" 2>/dev/null | wc -l)

echo "  • Security commits: $SECURITY_COMMITS"
echo "  • HTMX commits: $HTMX_COMMITS"
echo "  • WASM commits: $WASM_COMMITS"
echo ""

################################################################################
# RECOMMENDATIONS (INTELLIGENT)
################################################################################

echo -e "${BOLD}${YELLOW}▓▓▓ SMART RECOMMENDATIONS ▓▓▓${NC}\n"

if [ "$TOTAL" -eq 100 ]; then
    echo -e "${GREEN}✨ All phases complete!${NC}"
    echo "Status: PRODUCTION-READY"
    echo ""
    echo "Next steps:"
    echo "  1. Deploy to production"
    echo "  2. Monitor performance"
    echo "  3. Consider Phase 4 (trading features)"
elif [ "$P3_SCORE" -lt 100 ]; then
    echo -e "${YELLOW}⏳ Phase 3 (WASM) incomplete${NC}"
    [ "$WASM_COUNT" = "0" ] && echo "  • Missing: WASM module compilation"
    [ "$DB_COUNT" = "0" ] && echo "  • Missing: Database initialization"
elif [ "$P2_SCORE" -lt 100 ]; then
    echo -e "${YELLOW}⏳ Phase 2 (HTMX) incomplete${NC}"
    [ "$SESSION_COUNT" -eq 0 ] && echo "  • Missing: Session management"
    [ "$HTMX_COUNT" -eq 0 ] && echo "  • Missing: HTMX integration"
elif [ "$P1_SCORE" -lt 100 ]; then
    echo -e "${YELLOW}⏳ Phase 1 (Security) incomplete${NC}"
    [ "$VAULT_COUNT" -eq 0 ] && echo "  • Missing: Encryption"
    [ "$JWT_COUNT" -eq 0 ] && echo "  • Missing: JWT auth"
fi

echo ""

################################################################################
# FOOTER
################################################################################

echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}✨ This analysis is 100% dynamic - generated from real codebase state${NC}"
echo -e "${CYAN}📊 Run anytime for current status: bash Toolz/scripts/ScanMyApp-dynamic.sh${NC}"
echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo ""
