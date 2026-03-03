# 🔄 Backend Sync Guide

**Automatic synchronization script for keeping backend code in sync between Zig-toolz-Assembly variants.**

---

## 📋 Overview

The `sync-backend.sh` script synchronizes the `backend/` directory between:
- **Zig-toolz-Assembly** (Original - React + Zig)
- **Zig-toolz-Assembly-HTMX-Pure** (HTMX variant)

This keeps backend bug fixes and features shared across both implementations while allowing independent frontend code.

---

## 🚀 Quick Start

### Interactive Mode (Recommended)
```bash
bash Toolz/scripts/sync-backend.sh
```

Shows menu with options:
1. Show differences
2. Sync Original → HTMX-Pure
3. Sync HTMX-Pure → Original
4. Full sync with backup
5. Exit

### Command Line Mode
```bash
# Show differences between backends
bash Toolz/scripts/sync-backend.sh diff

# Sync Original → HTMX-Pure
bash Toolz/scripts/sync-backend.sh to-htmx

# Sync HTMX-Pure → Original
bash Toolz/scripts/sync-backend.sh to-original
```

---

## 🔍 What Gets Synced

### ✅ SYNCED (Identical in Both)
```
backend/src/
├── auth/              (Authentication logic)
├── config/            (Configuration)
├── crypto/            (Crypto functions)
├── db/                (Database layer)
├── exchange/          (Exchange APIs - LCX, Kraken, Coinbase)
├── models/            (Data structures)
├── session/           (Session management)
├── utils/             (Utilities)
├── wasm/              (WebAssembly code)
└── ws/                (WebSocket implementation)
```

### ❌ NOT SYNCED (Different Between Variants)
```
backend/src/templates/    (HTML templates - only in original/HTMX-Pure)
frontend/                 (React UI - only in original)
```

---

## 📊 Common Workflows

### Scenario 1: Bug Fix in Backend

**You find a bug in the Zig code:**

```bash
# Fix the bug in Zig-toolz-Assembly
cd /home/kiss/Zig-toolz-Assembly/backend
# ... make changes ...
git add -A
git commit -m "fix: Database query performance issue"

# Now sync to HTMX-Pure variant
bash Toolz/scripts/sync-backend.sh to-htmx
```

**Result:**
- ✅ Bug fix applied to HTMX-Pure backend too
- ✅ Automatic backup created
- ✅ Changes committed and pushed to GitHub

---

### Scenario 2: Add New Exchange API

**You want to support a new exchange:**

```bash
# Add new exchange in original
cd /home/kiss/Zig-toolz-Assembly/backend/src/exchange
# ... create new-exchange.zig ...

# Test it
cd /home/kiss/Zig-toolz-Assembly/backend
zig build test

# Once working, sync to HTMX-Pure
bash Toolz/scripts/sync-backend.sh to-htmx
```

---

### Scenario 3: WebSocket Improvement

**You optimize the WebSocket implementation:**

```bash
# Make changes in either repo
# ... edit backend/src/ws/ ...

# Sync the improvement
bash Toolz/scripts/sync-backend.sh [to-htmx|to-original]

# Both variants now have the same optimized code!
```

---

## 🛡️ Safety Features

### Automatic Backups
```
/tmp/backend-sync-backup-YYYYMMDD_HHMMSS/
└── backend-htmx-YYYYMMDD_HHMMSS/
```

Backups are created BEFORE any sync operation.

### Meaningful Commits
```
chore: Sync backend from original repository

Synchronized backend code to keep both implementations in sync.
This ensures bug fixes and improvements are shared across variants.
- Updated: backend/src/ (Zig code)
- Backend logic is now identical between original and HTMX-Pure
- HTMX-Pure UI remains unchanged (server-side templates)
```

### Git History Preserved
- All sync operations are committed with clear messages
- Can be reviewed with `git log`
- Can be reverted if needed with `git revert`

---

## ⚙️ Configuration

Set custom repo paths:

```bash
# Override default locations
export ORIGINAL_REPO="/path/to/original"
export HTMX_REPO="/path/to/htmx-pure"

bash Toolz/scripts/sync-backend.sh to-htmx
```

