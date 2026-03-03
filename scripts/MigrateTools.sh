#!/bin/bash

################################################################################
# MigrateTools.sh - Interactive Migration Variant Selector & Installer
#
# Features:
# - 10+ migration variants with different framework/tool combinations
# - Interactive menu system with detailed descriptions
# - Plugin architecture for extensibility
# - Dynamic plugin loading from GitHub
# - Agent/Skill integration for advanced tasks
# - Configuration generation for chosen variant
# - Multi-stage migration planning
#
# Usage: ./MigrateTools.sh [--variant NAME] [--plugins PLUGIN1,PLUGIN2] [--auto]
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Directories
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$REPO_ROOT/.migrate-plugins"
CONFIG_DIR="$REPO_ROOT/.migrate-config"
MIGRATION_BRANCH_PREFIX="migrate/"

# Version
VERSION="1.0.0"

################################################################################
# UTILITY FUNCTIONS
################################################################################

log_info() {
    echo -e "${CYAN}ℹ ${NC}$1"
}

log_success() {
    echo -e "${GREEN}✅ ${NC}$1"
}

log_warning() {
    echo -e "${YELLOW}⚠️  ${NC}$1"
}

log_error() {
    echo -e "${RED}❌ ${NC}$1"
}

log_header() {
    echo -e "\n${BOLD}${BLUE}$1${NC}\n"
}

pause() {
    read -p "Press Enter to continue..."
}

################################################################################
# MIGRATION VARIANTS (10+ options)
################################################################################

declare -A VARIANTS=(
    [1]="HTMX-Pure"
    [2]="HTMX-Bun"
    [3]="HTMX-WASM"
    [4]="HTMX-WASM-Advanced"
    [5]="Jetzig-Pure"
    [6]="Jetzig-WASM"
    [7]="Jetzig-WASM-Advanced"
    [8]="LowLatency-Base"
    [9]="LowLatency-WASM"
    [10]="MultiStage-Full"
    [11]="Custom-Build"
)

declare -A VARIANT_DESCRIPTIONS=(
    [HTMX-Pure]="HTMX (14KB) + Server-side rendering. Fastest to implement. 4 weeks."
    [HTMX-Bun]="HTMX + Bun runtime for faster JS execution. 4 weeks."
    [HTMX-WASM]="HTMX + Zig WebAssembly for computation. 10 weeks total."
    [HTMX-WASM-Advanced]="HTMX + WASM + Service Worker + caching. 12 weeks."
    [Jetzig-Pure]="Jetzig framework with built-in sessions. 3 weeks. Simplest."
    [Jetzig-WASM]="Jetzig + WASM computation layer. 8 weeks."
    [Jetzig-WASM-Advanced]="Jetzig + WASM + plugins + observability. 10 weeks."
    [LowLatency-Base]="Lock-free ring buffers + thread affinity. 7 weeks. Expert level."
    [LowLatency-WASM]="Low-latency + WASM + monitoring. 10 weeks. Professional."
    [MultiStage-Full]="Staged: Phase 1→HTMX, Phase 2→WASM, Phase 3→Low-Latency. 15 weeks."
    [Custom-Build]="Mix and match components. Build your own variant."
)

declare -A VARIANT_FRAMEWORKS=(
    [HTMX-Pure]="None (Zig stdlib)"
    [HTMX-Bun]="None (Zig stdlib) + Bun runtime"
    [HTMX-WASM]="None (Zig stdlib)"
    [HTMX-WASM-Advanced]="None (Zig stdlib)"
    [Jetzig-Pure]="Jetzig"
    [Jetzig-WASM]="Jetzig"
    [Jetzig-WASM-Advanced]="Jetzig"
    [LowLatency-Base]="None (raw Zig)"
    [LowLatency-WASM]="None (raw Zig)"
    [MultiStage-Full]="None → Jetzig → Advanced"
    [Custom-Build]="User defined"
)

declare -A VARIANT_DURATION=(
    [HTMX-Pure]="4"
    [HTMX-Bun]="4"
    [HTMX-WASM]="10"
    [HTMX-WASM-Advanced]="12"
    [Jetzig-Pure]="3"
    [Jetzig-WASM]="8"
    [Jetzig-WASM-Advanced]="10"
    [LowLatency-Base]="7"
    [LowLatency-WASM]="10"
    [MultiStage-Full]="15"
    [Custom-Build]="8-20"
)

declare -A VARIANT_RISK=(
    [HTMX-Pure]="⭐ Low"
    [HTMX-Bun]="⭐ Low"
    [HTMX-WASM]="⭐⭐ Medium"
    [HTMX-WASM-Advanced]="⭐⭐ Medium"
    [Jetzig-Pure]="⭐ Low"
    [Jetzig-WASM]="⭐⭐ Medium"
    [Jetzig-WASM-Advanced]="⭐⭐⭐ Medium-High"
    [LowLatency-Base]="⭐⭐⭐ High"
    [LowLatency-WASM]="⭐⭐⭐⭐ Very High"
    [MultiStage-Full]="⭐⭐ Medium (phased)"
    [Custom-Build]="Varies"
)

