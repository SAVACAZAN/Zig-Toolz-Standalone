# GitHub Actions CI/CD Setup Guide

This document provides the GitHub Actions CI/CD workflow configurations for the automation infrastructure.

## ⚠️ Setup Note

The workflow files below could not be automatically pushed to GitHub due to PAT (Personal Access Token) limitations. The token being used requires `workflow` scope to create or update GitHub Actions files.

**To enable CI/CD workflows, do ONE of the following:**

### Option 1: Update Your PAT Scope (Recommended)
1. Go to https://github.com/settings/tokens
2. Click on your PAT
3. Check the `workflow` scope
4. Save changes
5. Then you can manually create the workflow files in GitHub or commit them locally

### Option 2: Manually Create Workflows in GitHub
Use GitHub's web interface to create the workflow files with the content provided below.

### Option 3: Use SSH Authentication
GitHub Actions support includes SSH authentication which may not have the same scope restrictions.

---

## Workflow 1: Zig-Toolz-Standalone CI/CD

**Location:** `.github/workflows/ci.yml`

**Purpose:** Validates automation infrastructure on every push/PR

```yaml
name: Automation Infrastructure CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  validate-scripts:
    name: Validate Automation Scripts
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Zig
        uses: mlugg/setup-zig@v1
        with:
          version: 0.15.2

      - name: Validate BASH scripts syntax
        run: |
          echo "Validating BASH scripts..."
          for script in scripts/*.sh; do
            if [ -f "$script" ]; then
              bash -n "$script" || exit 1
              echo "✅ $script - syntax valid"
            fi
          done

      - name: Build all 48 ZIG automation scripts
        run: |
          echo "Building automation scripts..."
          zig build automation

      - name: Verify built executables
        run: |
          echo "Verifying executables..."
          count=$(find zig-cache -type f -executable -name "*" 2>/dev/null | wc -l)
          echo "✅ Built executables: $count"

      - name: Upload build artifacts
        if: success()
        uses: actions/upload-artifact@v4
        with:
          name: automation-scripts
          path: zig-cache/o/*/bin/
          if-no-files-found: ignore

  test-architecture:
    name: Validate Architecture
    runs-on: ubuntu-latest
    needs: validate-scripts

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Verify script count
        run: |
          expected_count=48
          script_count=$(grep -o '"[^"]*",' build.zig | grep -v "^\"default\|^\"automation" | wc -l)
          echo "Expected scripts: $expected_count"
          echo "Found in build.zig: $script_count"

      - name: Verify all script files exist
        run: |
          echo "Verifying all script files..."
          missing=0
          for script in registry-setup npm-publish docker-push github-release package-dist version-publish publish-all init-project setup-ci env-setup install-deps lint-all format-code integration-test smoke-test performance-bench security-scan security-audit dependency-check api-security-test logs-search metrics-collect db-migrate update-deps clean-artifacts changelog-gen code-stats health-report k8s-deploy k8s-rollback k8s-scale helm-upgrade pod-logs k8s-health region-failover geo-health-check replica-sync traffic-split alert-rules-push dashboard-deploy slo-report trace-analyze uptime-monitor terraform-plan infra-drift secret-rotate env-validate config-diff; do
            if [ ! -f "src/automation/$script.zig" ]; then
              echo "❌ Missing: $script.zig"
              ((missing++))
            fi
          done
          if [ $missing -gt 0 ]; then
            exit 1
          fi

  report-status:
    name: Report Status
    runs-on: ubuntu-latest
    needs: [validate-scripts, test-architecture]
    if: always()

    steps:
      - name: Set status
        run: |
          if [ "${{ needs.validate-scripts.result }}" = "success" ] && [ "${{ needs.test-architecture.result }}" = "success" ]; then
            echo "✅ All checks passed!"
            exit 0
          else
            echo "❌ Some checks failed"
            exit 1
          fi
```

---

## Workflow 2: Nightly Architecture Validation

