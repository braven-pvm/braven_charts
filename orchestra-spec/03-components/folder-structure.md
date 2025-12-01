# Folder Structure

> **Navigation**: [Index](../readme.md) | **Prev**: [ADR-001](../02-architecture/decisions/adr-001-translation-layer.md) | **Next**: [File Specifications](file-specifications.md)

---

## Overview

The `.orchestra/` folder is the self-contained root of all Orchestra artifacts. It's designed for:

- Clear role separation (orchestrator vs implementor)
- Hidden content enforcement (`.role-only/` subfolders)
- Transient handover state (empty at rest)
- Complete audit trail (results archive)
- Transportability (self-contained, works in any project)

## Canonical Structure

```
.orchestra/
│
├── orchestrator/                         # ORCHESTRATOR'S DOMAIN
│   ├── readme.md                         # Orchestrator quickstart guide
│   │
│   ├── .orchestrator-only/               # HIDDEN FROM IMPLEMENTOR
│   │   ├── verification/                 # Verification criteria (hidden)
│   │   │   ├── task-001.yaml             # Criteria for task 1
│   │   │   ├── task-002.yaml             # Criteria for task 2
│   │   │   └── ...
│   │   ├── preflight/                    # Pre-handover checklists
│   │   │   └── task-NNN-preflight.md     # Audit trail of orchestrator checks
│   │   └── templates/                    # Orchestrator-only templates
│   │       └── verification-template.yaml
│   │
│   ├── scripts/                          # Orchestrator's tools
│   │   ├── task-closeout-check.ps1       # Verify previous task closed
│   │   ├── prepare-handover.ps1          # Populate handover from templates
│   │   ├── handover-validate.ps1         # Validate handover completeness
│   │   ├── accept-signal-check.ps1       # Verify implementor's artifact
│   │   └── archive-and-close.ps1         # Copy to results, clear handover
│   │
│   ├── results/                          # COMPLETE AUDIT HISTORY
│   │   ├── task-001/                     # Archived task 1
│   │   │   ├── handover/                 # Exact copy at completion time
│   │   │   │   ├── current-task.md
│   │   │   │   ├── task-context.md
│   │   │   │   └── verification/
│   │   │   │       ├── screenshots/
│   │   │   │       ├── test-output.txt
│   │   │   │       └── completion-signal.md
│   │   │   ├── verification-results.md   # Orchestrator's verification notes
│   │   │   └── metadata.json             # Timestamps, commit hash
│   │   └── task-002/
│   │       └── ...
│   │
│   ├── manifest.yaml                     # Full task list (HIDDEN from implementor)
│   └── progress.yaml                     # Sprint progress tracking (HIDDEN)
│
├── implementor/                          # IMPLEMENTOR'S DOMAIN
│   ├── readme.md                         # Implementor quickstart guide
│   │
│   ├── .implementor-only/                # HIDDEN FROM ORCHESTRATOR
│   │   ├── scripts/
│   │   │   ├── validate-handover.ps1     # Validate orchestrator's handover
│   │   │   └── pre-signal-check.ps1      # Validate own work before signal
│   │   └── task-validator.md             # Validation rules reference
│   │
│   └── artifacts/                        # Implementor's proof of work
│       └── pre-signal/
│           └── task-NNN-YYYY-MM-DD_HHMMSS.txt
│
├── handover/                             # TRANSIENT EXCHANGE ZONE
│   │                                     # Empty at rest (only .gitkeep)
│   │
│   │  When populated by orchestrator:
│   ├── current-task.md                   # Single task to implement
│   ├── task-context.md                   # Sprint/phase context
│   └── verification/                     # For implementor artifacts
│       └── .gitkeep
│   │
│   │  When completed by implementor:
│   └── verification/
│       ├── screenshots/
│       │   └── task-NNN-feature.png
│       ├── test-output.txt
│       └── completion-signal.md
│
├── common/                               # SHARED RESOURCES
│   ├── scripts/
│   │   ├── set-env.ps1                   # Environment variable setup
│   │   └── check-utils.ps1               # Shared PowerShell utilities
│   │
│   └── templates/                        # Document templates
│       ├── current-task.md.template      # Task handover template
│       ├── task-context.md.template      # Context document template
│       ├── completion-signal.md.template # Completion signal template
│       └── verification.yaml.template    # Verification criteria template
│
└── docs/                                 # DOCUMENTATION
    ├── readme.md                         # Main Orchestra documentation
    ├── research_log.md                   # Issue and learning log
    └── solution-options.md               # Design decision documentation
```

## Folder Purposes

### `orchestrator/`

Everything the orchestrator needs to plan, verify, and track progress.

| Subfolder | Purpose | Visibility |
|-----------|---------|------------|
| `.orchestrator-only/verification/` | Hidden verification criteria | Orchestrator only |
| `.orchestrator-only/preflight/` | Orchestrator's self-audit trail | Orchestrator only |
| `scripts/` | Orchestrator's automation tools | Public (but orchestrator runs) |
| `results/` | Complete archive of all completed tasks | Public (after task done) |
| `manifest.yaml` | Full task list with mappings | Orchestrator only |
| `progress.yaml` | Sprint tracking | Orchestrator only |

