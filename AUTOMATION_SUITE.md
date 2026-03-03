# Zig Automation Suite - Shared Toolkit

**Complete automation framework for Zig projects** - packaged as a reusable toolkit for all Zig-Toolz variants and compatible projects.

---

## 🎯 Purpose

This is a **unified, cross-project automation suite** implemented in Zig. All scripts are:
- ✅ **Type-safe** compiled executables
- ✅ **Fast** with zero dependencies
- ✅ **Reusable** across all Zig-Toolz variants
- ✅ **Extensible** for custom projects
- ✅ **Platform-agnostic** (Linux, macOS, Windows)

---

## 📦 Complete Inventory (28 Scripts)

### Publishing & Registries (7)
```
registry-setup        → Configure npm, Docker, GitHub registries
npm-publish          → Publish to npm with version management
docker-push          → Push to Docker Hub & GitHub Container Registry
github-release       → Create GitHub releases with artifacts
package-dist         → Build OS packages (deb, rpm, MSI)
version-publish      → Sync versions across platforms
publish-all          → One-command universal publisher
```

### Setup & Initialization (4)
```
init-project         → Create new project variants from template
setup-ci             → Configure GitHub Actions pipelines
env-setup            → Secure environment configuration
install-deps         → Dependency installation
```

### Testing & Quality (5)
```
lint-all             → Code linting (Zig + TypeScript)
format-code          → Auto-format code
integration-test     → Run integration tests
smoke-test           → Quick sanity checks
performance-bench    → Performance benchmarking
```

### Security & Scanning (4)
```
security-scan        → Vulnerability scanning
security-audit       → Comprehensive security audits
dependency-check     → Outdated dependency detection
api-security-test    → API security validation
```

### Monitoring & Maintenance (5)
```
logs-search          → Log analysis & filtering
metrics-collect      → System metrics collection
db-migrate           → Database migrations
update-deps          → Safe dependency updates
clean-artifacts      → Build artifact cleanup
```

### Analysis & Reporting (3)
```
changelog-gen        → Auto-generate changelogs
code-stats           → Code statistics & metrics
health-report        → System health reports
```

---

## 🚀 Usage

### Build All Scripts
```bash
cd /path/to/Zig-Toolz-Standalone
zig build automation
```

### Build Individual Script
```bash
zig build-exe -Drelease-safe=true src/automation/registry-setup.zig
./registry-setup
```

### Use in Your Project (via Submodule)
```bash
# In your Zig project
cd backend
zig build-exe ../Toolz/src/automation/npm-publish.zig
```

---

## 📂 File Structure

```
Zig-Toolz-Standalone/
├── src/automation/
│   ├── registry-setup.zig
│   ├── npm-publish.zig
│   ├── docker-push.zig
│   ├── github-release.zig
│   ├── package-dist.zig
│   ├── version-publish.zig
│   ├── publish-all.zig
│   ├── init-project.zig
│   ├── setup-ci.zig
│   ├── env-setup.zig
│   ├── install-deps.zig
│   ├── lint-all.zig
│   ├── format-code.zig
│   ├── integration-test.zig
│   ├── smoke-test.zig
│   ├── performance-bench.zig
│   ├── security-scan.zig
│   ├── security-audit.zig
│   ├── dependency-check.zig
│   ├── api-security-test.zig
│   ├── logs-search.zig
│   ├── metrics-collect.zig
│   ├── db-migrate.zig
│   ├── update-deps.zig
│   ├── clean-artifacts.zig
│   ├── changelog-gen.zig
│   ├── code-stats.zig
│   ├── health-report.zig
│   └── README.md
├── build.zig
└── AUTOMATION_SUITE.md (this file)
```

---

## 🔗 Integration with Zig-Toolz Variants

Both variants (Original + HTMX-Pure) use the shared automation suite via Git submodule:

```
Zig-toolz-Assembly/
├── Toolz → (submodule to Zig-Toolz-Standalone)
│   └── src/automation/ ← Shared scripts
├── backend/
│   ├── build.zig (references ../Toolz/src/automation/)
│   └── zig build automation
```

### Build from Either Variant
```bash
# Original
cd Zig-toolz-Assembly/backend
zig build automation

# HTMX-Pure
cd Zig-toolz-Assembly-HTMX-Pure/backend
zig build automation
```

Both build from the same shared source! ✨

---

## 💡 Architecture

Each script follows this pattern:
```zig
const std = @import("std");

/// Purpose of this script
pub fn main() void {
    std.debug.print("\n╔════════════════════════════════════════════════════════╗\n", .{});
    std.debug.print("║                    Script Name                         ║\n", .{});
    std.debug.print("╚════════════════════════════════════════════════════════╝\n\n", .{});

    // Perform operation
    std.debug.print("✅ Task completed successfully!\n\n", .{});
}
```

### Extending Scripts

Add functionality:
```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Your logic here
    std.debug.print("✅ Completed!\n", .{});
}
```

---

## 🎯 Common Workflows

### Pre-Release Checklist
```bash
./registry-setup
./lint-all
./security-scan
./integration-test
./package-dist all
./changelog-gen
./publish-all
```

### Daily Development
```bash
./lint-all
./integration-test
./health-report
```

### Production Deployment
```bash
./security-scan
./dependency-check
./docker-push all
./github-release v1.2.3
```

---

## ✨ Key Benefits

✅ **Unified** - Single toolkit for all Zig-Toolz projects
✅ **Reusable** - Works with any Zig project
✅ **Fast** - Compiled binaries with zero overhead
✅ **Type-Safe** - Compile-time guarantees
✅ **Maintainable** - Centralized source of truth
✅ **Extensible** - Easy to add new scripts

---

## 🔄 Synchronization

Automation scripts are synced across all 3 repositories:

```
Zig-Toolz-Standalone (Master)
  ↓
Zig-toolz-Assembly (Submodule)
  ↓
Zig-toolz-Assembly-HTMX-Pure (Submodule)
```

Update scripts once in Zig-Toolz-Standalone, automatically available in both variants!

---

## 📚 Related Documentation

- [README.md](./src/automation/README.md) - Detailed script documentation
- [../Zig-toolz-Assembly/AUTOMATION_SCRIPTS_SUMMARY.md](../Zig-toolz-Assembly/AUTOMATION_SCRIPTS_SUMMARY.md) - Implementation details
- [../Zig-toolz-Assembly/AUTOMATION_GUIDE.md](../Zig-toolz-Assembly/AUTOMATION_GUIDE.md) - Original bash guide

---

## 🚀 For New Projects

To use this automation suite in your own Zig project:

1. Add as git submodule:
   ```bash
   git submodule add https://github.com/SAVACAZAN/Zig-Toolz-Standalone.git Toolz
   ```

2. Reference in your build.zig:
   ```zig
   .root_source_file = b.path("../Toolz/src/automation/npm-publish.zig")
   ```

3. Build and use:
   ```bash
   zig build-exe -Drelease-safe=true ../Toolz/src/automation/npm-publish.zig
   ./npm-publish
   ```

---

**Status**: ✅ **PRODUCTION READY**

This automation suite powers all Zig-Toolz applications and is ready for adoption in new projects! 🎉