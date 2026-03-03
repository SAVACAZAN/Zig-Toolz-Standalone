# 🚀 Full Automation Suite Guide

**Complete CI/CD pipeline scripts for Zig-toolz-Assembly applications**

---

## 📋 Quick Reference

| Script | Purpose | Runtime | Usage |
|--------|---------|---------|-------|
| `build-all.sh` | Compile both variants | ~2-3 min | `bash Toolz/scripts/build-all.sh` |
| `test-all.sh` | Run all tests | ~1-2 min | `bash Toolz/scripts/test-all.sh` |
| `health-check.sh` | System diagnostics | ~5 sec | `bash Toolz/scripts/health-check.sh` |
| `backup.sh` | Backup databases | ~10 sec | `bash Toolz/scripts/backup.sh` |
| `monitor.sh` | Real-time monitoring | ∞ loop | `bash Toolz/scripts/monitor.sh` |
| `docker-build.sh` | Build Docker images | ~5 min | `bash Toolz/scripts/docker-build.sh` |
| `deploy.sh` | Production deploy | ~3-5 min | `bash Toolz/scripts/deploy.sh [original\|htmx\|both]` |
| `sync-backend.sh` | Sync backend code | ~30 sec | `bash Toolz/scripts/sync-backend.sh [to-htmx\|to-original]` |

---

## 🏗️ Full Automation Workflow

### Daily Development

```bash
# Morning: Check system health
bash Toolz/scripts/health-check.sh

# Make changes, then build
bash Toolz/scripts/build-all.sh

# Run tests
bash Toolz/scripts/test-all.sh

# Sync backends if changed original
bash Toolz/scripts/sync-backend.sh to-htmx

# Backup before leaving
bash Toolz/scripts/backup.sh
```

### Production Deployment

```bash
# 1. Make sure everything passes tests
bash Toolz/scripts/test-all.sh || exit 1

# 2. Build production binaries
bash Toolz/scripts/build-all.sh || exit 1

# 3. Create Docker images
bash Toolz/scripts/docker-build.sh

# 4. Deploy to production
bash Toolz/scripts/deploy.sh both

# 5. Monitor deployment
bash Toolz/scripts/monitor.sh
```

### Emergency Operations

```bash
# Health check (find issues)
bash Toolz/scripts/health-check.sh

# Create backup immediately
bash Toolz/scripts/backup.sh

# Monitor servers
bash Toolz/scripts/monitor.sh

# Deploy hotfix
bash Toolz/scripts/deploy.sh original
```

---

## 📖 Detailed Script Documentation

### 1. build-all.sh
**Build both Zig variants in parallel**

```bash
bash Toolz/scripts/build-all.sh
```

**What it does:**
- Compiles Original and HTMX-Pure simultaneously
- ~50% faster than sequential builds
- Creates timestamped logs for debugging

**Output:**
```
Binaries:
  Original: backend/zig-out/bin/zig-exchange-server
  HTMX-Pure: backend/zig-out/bin/zig-exchange-server

Logs: /tmp/build-logs-YYYYMMDD_HHMMSS/
```

---

### 2. test-all.sh
**Run backend tests on both variants**

```bash
bash Toolz/scripts/test-all.sh
```

**What it does:**
- Executes `zig build test` on both backends
- Parallel test execution
- Ensures no regressions between variants

**Exit codes:**
- `0` - All tests passed
- `1` - Some tests failed (see logs)

---

### 3. health-check.sh
**Verify system and application health**

```bash
bash Toolz/scripts/health-check.sh
```

**Checks:**
- ✅ Zig, Git, curl, Docker installed
- ✅ Repository directories exist
- ✅ Build artifacts present
- ✅ Database files exist
- ✅ Servers running on ports 8000/8001

**Use when:**
- Debugging connectivity issues
- Verifying deployment success
- Before major operations

---

### 4. backup.sh
**Backup both databases with compression**

```bash
bash Toolz/scripts/backup.sh
```

