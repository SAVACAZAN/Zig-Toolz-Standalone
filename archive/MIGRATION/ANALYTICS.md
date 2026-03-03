# Project Analytics & Technology Stack

Complete breakdown of technologies, dependencies, libraries, and architecture for Zig-toolz-Assembly crypto exchange platform.

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   VITE/REACT FRONTEND                       │
│                   (Port 5173, TypeScript)                   │
├─────────────────────────────────────────────────────────────┤
│  Pages: Dashboard, Trade, Balance, APIKeys, Profile, etc    │
│  State: AuthContext (no Redux/Zustand)                      │
│  HTTP Client: Fetch API + WebSocket                         │
│  Styling: CSS + Glassmorphism Theme                         │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTP/WebSocket
                     │ localhost:8000
                     ↓
┌─────────────────────────────────────────────────────────────┐
│              ZIG BACKEND (Raw Stdlib)                       │
│              (Port 8000, No Framework)                      │
├─────────────────────────────────────────────────────────────┤
│  HTTP Server: std.net (raw TCP/IP)                          │
│  Database: SQLite 3.51 (C FFI)                              │
│  Async: std.Thread (per-connection threads)                 │
│  WebSockets: RFC 6455 implementation                        │
│  JSON: Manual string parsing                                │
│  Exchanges: LCX, Kraken, Coinbase (CCXT-compatible)         │
└─────────────────────────────────────────────────────────────┘
                     │
                     ├→ LCX (WebSocket)
                     ├→ Kraken (REST)
                     ├→ Coinbase (REST)
                     └→ CoinGecko (REST)
```

---

## 📦 BACKEND Stack

### Language & Runtime
- **Zig** v0.14.0+ (compiled to native binary)
  - No runtime, no GC (suitable for low-latency trading)
  - Manual memory management with allocators
  - Compiles to `zig-exchange-server` executable

### Core Libraries (Zig Stdlib Only)
| Module | Purpose | Source |
|--------|---------|--------|
| `std.net` | TCP/IP sockets, HTTP parsing | Zig stdlib |
| `std.Thread` | Per-connection threading | Zig stdlib |
| `std.ArrayList` | Dynamic arrays | Zig stdlib |
| `std.StringHashMap` | Hash maps | Zig stdlib |
| `std.heap.GeneralPurposeAllocator` | Memory allocation | Zig stdlib |
| `std.crypto.hash.Sha256` | HMAC-SHA256 | Zig stdlib |
| `std.crypto.pbkdf2` | Password hashing | Zig stdlib |

### External C Libraries
- **SQLite 3.51.0** (amalgamation)
  - Compiled from source: `sqlite-amalgamation-3510200/sqlite3.c`
  - Linked with: `-DSQLITE_THREADSAFE=1`
  - WAL mode enabled for concurrent read/write
  - Stores: users, orders, api_keys, price_feed tables

### Architecture Modules

#### 1. **HTTP Server** (`src/main.zig`)
```
TCP Listener (127.0.0.1:8000)
  ↓
Accept Loop (fork thread per connection)
  ↓
HTTP Parser (manual header parsing)
  ↓
Route Dispatcher
  ├→ POST /register
  ├→ POST /login
  ├→ GET /health
  ├→ GET /balance
  ├→ GET /orders
  ├→ POST /orders
  ├→ GET /apikeys
  ├→ POST /apikeys
  ├→ GET /public/tickers
  └→ WebSocket upgrade paths
