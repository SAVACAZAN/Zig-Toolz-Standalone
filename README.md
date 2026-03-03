# 🛠️ Zig-Toolz-Standalone

**Shared tools, scripts, and utilities for Zig development and applications.**

This is a standalone, reusable toolkit designed to be imported as a Git submodule into multiple Zig-based projects.

---

## 📦 What's Included

### 🔍 **Intelligent Scan Scripts**
- `auto-status.sh` - Master analyzer with feature detection & phase scoring
- `ScanMyApp-dynamic.sh` - Migration status tracker
- `scanAppFull-dynamic.sh` - Complete system analysis

### 📚 **Tools Registry (757+ Tools)**
- `Zig uToolz/tools-registry-full.json` - Complete database with 24 metadata fields
- `Zig uToolz/tools-registry.html` - Interactive web explorer
- `Zig uToolz/lista.md` - English tool inventory
- `Zig uToolz/lista-ro.md` - Romanian translation with detailed descriptions
- `Zig uToolz/REGISTRY_SUMMARY.md` - Complete documentation

### 📖 **Documentation**
- `docs/` - Guides and references
- `archive/` - Historical versions and migrations

---

## 🏗️ Ecosystem Integration

**Zig-Toolz-Standalone** is the shared tools repository in a 3-repository ecosystem:

```
┌─────────────────────────────────────────────────────┐
│           Zig-Toolz-Standalone (THIS REPO)          │
│                                                     │
│  Shared Tools, Scripts & Utilities for all Apps    │
│  - scripts/ (auto-status, ScanMyApp, etc)          │
│  - Zig uToolz/ (1200+ tools registry)              │
│  - docs/ (documentation & guides)                  │
│  - archive/ (reference implementations)            │
└────────────────┬────────────────┬──────────────────┘
                 │                │
        Used by ↓                 ↓ Used by
    ┌──────────────────┐   ┌──────────────────┐
    │ Zig-toolz-       │   │ Zig-toolz-       │
    │ Assembly         │   │ Assembly-HTMX    │
    │ (ORIGINAL)       │   │ (Pure variant)   │
    ├──────────────────┤   ├──────────────────┤
    │ ✅ React + Zig   │   │ ✅ HTMX + Zig    │
    │ ✅ Frontend      │   │ ❌ No Frontend   │
    │ 📊 140+ files    │   │ 📊 50 files      │
    └──────────────────┘   └──────────────────┘
```

### 🔗 Related Repositories

| Repository | Purpose | Size | Type |
|---|---|---|---|
| **Zig-toolz-Assembly** | Original with React UI | 140+ files | Private |
| **Zig-toolz-Assembly-HTMX-Pure** | Lightweight HTMX variant | 50 files | Private |
| **Zig-Toolz-Standalone** | **This repo** - Shared tools | 130+ files | Public |

### 📦 How Applications Use This

Both application variants integrate this repository by:

1. **Including the directory:** `Toolz/` in their project
2. **Running scripts:** `bash Toolz/scripts/auto-status.sh`
3. **Accessing tools:** `grep "tool-name" Toolz/Zig\ uToolz/lista.md`
4. **Referencing docs:** Links from both apps point here

### 🚀 Future Variants

New application variants can reuse this toolkit:

```bash
git clone --recurse-submodules https://github.com/SAVACAZAN/Zig-toolz-Assembly.git MyNewApp

cd MyNewApp
# Toolz is already included! Access all scripts and tools immediately
bash Toolz/scripts/auto-status.sh
```

---

## 🚀 Usage

### As a Git Submodule

```bash
# Add to your Zig application
git submodule add https://github.com/savacazan/Zig-Toolz-Standalone.git Toolz

# Clone with submodules
git clone --recurse-submodules <your-repo-url>

# Update submodule
git submodule update --init --recursive
```

### Using the Scripts

```bash
# Scan application status
bash Toolz/scripts/auto-status.sh

# Detailed migration analysis
bash Toolz/scripts/ScanMyApp-dynamic.sh

# Complete system analysis
bash Toolz/scripts/scanAppFull-dynamic.sh
```

### Tools Registry