**What it does:**
- Copies both exchange.db files
- Compresses into tar.gz
- Stores with timestamp
- Auto-deletes backups older than 7 days

**Backup location:**
```
/backups/zig-toolz/
├── YYYYMMDD_HHMMSS/
│   ├── original-exchange.db
│   └── htmx-exchange.db
└── backup-YYYYMMDD_HHMMSS.tar.gz
```

**Restore from backup:**
```bash
cd /backups/zig-toolz
tar -xzf backup-YYYYMMDD_HHMMSS.tar.gz
cp YYYYMMDD_HHMMSS/original-exchange.db /path/to/original/backend/
cp YYYYMMDD_HHMMSS/htmx-exchange.db /path/to/htmx/backend/
```

---

### 5. monitor.sh
**Real-time server monitoring**

```bash
bash Toolz/scripts/monitor.sh
```

**Displays:**
- Server status (ONLINE/OFFLINE)
- Process ID, CPU, Memory usage
- Health endpoint responses
- System uptime

**Refresh rate:** Every 5 seconds (customizable)

**Exit:** Press Ctrl+C

---

### 6. docker-build.sh
**Build Docker images for deployment**

```bash
bash Toolz/scripts/docker-build.sh
```

**Configuration:**
```bash
# Custom registry
export DOCKER_REGISTRY="gcr.io"
export DOCKER_NAMESPACE="my-org"
export VERSION="v1.0.0"

bash Toolz/scripts/docker-build.sh
```

**Output:**
```
Images created:
  - docker.io/savacazan/zig-toolz-assembly:latest
  - docker.io/savacazan/zig-toolz-assembly-htmx:latest
```

**Push to registry:**
```bash
docker push docker.io/savacazan/zig-toolz-assembly:latest
docker push docker.io/savacazan/zig-toolz-assembly-htmx:latest
```

---

### 7. deploy.sh
**Production deployment with zero-downtime**

```bash
# Deploy original only
bash Toolz/scripts/deploy.sh original

# Deploy HTMX-Pure only
bash Toolz/scripts/deploy.sh htmx

# Deploy both variants
bash Toolz/scripts/deploy.sh both
```

**Deployment process:**
1. Creates backup (auto-backup.sh)
2. Builds binaries
3. Copies to /opt/zig-toolz/
4. Creates symlinks for zero-downtime
5. Old deployments kept for rollback

**Rollback:**
```bash
# List deployments
ls -la /opt/zig-toolz/original*/
ls -la /opt/zig-toolz/htmx*/

# Rollback to previous
ln -sfn /opt/zig-toolz/original-YYYYMMDD_HHMMSS /opt/zig-toolz/original
```

---

### 8. sync-backend.sh
**Sync backend between variants**

```bash
# Interactive menu
bash Toolz/scripts/sync-backend.sh

# Or direct
bash Toolz/scripts/sync-backend.sh to-htmx
bash Toolz/scripts/sync-backend.sh diff
```

See [SYNC_GUIDE.md](./SYNC_GUIDE.md) for details.

---

## 🔧 Configuration

### Environment Variables

```bash
# Repository locations
export ORIGINAL_REPO="/custom/path/original"
export HTMX_REPO="/custom/path/htmx"

# Deployment
export DEPLOY_DIR="/custom/deploy/path"

# Docker
export DOCKER_REGISTRY="gcr.io"
export DOCKER_NAMESPACE="my-org"
export VERSION="v1.0.0"

# Backup
export BACKUP_DIR="/custom/backup/path"

# Monitor interval
export MONITOR_INTERVAL=10  # seconds
```

### Default Locations

```bash
# Repositories (detected automatically)
/home/kiss/Zig-toolz-Assembly
/home/kiss/Zig-toolz-Assembly-HTMX-Pure

# Deployment (if not custom)
/opt/zig-toolz/

# Backups
/backups/zig-toolz/

# Logs
/tmp/build-logs-*/
/tmp/test-logs-*/
```

---

## 📅 Scheduling with Cron

