# Secure-by-Design Checklist for Zig Applications

## End-to-End Security Model (From First Byte to Last Bit)

This document outlines the correct security mindset and vulnerability
model when building an application from scratch using Zig or low-level
systems languages.

------------------------------------------------------------------------

## Architecture Flow (Bit Lifecycle)

CPU → Memory → Compiler → Binary → OS → Process → Input → Parser → Logic
→ Storage → Network → Transport → Client

Each layer introduces specific vulnerabilities.

------------------------------------------------------------------------

# 1. CPU / MEMORY LEVEL

### Vulnerabilities

-   Buffer Overflow
-   Use-After-Free
-   Double Free
-   Integer Overflow
-   Out-of-bounds read/write

### Protections

-   Use `ReleaseSafe` builds
-   Bounds checking
-   Validate allocation sizes
-   Assertions

------------------------------------------------------------------------

# 2. COMPILER / BUILD CHAIN

### Vulnerabilities

-   Supply-chain attacks
-   Malicious dependencies
-   Build script injection
-   Unsafe build flags

### Protections

-   Pin dependency commits
-   Reproducible builds
-   Audit build.zig logic

------------------------------------------------------------------------

# 3. BINARY LEVEL

### Vulnerabilities

-   ROP (Return Oriented Programming)
-   Debug symbol leaks
-   Predictable memory layout

### Protections

-   PIE binaries
-   ASLR compatibility
-   Strip symbols only for final release

------------------------------------------------------------------------

# 4. OS / PROCESS LEVEL

### Vulnerabilities

-   Privilege escalation
-   File descriptor leaks
-   Unsafe temp files

### Protections (systemd sandbox example)

-   NoNewPrivileges=yes
-   PrivateTmp=yes
-   ProtectSystem=strict

------------------------------------------------------------------------

# 5. INPUT LAYER

### Vulnerabilities

-   Injection attacks
-   Oversized payload DoS
-   Encoding attacks

### Rule

Validate → Normalize → Use

------------------------------------------------------------------------

# 6. PARSER LEVEL

### Vulnerabilities

-   Parser confusion
-   Recursive parsing DoS
-   Infinite loops

### Protections

-   Depth limits
-   Token limits
-   Parsing timeouts

------------------------------------------------------------------------

# 7. BUSINESS LOGIC

### Vulnerabilities

-   Logic bypass
-   Replay attacks
-   Race conditions

### Protections

-   Nonce validation
-   Idempotency keys
-   Request locking

------------------------------------------------------------------------

# 8. STORAGE / FILE SYSTEM

### Vulnerabilities

-   Path traversal
-   Symlink attacks
-   Unsafe serialization

### Protections

-   Canonicalize paths
-   Directory sandboxing

------------------------------------------------------------------------

# 9. NETWORK STACK

### Vulnerabilities

-   MITM attacks
-   Request smuggling
-   Slowloris

### Protections

-   Reverse proxy (Caddy/Nginx)
-   Connection timeouts
-   Rate limiting

------------------------------------------------------------------------

# 10. TRANSPORT (TLS)

### Vulnerabilities

-   TLS downgrade
-   Weak cipher usage
-   Certificate spoofing

### Recommendation

Do NOT implement TLS manually. Use a reverse proxy.

------------------------------------------------------------------------

# 11. SESSION / AUTHENTICATION

### Vulnerabilities

-   Session fixation
-   Cookie theft
-   CSRF

### Secure Cookie Settings

-   HttpOnly
-   Secure
-   SameSite=Strict

------------------------------------------------------------------------

# 12. CLIENT SIDE

### Vulnerabilities

-   XSS
-   DOM injection
-   Malicious headers

### Protections

-   Escape HTML output
-   CSP headers

------------------------------------------------------------------------

# 13. OBSERVABILITY

### Required Logs

-   Authentication attempts
-   Rate limit triggers
-   Security events

------------------------------------------------------------------------

# 14. DOS / RESOURCE ATTACKS

### Examples

-   Memory exhaustion
-   CPU bombs
-   Infinite parsing

### Protections

-   Memory caps
-   Request size limits
-   Timeouts

------------------------------------------------------------------------

# 15. DEPLOYMENT HARDENING

### Risks

-   Exposed ports
-   Debug endpoints
-   Environment leaks

### Checklist

-   Run without root
-   Firewall enabled
-   Minimal OS image
-   Automatic updates

------------------------------------------------------------------------

## Correct Implementation Order

1.  Memory safety rules
2.  Input validation layer
3.  Parser limits
4.  Authentication model
5.  Storage sandbox
6.  Network limits
7.  TLS proxy
8.  Logging
9.  Rate limiting
10. Deployment hardening

------------------------------------------------------------------------

## Golden Rule

Every byte received must be treated as attacker-controlled until proven
otherwise.
