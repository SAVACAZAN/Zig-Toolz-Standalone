#!/bin/bash

#############################################################################
#                    HEALTH CHECK SCRIPT
#  Verify both servers and dependencies are working
#############################################################################

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
ORIGINAL_REPO="${ORIGINAL_REPO:-/home/kiss/Zig-toolz-Assembly}"
HTMX_REPO="${HTMX_REPO:-/home/kiss/Zig-toolz-Assembly-HTMX-Pure}"

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"
}

check_command() {
    local cmd=$1
    local name=$2

    if command -v "$cmd" &> /dev/null; then
        local version=$("$cmd" --version 2>/dev/null | head -1 || echo "installed")
        echo -e "${GREEN}✅${NC} $name: $version"
        return 0
    else
        echo -e "${RED}❌${NC} $name: NOT INSTALLED"
        return 1
    fi
}

check_file() {
    local file=$1
    local name=$2

    if [ -f "$file" ]; then
        local size=$(du -h "$file" | cut -f1)
        echo -e "${GREEN}✅${NC} $name: $size"
        return 0
    else
        echo -e "${RED}❌${NC} $name: NOT FOUND"
        return 1
    fi
}

print_header "Health Check"

# Check dependencies
echo "Dependencies:"
check_command "zig" "Zig"
check_command "git" "Git"
check_command "curl" "curl"
check_command "docker" "Docker"

echo ""
echo "Repositories:"
if [ -d "$ORIGINAL_REPO" ]; then
    echo -e "${GREEN}✅${NC} Original repo: $ORIGINAL_REPO"
else
    echo -e "${RED}❌${NC} Original repo: NOT FOUND"
fi

if [ -d "$HTMX_REPO" ]; then
    echo -e "${GREEN}✅${NC} HTMX repo: $HTMX_REPO"
else
    echo -e "${RED}❌${NC} HTMX repo: NOT FOUND"
fi

echo ""
echo "Build Artifacts:"
check_file "$ORIGINAL_REPO/backend/zig-out/bin/zig-exchange-server" "Original binary"
check_file "$HTMX_REPO/backend/zig-out/bin/zig-exchange-server" "HTMX binary"

echo ""
echo "Databases:"
check_file "$ORIGINAL_REPO/backend/exchange.db" "Original database"
check_file "$HTMX_REPO/backend/exchange.db" "HTMX database"

echo ""
echo "Server Status:"
if nc -z 127.0.0.1 8000 2>/dev/null; then
    echo -e "${GREEN}✅${NC} Original server running on 8000"
else
    echo -e "${YELLOW}⚠️${NC}  Original server NOT running on 8000"
fi

if nc -z 127.0.0.1 8001 2>/dev/null; then
    echo -e "${GREEN}✅${NC} HTMX server running on 8001"
else
    echo -e "${YELLOW}⚠️${NC}  HTMX server NOT running on 8001"
fi

echo ""
print_header "Health Check Complete"