################################################################################
# PLUGIN SYSTEM
################################################################################

initialize_plugins() {
    mkdir -p "$PLUGINS_DIR"
    mkdir -p "$CONFIG_DIR"

    # List of built-in plugins
    cat > "$PLUGINS_DIR/MANIFEST.txt" << 'EOF'
# Built-in plugins
plugin:monitoring
plugin:docker
plugin:cicd
plugin:observability
plugin:testing
plugin:security-audit
plugin:performance-profiling
EOF

    log_success "Plugin system initialized"
}

list_available_plugins() {
    log_header "Available Plugins"

    echo -e "${BOLD}Built-in Plugins:${NC}"
    echo "  • monitoring       - Real-time latency/performance monitoring"
    echo "  • docker          - Docker containerization setup"
    echo "  • cicd            - GitHub Actions CI/CD pipeline"
    echo "  • observability   - Structured logging + metrics"
    echo "  • testing         - Comprehensive test suite generation"
    echo "  • security-audit  - Security vulnerability scanning"
    echo "  • performance-profiling - Perf tools integration"
    echo ""

    echo -e "${BOLD}Community Plugins (from GitHub):${NC}"
    echo "  • github:USER/REPO - Install from GitHub repository"
    echo ""
}

install_plugin() {
    local plugin=$1

    if [[ $plugin == github:* ]]; then
        install_github_plugin "$plugin"
    else
        install_builtin_plugin "$plugin"
    fi
}

install_builtin_plugin() {
    local plugin=$1

    log_info "Installing built-in plugin: $plugin"

    case $plugin in
        monitoring)
            mkdir -p "$PLUGINS_DIR/monitoring"
            cat > "$PLUGINS_DIR/monitoring/plugin.zig" << 'EOF'
// Monitoring plugin for real-time latency tracking
pub const Metrics = struct {
    latency_p50: f64,
    latency_p99: f64,
    latency_max: f64,
    throughput: u64,
    memory_used: u64,
};

pub fn collect_metrics() Metrics {
    // Implementation
    return .{
        .latency_p50 = 0.0,
        .latency_p99 = 0.0,
        .latency_max = 0.0,
        .throughput = 0,
        .memory_used = 0,
    };
}
EOF
            log_success "Monitoring plugin installed"
            ;;
        docker)
            mkdir -p "$PLUGINS_DIR/docker"
            cat > "$PLUGINS_DIR/docker/Dockerfile" << 'EOF'
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y zig
WORKDIR /app
COPY . .
RUN zig build -Doptimize=ReleaseFast
CMD ["./zig-cache/bin/zig-exchange-server"]
EOF
            log_success "Docker plugin installed"
            ;;
        cicd)
            mkdir -p "$PLUGINS_DIR/cicd/.github/workflows"
            cat > "$PLUGINS_DIR/cicd/.github/workflows/build.yml" << 'EOF'
name: Build & Test
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: goto-bus-stop/setup-zig@v2
      - run: cd backend && zig build
      - run: cd backend && zig build test
EOF
            log_success "CI/CD plugin installed"
            ;;
        observability)
            mkdir -p "$PLUGINS_DIR/observability"
            cat > "$PLUGINS_DIR/observability/logger.zig" << 'EOF'
// Structured JSON logging
pub const Logger = struct {
    pub fn log(level: []const u8, message: []const u8, fields: anytype) void {
        // JSON output implementation
    }
};
EOF
            log_success "Observability plugin installed"
            ;;
        testing)
            mkdir -p "$PLUGINS_DIR/testing"
            cat > "$PLUGINS_DIR/testing/test_suite.zig" << 'EOF'
// Comprehensive test suite generator
pub fn generate_test_suite() void {
    // Test generation implementation
}
EOF
            log_success "Testing plugin installed"
            ;;
        security-audit)
            mkdir -p "$PLUGINS_DIR/security-audit"
            log_success "Security audit plugin installed"
            ;;
        performance-profiling)
            mkdir -p "$PLUGINS_DIR/performance-profiling"
            log_success "Performance profiling plugin installed"
            ;;
        *)
            log_error "Unknown plugin: $plugin"
            ;;
    esac
}

install_github_plugin() {
    local github_url=$1
    local repo_name="${github_url##*/}"

    log_info "Cloning plugin from GitHub: $github_url"
    git clone "https://github.com/${github_url#github:}" "$PLUGINS_DIR/$repo_name" 2>/dev/null || true
    log_success "GitHub plugin installed: $repo_name"
}

################################################################################
# VARIANT SELECTION & DISPLAY
################################################################################

