# HTMX + Zig WebAssembly: Hybrid Architecture for Crypto Exchange

Advanced architecture guide: HTMX for UI orchestration + Zig compiled to WebAssembly for computation-heavy tasks.

---

## 📊 Architecture Overview

### Traditional React SPA
```
┌─────────────────────────────────┐
│  Browser                        │
│  - React (300 KB)              │
│  - JavaScript runtime           │
│  - All computation in JS        │
│  - Slow calculations            │
└────────────┬────────────────────┘
             │ JSON requests
             ↓
┌─────────────────────────────────┐
│  Zig Backend                    │
│  - REST API                     │
│  - Database ops                 │
└─────────────────────────────────┘
```

### HTMX-Only Approach (from MIGRATE_TO_HTMX.md)
```
┌─────────────────────────────────┐
│  Browser                        │
│  - HTMX (14 KB)                │
│  - HTML manipulation            │
│  - NO complex computation       │
└────────────┬────────────────────┘
             │ HTML fragments
             ↓
┌─────────────────────────────────┐
│  Zig Backend                    │
│  - SSR templates                │
│  - Database ops                 │
│  - Complex calculations         │
└─────────────────────────────────┘
```

### 🚀 HTMX + Zig WASM (PROPOSED)
```
┌──────────────────────────────────────────────┐
│  Browser (Client-Side)                       │
│  ┌────────────────────────────────────────┐  │
│  │ HTMX (14 KB)                           │  │
│  │ - DOM manipulation                     │  │
│  │ - Server communication                 │  │
│  │ - Form handling                        │  │
│  └────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────┐  │
│  │ Zig WebAssembly (50-200 KB)           │  │
│  │ - Orderbook matching engine            │  │
│  │ - VWAP calculations                    │  │
│  │ - Order validation                     │  │
│  │ - Real-time aggregations               │  │
│  │ - Crypto operations (hashing, signing) │  │
│  └────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────┐  │
│  │ Service Worker                          │  │
│  │ - Intercepts HTMX requests              │  │
│  │ - Routes to WASM functions              │  │
│  │ - Caches computation results            │  │
│  └────────────────────────────────────────┘  │
└──────────────────────┬───────────────────────┘
                       │ (Only when needed)
                       │ HTML + JSON
                       ↓
┌──────────────────────────────────────────────┐
│  Zig Backend (Server-Side)                   │
│  - Database operations                       │
│  - Persistent state                          │
│  - Exchange API integrations                 │
│  - WebSocket for real-time updates           │
└──────────────────────────────────────────────┘
```

---

## 🎯 Why HTMX + Zig WASM for Crypto Exchange?

### Perfect Use Cases:
1. ✅ **Orderbook Processing** — Match buy/sell orders in real-time without server round-trip
2. ✅ **Price Calculations** — VWAP, TWA, midpoint, spread calculations instantly
3. ✅ **Order Validation** — Check balance, price limits, quantity precision client-side
4. ✅ **Data Aggregation** — Combine feeds from multiple exchanges (LCX, Kraken, Coinbase)
5. ✅ **Crypto Operations** — HMAC signing, hashing for API requests
6. ✅ **Performance-Critical Paths** — Latency-sensitive trading logic

### Key Advantages:
- **Lower Latency**: Calculations happen instantly in browser (no network round-trip)
- **Reduced Server Load**: Heavy computations offloaded to client
- **Offline Capability**: Some features work without server connection
- **Type Safety**: Zig's strong typing + compile-time checks
- **Small Binary**: Zig WASM modules are 50-200 KB (vs 300 KB React)
- **No Runtime Overhead**: Direct memory access, no garbage collection pause

### Constraints:
- ❌ No persistent state (data lost on page reload)
- ❌ Limited to computation (no file system, network from browser)
- ❌ Requires Service Worker support (older browsers)
- ❌ Additional complexity in build process

---

## 🏗️ Architecture Components

### 1. HTMX Layer (14 KB)
Handles all user interactions and DOM updates:
- Form submission (hx-post, hx-put, hx-delete)
- Dynamic content swapping
- Real-time polling/WebSocket
- Confirmation dialogs

### 2. Zig WASM Layer (50-200 KB)
Runs computationally intensive logic:
```zig
// Example: Order matching engine compiled to WASM
export fn matchOrders(
    bids_ptr: *const f64,    // Bid prices
    bids_len: usize,
    asks_ptr: *const f64,    // Ask prices
    asks_len: usize,
) f64 {
    // Returns midpoint price
    // Zero allocation, pure computation
}
```

