#!/bin/bash

#############################################################################
#                    DOCKER BUILD SCRIPT
#  Build and push Docker images for both variants
#############################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
REGISTRY="${DOCKER_REGISTRY:-docker.io}"
NAMESPACE="${DOCKER_NAMESPACE:-savacazan}"
VERSION="${VERSION:-latest}"
ORIGINAL_REPO="${ORIGINAL_REPO:-/home/kiss/Zig-toolz-Assembly}"
HTMX_REPO="${HTMX_REPO:-/home/kiss/Zig-toolz-Assembly-HTMX-Pure}"

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

# Check Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker not installed"
    exit 1
fi

print_header "Building Docker Images"

# Build Original
print_info "Building Original image..."
docker build \
    -t "$REGISTRY/$NAMESPACE/zig-toolz-assembly:$VERSION" \
    -f "$ORIGINAL_REPO/Dockerfile" \
    "$ORIGINAL_REPO" || print_error "Original build failed"

print_success "Original image built: $REGISTRY/$NAMESPACE/zig-toolz-assembly:$VERSION"

# Build HTMX-Pure
print_info "Building HTMX-Pure image..."
docker build \
    -t "$REGISTRY/$NAMESPACE/zig-toolz-assembly-htmx:$VERSION" \
    -f "$HTMX_REPO/Dockerfile" \
    "$HTMX_REPO" || print_error "HTMX-Pure build failed"

print_success "HTMX-Pure image built: $REGISTRY/$NAMESPACE/zig-toolz-assembly-htmx:$VERSION"

# Show images
echo ""
print_info "Built images:"
docker images | grep "zig-toolz"

echo ""
print_info "To push to registry:"
echo "  docker push $REGISTRY/$NAMESPACE/zig-toolz-assembly:$VERSION"
echo "  docker push $REGISTRY/$NAMESPACE/zig-toolz-assembly-htmx:$VERSION"

print_success "Docker build completed!"