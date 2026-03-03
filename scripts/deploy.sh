#!/bin/bash

#############################################################################
#                    DEPLOY SCRIPT
#  Deploy both variants to production with zero-downtime
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
DEPLOY_DIR="${DEPLOY_DIR:-/opt/zig-toolz}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

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

confirm() {
    local prompt="$1"
    local response

    read -p "$(echo -e ${YELLOW}$prompt${NC}) (y/N): " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Main deployment
main() {
    local variant=$1

    if [ -z "$variant" ]; then
        print_error "Usage: $0 [original|htmx|both]"
        exit 1
    fi

    print_header "Deployment Started"

    # Backup databases first
    print_info "Creating backup before deployment..."
    bash "$(dirname "$0")/backup.sh" || print_error "Backup failed but continuing..."

    # Determine which variants to deploy
    local deploy_original=false
    local deploy_htmx=false

    case "$variant" in
        original) deploy_original=true ;;
        htmx) deploy_htmx=true ;;
        both) deploy_original=true; deploy_htmx=true ;;
        *) print_error "Invalid variant: $variant"; exit 1 ;;
    esac

    # Deploy Original
    if [ "$deploy_original" = true ]; then
        print_header "Deploying Original Variant"

        # Build
        print_info "Building..."
        cd "$ORIGINAL_REPO/backend"
        zig build || { print_error "Build failed"; exit 1; }

        # Create deployment directory
        mkdir -p "$DEPLOY_DIR/original-$TIMESTAMP"

        # Copy binary
        print_info "Copying artifacts..."
        cp -r zig-out/bin/* "$DEPLOY_DIR/original-$TIMESTAMP/"
        cp exchange.db "$DEPLOY_DIR/original-$TIMESTAMP/" 2>/dev/null || true

        # Update symlink (zero-downtime)
        print_info "Activating deployment..."
        ln -sfn "$DEPLOY_DIR/original-$TIMESTAMP" "$DEPLOY_DIR/original"

        print_success "Original deployed to $DEPLOY_DIR/original"
    fi

    # Deploy HTMX-Pure
    if [ "$deploy_htmx" = true ]; then
        print_header "Deploying HTMX-Pure Variant"

        # Build
        print_info "Building..."
        cd "$HTMX_REPO/backend"
        zig build || { print_error "Build failed"; exit 1; }

        # Create deployment directory
        mkdir -p "$DEPLOY_DIR/htmx-$TIMESTAMP"

        # Copy binary
        print_info "Copying artifacts..."
        cp -r zig-out/bin/* "$DEPLOY_DIR/htmx-$TIMESTAMP/"
        cp exchange.db "$DEPLOY_DIR/htmx-$TIMESTAMP/" 2>/dev/null || true

        # Update symlink (zero-downtime)
        print_info "Activating deployment..."
        ln -sfn "$DEPLOY_DIR/htmx-$TIMESTAMP" "$DEPLOY_DIR/htmx"

        print_success "HTMX-Pure deployed to $DEPLOY_DIR/htmx"
    fi

    print_header "Deployment Summary"
    print_success "Deployment completed successfully!"
    echo ""
    echo "Deployment paths:"
    [ "$deploy_original" = true ] && echo "  Original: $DEPLOY_DIR/original -> $DEPLOY_DIR/original-$TIMESTAMP"
    [ "$deploy_htmx" = true ] && echo "  HTMX:     $DEPLOY_DIR/htmx -> $DEPLOY_DIR/htmx-$TIMESTAMP"
    echo ""
    print_info "Backup location: /backups/zig-toolz/"
    print_info "Old deployments can be cleaned up manually"
}

# Run
if confirm "Deploy $1 variant(s) to production?"; then
    main "$1"
else
    print_error "Deployment cancelled"
    exit 1
fi