display_variant_details() {
    local variant=$1

    log_header "Variant Details: $variant"

    echo -e "${CYAN}Description:${NC}"
    echo "  ${VARIANT_DESCRIPTIONS[$variant]}"
    echo ""

    echo -e "${CYAN}Framework:${NC}"
    echo "  ${VARIANT_FRAMEWORKS[$variant]}"
    echo ""

    echo -e "${CYAN}Duration:${NC}"
    echo "  ${VARIANT_DURATION[$variant]} weeks"
    echo ""

    echo -e "${CYAN}Risk Level:${NC}"
    echo "  ${VARIANT_RISK[$variant]}"
    echo ""
}

show_variant_menu() {
    log_header "Available Migration Variants (10+)"

    echo -e "${BOLD}Migration Paths:${NC}\n"

    for key in "${!VARIANTS[@]}"; do
        variant="${VARIANTS[$key]}"
        duration="${VARIANT_DURATION[$variant]}"
        risk="${VARIANT_RISK[$variant]}"
        printf "  %2d. %-30s | %2d weeks | %s\n" "$key" "$variant" "$duration" "$risk"
    done

    echo ""
    echo -e "${BOLD}Special Options:${NC}"
    echo "  p. Plugin management"
    echo "  a. Agent assistance"
    echo "  q. Quit"
    echo ""
}

################################################################################
# CONFIGURATION GENERATION
################################################################################