---

## 🔧 Troubleshooting

### "Repo not found"
```bash
# Fix: Check repo paths
ls -la /home/kiss/Zig-toolz-Assembly/backend
ls -la /home/kiss/Zig-toolz-Assembly-HTMX-Pure/backend
```

### "Git push failed"
```bash
# Ensure authentication
git -C /home/kiss/Zig-toolz-Assembly status
git -C /home/kiss/Zig-toolz-Assembly-HTMX-Pure status

# Check remotes
git -C /home/kiss/Zig-toolz-Assembly remote -v
```

### "Merge conflicts"
```bash
# The script uses rsync with --delete
# This overwrites the destination completely
# No conflicts should occur
```

### Restore from Backup
```bash
# Backups are stored in /tmp/backend-sync-backup-*/
# Restore manually if needed:
cp -r /tmp/backend-sync-backup-TIMESTAMP/backend-htmx-TIMESTAMP/* \
      /home/kiss/Zig-toolz-Assembly-HTMX-Pure/backend/
```

---

## 📅 Scheduling Regular Syncs

### Using Cron (Linux/Mac)

```bash
# Edit crontab
crontab -e

# Add this line to sync daily at 2 AM
0 2 * * * bash /home/kiss/Zig-toolz-Assembly/Toolz/scripts/sync-backend.sh to-htmx >> /var/log/backend-sync.log 2>&1
```

### Using Task Scheduler (Windows)

```batch
# Create a batch script
REM sync-backend.bat
bash %USERPROFILE%\Zig-toolz-Assembly\Toolz\scripts\sync-backend.sh to-htmx
```

Then schedule with Windows Task Scheduler

---

## 📝 Script Details

### What It Does
1. **Checks repos exist** - Validates both directories
2. **Shows differences** - Lists what's different
3. **Creates backup** - Safe copy before sync
4. **Syncs code** - Uses rsync with --delete
5. **Commits changes** - Auto-commits to git
6. **Pushes to GitHub** - Uploads commits

### What It Doesn't Do
- ❌ Sync frontend code (intentional)
- ❌ Sync templates (keep independent)
- ❌ Merge conflicts (overwrites destination)
- ❌ Create branches (works on main)

---

## 🎯 Best Practices

1. **Always check diff first**
   ```bash
   bash Toolz/scripts/sync-backend.sh diff
   ```

2. **Sync from main development branch**
   - Make changes in original (more complete)
   - Then sync to HTMX-Pure

3. **Review commits after sync**
   ```bash
   git -C /home/kiss/Zig-toolz-Assembly-HTMX-Pure log --oneline -5
   ```

4. **Test after sync**
   ```bash
   cd /home/kiss/Zig-toolz-Assembly-HTMX-Pure/backend
   zig build test
   ```

5. **Keep frontend changes separate**
   - Don't add React code expecting it to sync
   - Frontend is intentionally independent

---

## 🚨 Important Notes

### No Frontend Sync
The script ONLY syncs `backend/src/` code. Frontend implementations remain separate:
- Original: React 18 TypeScript
- HTMX-Pure: Server-side HTMX templates

This is intentional - each variant should have its own UI.

### Build Files Not Synced
- `backend/build.zig` - Compared but not auto-synced (review manually)
- `.zig-cache/` - Excluded (local build cache)
- `*.o`, `*.a` - Excluded (object files)

### What If They Differ?
If `build.zig` differs between variants, the script will warn you:
```
⚠️  build.zig differs - review manually
```

Review changes manually before syncing more frequently.

---

## 📞 Support

For issues with the script:

1. Check repository structure:
   ```bash
   bash Toolz/scripts/sync-backend.sh diff
   ```

2. Review backup location:
   ```bash
   ls -la /tmp/backend-sync-backup-*/
   ```

3. Check git status:
   ```bash
   git -C /home/kiss/Zig-toolz-Assembly status
   git -C /home/kiss/Zig-toolz-Assembly-HTMX-Pure status
   ```

---

**Happy syncing!** 🚀