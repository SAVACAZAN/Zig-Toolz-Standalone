# Zig Automation Suite

Complete automation toolkit for Zig-Toolz-Assembly, implemented in Zig for maximum performance and integration.

## 📦 Published Scripts (7)

Full suite of publishing and registry management utilities:

1. **registry-setup.zig** - Configure npm, Docker Hub, GitHub Container Registry
2. **npm-publish.zig** - Version bump and publish to npm registry
3. **docker-push.zig** - Push Docker images to registries
4. **github-release.zig** - Create GitHub releases with artifacts
5. **package-dist.zig** - Create OS-specific packages
6. **version-publish.zig** - Sync versions across all registries
7. **publish-all.zig** - Single command to publish everywhere

## 🏗️ Setup & Initialization (4)

Project initialization and environment setup:

8. **init-project.zig** - Create new application variant from template
9. **setup-ci.zig** - Configure GitHub Actions CI/CD pipeline
10. **env-setup.zig** - Initialize environment variables securely
11. **install-deps.zig** - Install all project dependencies

## 🧪 Testing & Quality (5)

Code quality and testing automation:

12. **lint-all.zig** - Lint Zig backend and TypeScript frontend
13. **format-code.zig** - Auto-format code (zig fmt, prettier)
14. **integration-test.zig** - Run integration tests
15. **smoke-test.zig** - Quick sanity checks
16. **performance-bench.zig** - Performance benchmarking suite

## 🔍 Security & Scanning (4)

Security vulnerability detection and analysis:

17. **security-scan.zig** - Scan dependencies and code for vulnerabilities
18. **security-audit.zig** - Comprehensive security audit
19. **dependency-check.zig** - Check for outdated/vulnerable dependencies
20. **api-security-test.zig** - Test API security headers and authentication

## 📊 Monitoring & Maintenance (5)

System monitoring and maintenance utilities:

21. **logs-search.zig** - Search and analyze logs
22. **metrics-collect.zig** - Collect system and application metrics
23. **db-migrate.zig** - Database schema migrations
24. **update-deps.zig** - Update all dependencies safely
25. **clean-artifacts.zig** - Clean build artifacts and cache

## 📈 Analysis & Reporting (3)

Code analysis and report generation:

26. **changelog-gen.zig** - Generate changelog from git commits
27. **code-stats.zig** - Generate code statistics and metrics
28. **health-report.zig** - Generate comprehensive health report

## 🚀 Building

### Build All Scripts
```bash
cd backend
zig build automation
```

### Build Individual Scripts
```bash
# Registry setup
zig build-exe src/automation/registry-setup.zig -Doptimize=ReleaseSafe

# Publishing
zig build-exe src/automation/npm-publish.zig -Doptimize=ReleaseSafe

# Security
zig build-exe src/automation/security-scan.zig -Doptimize=ReleaseSafe
```

### Output Locations
All compiled executables are placed in:
```
backend/zig-out/bin/
├── registry-setup
├── npm-publish
├── docker-push
├── github-release
├── lint-all
├── security-scan
├── health-report
└── ... (24 more)
```

## 📖 Usage Examples

### Publishing Workflow
```bash
# 1. Setup registries
./zig-out/bin/registry-setup all

# 2. Publish to npm
./zig-out/bin/npm-publish minor

# 3. Push Docker images
./zig-out/bin/docker-push all

# 4. Create GitHub release
./zig-out/bin/github-release v1.2.3

# 5. Publish everywhere at once
./zig-out/bin/publish-all
```

### Quality Assurance
```bash
# Lint all code
./zig-out/bin/lint-all all

# Run security scan
./zig-out/bin/security-scan all

# Check dependencies
./zig-out/bin/dependency-check

# Performance benchmark
./zig-out/bin/performance-bench
```

### Monitoring & Maintenance
```bash
# Generate health report
./zig-out/bin/health-report json

# Collect metrics
./zig-out/bin/metrics-collect

# Search logs
./zig-out/bin/logs-search "error"

# Update dependencies
./zig-out/bin/update-deps
```

## 🔑 Key Features

✅ **Type-Safe** - Compiled Zig with compile-time guarantees
✅ **Fast** - No interpretation overhead, pure binary execution
✅ **Integrated** - Part of your Zig build system
✅ **Cross-Platform** - Works on Linux, macOS, Windows
✅ **Single Binary** - Each script is a standalone executable
✅ **Zero Dependencies** - Uses only Zig stdlib

## 🎯 Common Workflows

### Daily Development
```bash
./zig-out/bin/lint-all all
./zig-out/bin/integration-test
./zig-out/bin/health-report text
```

### Pre-Release
```bash
./zig-out/bin/security-scan all
./zig-out/bin/dependency-check
./zig-out/bin/performance-bench
./zig-out/bin/changelog-gen
```

### Continuous Integration
```bash
./zig-out/bin/lint-all all || exit 1
./zig-out/bin/integration-test || exit 1
./zig-out/bin/security-scan all || exit 1
./zig-out/bin/health-report json > report.json
```

## 🏗️ Architecture

All scripts follow the same pattern:

1. **Allocator** - Use GeneralPurposeAllocator with defer cleanup
2. **Error Handling** - Result types with meaningful error messages
3. **Output** - Colored terminal output with progress indicators
4. **Exit Codes** - 0 for success, 1 for failure (compatible with shell scripts)
5. **Arguments** - Command-line args via std.process.argsAlloc

Example template:
```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Your code here
}
```

## 📝 Adding New Scripts

1. Create `new-script.zig` in `src/automation/`
2. Follow the standard template above
3. Add to `build.zig` build steps
4. Test with `zig build-exe src/automation/new-script.zig`
5. Update this README

## 🐛 Troubleshooting

### Script not found after building
Make sure you ran `zig build automation` (not just `zig build`)

### Permission denied on execution
```bash
chmod +x ./zig-out/bin/*
```

### Out of memory errors
Increase system memory or use ReleaseSafe optimization:
```bash
zig build-exe script.zig -Doptimize=ReleaseSafe
```

## 📚 Related Documentation

- [AUTOMATION_GUIDE.md](/AUTOMATION_GUIDE.md) - Comprehensive usage guide
- [SYNC_GUIDE.md](/SYNC_GUIDE.md) - Backend synchronization details
- [CLAUDE.md](/CLAUDE.md) - Project architecture and patterns

---

**Happy automating! 🚀**