```

#### 2. **Authentication** (`src/auth/`)
- **JWT Module** (`jwt.zig`)
  - Algorithm: HMAC-SHA256
  - Secret: Hardcoded (change before production)
  - Token format: `{header}.{payload}.{signature}`
  - Expiration: Configurable (default 7 days)

- **Password Hashing** (`auth.zig`)
  - Algorithm: PBKDF2-SHA256
  - Iterations: 100,000
  - Salt: Hardcoded (change before production)
  - Hex encoding for storage

#### 3. **Database** (`src/db/`)
- **SQLite Wrapper** (`database.zig`)
  - C FFI bindings to sqlite3
  - Connection pooling: Single global instance
  - Schema: Users, Orders, API Keys, Price Feed
  - Transactions: PRAGMA journal_mode=WAL

- **User Management** (`users.zig`)
  - CRUD operations
  - Email uniqueness validation
  - Password verification with hash comparison

#### 4. **Exchange Integrations** (`src/exchange/`)

**HTTP Client** (`http_client.zig`)
- Raw socket implementation
- Request building: GET/POST with headers
- Response parsing: Status + body extraction
- No external HTTP library

**LCX Exchange** (`lcx.zig`)
- Auth: HMAC-SHA256 signature (timestamp-based)
- Methods:
  - `fetchMarkets()` - Get trading pairs
  - `fetchTicker(pair)` - Single market data
  - `fetchTickers()` - Multiple markets (batch)
  - `fetchOrderBook(pair)` - Depth snapshot
  - `fetchBalance()` - Account balances
  - `createOrder()` - Place buy/sell
  - `cancelOrder()` - Cancel open order
  - `fetchOpenOrders()` - Active orders
  - `fetchClosedOrders()` - Historical orders
  - `fetchMyTrades()` - Executed trades
  - `fetchOHLCV()` - Candlestick data
  - `fetchTrades()` - Recent trades
- Response parsing: Manual JSON extraction

**Kraken Exchange** (`kraken.zig`)
- Auth: HMAC-SHA512 (base64 secret decoding)
- Methods: 12 CCXT-compatible operations
- Key normalization: XXBT→XBT, ZUSD→USD
- Response: Nested JSON with "result" field

**Coinbase Exchange** (`coinbase.zig`)
- Auth: ES256 JWT (EC private key)
- Methods: 12 CCXT-compatible operations
- Account-based balance tracking
- ISO 8601 timestamps

**CoinGecko Integration** (`coingecko.zig`)
- No auth required (public API)
- Endpoint: `/api/v3/simple/price`
- Response: Flat JSON with symbol→prices

#### 5. **WebSocket Layer** (`src/ws/`)

**Core WebSocket** (`ws_client.zig`)
- RFC 6455 frame parsing/generation
- Frame types: Text, Binary, Ping, Pong, Close
- Masking: Client-side masking for outgoing frames
- Connection state machine: CONNECTING → OPEN → CLOSED
- Exponential backoff reconnection (1s, 2s, 4s, 8s...)

**LCX Orderbook WebSocket** (`lcx_orderbook_ws.zig`)
- Endpoint: `wss://exchange-api.lcx.com/ws`
- Message types: Snapshot, Delta, Ping
- State: Per-pair orderbook (bids/asks)
- Calculations: Best bid/ask, spread, midpoint
- Public feed (no auth required)

**LCX Private Orders WebSocket** (`lcx_private_ws.zig`)
- Endpoint: `wss://exchange-api.lcx.com/api/auth/ws`
- Auth: HMAC-SHA256 signature in query params
- Query format: `?x-access-key=...&x-access-sign=...&x-access-timestamp=...`
- State: Open/partial/closed orders
- Subscription: JSON message format for filtering

**LCX Ticker WebSocket** (`lcx_ticker_ws.zig`)
- Endpoint: `wss://exchange-api.lcx.com/subscribeTicker`
- Message types: Snapshot, Update, Ping
- Fields: pair, bid, ask, last, high, low, volume
- State management: Per-ticker last_update timestamp

#### 6. **JSON Parsing** (`src/utils/json.zig`)
- No JSON library (manual string parsing)
- Functions:
  - `getString(allocator, json, key)` - Extract string
  - `getFloat(json, key)` - Parse float
  - `getObject(allocator, json, key)` - Get object
  - `getArray(allocator, json, key)` - Get array
  - `getArrayContent()` - Extract array contents
  - `getNextArrayObject()` - Iterate array elements