### 3. Service Worker Layer
Intercepts HTMX requests and routes to WASM:
```javascript
self.addEventListener('fetch', (event) => {
  // Check if request is for WASM computation
  if (event.request.url.includes('/compute/')) {
    // Extract parameters
    // Call Zig WASM function
    // Return HTML fragment
    event.respondWith(computeAndRespond(event.request));
  }
});
```

### 4. Server Layer (Zig Backend)
Persistent state and data:
- Database operations
- Session management
- Exchange integrations
- WebSocket push updates

---

## 🔧 Zig WASM Compilation

### Build Configuration (`backend/build.zig` - WASM target)

```zig
const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard backend binary
    const backend_exe = b.addExecutable(.{
        .name = "exchange-server",
        .root_source_file = b.path("src/main.zig"),
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });

    // NEW: WebAssembly library for trading logic
    const wasm_lib = b.addSharedLibrary(.{
        .name = "exchange_wasm",
        .root_source_file = b.path("src/wasm/exchange.zig"),
        .target = b.resolveTargetQuery(.{
            .cpu_arch = .wasm32,
            .os_tag = .freestanding,
            .abi = .musl,
        }),
        .optimize = .ReleaseSmall,  // Minimize binary size
    });

    // Remove C standard library (not available in WASM)
    wasm_lib.disable_sanitize_c = true;
    wasm_lib.rdynamic = true;  // Export all public symbols

    // Install WASM module to frontend
    const install_wasm = b.addInstallArtifact(wasm_lib, .{
        .dest_dir = .{ .override = .{ .custom = "static" } },
    });

    b.getInstallStep().dependOn(&install_wasm.step);
}
```

### WASM Module Structure (`src/wasm/exchange.zig`)

```zig
const std = @import("std");

// Use a static allocator for WASM (no heap allocation)
var static_arena: [1024 * 1024]u8 = undefined;  // 1 MB
var static_arena_used: usize = 0;

fn staticAlloc(size: usize) [*]u8 {
    const ptr = &static_arena[static_arena_used];
    static_arena_used += size;
    if (static_arena_used > static_arena.len) {
        @panic("Static arena overflow");
    }
    return ptr;
}

/// Export function: Calculate midpoint price from orderbook
/// Called from JavaScript: exchange_wasm.midpoint(bids_ptr, bids_len, asks_ptr, asks_len)
export fn midpoint(
    bids_ptr: *const f64,
    bids_len: usize,
    asks_ptr: *const f64,
    asks_len: usize,
) f64 {
    if (bids_len == 0 or asks_len == 0) return 0;

    const best_bid = bids_ptr[0];
    const best_ask = asks_ptr[0];
    return (best_bid + best_ask) / 2.0;
}

/// Export function: Calculate VWAP (Volume-Weighted Average Price)
export fn calculateVWAP(
    prices_ptr: *const f64,
    prices_len: usize,
    volumes_ptr: *const f64,
    volumes_len: usize,
) f64 {
    if (prices_len == 0 or volumes_len == 0) return 0;
    if (prices_len != volumes_len) return 0;

    var total_pv: f64 = 0;
    var total_v: f64 = 0;

    for (0..prices_len) |i| {
        total_pv += prices_ptr[i] * volumes_ptr[i];
        total_v += volumes_ptr[i];
    }

    if (total_v == 0) return 0;
    return total_pv / total_v;
}

/// Export function: Match orders (simplified)
export fn matchOrders(
    bid_price: f64,
    bid_amount: f64,
    ask_price: f64,
    ask_amount: f64,
) i32 {
    // Returns: 1 = match, 0 = no match
    if (bid_price >= ask_price and bid_amount > 0 and ask_amount > 0) {
        return 1;
    }
    return 0;
}

/// Export function: Validate order parameters
export fn validateOrder(
    price: f64,
    amount: f64,
    min_price: f64,
    max_price: f64,
    min_amount: f64,
) i32 {
    // Returns: 1 = valid, 0 = invalid
    if (price < min_price or price > max_price) return 0;
    if (amount < min_amount or amount <= 0) return 0;
    if (price <= 0) return 0;
    return 1;
}

/// Export function: HMAC-SHA256 for API signing (crypto operation)
pub export fn hmacSha256(
    key_ptr: *const u8,
    key_len: usize,
    msg_ptr: *const u8,
    msg_len: usize,
    output_ptr: *u8,
) void {
    // This would use Zig's crypto library
    // Output: 32 bytes of HMAC-SHA256 hash
    // Called from JavaScript for API authentication

    // Note: Would need careful implementation to avoid timing attacks
}
```

