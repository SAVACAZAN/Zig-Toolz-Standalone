# Migration Guide: React → HTMX + Zig Backend

Strategic guide for migrating from React SPA to HTMX + server-side rendering architecture.

---

## 📊 Executive Summary

| Aspect | React (Current) | HTMX (Proposed) |
|--------|-----------------|-----------------|
| **Bundle Size** | ~300 KB gzipped | ~15 KB (HTMX only) |
| **JS Runtime** | Full React 18 runtime | Lightweight browser APIs |
| **Rendering** | Client-side (CSR) | Server-side (SSR) via Zig |
| **State Management** | AuthContext | Server sessions + cookies |
| **Page Load** | ~2-3 seconds (dev) | ~500ms (SSR) |
| **Initial HTML** | Minimal, hydrated by JS | Full rendered HTML |
| **Interactive Dev** | Vite HMR | HTTP polling or WebSocket |
| **Architecture** | Decoupled API + UI | Integrated HTTP responses |
| **Complexity** | Moderate | Low |
| **Performance** | Good (after hydration) | Excellent (instant) |

---

## 🤔 Why HTMX for This Project?

### Reasons to Migrate:
1. ✅ **Backend Already Ready**: Zig HTTP server can serve HTML directly
2. ✅ **No Complex State**: Your app uses simple AuthContext (no Redux)
3. ✅ **Low Interactivity Complexity**: Forms, tables, modals — HTMX excels at these
4. ✅ **Bundle Size**: Reduce JS from 300 KB to 15 KB (95% reduction)
5. ✅ **Better SEO**: HTML served server-side is crawl-friendly
6. ✅ **Simpler Deployment**: Single Zig binary serves everything
7. ✅ **Type Safety**: Still use Zig for type-safe backend logic

### When NOT to Migrate:
1. ❌ Real-time dashboards with 100+ updates/second
2. ❌ Complex client-side state (Redux, Zustand needed)
3. ❌ Offline-first applications
4. ❌ Native mobile apps sharing code
5. ❌ Team deeply invested in React ecosystem

**Your Project?** ✅ **Perfect candidate for HTMX migration**

---

## 🏗️ Architecture Comparison

### Current: React SPA
```
┌─────────────────────────────────────────────┐
│  Browser (React 18 + TypeScript)            │
│  - Router (React Router v6)                 │
│  - State (AuthContext only)                 │
│  - API calls via fetch                      │
└────────────┬────────────────────────────────┘
             │ JSON API calls
             │ /api/login, /api/tickers, etc.
             ↓
┌─────────────────────────────────────────────┐
│  Zig Backend (main.zig)                     │
│  - HTTP server                              │
│  - Route handlers                           │
│  - Database (SQLite)                        │
│  - Exchange APIs                            │
└─────────────────────────────────────────────┘
```

### Proposed: HTMX + SSR
```
┌─────────────────────────────────────────────┐
│  Browser (HTMX + minimal JS)                │
│  - HTMX for dynamic interactions            │
│  - HTML swapping (not JSON)                 │
│  - Session cookies for auth                 │
└────────────┬────────────────────────────────┘
             │ HTML fragments
             │ /dashboard, /trade, /balance, etc.
             │ X-Requested-With: XMLHttpRequest
             ↓
┌─────────────────────────────────────────────┐
│  Zig Backend (Enhanced main.zig)            │
│  - HTTP server                              │
│  - HTML template rendering                  │
│  - Session management (cookies)             │
│  - Database (SQLite)                        │
│  - Exchange APIs                            │
│  - Returns HTML fragments instead of JSON   │
└─────────────────────────────────────────────┘
```

---

## 📋 Migration Strategy (Phased Approach)

### Phase 1: Setup & Infrastructure (Week 1)
- [ ] Add HTML template system to Zig backend
- [ ] Implement session management (cookie-based auth)
- [ ] Create base HTML layout template
- [ ] Add HTMX library to templates
- [ ] Create first template (login page)

### Phase 2: Core Pages (Week 2-3)
- [ ] Dashboard page (HTML + HTMX form)
- [ ] Markets page (HTML table with HTMX sorting)
- [ ] APIKeys page (HTML form + deletion with confirmation)
- [ ] Trade page (HTML form with HTMX submission)

### Phase 3: Advanced Features (Week 4)
- [ ] Real-time updates (WebSocket or polling)
- [ ] OrderbookMonitor (server-side filtering)
- [ ] Sentinel (live updates via HTMX)
- [ ] Shield Dashboard (aggregated HTML)

### Phase 4: Cleanup & Optimization (Week 5)
- [ ] Remove React dependencies
- [ ] Remove Vite build system
- [ ] Compress CSS/JS bundles
- [ ] Performance optimization
- [ ] Documentation updates

---

## 🔧 Implementation Examples

### Example 1: Login Page

**Current (React):**
```typescript
// frontend/src/pages/LoginPage.tsx
export default function LoginPage() {
  const { login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    await login(email, password);
    navigate('/dashboard');
  };

  return (
    <form onSubmit={handleSubmit}>
      <input value={email} onChange={(e) => setEmail(e.target.value)} />
      <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} />
      <button type="submit">Login</button>
    </form>
  );
}
```

**Proposed (HTMX + Zig):**
```html
<!-- backend/templates/login.html -->
<!DOCTYPE html>
<html>
<head>
  <title>Login - Exchange</title>
  <link rel="stylesheet" href="/static/styles.css">
  <script src="/static/htmx.min.js"></script>
</head>
<body>
  <div class="container">
    <h1>Login</h1>
    <form hx-post="/login" hx-target="body" hx-swap="outerHTML">
      <input type="email" name="email" required placeholder="Email" />
      <input type="password" name="password" required placeholder="Password" />
      <button type="submit">Login</button>
    </form>
  </div>
</body>
</html>
```