- String slicing: Efficient memory usage
- Error handling: Returns null for missing keys

#### 7. **Data Models** (`src/models/models.zig`)
Request/Response structs:
- `RegisterRequest`, `LoginRequest`, `LoginResponse`
- `Order`, `OpenOrder`, `ClosedOrder`
- `Balance`, `Ticker`, `Orderbook`
- `Trade`, `OHLCV`, `Market`
- `ApiKey`, `ExchangeManager` interface

---

## 🎨 FRONTEND Stack

### Language & Environment
- **React 18.2.0** (UI framework)
- **TypeScript 5.3.3** (type safety)
- **React Router v6.20.0** (routing)
- **Vite 5.0.8** (build tool, dev server on port 5173)

### Key NPM Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| react | 18.2.0 | UI framework |
| react-dom | 18.2.0 | React rendering |
| react-router-dom | 6.20.0 | Client-side routing |
| **devDependencies:** | | |
| vite | 5.0.8 | Build + dev server |
| @vitejs/plugin-react | 4.2.1 | React JSX support |
| typescript | 5.3.3 | Type checking |
| @types/react | 18.2.43 | React types |
| @types/react-dom | 18.2.17 | ReactDOM types |
| @types/node | 20.10.0 | Node.js types |


Security Improvements:
Aspect	Before	After
Secrets Storage	Hardcoded in source	Environment variables
Git Safety	🔴 Risk of leaking	✅ Can add to .gitignore
Multi-env Support	❌ No	✅ Yes (dev/prod)
Fallback	N/A	⚠️ Logs warning if not set
Memory Safety	❌ No cleanup	✅ Proper deinit()


### Notable Absence
- ❌ Redux / Zustand (state management)
- ❌ Jest / Vitest (unit testing)
- ❌ ESLint config (linting setup missing, but enforced via package.json)
- ❌ UI component library (hand-written components)

### Directory Structure

```
frontend/src/
├── main.tsx                    # Entry point
├── App.tsx                     # Router root
├── vite-env.d.ts              # Vite types
│
├── context/
│   └── AuthContext.tsx        # Auth state (user, token, login/logout)
│
├── api/
│   ├── exchange.ts            # HTTP client + WebSocket client
│   └── sentinel.ts            # Sentinel-specific API helpers
│
├── layouts/
│   └── AppLayout.tsx          # Sidebar + main layout wrapper
│
├── components/
│   ├── Sidebar.tsx            # Navigation sidebar
│   ├── Navigation.tsx         # Secondary navigation
│   ├── OrderBook.tsx          # Shared orderbook component
│   └── Balance.tsx            # Balance display component
│
├── pages/
│   ├── LoginPage.tsx          # Authentication
│   ├── RegisterPage.tsx       # User signup
│   ├── DashboardPage.tsx      # Overview dashboard
│   ├── MarketsPage.tsx        # Available markets
│   ├── TradePage.tsx          # Trading interface
│   ├── BalancePage.tsx        # Account balances
│   ├── APIKeysPage.tsx        # API key management
│   ├── ProfilePage.tsx        # User profile
│   ├── OrderBookPage.tsx      # Orderbook viewer
│   ├── OrderHistoryPage.tsx   # Order history
│   ├── ChartPage.tsx          # Price charts
│   ├── OrderbookMonitorPage.tsx    # NEW: Arbitrage monitor
│   ├── OrderbookWsPage.tsx        # WebSocket orderbook
│   ├── SentinelPage.tsx           # NEW: Order queue monitor
│   └── ShieldDashboardPage.tsx    # NEW: Unified dashboard
│
├── styles/
│   ├── App.css                # Global theme + glassmorphism
│   ├── OrderbookMonitorPage.css
│   ├── SentinelPage.css
│   └── ShieldDashboard.css
│
└── vite.config.ts             # Vite configuration
```

### State Management

