# Phase 1: CLI Tool

> **Navigation**: [Implementation Index](../readme.md) | **Next**: [Phase 2: MCP Server](../phase-2-mcp/readme.md)

---

## Overview

The Orchestra CLI is a command-line tool that automates orchestrator operations. It replaces manual file editing, verification running, and progress tracking with scriptable commands.

**Language**: TypeScript (Node.js) - shared codebase with VS Code extension

## Goals

1. **Eliminate manual translation** - Auto-generate handover from templates
2. **Automate verification** - Run all checks with single command
3. **Track progress reliably** - Update YAML files consistently
4. **Enable scripting** - All operations are non-interactive and composable
5. **Build reusable core** - `src/core/` used by CLI, MCP, and extension

## Success Criteria

- [ ] All 5 commands implemented and tested
- [ ] Works on Windows (PowerShell) and Unix (bash)
- [ ] Exit codes for scripting (0=success, 1=failure)
- [ ] Structured output (JSON option for parsing)
- [ ] Idempotent operations (safe to retry)
- [ ] `src/core/` has no CLI dependencies (reusable)

## Commands

| Command | Purpose | Document |
|---------|---------|----------|
| `orchestra init` | Initialize sprint from spec | [init.md](commands/init.md) |
| `orchestra prepare` | Prepare task handover | [prepare.md](commands/prepare.md) |
| `orchestra verify` | Run verification checks | [verify.md](commands/verify.md) |
| `orchestra complete` | Complete task, advance | [complete.md](commands/complete.md) |
| `orchestra status` | Show current state | [status.md](commands/status.md) |

## Architecture

```
tools/orchestra/
├── package.json              # Dependencies, scripts, bin
├── tsconfig.json             # TypeScript configuration
├── README.md                 # User documentation
│
├── src/
│   ├── cli.ts                # CLI entry point (commander.js)
│   │
│   ├── commands/             # CLI command implementations
│   │   ├── init.ts           # orchestra init
│   │   ├── prepare.ts        # orchestra prepare
│   │   ├── verify.ts         # orchestra verify
│   │   ├── complete.ts       # orchestra complete
│   │   └── status.ts         # orchestra status
│   │
│   └── core/                 # REUSABLE SERVICES (no CLI deps!)
│       ├── index.ts          # Public API exports
│       ├── types.ts          # TypeScript interfaces
│       ├── config.ts         # Load .orchestra config
│       ├── manifest.ts       # Manifest operations
│       ├── progress.ts       # Progress tracking
│       ├── verification.ts   # Verification engine
│       ├── templates.ts      # Template rendering
│       ├── git.ts            # Git operations
│       └── output.ts         # Structured results
│
├── templates/                # Task type templates
│   ├── infrastructure.md.hbs
│   ├── integration.md.hbs
│   └── visual.md.hbs
│
└── tests/                    # Test suite
    ├── core/                 # Core library tests
    └── commands/             # CLI command tests
```

**Key Design**: `src/core/` has ZERO CLI dependencies. It exports pure functions and classes that can be imported by:
- CLI commands (`src/commands/`)
- MCP server (Phase 2)
- VS Code extension (Phase 3)

## Tasks

| ID | Task | Status | Document |
|----|------|--------|----------|
| 1.1 | Project setup (package.json, tsconfig, vitest) | Not Started | [tasks/1.1-project-setup.md](tasks/1.1-project-setup.md) |
| 1.2 | Core libraries (types, config, manifest, progress) | Not Started | [tasks/1.2-core-libraries.md](tasks/1.2-core-libraries.md) |
| 1.3 | `orchestra status` command | Not Started | [tasks/1.3-status-command.md](tasks/1.3-status-command.md) |
| 1.4 | `orchestra init` command | Not Started | [tasks/1.4-init-command.md](tasks/1.4-init-command.md) |
| 1.5 | `orchestra prepare` command | Not Started | [tasks/1.5-prepare-command.md](tasks/1.5-prepare-command.md) |
| 1.6 | `orchestra verify` command | Not Started | [tasks/1.6-verify-command.md](tasks/1.6-verify-command.md) |
| 1.7 | `orchestra complete` command | Not Started | [tasks/1.7-complete-command.md](tasks/1.7-complete-command.md) |
| 1.8 | Integration testing (E2E workflow tests) | Not Started | [tasks/1.8-integration-testing.md](tasks/1.8-integration-testing.md) |
| 1.9 | Documentation (README, guides, reference) | Not Started | [tasks/1.9-documentation.md](tasks/1.9-documentation.md) |