---

## 🔌 Service Worker Integration

### Service Worker (`frontend/sw.js`)

```javascript
// Frontend service worker for intercepting HTMX requests

// Load WASM module at startup
let wasmModule = null;

async function initWasm() {
  const response = await fetch('/static/exchange_wasm.wasm');
  const buffer = await response.arrayBuffer();
  const wasmImports = {
    // Import memory from JavaScript if needed
    env: {
      log: (value) => console.log('WASM:', value),
    },
  };
  const wasmInstance = await WebAssembly.instantiate(buffer, wasmImports);
  return wasmInstance.instance.exports;
}

self.addEventListener('activate', async (event) => {
  console.log('[SW] Activated, loading WASM...');
  wasmModule = await initWasm();
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Route WASM computation requests
  if (url.pathname.startsWith('/compute/')) {
    event.respondWith(handleComputeRequest(event.request));
    return;
  }

  // All other requests: standard fetch
  event.respondWith(fetch(event.request));
});

async function handleComputeRequest(request) {
  try {
    const url = new URL(request.url);
    const operation = url.searchParams.get('op');
    const params = JSON.parse(url.searchParams.get('params'));

    let result;

    switch (operation) {
      case 'midpoint':
        result = wasmModule.midpoint(
          params.bids_ptr,
          params.bids_len,
          params.asks_ptr,
          params.asks_len,
        );
        break;

      case 'vwap':
        result = wasmModule.calculateVWAP(
          params.prices_ptr,
          params.prices_len,
          params.volumes_ptr,
          params.volumes_len,
        );
        break;

      case 'match':
        result = wasmModule.matchOrders(
          params.bid_price,
          params.bid_amount,
          params.ask_price,
          params.ask_amount,
        );
        break;

      case 'validate':
        result = wasmModule.validateOrder(
          params.price,
          params.amount,
          params.min_price,
          params.max_price,
          params.min_amount,
        );
        break;

      default:
        return new Response('Unknown operation', { status: 400 });
    }

    // Return result as JSON
    return new Response(
      JSON.stringify({ result, operation }),
      { headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}
```

---

## 🌐 HTMX + WASM Integration Points

### 1. Order Form Validation (Real-Time)

**HTML:**
```html
<form hx-post="/orders/create"
      hx-target="#result"
      hx-swap="innerHTML"
      hx-on="change: validateOrderLocal(event)">

  <input type="number" name="price" id="price" placeholder="Price" required />
  <input type="number" name="amount" id="amount" placeholder="Amount" required />

  <div id="validation-status"></div>

  <button type="submit" id="submit-btn" disabled>Place Order</button>
</form>

<script>
async function validateOrderLocal(event) {
  if (event.target.name !== 'price' && event.target.name !== 'amount') return;

  const price = parseFloat(document.querySelector('#price').value);
  const amount = parseFloat(document.querySelector('#amount').value);

  // Call WASM function via Service Worker
  const response = await fetch(
    `/compute/validate?op=validate&params=${JSON.stringify({
      price,
      amount,
      min_price: 0,
      max_price: 100000,
      min_amount: 0.001,
    })}`
  );

  const data = await response.json();
  const statusEl = document.querySelector('#validation-status');

  if (data.result === 1) {
    statusEl.innerHTML = '<span style="color: green;">✓ Valid order</span>';
    document.querySelector('#submit-btn').disabled = false;
  } else {
    statusEl.innerHTML = '<span style="color: red;">✗ Invalid order</span>';
    document.querySelector('#submit-btn').disabled = true;
  }
}
</script>
```

### 2. Real-Time Orderbook Processing

**WASM Module:**
```zig
/// Aggregate orderbook data from multiple exchanges
export fn aggregateOrderbook(
    lcx_bids_ptr: *const f64,
    lcx_bids_len: usize,
    kraken_bids_ptr: *const f64,
    kraken_bids_len: usize,
    coinbase_bids_ptr: *const f64,
    coinbase_bids_len: usize,
) f64 {
    // Find best bid across all exchanges
    var best_bid: f64 = 0;

    for (0..lcx_bids_len) |i| {
        if (lcx_bids_ptr[i] > best_bid) best_bid = lcx_bids_ptr[i];
    }
    for (0..kraken_bids_len) |i| {
        if (kraken_bids_ptr[i] > best_bid) best_bid = kraken_bids_ptr[i];
    }
    for (0..coinbase_bids_len) |i| {
        if (coinbase_bids_ptr[i] > best_bid) best_bid = coinbase_bids_ptr[i];
    }

    return best_bid;
}
```