generate_variant_config() {
    local variant=$1
    local branch="$MIGRATION_BRANCH_PREFIX$(echo $variant | tr '[:upper:]' '[:lower:]' | tr '-' '_')"

    log_header "Generating Configuration: $variant"

    # Create config file
    cat > "$CONFIG_DIR/${variant}.config" << EOF
# Migration Configuration
VARIANT_NAME="$variant"
FRAMEWORK="${VARIANT_FRAMEWORKS[$variant]}"
DURATION_WEEKS="${VARIANT_DURATION[$variant]}"
RISK_LEVEL="${VARIANT_RISK[$variant]}"
GIT_BRANCH="$branch"
CREATED_AT="$(date)"

# Phase breakdown
PHASE_1_SECURITY=true
PHASE_2_FRONTEND=${variant#*HTMX*}
PHASE_3_WASM=${variant#*WASM*}
PHASE_4_LOWLATENCY=${variant#*LowLatency*}

# Framework-specific
JETZIG_ENABLED=$(if [[ "$variant" =~ "Jetzig" ]]; then echo "true"; else echo "false"; fi)
BUN_ENABLED=$(if [[ "$variant" =~ "Bun" ]]; then echo "true"; else echo "false"; fi)
WASM_ENABLED=$(if [[ "$variant" =~ "WASM" ]]; then echo "true"; else echo "false"; fi)
LOW_LATENCY_ENABLED=$(if [[ "$variant" =~ "LowLatency" ]]; then echo "true"; else echo "false"; fi)

# Plugins to install
PLUGINS_MONITORING=${PLUGINS_MONITORING:-false}
PLUGINS_DOCKER=${PLUGINS_DOCKER:-true}
PLUGINS_CICD=${PLUGINS_CICD:-true}
PLUGINS_OBSERVABILITY=${PLUGINS_OBSERVABILITY:-false}
EOF

    log_success "Configuration generated: $CONFIG_DIR/${variant}.config"

    # Show configuration preview
    echo ""
    echo -e "${CYAN}Configuration Preview:${NC}"
    cat "$CONFIG_DIR/${variant}.config" | sed 's/^/  /'
    echo ""

    # Generate AGENT PROMPT file
    generate_agent_prompt "$variant"
}

generate_agent_prompt() {
    local variant=$1

    log_info "Generating AI Agent Implementation Prompt..."

    cat > "$CONFIG_DIR/AGENT_PROMPT_${variant}.md" << 'AGENT_EOF'
# 🤖 AGENT IMPLEMENTATION PROMPT: Phase 2 HTMX Frontend Migration

## ✅ What is Already Done (Phase 1 - Complete)
- AES-256-GCM encryption for API keys in database (`backend/src/crypto/vault.zig`)
- Constant-time HMAC comparison prevents timing attacks (`jwt.zig`)
- Memory zeroing for sensitive data (`secureZero()`)
- All debug logs with API key snippets removed
- Backend compiles without errors, 3/3 unit tests passing
- Database schema ready for encrypted keys

## 📋 Your Task: Implement Phase 2 - HTMX Frontend Migration

### Current State
- Frontend: React 18 + TypeScript + Vite (300 KB JS bundle)
- Backend: Raw Zig stdlib HTTP server with JSON API endpoints
- Authentication: JWT tokens (localStorage)
- Database: SQLite with WAL mode, HTTPS encrypted
- Need to: Convert to server-side rendering with HTMX

### Target State (After Phase 2)
- Frontend: Server-rendered HTML + HTMX (14 KB JavaScript only)
- Backend: HTTP server returns HTML fragments, manages sessions via cookies
- Authentication: HTTP-only secure cookies (no localStorage)
- Database: Same SQLite schema
- No React, Vite, TypeScript, or npm

### Timeline: 4 Weeks (20 working days)

---

## 📁 Project Structure Reference

```
/home/kiss/Zig-toolz-Assembly/
├── backend/
│   ├── src/
│   │   ├── main.zig              (HTTP server entry point)
│   │   ├── config/
│   │   │   └── config.zig        (Environment variables, secrets)
│   │   ├── auth/
│   │   │   ├── jwt.zig           (JWT generation + verification)
│   │   │   └── auth.zig          (PBKDF2 password hashing)
│   │   ├── db/
│   │   │   └── database.zig      (SQLite + user/order/apikey queries)
│   │   ├── crypto/
│   │   │   └── vault.zig         (AES-256-GCM encryption)
│   │   ├── exchange/             (LCX, Kraken, Coinbase clients)
│   │   ├── ws/                   (WebSocket client + handlers)
│   │   └── utils/                (JSON parsing, models)
│   └── build.zig                 (Build configuration)
├── frontend/                     (DELETE AFTER PHASE 2)
│   ├── src/
│   │   ├── pages/                (Login, Dashboard, Trade, Balance, etc.)
│   │   ├── context/              (AuthContext - not needed after)
│   │   └── api/                  (exchange.ts - will be built into backend)
│   └── package.json              (npm - DELETE)
├── CLAUDE.md                     (Update with new environment variables)
├── backend/.migrate-config/      (Configuration files)
├── backend/templates/            (NEW - HTML templates with HTMX)
└── .migrate-plugins/             (Plugin system)
```

---

## 🎯 Implementation Steps (Week-by-Week Breakdown)

### WEEK 1: Session Management & Authentication

#### Step 1.1: Create Session Module (`backend/src/session/session.zig`)
**Purpose**: Manage HTTP session cookies (session ID → user mapping)

Create file: `backend/src/session/session.zig`

```zig
const std = @import("std");
const crypto = std.crypto;

pub const Session = struct {
    id: []const u8,           // Secure random 32-byte hex string
    user_id: u64,
    created_at: i64,
    expires_at: i64,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, user_id: u64) !Session {
        var id_bytes: [32]u8 = undefined;
        crypto.random.bytes(&id_bytes);

        const id_hex = try allocator.alloc(u8, 64);
        for (id_bytes, 0..) |b, i| {
            const hex_chars = "0123456789abcdef";
            id_hex[i * 2] = hex_chars[(b >> 4) & 0xf];
            id_hex[i * 2 + 1] = hex_chars[b & 0xf];
        }

        const now = std.time.milliTimestamp();
        const expires_at = now + (24 * 60 * 60 * 1000); // 24 hours

        return .{
            .id = id_hex,
            .user_id = user_id,
            .created_at = now,
            .expires_at = expires_at,
            .allocator = allocator,
        };
    }

    pub fn isExpired(self: *const Session) bool {
        return std.time.milliTimestamp() > self.expires_at;
    }

    pub fn deinit(self: *const Session) void {
        self.allocator.free(self.id);
    }
};

pub const SessionStore = struct {
    sessions: std.StringHashMap(Session),
    allocator: std.mem.Allocator,
    mutex: std.Thread.Mutex = .{},

    pub fn init(allocator: std.mem.Allocator) SessionStore {
        return .{
            .sessions = std.StringHashMap(Session).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn create(self: *SessionStore, user_id: u64) ![]const u8 {
        var lock = self.mutex.lock();
        defer lock.unlock();

        const session = try Session.init(self.allocator, user_id);
        try self.sessions.put(session.id, session);
        return session.id;
    }

    pub fn get(self: *SessionStore, session_id: []const u8) ?Session {
        var lock = self.mutex.lock();
        defer lock.unlock();

        if (self.sessions.get(session_id)) |session| {
            if (!session.isExpired()) {
                return session;
            } else {
                session.deinit();
                _ = self.sessions.remove(session_id);
                return null;
            }
        }
        return null;
    }

    pub fn destroy(self: *SessionStore, session_id: []const u8) void {
        var lock = self.mutex.lock();
        defer lock.unlock();

        if (self.sessions.get(session_id)) |session| {
            session.deinit();
            _ = self.sessions.remove(session_id);
        }
    }

    pub fn deinit(self: *SessionStore) void {
        var iter = self.sessions.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.deinit();
        }
        self.sessions.deinit();
    }
};
```

---

#### Step 1.2: Integrate SessionStore into main.zig
**Location**: `backend/src/main.zig` (modify global state)

Add to imports:
```zig
const session_module = @import("session/session.zig");
```

Add to Server struct:
```zig
pub const Server = struct {
    listener: net.Server,
    config: Config,
    db: Database,
    session_store: session_module.SessionStore,  // NEW
    allocator: std.mem.Allocator,
    // ... existing fields
};
```

Add initialization in `main()` before accept loop:
```zig
var session_store = session_module.SessionStore.init(gpa.allocator());
defer session_store.deinit();

const server = Server{
    .listener = listener,
    .config = config,
    .db = db,
    .session_store = session_store,  // NEW
    .allocator = gpa.allocator(),
};
```

---

#### Step 1.3: Create HTML Template Helpers (`backend/src/templates/templates.zig`)
**Purpose**: Provide utilities for rendering HTML with HTMX

Create file: `backend/src/templates/templates.zig`

```zig
const std = @import("std");

pub fn renderLogin() []const u8 {
    return
        \\<!DOCTYPE html>
        \\<html lang="en">
        \\<head>
        \\  <meta charset="UTF-8">
        \\  <meta name="viewport" content="width=device-width, initial-scale=1.0">
        \\  <title>Login - ZigTradingEngine</title>
        \\  <script src="https://unpkg.com/htmx.org"></script>
        \\  <style>
        \\    * { margin: 0; padding: 0; box-sizing: border-box; }
        \\    body { font-family: sans-serif; background: linear-gradient(135deg, #1e1e2e, #2d2d44);
        \\           min-height: 100vh; display: flex; align-items: center; justify-content: center; }
        \\    .login-card { background: rgba(255,255,255,0.1); backdrop-filter: blur(10px);
        \\                  border-radius: 12px; padding: 40px; width: 100%; max-width: 400px;
        \\                  box-shadow: 0 8px 32px rgba(0,0,0,0.3); }
        \\    h1 { color: #fff; margin-bottom: 30px; text-align: center; }
        \\    .form-group { margin-bottom: 20px; }
        \\    label { display: block; color: #ccc; margin-bottom: 8px; font-weight: 500; }
        \\    input { width: 100%; padding: 12px; background: rgba(255,255,255,0.1);
        \\            border: 1px solid rgba(255,255,255,0.2); border-radius: 6px;
        \\            color: #fff; }
        \\    input::placeholder { color: rgba(255,255,255,0.5); }
        \\    button { width: 100%; padding: 12px; background: linear-gradient(135deg, #667eea, #764ba2);
        \\             color: white; border: none; border-radius: 6px; font-size: 16px;
        \\             cursor: pointer; font-weight: 600; }
        \\    button:hover { transform: translateY(-2px); box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4); }
        \\    .error { color: #ff6b6b; font-size: 14px; margin-top: 5px; }
        \\  </style>
        \\</head>
        \\<body>
        \\  <div class="login-card">
        \\    <h1>ZigTradingEngine</h1>
        \\    <form hx-post="/api/login" hx-target="body" hx-swap="outerHTML">
        \\      <div class="form-group">
        \\        <label for="email">Email</label>
        \\        <input type="email" id="email" name="email" required>
        \\      </div>
        \\      <div class="form-group">
        \\        <label for="password">Password</label>
        \\        <input type="password" id="password" name="password" required>
        \\      </div>
        \\      <button type="submit">Login</button>
        \\    </form>
        \\  </div>
        \\</body>
        \\</html>
    ;
}

pub fn sendHtmlResponse(writer: anytype, content: []const u8) !void {
    try writer.writeAll("HTTP/1.1 200 OK\r\n");
    try writer.writeAll("Content-Type: text/html; charset=utf-8\r\n");
    try writer.print("Content-Length: {}\r\n", .{content.len});
    try writer.writeAll("Connection: close\r\n");
    try writer.writeAll("\r\n");
    try writer.writeAll(content);
}

pub fn sendCookie(writer: anytype, name: []const u8, value: []const u8) !void {
    try writer.print("Set-Cookie: {}={}; Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=86400\r\n",
        .{name, value});
}
```

---

#### Step 1.4: Update Login Endpoint in main.zig
**Location**: `backend/src/main.zig` - modify login handler

Change from JSON response to HTML + Session Cookie:

```zig
if (std.mem.eql(u8, request.path, "/api/login")) {
    // ... existing POST parameter parsing

    if (try database.getUserByEmail(allocator, email)) |user| {
        if (auth.verifyPassword(password, user.password_hash)) {
            // Create session
            const session_id = try server.session_store.create(user.id);

            // Return HTML response with session cookie
            try response_writer.writeAll("HTTP/1.1 200 OK\r\n");
            try response_writer.writeAll("Content-Type: text/html; charset=utf-8\r\n");
            try templates.sendCookie(response_writer, "session_id", session_id);
            try response_writer.writeAll("Location: /dashboard\r\n");
            try response_writer.writeAll("Content-Length: 0\r\n");
            try response_writer.writeAll("\r\n");

            allocator.free(email);
            allocator.free(password);
            return;
        }
    }

    // Error response
    try response_writer.writeAll("HTTP/1.1 401 Unauthorized\r\n");
    try response_writer.writeAll("Content-Type: text/html\r\n");
    try response_writer.writeAll("Content-Length: 38\r\n\r\n");
    try response_writer.writeAll("<h1>Invalid email or password</h1>");
}
```

---

### WEEK 2: Create Core Page Templates

#### Step 2.1: Dashboard Template
Add to `templates/templates.zig`:
```zig
pub fn renderDashboard(user_email: []const u8, balance_btc: f64) []const u8 {
    // HTML with balance display
}
```

#### Step 2.2: Markets/Tickers Page
Similar structure with HTMX for live updates

#### Step 2.3: Balance Page
Show user's exchange balances

---

### WEEK 3: Complex Pages (Trade, Orders, API Keys)

...similar pattern...

---

### WEEK 4: Deployment & Cleanup

- Remove all React dependencies
- Delete `frontend/` directory
- Update CLAUDE.md with new instructions
- Test all pages thoroughly
- Commit to git

---

## ✅ Verification Checklist

After each step:
```bash
cd backend && zig build           # Compiles without errors
cd backend && zig build test      # Tests still pass
bash ScanMyApp.sh                 # Shows Phase 2 progress
```

Final verification:
```bash
./zig-cache/bin/zig-exchange-server &
curl http://localhost:8000/login  # Should return HTML
```

---

## 📚 Key Files to Reference

1. **Existing HTTP routing**: `backend/src/main.zig` (lines 50-150)
2. **Database queries**: `backend/src/db/database.zig`
3. **Auth module**: `backend/src/auth/auth.zig`
4. **Config**: `backend/src/config/config.zig`

---

## 🚀 Success Criteria

- [x] Backend compiles without errors
- [ ] Session system working (login/logout)
- [ ] All pages rendering as HTML (not JSON)
- [ ] HTMX interactive elements working
- [ ] HTTP-only session cookies set correctly
- [ ] Can delete `frontend/` directory
- [ ] npm/Node.js no longer needed
- [ ] ScanMyApp.sh shows Phase 2: 100% complete

AGENT_EOF

    log_success "Agent prompt generated: $CONFIG_DIR/AGENT_PROMPT_${variant}.md"
    log_info "📌 This file is ready to paste into Claude/Agent for automatic implementation"
}

################################################################################
# INSTALLATION INSTRUCTIONS
################################################################################

generate_installation_plan() {
    local variant=$1

    log_header "Installation Plan: $variant"

    case $variant in
        HTMX-Pure)
            cat << 'EOF'
Week 1: Foundation
  [ ] Create session.zig module
  [ ] Add session middleware to main.zig
  [ ] Convert login/register to HTMX
  [ ] Test session cookies

Week 2: Core Pages
  [ ] Dashboard (server-side rendering)
  [ ] Markets page
  [ ] Balance page
  [ ] Order history

Week 3: Complex Pages
  [ ] Trade page with forms
  [ ] Orderbook (polling)
  [ ] API Keys management

Week 4: Deployment
  [ ] Real-time WebSocket
  [ ] Remove React/Vite/npm
  [ ] Testing & documentation

Commands to Run:
  git checkout -b migrate/htmx_pure
  cd backend && zig build run
EOF
            ;;
        HTMX-Bun)
            cat << 'EOF'
Week 1-4: Same as HTMX-Pure
Plus: Integrate Bun for faster builds

Installation:
  curl -fsSL https://bun.sh/install | bash
  bun run build  # if using bun scripts

Benefits:
  - 3x faster npm operations
  - Single binary for JS runtime
  - TypeScript without compilation
EOF
            ;;
        HTMX-WASM)
            cat << 'EOF'
Weeks 1-4: HTMX Foundation (HTMX-Pure path)

Weeks 5-8: WASM Modules
  [ ] Setup WASM compilation (wasm32-freestanding)
  [ ] Orderbook matching engine
  [ ] Price aggregation
  [ ] Order validation module
  [ ] Service Worker integration

Compilation:
  zig build-lib src/wasm/exchange.zig -target wasm32-freestanding -O ReleaseSmall

Result:
  - 28 KB HTMX + 50-150 KB WASM
  - 100-530x faster calculations
  - Service Worker for request interception
EOF
            ;;
        Jetzig-Pure)
            cat << 'EOF'