### `implementor/`

Everything the implementor needs to validate and prove their work.

| Subfolder | Purpose | Visibility |
|-----------|---------|------------|
| `.implementor-only/scripts/` | Validation tools | Implementor only |
| `.implementor-only/task-validator.md` | Validation rules | Implementor only |
| `artifacts/pre-signal/` | Proof that pre-signal check was run | Public (both roles) |

### `handover/`

The transient exchange zone between roles.

| State | Contents | Who Populates |
|-------|----------|---------------|
| At rest | `.gitkeep` only | Nobody |
| Task prepared | `current-task.md`, `task-context.md`, `verification/` | Orchestrator |
| Task complete | Above + screenshots, test-output, completion-signal | Implementor |
| After archive | `.gitkeep` only | Orchestrator clears |

### `common/`

Shared resources both roles can use.

| Subfolder | Purpose |
|-----------|---------|
| `scripts/` | Environment setup, shared utilities |
| `templates/` | Document templates for both roles |

### `docs/`

Documentation and historical records.

| File | Purpose |
|------|---------|
| `readme.md` | Main Orchestra documentation (process, commands) |
| `research_log.md` | Chronological log of issues and learnings |
| `solution-options.md` | Design decision analysis |

## Access Control Matrix

| Resource | Orchestrator | Implementor | Notes |
|----------|-------------|-------------|-------|
| `orchestrator/.orchestrator-only/` | Read/Write | Never | Verification criteria hidden |
| `orchestrator/scripts/` | Read/Write | Can see | Orchestrator's tools |
| `orchestrator/results/` | Read/Write | Read (after task) | Audit trail |
| `orchestrator/manifest.yaml` | Read/Write | Never | Task list hidden |
| `orchestrator/progress.yaml` | Read/Write | Never | Progress hidden |
| `implementor/.implementor-only/` | Should not read | Read/Write | Implementor's private tools |
| `implementor/artifacts/` | Read | Read/Write | Proof artifacts |
| `handover/` | Read/Write | Read/Write | Exchange zone |
| `common/` | Read | Read | Shared utilities |
| `docs/` | Read/Write | Read | Documentation |

## File Lifecycle

### `handover/current-task.md`

**Lifecycle**: VOLATILE

| Event | Action |
|-------|--------|
| Task preparation | Created from template, filled by orchestrator |
| Task completion | Read by implementor, unchanged |
| Task archive | Copied to results, then deleted |

### `handover/verification/completion-signal.md`

**Lifecycle**: TRANSIENT

| Event | Action |
|-------|--------|
| Task preparation | Created from template (empty body) |
| Implementation done | Filled by implementor |
| Verification | Read by orchestrator |
| Task archive | Copied to results, then deleted |

### `handover/task-context.md`

**Lifecycle**: SEMI-STABLE

| Event | Action |
|-------|--------|
| Sprint start | Created with initial context |
| Phase change | Updated with new phase context |
| Same phase | Persists unchanged |
| Sprint end | Archived with final task |

### `orchestrator/results/task-NNN/`

**Lifecycle**: PERMANENT

| Event | Action |
|-------|--------|
| Task archived | Created with full handover copy |
| Later review | Read-only, never modified |
| Sprint complete | Remains for audit trail |

## Environment Variables

Set by `common/scripts/set-env.ps1`:

```powershell
# Core paths
$env:ORCHESTRA_ROOT = ".orchestra"
$env:ORCHESTRATOR_PATH = ".orchestra/orchestrator"
$env:IMPLEMENTOR_PATH = ".orchestra/implementor"
$env:HANDOVER_PATH = ".orchestra/handover"
$env:COMMON_PATH = ".orchestra/common"
$env:DOCS_PATH = ".orchestra/docs"

# Hidden paths
$env:ORCHESTRATOR_HIDDEN = ".orchestra/orchestrator/.orchestrator-only"
$env:IMPLEMENTOR_HIDDEN = ".orchestra/implementor/.implementor-only"

# Derived paths
$env:VERIFICATION_PATH = "$env:ORCHESTRATOR_HIDDEN/verification"
$env:TEMPLATES_PATH = "$env:COMMON_PATH/templates"
$env:RESULTS_PATH = "$env:ORCHESTRATOR_PATH/results"

# Manifest and progress
$env:MANIFEST_PATH = "$env:ORCHESTRATOR_PATH/manifest.yaml"
$env:PROGRESS_PATH = "$env:ORCHESTRATOR_PATH/progress.yaml"
```

## Transportability

To use Orchestra in a new project:

1. Copy entire `.orchestra/` folder
2. Edit `common/scripts/set-env.ps1`:
   - Update `$env:SPRINT_NAME`
   - Update `$env:SPECKIT_ROOT` (if using SpecKit)
   - Update `$env:SPRINT_TEST_PATH`
3. Create new `manifest.yaml` for the sprint
4. Create verification criteria for each task
5. Initialize `progress.yaml`

The folder is self-contained with no external dependencies.