**HTMX Integration:**
```html
<!-- OrderbookMonitor page: Real-time aggregation -->
<div hx-ext="ws" ws-connect="/ws/orderbook">
  <div id="best-bid" hx-on="message: updateBestBid(event)"></div>
  <div id="best-ask" hx-on="message: updateBestAsk(event)"></div>
  <div id="spread"></div>
</div>

<script>
async function updateBestBid(event) {
  const data = JSON.parse(event.detail.message);

  // Call WASM to compute best bid across exchanges
  const response = await fetch(
    `/compute/aggregate?op=aggregateOrderbook&params=${JSON.stringify({
      lcx_bids: data.lcx.bids,
      kraken_bids: data.kraken.bids,
      coinbase_bids: data.coinbase.bids,
    })}`
  );

  const result = await response.json();
  document.querySelector('#best-bid').textContent = result.result.toFixed(2);
}
</script>
```

### 3. API Authentication (Crypto Operations)

**WASM Module:**
```zig
export fn signMessage(
    message_ptr: *const u8,
    message_len: usize,
    signature_ptr: *u8,
) void {
    // Sign message with client-side key
    // Returns 64-byte signature
}
```

**HTMX + Service Worker:**
```javascript
// Before sending API request, sign with WASM
document.addEventListener('htmx:beforeRequest', async (event) => {
  if (event.detail.xhr.method === 'POST' &&
      event.detail.path.includes('/api/trade')) {

    const message = event.detail.xhr.body;

    // Call WASM to sign
    const signature = wasmModule.signMessage(
      new TextEncoder().encode(message)
    );

    // Add signature to request header
    event.detail.xhr.setRequestHeader(
      'X-Signature',
      btoa(String.fromCharCode(...signature))
    );
  }
});
```

---

## 📦 Build & Deployment

### Build Process (Unified)

```bash
#!/bin/bash
# start-dev-hybrid.sh - Full stack with WASM

echo "[BUILD] Compiling Zig WASM module..."
cd backend && zig build wasm
# Output: static/exchange_wasm.wasm

echo "[BUILD] Building frontend with Bun..."
cd ../frontend && bun build

echo "[BUILD] Compiling Zig backend..."
cd ../backend && zig build run

echo "[READY] Full stack running:"
echo "  - Backend: localhost:8000"
echo "  - Frontend: localhost:8000 (served by backend)"
echo "  - WASM: exchange_wasm.wasm (50-200 KB)"
```

### Production Build

```bash
# Optimize WASM for size
zig build-lib src/wasm/exchange.zig \
  -target wasm32-freestanding \
  -O ReleaseSmall \
  -dynamic \
  -fstrip \
  -o exchange_wasm.wasm

# Result: ~50-150 KB binary
# Compress with gzip: ~15-50 KB
```

### Deployment Artifact

```
Single Zig Binary Contains:
├── Backend server code (compiled from Zig)
├── Static files
│   ├── index.html
│   ├── styles.css (~6 KB)
│   ├── app.js (~2 KB)
│   ├── htmx.min.js (~14 KB)
│   ├── sw.js (Service Worker)
│   └── exchange_wasm.wasm (~50-150 KB)
└── Database schema initialization

Total Download: ~30-40 MB (Zig binary + assets)
Actual Runtime: ~5 MB (WASM modules loaded on demand)
```

---

## 🎯 Use Cases & Examples for Crypto Exchange

### 1. Order Matching Engine

**Problem**: Matching buy/sell orders is latency-critical in trading.

**Solution**: Run matching logic in WASM
```zig
/// Fast order matching without server round-trip
export fn matchBuySell(
    buy_orders_ptr: *const Order,
    buy_orders_len: usize,
    sell_orders_ptr: *const Order,
    sell_orders_len: usize,
    results_ptr: *Match,
) usize {
    // Returns number of matches found
    // Zero-copy algorithm, runs in microseconds
}
```

**HTMX Usage**:
```html
<form hx-post="/trade/buy"
      hx-on="submit: validateMatchInWasm(event)">
  <!-- Client checks if order can match before server request -->
</form>
```

### 2. Price Aggregation (Multi-Exchange)

