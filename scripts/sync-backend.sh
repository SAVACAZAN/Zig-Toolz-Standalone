#!/bin/bash

#############################################################################
#                    BACKEND SYNC SCRIPT
#  Synchronize backend/ code between Zig-toolz-Assembly variants
#############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ORIGINAL_REPO="${ORIGINAL_REPO:-/home/kiss/Zig-toolz-Assembly}"
HTMX_REPO="${HTMX_REPO:-/home/kiss/Zig-toolz-Assembly-HTMX-Pure}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/backend-sync-backup-$TIMESTAMP"

# Functions
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

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if repos exist
check_repos() {
    print_header "Checking Repositories"

    if [ ! -d "$ORIGINAL_REPO/backend" ]; then
        print_error "Original repo not found at $ORIGINAL_REPO"
        exit 1
    fi
    print_success "Original repo found: $ORIGINAL_REPO"

    if [ ! -d "$HTMX_REPO/backend" ]; then
        print_error "HTMX repo not found at $HTMX_REPO"
        exit 1
    fi
    print_success "HTMX repo found: $HTMX_REPO"
}

# Show differences
show_diff() {
    print_header "Analyzing Differences"

    print_info "Files only in Original:"
    diff -r "$ORIGINAL_REPO/backend/src" "$HTMX_REPO/backend/src" --suppress-common-lines 2>/dev/null | grep "^<" | head -5 || echo "  (none)"

    print_info "Files only in HTMX-Pure:"
    diff -r "$ORIGINAL_REPO/backend/src" "$HTMX_REPO/backend/src" --suppress-common-lines 2>/dev/null | grep "^>" | head -5 || echo "  (none)"
}

# Create backup
create_backup() {
    print_header "Creating Backup"

    mkdir -p "$BACKUP_DIR"
    cp -r "$HTMX_REPO/backend" "$BACKUP_DIR/backend-htmx-$TIMESTAMP"
    print_success "Backup created at $BACKUP_DIR"
}

# Sync from Original to HTMX
sync_original_to_htmx() {
    print_header "Syncing: Original → HTMX-Pure"

    # Sync src/ directory
    print_info "Syncing backend/src/..."
    rsync -av --delete \
        "$ORIGINAL_REPO/backend/src/" \
        "$HTMX_REPO/backend/src/" \
        --exclude=".git" \
        --exclude="*.o" \
        --exclude="*.a"

    # Sync build.zig if identical in structure
    if diff "$ORIGINAL_REPO/backend/build.zig" "$HTMX_REPO/backend/build.zig" > /dev/null 2>&1; then
        print_info "build.zig is identical, skipping..."
    else
        print_warning "build.zig differs - review manually"
        print_info "Original: $ORIGINAL_REPO/backend/build.zig"
        print_info "HTMX: $HTMX_REPO/backend/build.zig"
    fi

    print_success "Sync completed"
}

# Sync from HTMX to Original
sync_htmx_to_original() {
    print_header "Syncing: HTMX-Pure → Original"

    print_info "Syncing backend/src/..."
    rsync -av --delete \
        "$HTMX_REPO/backend/src/" \
        "$ORIGINAL_REPO/backend/src/" \
        --exclude=".git" \
        --exclude="*.o" \
        --exclude="*.a"

    print_success "Sync completed"
}

# Commit changes
commit_changes() {
    local repo=$1
    local direction=$2

    print_header "Committing Changes in $direction"

    cd "$repo"

    if git diff --quiet backend/; then
        print_info "No changes in backend/"
        return
    fi

    git add backend/

    case $direction in
        "Original")
            git commit -m "chore: Sync backend from HTMX-Pure variant

Synchronized backend code to keep both implementations in sync.
This ensures bug fixes and improvements are shared across variants.
- Updated: backend/src/ (Zig code)
- Backend logic is now identical between original and HTMX-Pure
- HTMX-Pure UI remains unchanged (server-side templates)" || true
            ;;
        "HTMX-Pure")
            git commit -m "chore: Sync backend from original repository

Synchronized backend code to keep both implementations in sync.
This ensures bug fixes and improvements are shared across variants.
- Updated: backend/src/ (Zig code)
- Backend logic is now identical between original and HTMX-Pure
- HTMX-Pure UI remains unchanged (server-side templates)" || true
            ;;
    esac

    print_success "Changes committed"
}

# Push to GitHub
push_changes() {
    local repo=$1
    local repo_name=$2

    print_header "Pushing to GitHub: $repo_name"

    cd "$repo"

    if [ -z "$(git log origin/main..main 2>/dev/null)" ]; then
        print_info "No new commits to push"
        return
    fi

    print_info "Pushing commits..."
    git push origin main || print_warning "Push failed - check authentication"
    print_success "Pushed to $repo_name"
}

# Main menu
show_menu() {
    print_header "Backend Sync Tool - Main Menu"

    echo "1) Show differences between repos"
    echo "2) Sync Original → HTMX-Pure"
    echo "3) Sync HTMX-Pure → Original"
    echo "4) Full sync with backup (Original → HTMX-Pure)"
    echo "5) Full sync with backup (HTMX-Pure → Original)"
    echo "6) Exit"
    echo ""
}

# Full sync with all steps
full_sync() {
    local direction=$1

    check_repos
    show_diff
    create_backup

    if [ "$direction" = "to_htmx" ]; then
        sync_original_to_htmx
        commit_changes "$HTMX_REPO" "HTMX-Pure"
        push_changes "$HTMX_REPO" "Zig-toolz-Assembly-HTMX-Pure"
    else
        sync_htmx_to_original
        commit_changes "$ORIGINAL_REPO" "Original"
        push_changes "$ORIGINAL_REPO" "Zig-toolz-Assembly"
    fi

    print_header "Sync Complete! ✅"
    print_success "Backup available at: $BACKUP_DIR"
}

# Main
main() {
    if [ $# -eq 0 ]; then
        # Interactive mode
        while true; do
            show_menu
            read -p "Select option (1-6): " choice

            case $choice in
                1) show_diff ;;
                2) full_sync "to_htmx" ;;
                3) full_sync "to_original" ;;
                4)
                    check_repos
                    create_backup
                    sync_original_to_htmx
                    commit_changes "$HTMX_REPO" "HTMX-Pure"
                    ;;
                5)
                    check_repos
                    create_backup
                    sync_htmx_to_original
                    commit_changes "$ORIGINAL_REPO" "Original"
                    ;;
                6)
                    print_success "Exiting"
                    exit 0
                    ;;
                *)
                    print_error "Invalid option"
                    ;;
            esac
        done
    else
        # Command line mode
        case "$1" in
            "to-htmx")
                full_sync "to_htmx"
                ;;
            "to-original")
                full_sync "to_original"
                ;;
            "diff")
                check_repos
                show_diff
                ;;
            *)
                echo "Usage: $0 [to-htmx|to-original|diff]"
                echo ""
                echo "Options:"
                echo "  to-htmx      Sync Original → HTMX-Pure with backup & commit"
                echo "  to-original  Sync HTMX-Pure → Original with backup & commit"
                echo "  diff         Show differences between repos"
                echo ""
                echo "Run without arguments for interactive menu"
                exit 1
                ;;
        esac
    fi
}

# Run main function
main "$@"