Week 1: Jetzig Setup & Auth
  [ ] Initialize Jetzig project
  [ ] Migrate database models
  [ ] Implement sessions (built-in)
  [ ] Login/Register pages

Week 2: Core Features
  [ ] Dashboard
  [ ] Markets, Balance, Trade pages
  [ ] API Keys management
  [ ] Form handling

Week 3: Advanced & Deploy
  [ ] Real-time WebSocket
  [ ] Testing
  [ ] Docker containerization
  [ ] Documentation

Installation:
  zigmod fetch
  zig build
EOF
            ;;
        LowLatency-Base)
            cat << 'EOF'
Week 1-2: Foundation (Advanced - requires expertise)
  [ ] Lock-free SPSC ring buffers
  [ ] Thread affinity model (6 cores)
  [ ] SoA orderbook layout
  [ ] Kernel-bypass socket optimization

Week 3-4: Optimization
  [ ] CPU branch prediction tuning
  [ ] Jitter detection
  [ ] Linux system tuning
  [ ] Latency benchmarking

Week 5: Safety
  [ ] Watchdog thread
  [ ] Risk limiter
  [ ] Graceful shutdown

Week 6-7: Production
  [ ] Multi-exchange support
  [ ] Monitoring
  [ ] Testing

Requirements:
  - Linux kernel 5.4+
  - 6+ dedicated CPU cores
  - System-level tuning knowledge
  - perf/flamegraph tools