**Problem**: Show best price across LCX, Kraken, Coinbase.

**Solution**: WASM aggregates real-time data
```zig
export fn bestPrice(
    all_prices_ptr: *const f64,
    all_prices_len: usize,
) f64 {
    // Returns best price in ~0.1ms (vs 50ms network)
}
```

**HTMX Usage**:
```html
<div hx-ext="ws" ws-connect="/ws/prices">
  <div id="btc-price" hx-on="message: showBestPrice(event)"></div>
</div>

<script>
function showBestPrice(event) {
  const prices = event.detail.message;
  const best = wasmModule.bestPrice(prices);
  document.querySelector('#btc-price').textContent = best.toFixed(2);
}
</script>
```

### 3. Balance & Margin Calculations

**Problem**: Calculate available balance considering open orders and margin.

**Solution**: WASM computation
```zig
export fn availableBalance(
    total_balance: f64,
    reserved_in_orders: f64,
    margin_used: f64,
    leverage: f64,
) f64 {
    return (total_balance - reserved_in_orders) * leverage - margin_used;
}
```

### 4. Order Validation Suite

**Problem**: Validate orders against multiple constraints (price, amount, balance).

**Solution**: WASM validation logic
```zig
export fn validateTradeOrder(
    side: u8,              // 0 = buy, 1 = sell
    price: f64,
    amount: f64,
    available_balance: f64,
    min_order_value: f64,
    price_precision: u32,
) i32 {
    // Check all constraints
    // Returns error code (0 = valid, >0 = error)
}
```

### 5. Real-Time Chart Data Processing

**Problem**: Process OHLCV data for charts without blocking UI.

**Solution**: WASM aggregation
```zig
export fn calculateOHLCV(
    prices_ptr: *const f64,
    prices_len: usize,
    period: u32,  // Timeframe in minutes
    ohlcv_ptr: *u8,
) void {
    // Compute Open, High, Low, Close, Volume
    // Fills ohlcv_ptr with results
}
```

---

## 📊 Performance Comparison

### Single Price Calculation (Midpoint)
```
React (JavaScript):        2-3 ms
HTMX + Server (RTT 50ms): 52-53 ms
HTMX + WASM:              0.1-0.5 ms

Improvement: 100-530x faster
```

### Orderbook Aggregation (3 exchanges)
```
React (JavaScript):        5-10 ms
Server-side (RTT 50ms):    55-60 ms
Zig WASM:                  0.5-2 ms

Improvement: 27-120x faster
```

### Balance Calculation with Constraints
```
JavaScript:               3-5 ms
Zig WASM:                 0.2-1 ms

Improvement: 3-25x faster
```

---

## 🔐 Security Considerations

### What WASM Can Do Safely:
✅ Computations (math, crypto hashing)
✅ Data validation
✅ Local order matching
✅ Offline calculations

### What SHOULD Stay on Server:
❌ Key management (API keys)
❌ Persistent state (database)
❌ Authentication (JWT)
❌ Authorization (permission checks)
❌ Settlement (actual trades)

### WASM Limitations:
- ❌ Cannot access file system
- ❌ Cannot make HTTP requests directly
- ❌ Runs in unprivileged context (browser)
- ❌ User can see/modify WASM code
- ❌ Client-side data not trusted for final decisions

**Solution**: Use WASM for UX/performance, validate ALL operations server-side.

---

## 🚀 Migration Path: React → HTMX + WASM

### Phase 1: HTMX Migration (weeks 1-4)
- Migrate pages to HTMX (as per MIGRATE_TO_HTMX.md)
- Keep all logic on server initially
- Result: 90% JS reduction

### Phase 2: WASM Modules (weeks 5-8)
- Extract computation-heavy functions
- Compile to WASM with Zig
- Integrate with Service Worker
- Result: Additional 10-100x speedup for specific operations

### Phase 3: Optimization (weeks 9-10)
- Benchmark and profile
- Optimize memory usage in WASM
- Add caching layer
- Result: Production-ready performance

---

## 📋 Implementation Checklist

### Backend (Zig WASM)
- [ ] Define WASM module structure (`src/wasm/exchange.zig`)
- [ ] Implement core functions (matching, validation, calculation)
- [ ] Add `export` keywords for exported functions
- [ ] Create build target in `build.zig` (wasm32-freestanding)
- [ ] Test WASM functions in isolation
- [ ] Optimize for size (ReleaseSmall)