## Dependencies

### npm Packages

```json
{
  "dependencies": {
    "commander": "^12.0.0",        // CLI framework
    "js-yaml": "^4.1.0",           // YAML parsing
    "handlebars": "^4.7.8",        // Template rendering
    "chalk": "^5.3.0",             // Colored output
    "simple-git": "^3.22.0",       // Git operations
    "zod": "^3.22.0"               // Schema validation
  },
  "devDependencies": {
    "typescript": "^5.3.0",
    "tsx": "^4.7.0",               // Run TS directly
    "vitest": "^1.2.0",            // Testing
    "@types/node": "^20.0.0"
  }
}
```

### External Requirements

- Node.js 20+
- Git (for git operations)
- Flutter (for verification checks)

## Configuration

The CLI reads configuration from `.orchestra/config.yaml`:

```yaml
# .orchestra/config.yaml
orchestra:
  version: "1.0"
  
  paths:
    manifest: "orchestrator/.orchestrator-only/manifest.yaml"
    progress: "orchestrator/.orchestrator-only/progress.yaml"
    verification: "orchestrator/.orchestrator-only/verification"
    handover: "handover"
    templates: "common/templates"
    
  verification:
    flutter_analyze: true
    flutter_test: true
    file_checks: true
    
  git:
    auto_commit: false
    commit_prefix: "orchestra"
```

## Output Formats

All commands support two output formats:

### Human-Readable (default)

```
$ orchestra status

Orchestra Status
────────────────────────────────────
Sprint: 011-multi-axis-normalization
Current Task: 16 of 16
Phase: Visual (4/4)

Task 16: Multi-axis demo verification
Status: in_progress
Attempts: 1
Started: 2025-12-01 10:30:00
```

### JSON (--json flag)

```json
$ orchestra status --json
{
  "sprint": "011-multi-axis-normalization",
  "current_task": 16,
  "total_tasks": 16,
  "phase": { "name": "Visual", "current": 4, "total": 4 },
  "task": {
    "id": 16,
    "title": "Multi-axis demo verification",
    "status": "in_progress",
    "attempts": 1,
    "started_at": "2025-12-01T10:30:00Z"
  }
}
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Configuration error |
| 3 | Verification failed |
| 4 | Git error |

## Installation

```bash
# From tools/orchestra directory
npm install

# Build
npm run build

# Link globally (optional)
npm link

# Verify installation
orchestra --version

# Or run directly without global install
npx orchestra --version
# Or with tsx for development
npx tsx src/cli.ts --version
```

## Usage Examples

```bash
# Initialize sprint from spec
orchestra init --spec specs/012-feature/spec.md

# Check current status
orchestra status

# Prepare next task
orchestra prepare --task 1

# Run verification
orchestra verify
# Returns exit code 0 if all checks pass

# Complete task and advance
orchestra complete --message "feat: add YAxisConfig"

# Full workflow
orchestra init --spec specs/012/spec.md
for task in $(seq 1 16); do
    orchestra prepare --task $task
    # ... implementor does work ...
    orchestra verify && orchestra complete --message "Task $task complete"
done
```

## Core Library API

The `src/core/` module exports a clean API for reuse:

```typescript
// Importable by MCP server, VS Code extension, etc.
import {
  // Types
  Manifest,
  Progress,
  Task,
  VerificationResult,
  
  // Services
  loadConfig,
  loadManifest,
  loadProgress,
  updateProgress,
  runVerification,
  prepareHandover,
  renderTemplate,
  
  // Git
  commitChanges,
  getGitStatus
} from '@orchestra/core';
```

## Detailed Documentation

- [Commands](commands/) - Detailed command specifications
- [Tasks](tasks/) - Implementation task breakdown