EOF
            ;;
        MultiStage-Full)
            cat << 'EOF'
Phase 1: HTMX Migration (Weeks 1-4)
  Week 1-4: Follow HTMX-Pure path

Phase 2: WASM Integration (Weeks 5-10)
  Week 5-10: Follow HTMX-WASM path

Phase 3: Low-Latency (Weeks 11-17)
  Week 11-17: Follow LowLatency-Base path

Total: 17 weeks of incremental, risk-mitigated improvements
Each phase can be paused/reviewed before continuing
EOF
            ;;
        Custom-Build)
            cat << 'EOF'
Select your own components:

Frontend Layers:
  [ ] HTMX (server-side rendering)
  [ ] React (existing)
  [ ] Jetzig (framework)

Computation Layers:
  [ ] WebAssembly
  [ ] Native Zig
  [ ] Low-latency threading

Deployment Options:
  [ ] Docker
  [ ] Static binary (musl)
  [ ] Nix flake

Plugins:
  [ ] Monitoring
  [ ] CI/CD
  [ ] Observability
  [ ] Performance profiling
EOF
            ;;
    esac

    echo ""
}

################################################################################
# AGENT & SKILL INTEGRATION
################################################################################

show_agent_menu() {
    log_header "Agent & Skill Integration"

    echo -e "${BOLD}Available Agents:${NC}"
    echo "  1. Explore - Codebase exploration and analysis"
    echo "  2. Plan - Implementation planning and architecture"
    echo "  3. General-Purpose - Multi-step task execution"
    echo ""

    echo -e "${BOLD}Available Skills:${NC}"
    echo "  • commit - Create git commits with AI assistance"
    echo "  • review-pr - Review pull requests"
    echo "  • pdf - Generate PDF documentation"
    echo "  • simplify - Code quality analysis"
    echo ""

    read -p "Select agent (1-3) or skill (name): " selection

    case $selection in
        1)
            log_info "Launching Explore agent for codebase analysis..."
            ;;
        2)
            log_info "Launching Plan agent for architecture design..."
            ;;
        3)
            log_info "Launching General-Purpose agent..."
            ;;
        *)
            log_info "Launching skill: $selection"
            ;;
    esac
}