**Location:** `.github/workflows/validate-architecture.yml`

**Purpose:** Runs nightly validation (2 AM UTC) + manual trigger

**Triggers:**
- Schedule: 0 2 * * * (Every night at 2 AM UTC)
- Manual: `workflow_dispatch` (click "Run workflow" on GitHub)

**Checks:**
- Script count validation (48 expected)
- Category verification (10 categories)
- BASH syntax validation
- Documentation presence
- Build status

---

## Workflow 3: Zig-toolz-Assembly CI/CD

**Location:** `.github/workflows/ci.yml` (in Zig-toolz-Assembly)

**Purpose:** Build backend + frontend + verify submodule integration

**Jobs:**
1. `backend-build`: Compile Zig backend + automation suite
2. `frontend-build`: React build + ESLint validation
3. `integration-tests`: Verify Toolz submodule + shared automation
4. `status-check`: Final status aggregation

---

## Workflow 4: Zig-toolz-Assembly-HTMX-Pure CI/CD

**Location:** `.github/workflows/ci.yml` (in HTMX-Pure)

**Purpose:** Build HTMX backend + verify shared automation access

**Jobs:**
1. `backend-build`: Compile HTMX backend + automation
2. `automation-build`: Build 48 scripts from submodule
3. `integration-check`: Verify variant architecture
4. `status-check`: Final status

---

## Manual Setup Instructions

### For Zig-Toolz-Standalone:

1. Create directory: `.github/workflows/`
2. Create file `ci.yml` with content from "Workflow 1" above
3. Create file `validate-architecture.yml` with the nightly validation content
4. Commit and push

### For Zig-toolz-Assembly:

1. Create directory: `.github/workflows/`
2. Create file `ci.yml` with content from "Workflow 3" above
3. Commit and push

### For Zig-toolz-Assembly-HTMX-Pure:

1. Create directory: `.github/workflows/`
2. Create file `ci.yml` with content from "Workflow 4" above
3. Commit and push

---

## Expected Results

Once workflows are enabled:

✅ **On Every Push/PR:**
- Compiles all 48 ZIG scripts
- Validates BASH syntax
- Checks architecture consistency
- Runs integration tests

✅ **Every Night (2 AM UTC):**
- Validates script count
- Verifies categories
- Checks documentation
- Creates issues on failure

✅ **Status Badges:**
Once workflows run successfully, you can add badges to README:
```markdown
![CI Status](https://github.com/SAVACAZAN/Zig-Toolz-Standalone/workflows/Automation%20Infrastructure%20CI/badge.svg)
![Architecture Validation](https://github.com/SAVACAZAN/Zig-Toolz-Standalone/workflows/Nightly%20Architecture%20Validation/badge.svg)
```

---

## Troubleshooting

### PAT Scope Issues
If you see "refusing to allow a Personal Access Token ... without `workflow` scope":
1. Go to GitHub Settings > Developer Settings > Personal Access Tokens
2. Edit your token
3. Check the `workflow` scope (under `repo` section)
4. Save and try again

### Zig Version Mismatch
The workflows use Zig 0.15.2. If you use a different version:
1. Edit the workflow YAML
2. Change `version: 0.15.2` to your version
3. Commit and push

### Missing Dependencies
Make sure your repositories have:
- `build.zig` in root (Standalone) or `backend/` (variants)
- `scripts/*.sh` files (BASH scripts)
- `src/automation/*.zig` files (ZIG scripts)
- `.git/config` with submodule configuration (for variants)

---

## Next Steps

1. ✅ Update your PAT with `workflow` scope
2. ✅ Manually create the workflow files using the YAML above
3. ✅ Push changes to GitHub
4. ✅ Verify workflows appear in GitHub Actions tab
5. ✅ Trigger manually or wait for next push/schedule
6. ✅ Add status badges to README files

---

For questions or issues, refer to:
- GitHub Actions documentation: https://docs.github.com/en/actions
- Zig setup action: https://github.com/mlugg/setup-zig