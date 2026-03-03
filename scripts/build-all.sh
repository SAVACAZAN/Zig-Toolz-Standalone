#!/bin/bash

#############################################################################
#                    BUILD ALL VARIANTS SCRIPT
#  Compile both Zig-toolz-Assembly and HTMX-Pure in parallel
#############################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
ORIGINAL_REPO="${ORIGINAL_REPO:-/home/kiss/Zig-toolz-Assembly}"
HTMX_REPO="${HTMX_REPO:-/home/kiss/Zig-toolz-Assembly-HTMX-Pure}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="/tmp/build-logs-$TIMESTAMP"

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Create log directory
mkdir -p "$LOG_DIR"

print_header "Building All Variants (Parallel Mode)"

# Build Original in background
print_info "Building Original (Zig-toolz-Assembly)..."
(
    cd "$ORIGINAL_REPO/backend"
    zig build > "$LOG_DIR/original.log" 2>&1
    if [ $? -eq 0 ]; then
        echo "ORIGINAL_SUCCESS"
    else
        echo "ORIGINAL_FAILED"
    fi
) &
ORIGINAL_PID=$!

# Build HTMX-Pure in background
print_info "Building HTMX-Pure (Zig-toolz-Assembly-HTMX-Pure)..."
(
    cd "$HTMX_REPO/backend"
    zig build > "$LOG_DIR/htmx.log" 2>&1
    if [ $? -eq 0 ]; then
        echo "HTMX_SUCCESS"
    else
        echo "HTMX_FAILED"
    fi
) &
HTMX_PID=$!

# Wait for both
wait $ORIGINAL_PID
ORIGINAL_EXIT=$?

wait $HTMX_PID
HTMX_EXIT=$?

print_header "Build Results"

if [ $ORIGINAL_EXIT -eq 0 ]; then
    print_success "Original built successfully"
    echo "Binary: $ORIGINAL_REPO/backend/zig-out/bin/zig-exchange-server"
else
    print_error "Original build failed"
    echo "Log: $LOG_DIR/original.log"
fi

if [ $HTMX_EXIT -eq 0 ]; then
    print_success "HTMX-Pure built successfully"
    echo "Binary: $HTMX_REPO/backend/zig-out/bin/zig-exchange-server"
else
    print_error "HTMX-Pure build failed"
    echo "Log: $LOG_DIR/htmx.log"
fi

echo ""
print_info "Build logs: $LOG_DIR/"

if [ $ORIGINAL_EXIT -eq 0 ] && [ $HTMX_EXIT -eq 0 ]; then
    print_success "All builds completed successfully!"
    exit 0
else
    print_error "Some builds failed"
    exit 1
fi