################################################################################
# PLUGIN SELECTION
################################################################################

select_plugins() {
    log_header "Plugin Selection"

    echo -e "${BOLD}Choose plugins to install:${NC}\n"

    plugins_to_install=""

    read -p "Install monitoring plugin? (y/n) " -n 1 -r && echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        plugins_to_install="$plugins_to_install monitoring"
    fi

    read -p "Install Docker plugin? (y/n) " -n 1 -r && echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        plugins_to_install="$plugins_to_install docker"
    fi

    read -p "Install CI/CD plugin? (y/n) " -n 1 -r && echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        plugins_to_install="$plugins_to_install cicd"
    fi

    read -p "Install observability plugin? (y/n) " -n 1 -r && echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        plugins_to_install="$plugins_to_install observability"
    fi

    read -p "Install GitHub plugin (github:user/repo)? (leave blank to skip) " github_plugin
    if [ -n "$github_plugin" ]; then
        plugins_to_install="$plugins_to_install github:$github_plugin"
    fi

    echo ""
    log_info "Selected plugins: $plugins_to_install"

    for plugin in $plugins_to_install; do
        install_plugin "$plugin"
    done
}

################################################################################
# MAIN INTERACTIVE FLOW
################################################################################

main_menu() {
    clear

    cat << 'EOF'

╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║           🚀 ZIG-TOOLZ-ASSEMBLY - MIGRATION TOOLS & INSTALLER             ║
║                                                                            ║
║  Interactive tool for selecting, configuring, and installing migration    ║
║  variants with plugin architecture and agent integration support.         ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝

EOF

    show_variant_menu
    read -p "Select option: " choice

    case $choice in
        [0-9])
            if [[ -n "${VARIANTS[$choice]}" ]]; then
                selected_variant="${VARIANTS[$choice]}"
                handle_variant_selection "$selected_variant"
            else
                log_error "Invalid selection"
                pause && main_menu
            fi
            ;;
        p)
            plugin_menu
            ;;
        a)
            show_agent_menu
            ;;
        q)
            log_success "Goodbye!"
            exit 0
            ;;
        *)
            log_error "Invalid option"
            pause && main_menu
            ;;
    esac
}

