#!/bin/bash

#############################################################################
#                    MONITOR SCRIPT
#  Real-time monitoring of both application servers
#############################################################################

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
ORIGINAL_PORT=8000
HTMX_PORT=8001
INTERVAL=5  # seconds

print_header() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           ZIG-TOOLZ-ASSEMBLY MONITOR (Real-time)       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

check_server() {
    local port=$1
    local name=$2

    if nc -z 127.0.0.1 $port 2>/dev/null; then
        echo -e "${GREEN}● $name${NC} (Port $port): ${GREEN}ONLINE${NC}"

        # Get process info
        if command -v lsof &> /dev/null; then
            local pid=$(lsof -i :$port -t 2>/dev/null | head -1)
            if [ ! -z "$pid" ]; then
                local cpu=$(ps -p $pid -o %cpu= 2>/dev/null | tr -d ' ')
                local mem=$(ps -p $pid -o %mem= 2>/dev/null | tr -d ' ')
                echo "  PID: $pid | CPU: ${cpu}% | Memory: ${mem}%"
            fi
        fi
    else
        echo -e "${RED}● $name${NC} (Port $port): ${RED}OFFLINE${NC}"
    fi
}

check_health() {
    local port=$1
    local name=$2

    if command -v curl &> /dev/null; then
        local response=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:$port/health 2>/dev/null)
        if [ "$response" = "200" ]; then
            echo -e "${GREEN}  Health: OK (HTTP $response)${NC}"
        else
            echo -e "${YELLOW}  Health: HTTP $response${NC}"
        fi
    fi
}

# Main loop
while true; do
    print_header

    echo "Original Variant:"
    check_server $ORIGINAL_PORT "Zig-toolz-Assembly"
    check_health $ORIGINAL_PORT "original"

    echo ""
    echo "HTMX-Pure Variant:"
    check_server $HTMX_PORT "Zig-toolz-Assembly-HTMX-Pure"
    check_health $HTMX_PORT "htmx"

    echo ""
    echo "System:"
    if command -v uptime &> /dev/null; then
        uptime
    fi

    echo ""
    echo -e "${YELLOW}Refreshing in ${INTERVAL}s... (Press Ctrl+C to exit)${NC}"

    sleep $INTERVAL
done