### Daily Backups
```bash
# Add to crontab -e
0 2 * * * bash /path/to/backup.sh >> /var/log/zig-backup.log 2>&1
```

### Nightly Builds
```bash
# Build every night at midnight
0 0 * * * bash /path/to/build-all.sh >> /var/log/zig-build.log 2>&1
```

### Weekly Tests
```bash
# Test every Sunday at 3 AM
0 3 * * 0 bash /path/to/test-all.sh >> /var/log/zig-test.log 2>&1
```

### Auto-Deploy on Changes
```bash
# Use with git hooks:
cat > .git/hooks/post-merge << 'EOF'
#!/bin/bash
bash Toolz/scripts/sync-backend.sh to-htmx
bash Toolz/scripts/build-all.sh
bash Toolz/scripts/test-all.sh
bash Toolz/scripts/deploy.sh both
EOF
chmod +x .git/hooks/post-merge
```

---

## 🚨 Troubleshooting

### Build Fails
```bash
# Check logs
cat /tmp/build-logs-*/original.log
cat /tmp/build-logs-*/htmx.log

# Check health
bash Toolz/scripts/health-check.sh

# Clean and rebuild
cd backend && zig build clean && zig build
```

### Deploy Fails
```bash
# Restore from backup
bash Toolz/scripts/backup.sh  # Create restore point

# Check health
bash Toolz/scripts/health-check.sh

# Check logs
ls -la /opt/zig-toolz/
cat /opt/zig-toolz/original/build.log
```

### Monitoring Issues
```bash
# Kill monitor process
pkill -f "monitor.sh"

# Test connectivity
curl http://127.0.0.1:8000/health
curl http://127.0.0.1:8001/health
```

---

## 📊 Automation Metrics

**Parallel vs Sequential:**

| Task | Sequential | Parallel | Savings |
|------|-----------|----------|---------|
| Build both | 4-6 min | 2-3 min | ~50% |
| Test both | 2-3 min | 1-2 min | ~50% |
| Sync + Build + Test | 8-10 min | 5-6 min | ~40% |

**Time to Deploy:**
- Backup: ~10 sec
- Build: ~2-3 min
- Deploy: ~30 sec
- **Total:** ~3-4 min

---

## ✅ Best Practices

1. **Always test before deploy**
   ```bash
   bash Toolz/scripts/test-all.sh || exit 1
   bash Toolz/scripts/deploy.sh both
   ```

2. **Backup before major changes**
   ```bash
   bash Toolz/scripts/backup.sh
   bash Toolz/scripts/sync-backend.sh to-htmx
   ```

3. **Monitor after deployment**
   ```bash
   bash Toolz/scripts/deploy.sh both
   bash Toolz/scripts/monitor.sh  # Watch for issues
   ```

4. **Keep logs organized**
   - Logs rotate into `/tmp/` by default
   - Consider moving to persistent storage
   - Archive weekly for compliance

5. **Schedule backups**
   - Daily at off-peak hours
   - Keep 7+ days of backups
   - Test restore procedures quarterly

---

## 🎯 Common Workflows

### Development Cycle
```bash
git checkout -b feature/new-feature
# ... make changes ...
bash Toolz/scripts/build-all.sh
bash Toolz/scripts/test-all.sh
bash Toolz/scripts/sync-backend.sh to-htmx
git commit -am "feat: my changes"
git push origin feature/new-feature
```

### Release Process
```bash
git checkout main
git pull origin main
bash Toolz/scripts/test-all.sh
bash Toolz/scripts/build-all.sh
bash Toolz/scripts/docker-build.sh
bash Toolz/scripts/deploy.sh both
bash Toolz/scripts/monitor.sh
```

### Incident Response
```bash
bash Toolz/scripts/health-check.sh
bash Toolz/scripts/monitor.sh
bash Toolz/scripts/backup.sh
# Fix issue
bash Toolz/scripts/build-all.sh
bash Toolz/scripts/deploy.sh both  # Deploy hotfix
bash Toolz/scripts/monitor.sh  # Verify fix
```

---

**Happy automating!** 🚀