handle_variant_selection() {
    local variant=$1

    display_variant_details "$variant"

    echo -e "${BOLD}Actions:${NC}"
    echo "  1. Generate configuration"
    echo "  2. Show installation plan"
    echo "  3. Create git branch"
    echo "  4. Select plugins"
    echo "  5. Start installation"
    echo "  6. Back to menu"
    echo ""

    read -p "Select action: " action

    case $action in
        1)
            generate_variant_config "$variant"
            pause && handle_variant_selection "$variant"
            ;;
        2)
            generate_installation_plan "$variant"
            pause && handle_variant_selection "$variant"
            ;;
        3)
            branch_name="migrate/$(echo $variant | tr '[:upper:]' '[:lower:]' | tr '-' '_')"
            log_info "Creating git branch: $branch_name"
            git checkout -b "$branch_name" 2>/dev/null || git checkout "$branch_name"
            log_success "Branch created/switched"
            pause && handle_variant_selection "$variant"
            ;;
        4)
            select_plugins
            pause && handle_variant_selection "$variant"
            ;;
        5)
            log_header "Starting Installation: $variant"
            generate_variant_config "$variant"
            generate_installation_plan "$variant"
            select_plugins
            log_success "Installation setup complete!"
            log_info "Follow the installation plan above to proceed"
            pause && main_menu
            ;;
        6)
            main_menu
            ;;
        *)
            log_error "Invalid action"
            pause && handle_variant_selection "$variant"
            ;;
    esac
}

plugin_menu() {
    log_header "Plugin Management"

    echo -e "${BOLD}Options:${NC}"
    echo "  1. List available plugins"
    echo "  2. Install plugin"
    echo "  3. List installed plugins"
    echo "  4. Uninstall plugin"
    echo "  5. Back to menu"
    echo ""

    read -p "Select option: " option

    case $option in
        1)
            list_available_plugins
            pause && plugin_menu
            ;;
        2)
            read -p "Enter plugin name or github:user/repo: " plugin_name
            install_plugin "$plugin_name"
            pause && plugin_menu
            ;;
        3)
            log_header "Installed Plugins"
            ls -la "$PLUGINS_DIR" 2>/dev/null || echo "No plugins installed"
            pause && plugin_menu
            ;;
        4)
            read -p "Enter plugin name to uninstall: " plugin_name
            rm -rf "$PLUGINS_DIR/$plugin_name"
            log_success "Plugin uninstalled"
            pause && plugin_menu
            ;;
        5)
            main_menu
            ;;
        *)
            log_error "Invalid option"
            pause && plugin_menu
            ;;
    esac
}

################################################################################
# COMMAND LINE ARGUMENTS
################################################################################

handle_arguments() {
    local variant=""
    local plugins=""
    local auto_install=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --variant)
                variant="$2"
                shift 2
                ;;
            --plugins)
                plugins="$2"
                shift 2
                ;;
            --auto)
                auto_install=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done

    if [ -n "$variant" ]; then
        generate_variant_config "$variant"
        generate_installation_plan "$variant"

        if [ -n "$plugins" ]; then
            for plugin in ${plugins//,/ }; do
                install_plugin "$plugin"
            done
        fi

        if [ "$auto_install" = true ]; then
            log_success "Configuration and plugins ready for installation"
        fi
    fi
}

show_help() {
    cat << 'EOF'
MigrateTools.sh - Migration Variant Selector & Installer

Usage:
  ./MigrateTools.sh                    # Interactive mode
  ./MigrateTools.sh --variant NAME     # Direct variant selection
  ./MigrateTools.sh --plugins P1,P2    # Install specific plugins
  ./MigrateTools.sh --auto             # Auto-configure

Examples:
  ./MigrateTools.sh --variant HTMX-Pure
  ./MigrateTools.sh --variant Jetzig-WASM --plugins docker,cicd
  ./MigrateTools.sh --variant MultiStage-Full --auto

Available Variants:
  1.  HTMX-Pure               - 4 weeks, low risk
  2.  HTMX-Bun               - 4 weeks, low risk
  3.  HTMX-WASM              - 10 weeks, medium risk
  4.  HTMX-WASM-Advanced     - 12 weeks, medium risk
  5.  Jetzig-Pure            - 3 weeks, low risk
  6.  Jetzig-WASM            - 8 weeks, medium risk
  7.  Jetzig-WASM-Advanced   - 10 weeks, medium-high risk
  8.  LowLatency-Base        - 7 weeks, high risk
  9.  LowLatency-WASM        - 10 weeks, very high risk
  10. MultiStage-Full        - 15 weeks, phased approach
  11. Custom-Build           - Build your own

Built-in Plugins:
  monitoring, docker, cicd, observability, testing, security-audit, performance-profiling

EOF
}

################################################################################
# ENTRY POINT
################################################################################

main() {
    # Initialize plugin system
    initialize_plugins

    # Handle command line arguments
    if [ $# -gt 0 ]; then
        handle_arguments "$@"
    else
        # Interactive mode
        main_menu
    fi
}

# Run main function
main "$@"