**AuthContext** (`context/AuthContext.tsx`)
```typescript
interface AuthContextType {
  user: User | null;
  token: string | null;
  login(email, password): Promise<void>;
  register(email, password): Promise<void>;
  logout(): void;
}
```
- Stored in `localStorage` (key: "user", "token")
- Persists across page reloads
- No other global state management (Redux, Zustand, etc.)

### API Client

**ExchangeAPI** (`api/exchange.ts`)
- Base URL: `http://127.0.0.1:8000`
- Methods:
  - `register()`, `login()`, `logout()`
  - `getMarkets()`, `getTickers()`, `getBalance()`
  - `getOpenOrders()`, `getClosedOrders()`
  - `createOrder()`, `cancelOrder()`
  - `getApiKeys()`, `saveApiKey()`, `deleteApiKey()`

**ExchangeWebSocket** (`api/exchange.ts`)
- Connects to: `wss://exchange-api.lcx.com/ws`
- Event handlers: onOpen, onMessage, onClose, onError
- Exponential backoff: 1s → 2s → 4s → 8s max
- Auto-resubscribe on reconnect

### Styling Approach

**Glassmorphism Theme**
```css
/* Global */
--bg-dark: #050812 to #0a0e27 (gradient)
--glass: rgba(255, 255, 255, 0.03) + blur(20px)
--shadow: 0 8px 32px rgba(0, 0, 0, 0.3)

/* Colors */
--green (BUY): #10b981
--red (SELL): #ef4444
--cyan (accent): #0ea5e9
--indigo (primary): #6366f1
--amber (secondary): #f59e0b
```

- No Tailwind / Bootstrap
- Inline styles + CSS modules
- Responsive design: CSS media queries
- Dark theme only (no light mode)

### Pages Summary

| Page | Route | Purpose | Features |
|------|-------|---------|----------|
| Login | `/login` | Authentication | Email/password input |
| Register | `/register` | User signup | Email/password registration |
| Dashboard | `/dashboard` | Main overview | Stats, recent trades |
| Markets | `/markets` | Available pairs | List all trading pairs |
| Trade | `/trade` | Buy/sell interface | Order form, live prices |
| Balance | `/balance` | Account assets | Per-exchange balances |
| API Keys | `/apikeys` | Key management | Add/delete API keys |
| Profile | `/profile` | User settings | Email, password, referral |
| Orderbook | `/orderbook` | Depth snapshot | Bids/asks visual |
| Order History | `/order-history` | Trade history | Filled/cancelled orders |
| Charts | `/charts` | Price charts | OHLCV visualization |
| OB Monitor | `/orderbook-monitor` | Arbitrage detector | LCX vs external prices |
| Sentinel | `/sentinel` | Order queue monitor | Queue position, spoof detection |
| Shield | `/shield-dashboard` | Unified monitor | Combined metrics + alerts |

---

## 🔄 Data Flow

### Authentication Flow
```
LoginPage
  ↓ POST /api/login
Backend (main.zig)
  ↓ Check user in SQLite
  ↓ Verify password (PBKDF2)
  ↓ Generate JWT
  ↓ Return token
Frontend
  ↓ Store token in localStorage
  ↓ Set AuthContext.token
  ↓ Redirect to /dashboard
```

### Trading Flow
```
TradePage
  ↓ Select exchange (LCX)
  ↓ GET /api/public/tickers
Backend
  ↓ Fetch from exchange.lcx.zig
  ↓ HTTP request to LCX
  ↓ Parse JSON response
  ↓ Cache in SQLite
  ↓ Return to frontend
Frontend
  ↓ Display tickers
  ↓ User selects pair, amount, price
  ↓ POST /api/orders
Backend
  ↓ Use stored API key from SQLite
  ↓ Sign request (HMAC-SHA256)
  ↓ POST to exchange
  ↓ Verify and store order
Frontend
  ↓ Show confirmation
```