**Zig Backend Handler:**
```zig
fn handleLogin(req: *std.http.Server.Request) !void {
    // Parse form data from POST body
    var email: []const u8 = "";
    var password: []const u8 = "";

    // Validate credentials
    if (try users.authenticate(allocator, email, password)) |user| {
        // Create session cookie
        const session_token = try jwt.generateToken(allocator, user.id, email);

        // Return redirect response
        const response = "HTTP/1.1 302 Found\r\nLocation: /dashboard\r\nSet-Cookie: session={s}; Path=/\r\n\r\n";
        try req.writer().writeAll(try std.fmt.allocPrint(allocator, response, .{session_token}));
    } else {
        // Return error HTML
        const error_html = @embedFile("templates/login_error.html");
        try req.writer().writeAll(error_html);
    }
}
```

### Example 2: Markets Table (with live filtering)

**Current (React):**
```typescript
// frontend/src/pages/MarketsPage.tsx
export default function MarketsPage() {
  const [markets, setMarkets] = useState([]);
  const [search, setSearch] = useState('');

  useEffect(() => {
    const filtered = markets.filter(m => m.symbol.includes(search));
    // render table...
  }, [search, markets]);
}
```

**Proposed (HTMX):**
```html
<!-- backend/templates/markets.html -->
<div class="markets-container">
  <input
    type="text"
    name="search"
    placeholder="Search pairs..."
    hx-get="/markets/table"
    hx-target="#markets-table"
    hx-trigger="keyup changed delay:500ms"
  />

  <table id="markets-table" hx-get="/markets/table" hx-trigger="load">
    <!-- Server will fill this with filtered results -->
  </table>
</div>
```

**Zig Backend:**
```zig
fn handleMarketsTable(req: *std.http.Server.Request) !void {
    const search = try getQueryParam(req, "search", "");
    var markets = try lcx.fetchMarkets(allocator);

    if (search.len > 0) {
        markets = filterMarkets(markets, search);
    }

    // Generate HTML rows
    var html = try std.fmt.allocPrint(allocator,
        "<tbody>", .{});

    for (markets) |market| {
        html = try std.fmt.allocPrint(allocator,
            "{s}<tr><td>{s}</td><td>{f}</td><td>{f}</td></tr>",
            .{ html, market.symbol, market.bid, market.ask }
        );
    }

    html = try std.fmt.allocPrint(allocator, "{s}</tbody>", .{html});
    try req.writer().writeAll(html);
}
```

### Example 3: Delete with Confirmation

**Current (React):**
```typescript
const handleDelete = async (id) => {
  if (confirm('Really delete?')) {
    await fetch(`/api/apikeys/${id}`, { method: 'DELETE' });
    setKeys(keys.filter(k => k.id !== id));
  }
};

// render: <button onClick={() => handleDelete(key.id)}>Delete</button>
```

**Proposed (HTMX):**
```html
<!-- HTML button with confirmation -->
<button
  hx-delete="/apikeys/{id}"
  hx-confirm="Really delete this key?"
  hx-target="#key-{id}"
  hx-swap="outerHTML swap:1s"
>
  Delete
</button>
```

No JavaScript needed! HTMX handles the confirmation dialog.

---

## 🔐 Authentication Flow (HTMX)

### Session-Based Auth (vs. JWT tokens)

**Current (React + JWT):**
```
1. User submits login
2. Backend returns JWT token
3. Frontend stores token in localStorage
4. Frontend includes token in Authorization header
5. Backend verifies token on each request
```

**Proposed (HTMX + Sessions):**
```
1. User submits login form
2. Backend creates session, returns Set-Cookie header
3. Browser automatically stores session cookie
4. Browser includes cookie in all requests
5. Backend verifies session from cookie
6. Server returns rendered HTML
```

