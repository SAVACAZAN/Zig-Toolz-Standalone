#!/bin/bash

#############################################################################
#                    BACKUP SCRIPT
#  Backup databases from both variants with compression
#############################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
ORIGINAL_REPO="${ORIGINAL_REPO:-/home/kiss/Zig-toolz-Assembly}"
HTMX_REPO="${HTMX_REPO:-/home/kiss/Zig-toolz-Assembly-HTMX-Pure}"
BACKUP_BASE_DIR="${BACKUP_DIR:-/backups/zig-toolz}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_BASE_DIR/$TIMESTAMP"

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_header "Backing Up Databases"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup Original
print_info "Backing up Original database..."
if [ -f "$ORIGINAL_REPO/backend/exchange.db" ]; then
    cp "$ORIGINAL_REPO/backend/exchange.db" "$BACKUP_DIR/original-exchange.db"
    print_success "Original database backed up"
else
    print_info "Original database not found (OK if new installation)"
fi

# Backup HTMX-Pure
print_info "Backing up HTMX-Pure database..."
if [ -f "$HTMX_REPO/backend/exchange.db" ]; then
    cp "$HTMX_REPO/backend/exchange.db" "$BACKUP_DIR/htmx-exchange.db"
    print_success "HTMX-Pure database backed up"
else
    print_info "HTMX-Pure database not found (OK if new installation)"
fi

# Compress backups
print_info "Compressing backup..."
cd "$BACKUP_BASE_DIR"
tar -czf "backup-$TIMESTAMP.tar.gz" "$TIMESTAMP/"
print_success "Compressed: backup-$TIMESTAMP.tar.gz"

# Show backup info
echo ""
print_info "Backup location: $BACKUP_DIR"
print_info "Compressed size: $(du -h "$BACKUP_BASE_DIR/backup-$TIMESTAMP.tar.gz" | cut -f1)"

# Cleanup old backups (keep last 7)
print_info "Cleaning up old backups (keeping last 7 days)..."
find "$BACKUP_BASE_DIR" -maxdepth 1 -name "backup-*.tar.gz" -mtime +7 -delete

print_success "Backup completed!"