### Orderbook Monitor Flow
```
OrderbookMonitorPage
  ↓ Fetch LCX tickers: GET /api/public/tickers?exchange=lcx
  ↓ Fetch CoinGecko API key: GET /api/apikeys?exchange=coingecko
  ↓ Fetch external prices: CoinGecko REST API
  ↓ Calculate DEV2% = (LCX_mid - external) / external * 100
  ↓ Filter opportunities: |DEV2%| > 0.5%
  ↓ Sort by signal strength
  ↓ Display top 5 BUY/SELL pairs
```

### WebSocket Flow
```
OrderbookMonitorPage / SentinelPage
  ↓ WSClient.connect("wss://exchange-api.lcx.com/ws")
  ↓ TCP connection
  ↓ WebSocket handshake (RFC 6455)
  ↓ Send subscription: {command: "subscribe", channels: ["orderbook|BTC/EUR"]}
  ↓ Receive messages (binary frames)
  ↓ Parse and update local state
  ↓ On disconnect: exponential backoff reconnect
```

---

## 📊 Dependency Analysis

### Root Package.json
```json
{
  "devDependencies": {
    "concurrently": "^8.2.2"  // Run backend + frontend in parallel
  },
  "dependencies": {
    "axios": "^1.13.6"        // Unused (fetch API used instead)
    "crypto-js": "^4.2.0"     // Unused (crypto in backend)
  },
  "scripts": {
    "backend": "cd backend && zig build run",
    "frontend": "cd frontend && npm run dev",
    "start:all": "concurrently \"npm run backend\" \"npm run frontend\""
  }
}
```

### Backend Dependencies
- **Zero external dependencies** (only Zig stdlib + SQLite)
- Total binary size: ~2-3 MB
- Compilation time: ~10-30 seconds
- No dependency updates needed (Zig is stable)

### Frontend Dependencies
- **5 runtime dependencies**
  - react, react-dom: Core UI
  - react-router-dom: Routing
- **6 dev dependencies**
  - vite, typescript: Build tools
  - React types: Type checking
- **Unused packages** (should clean up)
  - axios: Using fetch instead
  - crypto-js: Crypto in backend only
  - concurrently: Root only, not in frontend

---

## 🔐 Security Architecture

### Frontend
- ✅ Token stored in localStorage (XSS risk mitigated by backend)
- ✅ Authorization header on all API calls
- ✅ HTTPS recommended (currently localhost)
- ❌ No CSRF protection (SameSite cookie not used)
- ❌ No rate limiting (should add)

### Backend
- ✅ Password hashing: PBKDF2-SHA256
- ✅ JWT validation: HMAC-SHA256
- ✅ API key storage: Encrypted in SQLite (planned)
- ✅ Exchange credentials: Never exposed to frontend
- ⚠️ Hardcoded secrets (JWT_SECRET, salt) — must change before production
- ⚠️ CORS: Allows all origins (localhost dev only)
- ⚠️ No rate limiting

### Database (SQLite)
- ✅ WAL mode: Concurrent read/write
- ✅ Password hashing: salted PBKDF2
- ❌ No encryption: Database file is plaintext
- ❌ No backup: Single file (add backup strategy)

---

## 🚀 Performance Characteristics

### Backend
- **Memory**: ~50-200 MB (depending on connections)
- **Concurrency**: Per-thread model (OS scheduler handles limits)
- **Throughput**: ~1000-5000 req/sec (estimated, untested)
- **Latency**: <10ms local network
- **Database**: SQLite WAL mode allows concurrent reads

### Frontend
- **Bundle size**: ~300 KB gzipped
- **Load time**: ~2-3 seconds (dev) / <1s (production)
- **Memory**: ~50-100 MB runtime
- **Update latency**: <100ms (local API calls)

---

## 📋 Build & Deploy

### Development
```bash
# Start both servers
npm run start:all

# Or separately:
npm run backend      # Port 8000
npm run frontend     # Port 5173
```