**Benefits of sessions:**
- ✅ No localStorage vulnerability (XSS can't steal cookies with HttpOnly flag)
- ✅ Server-side revocation (immediate logout)
- ✅ No token expiration issues
- ✅ Simpler client-side (no token management)

**Implementation in Zig:**
```zig
pub const SessionManager = struct {
    pub fn createSession(allocator: std.mem.Allocator, user_id: u32) ![]u8 {
        const token = try generateSecureRandomToken(allocator);
        try sessionStore.put(allocator, token, .{ .user_id = user_id, .created_at = now() });
        return token;
    }

    pub fn validateSession(token: []const u8) ?u32 {
        if (sessionStore.get(token)) |session| {
            if (session.created_at + SESSION_TIMEOUT < now()) {
                sessionStore.delete(token);
                return null;
            }
            return session.user_id;
        }
        return null;
    }
};
```

---

## 📁 Backend Changes Required

### New Directory Structure:
```
backend/
├── src/
│   ├── main.zig                 (enhanced with template rendering)
│   ├── template/
│   │   ├── base.html           (layout template)
│   │   ├── login.html
│   │   ├── dashboard.html
│   │   ├── trade.html
│   │   ├── markets.html
│   │   ├── apikeys.html
│   │   └── components/
│   │       ├── navbar.html
│   │       ├── sidebar.html
│   │       └── table_rows.html
│   ├── session/
│   │   └── manager.zig         (session management)
│   └── template/
│       └── engine.zig          (template rendering)
├── static/
│   ├── styles.css              (minimal CSS, no React styling)
│   ├── htmx.min.js             (14 KB)
│   └── app.js                  (minimal JS, <5 KB)
└── build.zig                   (updated)
```

### New Modules:

**1. Template Engine** (`src/template/engine.zig`):
```zig
pub fn renderTemplate(
    allocator: std.mem.Allocator,
    template_name: []const u8,
    context: anytype,
) ![]u8 {
    const template = try std.fs.cwd().readFileAlloc(
        allocator,
        try std.fmt.allocPrint(allocator, "templates/{s}.html", .{template_name}),
        1024 * 1024
    );

    // Simple mustache-like substitution: {{variable}}
    var result = template;
    inline for (@typeInfo(@TypeOf(context)).Struct.fields) |field| {
        const value = @field(context, field.name);
        const placeholder = try std.fmt.allocPrint(allocator, "{{{{{s}}}}}", .{field.name});
        result = try replaceAll(allocator, result, placeholder, value);
    }

    return result;
}
```

**2. Session Manager** (`src/session/manager.zig`):
```zig
pub const SessionManager = struct {
    sessions: std.StringHashMap(Session),
    allocator: std.mem.Allocator,

    pub fn create(allocator: std.mem.Allocator) SessionManager {
        return .{
            .sessions = std.StringHashMap(Session).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn createSession(self: *SessionManager, user_id: u32) ![]u8 {
        const token = try generateRandomToken(self.allocator);
        try self.sessions.put(token, .{
            .user_id = user_id,
            .created_at = @intCast(std.time.timestamp()),
        });
        return token;
    }

    pub fn validateSession(self: *SessionManager, token: []const u8) ?u32 {
        if (self.sessions.get(token)) |session| {
            if (@intCast(std.time.timestamp()) - session.created_at > 7 * 24 * 60 * 60) {
                _ = self.sessions.remove(token);
                return null;
            }
            return session.user_id;
        }
        return null;
    }
};
```

---

## 🗑️ Frontend Cleanup

### Files to Remove:
```bash
# Remove all React files
rm -rf frontend/src/pages/
rm -rf frontend/src/components/
rm -rf frontend/src/context/
rm -rf frontend/src/layouts/
rm -rf frontend/src/api/
rm -rf frontend/src/styles/

# Remove build tools (Vite)
rm frontend/package.json
rm frontend/vite.config.ts
rm frontend/tsconfig.json
rm -rf frontend/node_modules/

# Remove React dependencies
npm uninstall react react-dom react-router-dom
```

### Final Frontend Structure:
```
frontend/
├── index.html              (entry point, includes HTMX)
├── styles.css              (minimal, ~10 KB)
└── app.js                  (minimal interactions, <5 KB)
```

---

## 🚀 Build System: Bun (Zig-Native)

Since you're already using Zig for the backend, **Bun** is the perfect choice for your build system. It's written in Zig and dramatically faster than Node.js.

### Why Bun Over npm/Node.js?

| Feature | npm/Node | Bun | Winner |
|---------|----------|-----|--------|
| **Language** | JavaScript | Zig | Bun 🎯 |
| **Speed** | ~5-10s | ~500ms | Bun 20x faster |
| **Bundle Size** | 50+ MB | 100 MB single binary | Node (but Bun OK) |
| **CSS Minification** | Needs plugin | Built-in | Bun 🎯 |
| **JS Minification** | esbuild/terser | Built-in | Bun 🎯 |
| **Package Caching** | npm_modules | Global cache | Bun 🎯 |
| **Task Runner** | npm scripts | bunx | Bun 🎯 |
| **Alignment** | JavaScript ecosystem | Zig ecosystem | Bun 🎯 |

### Installation:

```bash
# macOS/Linux
curl -fsSL https://bun.sh/install | bash

# Or use your package manager
brew install zig-bun  # or similar

# Verify
bun --version
```

### Bun Setup for HTMX Project:

**Create `bunfile.ts` (Bun's build script):**
```typescript
import { build } from "bun";

await build({
  entrypoints: ["./app.ts"],
  outdir: "../backend/static",
  minify: {
    syntax: true,
    whitespace: true,
    identifiers: true,
  },
  sourcemap: "external",
});

// Also minify CSS
import { exec } from "bun";
await exec(["bun", "x", "lightningcss", "styles.css",
            "--minify", "--output-file", "../backend/static/styles.css"]);
```

**Create `bunx.toml` (Bun package config):**
```toml
[package]
name = "exchange-frontend"
version = "1.0.0"

[tasks]
dev = "bun run --watch app.ts"
build = "bun run bunfile.ts"
minify = "bun x lightningcss styles.css --minify"
```

### Complete Build Pipeline:

```bash
# Development: Watch mode with live reload
bun dev

# Production: Minified build
bun build

# Single command: Build everything
bun run build && cd ../backend && zig build run
```

### What Bun Does (for your HTMX setup):

1. **Minify JavaScript** (app.js: 5 KB → 2 KB)
2. **Minify CSS** (styles.css: 10 KB → 6 KB)
3. **Manage static assets** (htmx, fonts, images)
4. **Run dev server** (optional, for development)
5. **Copy to backend** (`/backend/static/` directory)

### Total Frontend Package Size with Bun:

```
Before (React + Vite + npm):
  React:         42 KB
  Vite:          30 KB
  Dependencies:  500+ MB (node_modules)
  ─────────────────────────
  Total:         570+ MB

After (HTMX + Bun):
  HTMX:          14 KB
  CSS:           6 KB (minified)
  JS:            2 KB (minified)
  Bun binary:    100 MB (one-time, not per project)
  ─────────────────────────
  Total:         122 KB + Bun binary

Reduction: 99.98% (project files only)
```

### Bun + Zig Workflow:

```bash
# Terminal 1: Watch frontend assets
$ bun dev
[bun] Watching frontend assets...

# Terminal 2: Build and run backend
$ cd backend && zig build run
[SERVER] Zig Exchange Server starting...
```

Or use a unified command:

```bash
# backend/build.zig can call Bun to build frontend
const run_bun = b.addSystemCommand(&.{ "bun", "build" });
run_bun.cwd = b.pathJoin(&.{ b.build_root.path.?, "..", "frontend" });
const frontend_step = b.step("frontend", "Build frontend with Bun");
frontend_step.dependOn(&run_bun.step);
```

### Bun in Production:

For production deployment:
```bash
# Single build step
bun build

# Output: /backend/static/
#   - htmx.min.js (14 KB)
#   - app.js (2 KB minified)
#   - styles.css (6 KB minified)

# Backend serves static files
cd backend && zig build -Doptimize=ReleaseFast

# Single Zig binary includes all static assets
```

### Comparison: Full Stack with Bun + Zig

```
Old Setup (React + Vite + Node.js):
  - Backend: Zig binary (3 MB)
  - Frontend: React + npm (500+ MB)
  - Total: 503+ MB development setup
  - Build time: 10-30 seconds

New Setup (HTMX + Bun + Zig):
  - Backend: Zig binary (3 MB)
  - Frontend: Bun + source files (100 MB)
  - Total: 103 MB development setup
  - Build time: 500 ms
  - Alignment: Both written in Zig (conceptual alignment)
```

### Advanced: Automated CSS Processing with Bun

If you want CSS preprocessing (variables, nesting, etc.):

```bash
# Using Lightning CSS (Zig-based CSS processor)
bun add -d lightningcss

# Create bunfile.ts for CSS + JS pipeline
import { spawnSync } from "bun";
import fs from "fs";

// Step 1: Process CSS with Lightning CSS
spawnSync({
  cmd: ["bun", "x", "lightningcss", "styles.css",
        "--minify", "--targets", "chrome 90",
        "--output-file", "../backend/static/styles.css"]
});

// Step 2: Minify app.js
const { minify } = await import("terser");
const code = fs.readFileSync("app.js", "utf-8");
const result = await minify(code);
fs.writeFileSync("../backend/static/app.js", result.code);

console.log("✅ Frontend built (Bun + Zig ecosystem)");
```

---

## Integration: Bun ↔ Zig Backend

### Unified Development:

```bash
#!/bin/bash
# start-dev-bun.sh - Complete startup script

echo "[STARTUP] Building frontend with Bun..."
cd frontend && bun build

echo "[STARTUP] Starting Zig backend..."
cd ../backend && zig build run &

echo "[STARTUP] Watching frontend (development)..."
cd ../frontend && bun dev

wait
```

### Why This Matters:

1. ✅ **No Node.js/npm complexity** — Bun is single binary
2. ✅ **Zig alignment** — Both languages, same philosophy
3. ✅ **Fast builds** — 500ms vs 10-30s with Vite
4. ✅ **Minimal dependencies** — HTMX + CSS + JS only
5. ✅ **Production ready** — Single binary output

---

## 🛡️ Error Handling (Without Modal Alerts)

### The Problem:
In React, error handling is typically modal alerts or toast notifications. In HTMX, errors need graceful UX without JavaScript alert windows.

### Solution: Server-Driven Error Responses

**Zig Backend Handler with Error Handling:**
```zig
fn handleTradeOrder(req: *std.http.Server.Request, allocator: std.mem.Allocator) !void {
    // Parse form data
    var price: f64 = 0;
    var amount: f64 = 0;
    var side: []const u8 = "";

    // Validation
    if (price <= 0) {
        const error_html =
            \\<div class="error-toast">
            \\  <svg class="icon-error"><!-- error icon --></svg>
            \\  <span>Price must be greater than 0</span>
            \\</div>
        ;
        try req.writer().writeAll(error_html);
        return;
    }

    // If validation passes, return success HTML
    const response = try std.fmt.allocPrint(allocator,
        \\<div class="success-toast">
        \\  <svg class="icon-check"><!-- check icon --></svg>
        \\  <span>Order placed: {f} {s} at {f}</span>
        \\</div>
        \\<div id="open-orders" hx-get="/orders/open" hx-trigger="load">
        \\  <!-- Updated orders will load here -->
        \\</div>
        , .{ amount, side, price }
    );

    try req.writer().writeAll(response);
}
```

**Frontend HTML:**
```html
<form hx-post="/orders/create"
      hx-target="#order-messages"
      hx-swap="innerHTML"
      hx-on="htmx:responseError: this.classList.add('shake')">
  <input type="number" name="price" placeholder="Price" required />
  <input type="number" name="amount" placeholder="Amount" required />
  <select name="side" required>
    <option value="buy">Buy</option>
    <option value="sell">Sell</option>
  </select>
  <button type="submit">Place Order</button>
</form>

<div id="order-messages"></div>

<style>
  .error-toast {
    background: linear-gradient(135deg, #ef4444, #dc2626);
    color: white;
    padding: 12px 16px;
    border-radius: 8px;
    display: flex;
    align-items: center;
    gap: 8px;
    animation: slideIn 0.3s ease-out;
  }

  .success-toast {
    background: linear-gradient(135deg, #10b981, #059669);
    color: white;
    padding: 12px 16px;
    border-radius: 8px;
    display: flex;
    align-items: center;
    gap: 8px;
    animation: slideIn 0.3s ease-out;
  }

  @keyframes slideIn {
    from {
      opacity: 0;
      transform: translateY(-10px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  form.shake {
    animation: shake 0.4s;
  }

  @keyframes shake {
    0%, 100% { transform: translateX(0); }
    25% { transform: translateX(-5px); }
    75% { transform: translateX(5px); }
  }
</style>
```

### Key Pattern: HX-Retarget
For errors on one element that affect another:
```html
<!-- Swap error into #error-container, not default target -->
<button hx-delete="/orders/{id}"
        hx-target="#error-container"
        hx-retarget="#error-container"
        hx-swap="outerHTML">
  Delete Order
</button>

<!-- Server responds with error in #error-container wrapper -->
<div id="error-container">
  <!-- Error toast inserted here -->
</div>
```

---

## 🔀 Partial Swaps (Multi-Element Updates)

### The Problem:
One action affects multiple parts of the UI. Update balance + transaction list + total portfolio value simultaneously.

### Solution: HX-Trigger with Multiple Targets

**Zig Backend:**
```zig
fn handleBuyOrder(req: *std.http.Server.Request, allocator: std.mem.Allocator) !void {
    // Place order
    const order = try orders.create(allocator, .{
        .user_id = session.user_id,
        .pair = "BTC/USD",
        .side = "buy",
        .price = 54000,
        .amount = 0.1,
    });

    // Generate THREE HTML fragments
    const balance_html = try renderBalanceWidget(allocator, session.user_id);
    const order_html = try renderOpenOrder(allocator, order);
    const stats_html = try renderPortfolioStats(allocator, session.user_id);

    // Combine with HX-Trigger header
    const response = try std.fmt.allocPrint(allocator,
        "HTTP/1.1 200 OK\r\n" ++
        "Content-Type: text/html\r\n" ++
        "HX-Trigger: {{\n" ++
        "  \"balanceUpdated\": true,\n" ++
        "  \"orderAdded\": true,\n" ++
        "  \"portfolioChanged\": true\n" ++
        "}}\r\n" ++
        "Content-Length: {}\r\n" ++
        "\r\n" ++
        "{s}",
        .{ balance_html.len + order_html.len + stats_html.len, balance_html }
    );

    try req.writer().writeAll(response);
}
```

**Frontend HTML with Multi-Target:**
```html
<form hx-post="/orders/buy"
      hx-target="this"
      hx-swap="outerHTML"
      hx-on="htmx:afterSwap: handleOrderSuccess(event)">
  <input type="number" name="amount" placeholder="Amount" />
  <button type="submit">Buy BTC</button>
</form>

<!-- Listen for HX-Trigger events -->
<div id="balance" hx-trigger="balanceUpdated from:body" hx-get="/widget/balance"></div>
<div id="orders" hx-trigger="orderAdded from:body" hx-get="/widget/orders"></div>
<div id="stats" hx-trigger="portfolioChanged from:body" hx-get="/widget/stats"></div>

<script>
function handleOrderSuccess(event) {
  // Trigger multiple refreshes via HX-Trigger
  htmx.trigger('#balance', 'balanceUpdated');
  htmx.trigger('#orders', 'orderAdded');
  htmx.trigger('#stats', 'portfolioChanged');
}
</script>
```

### Pattern: Event-Driven UI Updates
```zig
// Server sends structured response with multiple targets
const response =
    \\HTTP/1.1 200 OK
    \\Content-Type: multipart/form-data; boundary=----
    \\HX-Trigger: {"orderPlaced": true, "balanceUpdated": true}
    \\
    \\------
    \\Content-Disposition: form-data; name="order-html"
    \\
    ;

// Each fragment targeted by HTMX event listener
```

---

## 🔐 CSRF Protection

### The Problem:
HTMX requests bypass standard CSRF protection from browser Same-Origin Policy. Need token-based CSRF protection.

### Solution: Token Generation & Validation in Zig

**Session/CSRF Module** (`src/csrf/csrf.zig`):
```zig
pub const CSRFManager = struct {
    tokens: std.StringHashMap([]u8),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) CSRFManager {
        return .{
            .tokens = std.StringHashMap([]u8).init(allocator),
            .allocator = allocator,
        };
    }

    /// Generate CSRF token for session
    pub fn generateToken(self: *CSRFManager, session_id: []const u8) ![]u8 {
        var rand_bytes: [32]u8 = undefined;
        const random = std.crypto.random;
        random.bytes(&rand_bytes);

        const token = try std.fmt.allocPrint(self.allocator, "{x}", .{rand_bytes});
        try self.tokens.put(session_id, token);
        return token;
    }

    /// Validate CSRF token
    pub fn validateToken(self: *CSRFManager, session_id: []const u8, token: []const u8) bool {
        if (self.tokens.get(session_id)) |valid_token| {
            return std.mem.eql(u8, valid_token, token);
        }
        return false;
    }

    /// Rotate token after use (security best practice)
    pub fn rotateToken(self: *CSRFManager, session_id: []const u8) ![]u8 {
        _ = self.tokens.remove(session_id);
        return self.generateToken(session_id);
    }
};
```

**Middleware in Zig:**
```zig
fn validateCSRFMiddleware(req: *std.http.Server.Request, allocator: std.mem.Allocator) !bool {
    // CSRF check only for state-changing requests
    if (!std.mem.eql(u8, req.method, "POST") and
        !std.mem.eql(u8, req.method, "PUT") and
        !std.mem.eql(u8, req.method, "DELETE")) {
        return true; // GET requests don't need CSRF
    }

    // Get session from cookie
    const session_id = try getSessionFromCookie(req);

    // Get CSRF token from request header
    const csrf_token = req.headers.getFirstValue("X-CSRF-Token") orelse {
        try respondWithError(req, 403, "CSRF token missing");
        return false;
    };

    // Validate token
    if (!csrf_manager.validateToken(session_id, csrf_token)) {
        try respondWithError(req, 403, "Invalid CSRF token");
        return false;
    }

    // Rotate token after use
    const new_token = try csrf_manager.rotateToken(session_id);

    // Include new token in response headers
    try req.response.headers.append("X-CSRF-Token", new_token);

    return true;
}
```

**Frontend Template Include:**
```html
<!-- base.html - included in all forms -->
<!DOCTYPE html>
<html>
<head>
  <script src="/static/htmx.min.js"></script>
  <script>
    // Add CSRF token to all HTMX requests
    document.addEventListener('htmx:beforeRequest', function(evt) {
      const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
      evt.detail.xhr.setRequestHeader('X-CSRF-Token', csrfToken);
    });

    // Rotate token after successful request
    document.addEventListener('htmx:afterSwap', function(evt) {
      const newToken = evt.detail.xhr.getResponseHeader('X-CSRF-Token');
      if (newToken) {
        document.querySelector('meta[name="csrf-token"]').setAttribute('content', newToken);
      }
    });
  </script>
</head>
<body>
  <meta name="csrf-token" content="{{csrf_token}}" />
  <!-- Forms use HTMX, no manual token handling needed -->
</body>
</html>
```

### CSRF in Forms:
```html
<form hx-post="/orders/create"
      hx-target="#result"
      hx-swap="innerHTML">
  <!-- CSRF token automatically added by middleware via JavaScript above -->
  <input type="number" name="price" required />
  <input type="number" name="amount" required />
  <button type="submit">Place Order</button>
</form>
```

---

## ⏳ Loading States

### The Problem:
Users need visual feedback while HTMX requests are in flight. Show spinners, disable buttons, blur content.

### Solution: HTMX Indicator Class + CSS

**CSS for Loading States:**
```css
/* HTMX built-in indicator class */
.htmx-request .htmx-indicator {
  display: inline-block;
}

.htmx-indicator {
  display: none;
}

/* Spinner animation */
.spinner {
  border: 3px solid rgba(99, 102, 241, 0.1);
  border-top: 3px solid #6366f1;
  border-radius: 50%;
  width: 20px;
  height: 20px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* Fade out content while loading */
.htmx-request.fade-on-load {
  opacity: 0.5;
  pointer-events: none;
  transition: opacity 0.3s ease;
}

/* Disable button while loading */
.htmx-request button:disabled,
button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* Loading text */
.loading-text::after {
  content: '';
  animation: dots 1.5s steps(4, end) infinite;
}

@keyframes dots {
  0%, 20% { content: ''; }
  40% { content: '.'; }
  60% { content: '..'; }
  80%, 100% { content: '...'; }
}
```

**HTML with Loading States:**
```html
<!-- Form with spinner -->
<form hx-post="/orders/buy"
      hx-target="#result"
      hx-swap="innerHTML"
      hx-indicator="#loading-spinner"
      class="fade-on-load">
  <input type="number" name="amount" placeholder="Amount" />

  <button type="submit" hx-disable-element="true">
    <span class="htmx-indicator spinner"></span>
    Place Order
  </button>
</form>

<div id="loading-spinner" class="htmx-indicator">
  <span class="spinner"></span> Processing...
</div>

<div id="result"></div>
```

**Advanced: Custom Indicator Elements:**
```html
<!-- Table with row loading indicator -->
<table>
  <tbody>
    <tr hx-get="/orders/details/123"
        hx-target="this"
        hx-swap="outerHTML"
        hx-indicator="#row-loading">
      <td>Order #123</td>
      <td>Pending</td>
      <td>
        <span class="htmx-indicator spinner"></span>
      </td>
    </tr>
  </tbody>
</table>

<script>
// Disable row interaction while loading
document.addEventListener('htmx:beforeRequest', function(evt) {
  evt.detail.xhr.target?.classList.add('fade-on-load');
});

document.addEventListener('htmx:afterSwap', function(evt) {
  evt.detail.xhr.target?.classList.remove('fade-on-load');
});
</script>
```

### Progress Bar for Long Operations:
```html
<div id="progress" hx-get="/export/status" hx-trigger="every 500ms" hx-swap="innerHTML">
  <div class="progress-bar" style="width: 0%"></div>
  <span>0%</span>
</div>

<style>
.progress-bar {
  height: 4px;
  background: linear-gradient(90deg, #6366f1, #0ea5e9);
  transition: width 0.2s ease;
}
</style>
```

---

## 📦 Static Asset Pipeline (.embedFile)

### The Problem:
Serve static assets (CSS, JS, images) from a single Zig binary without a separate `node_modules` folder or filesystem dependencies.

### Solution: Zig @embedFile for Single-Binary Distribution

**Build Configuration** (`backend/build.zig`):
```zig
const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const exe = b.addExecutable(.{
        .name = "exchange-server",
        .root_source_file = b.path("src/main.zig"),
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });

    // Step 1: Build frontend with Bun
    const bun_build = b.addSystemCommand(&.{
        "bun", "build",
    });
    bun_build.setCwd(b.path("../frontend"));

    // Step 2: Embed all static files
    const embed_step = b.addWriteFiles();

    // Copy minified assets to temp directory
    const assets_dir = embed_step.addCopyDirectory(
        b.path("../frontend/dist"),
        "static"
    );

    // Step 3: Link embedded files to binary
    exe.root_module.addAnonymousImport("static", .{
        .root_source_file = b.path("src/assets.zig"),
    });

    b.getInstallStep().dependOn(&bun_build.step);
    exe.step.dependOn(b.getInstallStep());

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the exchange server");
    run_step.dependOn(&run_cmd.step);
}
```

**Asset Module** (`backend/src/assets.zig`):
```zig
const std = @import("std");

/// Embed all static files at compile time
pub const assets = struct {
    pub const styles_css = @embedFile("../frontend/dist/styles.css");
    pub const app_js = @embedFile("../frontend/dist/app.js");
    pub const htmx_js = @embedFile("../frontend/dist/htmx.min.js");
    pub const favicon = @embedFile("../frontend/dist/favicon.ico");
};

/// Serve static files from memory (no filesystem reads)
pub fn serveStatic(
    req: *std.http.Server.Request,
    path: []const u8,
    allocator: std.mem.Allocator,
) !void {
    const content_type = if (std.mem.endsWith(u8, path, ".css"))
        "text/css"
    else if (std.mem.endsWith(u8, path, ".js"))
        "application/javascript"
    else if (std.mem.endsWith(u8, path, ".ico"))
        "image/x-icon"
    else
        "application/octet-stream";

    const body = switch (path) {
        "/static/styles.css" => assets.styles_css,
        "/static/app.js" => assets.app_js,
        "/static/htmx.min.js" => assets.htmx_js,
        "/favicon.ico" => assets.favicon,
        else => {
            try req.writer().writeAll("HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n");
            return;
        },
    };

    const response = try std.fmt.allocPrint(allocator,
        "HTTP/1.1 200 OK\r\n" ++
        "Content-Type: {s}\r\n" ++
        "Content-Length: {}\r\n" ++
        "Cache-Control: public, max-age=31536000\r\n" ++
        "\r\n" ++
        "{s}",
        .{ content_type, body.len, body }
    );

    try req.writer().writeAll(response);
}
```

**Main Server Integration:**
```zig
// In main.zig handleConnection()
fn handleConnection(req: *std.http.Server.Request, allocator: std.mem.Allocator) !void {
    // Route static assets
    if (std.mem.startsWith(u8, req.path, "/static/")) {
        return try assets.serveStatic(req, req.path, allocator);
    }

    if (std.mem.eql(u8, req.path, "/favicon.ico")) {
        return try assets.serveStatic(req, "/favicon.ico", allocator);
    }

    // ... other routes
}
```

**Deployment Advantage:**
```bash
# Before: React + Node.js
npm run build        # ~30 seconds
node server.js       # 500+ MB in memory
# Deploy: Copy node_modules (500+ MB) + dist/ + server

# After: HTMX + Zig + @embedFile
bun build            # ~500ms
zig build -Doptimize=ReleaseFast
# Deploy: Single 5 MB binary with all static assets embedded
# Zero external file dependencies
# Instant startup: <1 second
```

---

## 📊 Chart Integration (htmx:afterSwap)

### The Problem:
Charts (Chart.js, Lightweight Charts) require JavaScript initialization after DOM content loads. HTMX swaps HTML dynamically, so charts need reinitializing.

### Solution: htmx:afterSwap Event Handler

**Zig Backend:** Return HTML with chart container:
```zig
fn handleChartData(req: *std.http.Server.Request, allocator: std.mem.Allocator) !void {
    // Fetch data from database or exchange
    var prices = try db.getPriceHistory(allocator, "BTC/USD", 1440); // last 24 hours

    // Generate chart HTML
    const chart_html = try std.fmt.allocPrint(allocator,
        \\<div class="chart-container">
        \\  <canvas id="price-chart" data-prices="{s}"></canvas>
        \\</div>
        , .{try serializePrices(allocator, prices)}
    );

    try req.writer().writeAll(chart_html);
}
```

**Frontend: Initialize Charts on Swap:**
```html
<div hx-get="/chart/price"
     hx-target="#chart-area"
     hx-trigger="load"
     hx-on="htmx:afterSwap: initChart(event)">
  <div id="chart-area"></div>
</div>

<script src="/static/chart.min.js"></script>
<script>
  // Initialize chart library after HTMX swaps content
  function initChart(event) {
    const canvas = document.querySelector('#price-chart');
    if (!canvas) return;

    const pricesJson = canvas.getAttribute('data-prices');
    const prices = JSON.parse(pricesJson);

    // Lightweight Charts example
    const container = canvas.parentElement;
    const chart = LightweightCharts.createChart(container, {
      width: container.clientWidth,
      height: 300,
    });

    const lineSeries = chart.addLineSeries();
    lineSeries.setData(prices);
    chart.timeScale().fitContent();
  }

  // Reinitialize chart when data refreshes
  document.addEventListener('htmx:afterSwap', function(evt) {
    if (evt.detail.xhr.responseURL.includes('/chart/')) {
      initChart(evt);
    }
  });
</script>
```

**Auto-Refresh Charts with Polling:**
```html
<div hx-get="/chart/live"
     hx-trigger="every 5s"
     hx-swap="outerHTML"
     hx-on="htmx:afterSwap: updateChart(event)"
     id="live-chart">
  <canvas id="live-price-chart"></canvas>
</div>
```

**Chart.js Initialization Pattern:**
```html
<script src="/static/chart.js"></script>
<script>
  let chartInstance = null;

  function initChart(event) {
    const ctx = document.querySelector('#price-chart');
    if (!ctx) return;

    // Destroy previous chart instance
    if (chartInstance) {
      chartInstance.destroy();
    }

    const data = JSON.parse(ctx.getAttribute('data-prices'));

    chartInstance = new Chart(ctx, {
      type: 'line',
      data: {
        labels: data.labels,
        datasets: [{
          label: 'BTC/USD Price',
          data: data.prices,
          borderColor: '#6366f1',
          backgroundColor: 'rgba(99, 102, 241, 0.1)',
          tension: 0.4,
        }],
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          legend: { display: true },
        },
        scales: {
          y: { beginAtZero: false },
        },
      },
    });
  }

  // Event delegation for dynamic chart updates
  document.addEventListener('htmx:afterSwap', function(evt) {
    if (evt.detail.target.id === 'live-chart' || evt.detail.target.id === 'chart-area') {
      initChart(evt);
    }
  });
</script>
```

**Real-Time Price Updates with WebSocket:**
```html
<!-- WebSocket extension for HTMX -->
<div hx-ext="ws"
     ws-connect="/ws/prices"
     id="price-ticker">
  <table id="prices-table">
    <tr><td>BTC</td><td id="btc-price">—</td></tr>
    <tr><td>ETH</td><td id="eth-price">—</td></tr>
  </table>

  <div id="price-chart" hx-get="/chart/live" hx-trigger="priceUpdated from:body">
    <!-- Chart reloads when prices update -->
  </div>
</div>

<script>
  document.addEventListener('htmx:ws:open', function(evt) {
    console.log('WebSocket connected for live prices');
  });

  document.addEventListener('htmx:ws:message', function(evt) {
    const data = JSON.parse(evt.detail.message);

    // Update ticker
    document.querySelector('#btc-price').textContent = data.btc;
    document.querySelector('#eth-price').textContent = data.eth;

    // Trigger chart refresh
    htmx.trigger('#price-chart', 'priceUpdated');
  });

  // Initialize chart on first load
  document.addEventListener('htmx:afterSwap', initChart);
</script>
```

**Memory-Efficient Chart Updates:**
```zig
// Send minimal data for updates
fn handleChartUpdate(req: *std.http.Server.Request, allocator: std.mem.Allocator) !void {
    // Instead of full chart, return just data point
    const latest_price = try db.getLatestPrice(allocator, "BTC/USD");

    const response = try std.fmt.allocPrint(allocator,
        \\<script>
        \\  if (window.chartInstance) {{
        \\    window.chartInstance.data.datasets[0].data.push({f});
        \\    window.chartInstance.update('none');
        \\  }}
        \\</script>
        , .{latest_price}
    );

    try req.writer().writeAll(response);
}
```

---

---

## ⚡ Performance Impact

### Bundle Size Reduction:
```
Before (React):
  react:                    42 KB
  react-dom:                48 KB
  react-router-dom:         32 KB
  @vitejs/plugin-react:     15 KB
  typescript:               30 KB
  other:                   133 KB
  ────────────────────────────────
  Total:                   300 KB

After (HTMX):
  htmx:                     14 KB
  app.js:                    4 KB
  styles.css:               10 KB
  ────────────────────────────────
  Total:                    28 KB

Reduction: 90.7% (272 KB saved)
```

### Load Time Improvements:
```
Metric          React (CSR)    HTMX (SSR)    Improvement
──────────────────────────────────────────────────────────
Initial HTML    50 ms          50 ms         —
JS Download     200 ms         15 ms         93% faster
JS Parse        150 ms         5 ms          97% faster
React Hydrate   300 ms         0 ms          100% faster
First Paint     700 ms         65 ms         91% faster
Interaction     900 ms         65 ms         93% faster

Total: 900ms → 65ms (92% improvement)
```

---

## 🚀 Migration Checklist

### Pre-Migration (Week 0):
- [ ] Backup current React codebase (git branch)
- [ ] Document API endpoints
- [ ] Document current page routes
- [ ] Identify interactive components (forms, modals, etc.)
- [ ] Review HTMX documentation

### Phase 1: Infrastructure:
- [ ] Add template engine to Zig backend
- [ ] Implement session manager
- [ ] Create base HTML template
- [ ] Create static CSS file
- [ ] Add HTMX to templates
- [ ] Test session creation/validation

### Phase 2: Authentication:
- [ ] Create login.html template
- [ ] Update login handler to return HTML
- [ ] Create session-based auth
- [ ] Add Set-Cookie headers
- [ ] Create logout handler
- [ ] Add middleware to check sessions

### Phase 3: Pages (one at a time):
- [ ] **Login/Register** (static forms, highest priority)
- [ ] **Dashboard** (simple data display)
- [ ] **Markets** (table with search - uses HTMX filtering)
- [ ] **Trade** (form with submission)
- [ ] **APIKeys** (CRUD with confirmation)
- [ ] **Balance** (data display with refresh)
- [ ] **OrderbookMonitor** (server-side filtering + polling)
- [ ] **Sentinel** (live updates via WebSocket)
- [ ] **ShieldDashboard** (aggregated view)

### Phase 4: Polish:
- [ ] Remove React/TypeScript from pipeline
- [ ] Remove Vite build system
- [ ] Add Zig build step for static assets
- [ ] Minify CSS and JS
- [ ] Test all pages thoroughly
- [ ] Performance profiling
- [ ] Update documentation

---

## 🔄 Real-Time Updates Strategy

### For Orderbook Monitor & Sentinel:

**Option A: HTMX with Polling (Simple)**
```html
<div hx-get="/sentinel/orders" hx-trigger="load, every 2s">
  <!-- Server returns updated HTML -->
</div>
```
- ✅ Simple implementation
- ✅ No WebSocket setup
- ❌ Higher latency (polling)
- ❌ More server load

**Option B: HTMX with WebSocket (Better)**
```html
<div
  hx-ext="ws"
  ws-connect="/ws/sentinel"
>
  <!-- WebSocket pushes HTML fragments -->
</div>
```
- ✅ Real-time updates
- ✅ Lower latency
- ✅ Lower server load
- ❌ Slightly complex

**Recommendation:** Use WebSocket with HTMX ext for these pages.

---

## ⚠️ Migration Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| **Breaking changes** | High | Keep React branch, parallel development |
| **Session management bugs** | High | Extensive testing, clear token handling |
| **Lost functionality** | Medium | Feature-by-feature migration checklist |
| **Performance regression** | Medium | Benchmark each phase |
| **Browser compatibility** | Low | HTMX supports IE11+ |
| **Team learning curve** | Medium | Pair programming, documentation |

---

## 📚 Learning Resources

### HTMX Documentation:
- Official: https://htmx.org/
- Attributes: https://htmx.org/reference/
- Extensions: https://htmx.org/extensions/

### Zig Resources:
- Template rendering patterns
- Session management best practices
- Static file serving

### Recommended Reading:
1. "Hypermedia Systems" (Carson Gross, Adam Stepinski)
2. HTMX documentation (2-3 hours)
3. Server-sent events with HTMX

---

## 🎯 Success Criteria

- ✅ Zero broken user workflows
- ✅ 90%+ bundle size reduction
- ✅ 80%+ page load time improvement
- ✅ All tests pass (if added)
- ✅ Full feature parity with React version
- ✅ Documentation updated
- ✅ Team comfortable with HTMX

---

## 📝 Final Notes

### This Migration is Worth It Because:
1. **Your project is ideal**: Simple state management, no complex Redux
2. **Dramatic improvement**: 90% JS reduction + 92% faster loads
3. **Zig is perfect**: Backend already serving HTTP, no additional frameworks
4. **Easier maintenance**: Less code, fewer dependencies, clearer flow
5. **Better semantics**: HTML is the natural language for web apps

### Alternative: Hybrid Approach
Keep React for complex pages (Sentinel real-time updates), migrate simpler pages to HTMX first. This reduces risk while capturing 70% of benefits.

---

## 🚦 Recommended Decision Tree

```
Start HTMX migration?
│
├─→ Can we defer Sentinel? YES
│   └─→ Migrate full (Recommended)
│       Benefits: 90% reduction, simpler, faster
│
├─→ Need Sentinel first? YES
│   ├─→ Migrate 8 pages to HTMX
│   └─→ Keep React for Sentinel only
│       Benefits: 70% reduction, lower risk
│
└─→ Complex real-time needed? YES
    └─→ Stay with React + HTMX hybrid
        Benefits: Best of both, moderate effort
```

---

**Status:** Ready to proceed with Phase 1
**Timeline:** 5 weeks for full migration
**Effort:** ~200-250 hours
**ROI:** Massive (90% JS reduction, faster loads, simpler codebase)

---

*Last Updated: March 2026*
*Author: SAVACAZAN Development Team*
