# Orchestra Scripts System
# ========================

## Overview

This directory contains standardized scripts for orchestrator and implementor agents.
All scripts use hard failures - no soft warnings. If something is wrong, the script fails.

## Environment Setup

Before running any script, source the environment:

```powershell
. .\.orchestra\scripts\set-env.ps1
```

This sets:
- `$env:ORCHESTRA_ROOT` - Path to .orchestra
- `$env:SPECKIT_ROOT` - Path to specs/xxx
- `$env:SPRINT_NAME` - Current sprint name
- `$env:CURRENT_TASK` - Current task ID from progress.yaml
- `$env:SPRINT_TEST_PATH` - Path to sprint tests

## Directory Structure

```
scripts/
├── set-env.ps1               # Environment setup (run first!)
├── README.md                 # This file
├── common/
│   └── check-utils.ps1       # Shared utilities for all scripts
└── orchestrator/
    ├── task-closeout-check.ps1  # Verify previous task is closed out
    ├── task-coverage.ps1        # Check SpecKit ↔ Orchestrator sync
    ├── verification-audit.ps1   # Audit all verification records
    └── handover-validate.ps1    # Validate current-task.md before handoff

handover/.implementor/scripts/
├── validate-handover.ps1     # Implementor reads handover
└── pre-signal-check.ps1      # Implementor pre-completion checks
```

## Orchestrator Scripts

### `task-closeout-check.ps1`
**When:** AFTER task completion, BEFORE preparing next handover
**Purpose:** Gate check between implementor completion and next task prep
**What:** Verifies the completed task is fully closed out:
- Git status clean (all work committed)
- Previous task marked completed in progress.yaml
- Commit hash recorded
- SpecKit tasks.md updated with completion
- Verification results exist
- Tests still passing

**Workflow Position:**
```
Implementor signals done → Orchestrator verifies → task-closeout-check.ps1 → Prepare next handover
```

```powershell
. .\.orchestra\scripts\set-env.ps1
.\.orchestra\scripts\orchestrator\task-closeout-check.ps1
```

### `task-coverage.ps1`
**When:** During sprint planning or task prep
**What:** Bidirectional SpecKit ↔ Orchestrator verification
- All SpecKit tasks mapped to orchestrator tasks
- All orchestrator task refs exist in SpecKit
- Completion status in sync

```powershell
.\.orchestra\scripts\orchestrator\task-coverage.ps1
```

### `verification-audit.ps1`
**When:** End of sprint or task completion
**What:** Audits all verification records for completeness
- All completed tasks have verification YAMLs
- YAMLs have required sections
- Screenshot content was actually verified

```powershell
# Audit all completed tasks
.\.orchestra\scripts\orchestrator\verification-audit.ps1

# Audit specific task
.\.orchestra\scripts\orchestrator\verification-audit.ps1 -TaskId 10
```

### `handover-validate.ps1`
**When:** After creating current-task.md, before handoff
**What:** Validates handover document is complete
- Has objective, file operations, TDD section
- No TODOs or placeholders
- Matches progress.yaml current task

```powershell
.\.orchestra\scripts\orchestrator\handover-validate.ps1
```

## Implementor Scripts

### `validate-handover.ps1`
**When:** Implementor receives task
**What:** Validates instructions are actionable
- Objective is clear
- File paths are specific
- TDD section exists
- No ambiguity

```powershell
. .\.orchestra\scripts\set-env.ps1
.\.orchestra\handover\.implementor\scripts\validate-handover.ps1
```

### `pre-signal-check.ps1`
**When:** Before signaling completion
**What:** Verifies all deliverables are ready
- CREATE files exist with content
- UPDATE files were modified
- Tests pass
- No TODOs in code
- Demo exists (if visual task)

```powershell
.\.orchestra\handover\.implementor\scripts\pre-signal-check.ps1
```

## Failure Behavior

**All scripts use HARD failures:**
- Exit code 0 = All checks pass
- Exit code 1 = One or more checks failed

Failures include:
1. Check name
2. What went wrong
3. How to fix it
4. Location (file/path)

## Transportability

These scripts are self-contained in `.orchestra/`.
To use in another project:
1. Copy entire `.orchestra/` folder
2. Edit `scripts/set-env.ps1` with new sprint config
3. Create appropriate manifest.yaml and progress.yaml

## Common Utilities

`common/check-utils.ps1` provides:

- `New-CheckCollector` - Create result collector
- `Add-CheckResult` - Add pass/fail to collector
- `Get-CheckSummary` - Get final results
- `Write-CheckPass/Fail/Warning` - Standalone output
- `Write-Section` - Section headers
- `Get-YamlValue` - Parse simple YAML
- `Get-SpeckitTasks` - Parse tasks.md
- `Get-OrchestratorTasks` - Parse manifest.yaml
- `Test-FileHasContent` - Check file exists with content
- `Test-FileModified` - Check git modification