### Production Build
```bash
# Backend (creates zig-exchange-server binary)
cd backend && zig build -Doptimize=ReleaseFast

# Frontend (creates dist/ folder)
cd frontend && npm run build
```

### Testing
```bash
# Backend tests (Zig)
cd backend && zig build test

# Frontend tests
# None configured (ESLint linting only)
```

---

## 🗂️ File Size Breakdown

```
backend/
├── src/             ~50 KB (Zig source)
├── sqlite-*.c       ~800 KB (SQLite source)
└── exchange.db      ~5-50 MB (SQLite database)

frontend/
├── src/             ~200 KB (TypeScript source)
├── dist/            ~300 KB (gzipped build)
└── node_modules/    ~500 MB (dependencies)
```

---

## ✅ Completed Features

### Backend
- ✅ HTTP server (raw Zig stdlib)
- ✅ JWT authentication
- ✅ SQLite persistence
- ✅ Exchange integrations (LCX, Kraken, Coinbase)
- ✅ WebSocket support (RFC 6455)
- ✅ Order management
- ✅ Balance tracking
- ✅ API key management

### Frontend
- ✅ React Router navigation
- ✅ Authentication (login/register)
- ✅ Market data display
- ✅ Trading interface
- ✅ Order management
- ✅ API key management
- ✅ Orderbook Monitor (arbitrage detection)
- ✅ Sentinel (order queue monitor)
- ✅ Shield Dashboard (unified view)

---

## 🚧 Potential Improvements

### Backend
1. Add rate limiting middleware
2. Encrypt sensitive data in SQLite
3. Implement backup strategy
4. Add error logging to file
5. Health check endpoint
6. Database migrations system
7. Metrics collection (Prometheus)

### Frontend
1. Add ESLint configuration (currently missing)
2. Add Jest/Vitest for unit tests
3. Add error boundary component
4. Implement retry logic for failed requests
5. Add loading spinners
6. Add success/error toast notifications
7. Code splitting by route

### DevOps
1. Containerize (Docker)
2. CI/CD pipeline (GitHub Actions)
3. Environment variables (.env)
4. SSL/TLS certificates
5. Reverse proxy (Nginx)
6. Monitoring & alerting

---

## 📚 Reference Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        INTERNET                                 │
├─────────────────────────────────────────────────────────────────┤
│  LCX WebSocket       Kraken REST       CoinGecko REST          │
└────────────┬──────────────┬───────────────────┬─────────────────┘
             │              │                   │
             └──────────────┴───────────────────┘
                            │
             ┌──────────────▼────────────────┐
             │  ZIG BACKEND                  │
             │  (127.0.0.1:8000)             │
             │                               │
             │  ┌─────────────────────────┐  │
             │  │ HTTP/WebSocket Server   │  │
             │  │ (std.net)               │  │
             │  └─────────────┬───────────┘  │
             │                │               │
             │  ┌─────────────▼───────────┐  │
             │  │ Route Dispatcher        │  │
             │  │ /register /login /trade │  │
             │  └─────────────┬───────────┘  │
             │                │               │
             │  ┌─────────────▼───────────┐  │
             │  │ SQLite Database         │  │
             │  │ (users, orders, keys)   │  │
             │  └─────────────────────────┘  │
             │                               │
             └──────────────┬────────────────┘
                            │
                HTTP (Vite Proxy)
                    /api/*
                            │
             ┌──────────────▼────────────────┐
             │  REACT FRONTEND               │
             │  (localhost:5173)             │
             │                               │
             │  ┌─────────────────────────┐  │
             │  │ Pages (12 routes)       │  │
             │  │ Components              │  │
             │  │ AuthContext             │  │
             │  └─────────────────────────┘  │
             │                               │
             └───────────────────────────────┘
```

---

## 📞 Contact & Support

For questions about the architecture, see `/CLAUDE.md` for development guide.

**Last updated:** March 2026
**Author:** SAVACAZAN (Development Team)