```bash
# Run local HTTP server to view registry
cd Toolz/Zig\ uToolz
python3 -m http.server 8000

# Open in browser
# http://localhost:8000/tools-registry.html
```

---

## 📊 Tools Registry Features

✨ **757+ unique tools** organized in 21 categories
✨ **24 metadata fields** per tool (name, rating, purpose, category, language, platform, etc.)
✨ **Interactive HTML UI** with search, filters, and sorting
✨ **Real-time statistics** showing ecosystem overview
✨ **Responsive design** for mobile, tablet, and desktop

### Supported Languages
- Zig (240+ tools)
- Assembly (50+ tools)
- Multi-language tools (510+ tools)

### Categories
Core Zig Tools, Development & IDE, Assembly & Low-Level, System Programming, WebAssembly, Security & Cryptography, Web Development, Async & Concurrency, Testing & Quality, Performance & Profiling, Database & Storage, Networking, Graphics & Media, Machine Learning, Financial Systems, Cryptography & Trading, Advanced Trading, Embedded & IoT, DevOps & Deployment, and more.

---

## 📋 Repository Structure

```
Zig-Toolz-Standalone/
├── scripts/                    # Automation scripts
│   ├── auto-status.sh
│   ├── ScanMyApp-dynamic.sh
│   └── scanAppFull-dynamic.sh
│
├── Zig\ uToolz/               # Tools registry and documentation
│   ├── tools-registry.html
│   ├── tools-registry-full.json
│   ├── lista.md
│   ├── lista-ro.md
│   └── REGISTRY_SUMMARY.md
│
├── docs/                       # Documentation
│   └── *.md
│
├── archive/                    # Historical content
│   └── ...
│
├── .gitignore
└── README.md
```

---

## 🔄 Integration in Projects

### Example 1: Crypto Exchange Application
```bash
git clone --recurse-submodules https://github.com/yourname/Zig-toolz-Assembly.git
cd Zig-toolz-Assembly
bash Toolz/scripts/auto-status.sh
```

### Example 2: HTMX Migration Variant
```bash
git clone --recurse-submodules https://github.com/yourname/Zig-toolz-Assembly-HTMX-Pure.git
cd Zig-toolz-Assembly-HTMX-Pure
bash Toolz/scripts/ScanMyApp-dynamic.sh
```

---

## 📈 Keeping Tools Updated

### When working in an application that uses Toolz:

```bash
# Update Toolz to latest version
git submodule update --remote

# Commit the update
git add Toolz
git commit -m "chore: Update Toolz to latest"
git push origin main
```

### When updating Toolz itself:

```bash
# Make changes in Toolz
cd Toolz
echo "new content" >> scripts/new-script.sh
git add -A
git commit -m "feat: Add new script"
git push origin main

# Return to app and update reference
cd ..
git add Toolz
git commit -m "chore: Update Toolz reference"
git push origin main
```

---

## 🛠️ Features

### Dynamic Analysis Scripts
- Auto-detect project features from actual codebase
- Calculate phase completion percentages
- Scan for security implementations
- Analyze build status
- Provide intelligent recommendations

### Tools Registry
- Search across 757 tools
- Filter by category, language, platform, rating
- Sort by any column
- Real-time statistics
- Direct links to repositories and documentation

---

## 📝 Documentation

- **REGISTRY_SUMMARY.md** - Complete field descriptions and usage examples
- **lista.md** - English inventory of all tools
- **lista-ro.md** - Romanian translation with detailed descriptions
- **docs/** - Additional guides and references

---

## 🔐 License

MIT License - Feel free to use in your projects

---

## 📧 Contributing

Submit issues and pull requests to improve the toolkit.

---

## 🎯 Project Status

✅ **Version 1.0** - Complete tools registry with 757+ tools
✅ **Scripts** - Dynamic analysis and status scanning
✅ **Documentation** - English and Romanian versions
✅ **CI/CD Ready** - Can be imported into any Zig project

---

**Last Updated:** 2026-03-03
**Maintained by:** SAVACAZAN
**Repository:** https://github.com/savacazan/Zig-Toolz-Standalone