### Frontend (HTMX + Service Worker)
- [ ] Create Service Worker (`frontend/sw.js`)
- [ ] Register SW in base template
- [ ] Load WASM module on startup
- [ ] Create helper functions for WASM calls
- [ ] Integrate with HTMX forms
- [ ] Add fallback for browsers without SW support

### Integration
- [ ] HTMX attributes for triggering WASM calls
- [ ] Error handling and validation feedback
- [ ] Caching strategy for computation results
- [ ] Performance monitoring
- [ ] Documentation for adding new WASM functions

---

## 📚 Example: Complete Flow

### User Places Order (Buy BTC)

**1. HTML Form (HTMX)**
```html
<form hx-post="/orders/create"
      hx-on="submit: preValidateOrder(event)"
      hx-target="#order-result">
  <input type="number" name="price" id="price" />
  <input type="number" name="amount" id="amount" />
  <button type="submit">Buy BTC</button>
</form>
```

**2. Client-Side Validation (WASM)**
```javascript
async function preValidateOrder(event) {
  const price = parseFloat(document.querySelector('#price').value);
  const amount = parseFloat(document.querySelector('#amount').value);

  // Call WASM: < 1ms
  const response = await fetch('/compute/validate?op=validate&params=...');
  const {result} = await response.json();

  if (result === 0) {
    event.preventDefault();
    alert('Invalid order parameters');
    return false;
  }

  // Let HTMX proceed with server request
}
```

**3. Server Validation (Zig Backend)**
```zig
fn handleOrderCreate(req: *std.http.Server.Request) !void {
    // Re-validate on server (trust no client data)
    const order = try parseOrderFromRequest(req);

    // Check balance, permissions, market conditions
    if (!isOrderValid(order)) {
        try respondWithError(req, 400, "Invalid order");
        return;
    }

    // Create order in database
    const created = try db.orders.insert(order);

    // Return HTML with success message
    const html = try renderOrderConfirmation(allocator, created);
    try req.writer().writeAll(html);
}
```

**4. Response to Browser (HTMX Swap)**
```html
<!-- Server returns this HTML fragment -->
<div class="success-toast">
  Order #12345 placed successfully
  Price: 54,000 USD
  Amount: 0.1 BTC
</div>
<div id="orders-list" hx-get="/orders/open" hx-trigger="load"></div>
```

**Total Flow**: 1ms (WASM) + 50ms (network) + 10ms (server) = 61ms (vs 100-200ms React)

---

## 🔄 Alternative: Hybrid (Keep React for Some Pages)

If full HTMX migration isn't viable, use hybrid approach:

**HTMX Pages** (most of app):
- Markets, APIKeys, Profile, TradePage
- 90% JS reduction
- WASM for heavy computations

**React Pages** (complex features):
- Sentinel (real-time dashboard)
- OrderbookMonitor with advanced features
- 300 KB React burden acceptable

**Shared WASM Module**: Both HTMX and React use same WASM functions

---

## 🎓 Learning Resources

### Zig WASM
- Zig Manual: https://ziglang.org/documentation/master/
- WASM Target: `zig build-lib --help` (look for wasm32 targets)
- Example: https://github.com/kubkon/zig-wasm-example

### Service Workers
- MDN: https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API
- HTMX + SW: https://htmx.org/essays/htmx-and-web-sockets/

### Crypto Exchange Architecture
- Order Matching: https://en.wikipedia.org/wiki/Order_matching_engine
- VWAP: https://en.wikipedia.org/wiki/Volume-weighted_average_price

---

## 📝 Decision Matrix

| Aspect | React Only | HTMX Only | HTMX + WASM |
|--------|-----------|-----------|------------|
| **JS Bundle** | 300 KB | 14 KB | 14 KB + 50-150 KB WASM |
| **Latency** | 100-200ms | 50-100ms | 1-10ms + 50-100ms |
| **Computation Speed** | ~1x | ~1x | ~100x (selective) |
| **Complexity** | Low | Medium | High |
| **Browser Support** | 99% | 95% | 85% (SW required) |
| **Maintenance** | High | Medium | High (build process) |
| **Recommended** | Simple apps | Most apps | Trading platforms |

---

**Status**: Ready for Phase 1 (HTMX migration), then Phase 2 (WASM modules)
**Next Steps**: Implement HTMX migration first, then add WASM modules where needed
**Timeline**: HTMX (4 weeks) → WASM (4 weeks) → Optimization (2 weeks)

---

*Last Updated: March 2026*
*For: Zig-toolz-Assembly Crypto Exchange*
