# Orchestra Scripts System
# ========================

## Overview

This directory contains standardized scripts for orchestrator and implementor agents.
All scripts use hard failures - no soft warnings. If something is wrong, the script fails.

## Environment Setup

Before running any script, source the environment:

```powershell
. .\.orchestra\common\scripts\set-env.ps1
```

This sets:
- `$env:ORCHESTRA_ROOT` - Path to .orchestra
- `$env:SPECKIT_ROOT` - Path to specs/xxx
- `$env:SPRINT_NAME` - Current sprint name
- `$env:CURRENT_TASK` - Current task ID from progress.yaml
- `$env:SPRINT_TEST_PATH` - Path to sprint tests

## Directory Structure

```
common/scripts/
├── set-env.ps1               # Environment setup (run first!)
├── check-utils.ps1           # Shared utilities for all scripts
└── README.md                 # This file

orchestrator/scripts/
├── task-closeout-check.ps1   # Verify previous task is closed out
├── accept-signal-check.ps1   # ⛔ Verify implementor ran pre-signal check
├── task-coverage.ps1         # Check SpecKit ↔ Orchestrator sync
├── verification-audit.ps1    # Audit all verification records
└── handover-validate.ps1     # Validate current-task.md before handoff

implementor/.implementor-only/scripts/
├── validate-handover.ps1     # Implementor reads handover
└── pre-signal-check.ps1      # Implementor pre-completion checks (WRITES ARTIFACT)
```
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
. .\.orchestra\common\scripts\set-env.ps1
.\.orchestra\orchestrator\scripts\task-closeout-check.ps1
```

### `accept-signal-check.ps1` ⛔ CRITICAL

**When:** IMMEDIATELY when implementor says "ready for review" (BEFORE reading verification yaml)
**Purpose:** STRUCTURAL GATE to ensure implementor ran pre-signal-check.ps1
**What:** Verifies the implementor ACTUALLY ran their validation script:
- Artifact file exists: `.orchestra/implementor/artifacts/pre-signal/pre-signal-check-{task}.txt`
- Artifact shows "PASSED" status (not FAILED)
- Artifact is not stale (warning if >24 hours old)

**Why This Exists:**
- Implementors can skip validation scripts
- Without structural enforcement, process drift occurs
- This creates a GATE: no artifact = no verification proceeds

**Workflow Position:**
```
Implementor signals done → accept-signal-check.ps1 → (if PASS) → Read verification YAML
                                   ↓
                             (if FAIL)
                                   ↓
                           BLOCK - Tell implementor to run pre-signal-check.ps1
```

**Consequences:**
- If artifact missing: BLOCKING - verification cannot proceed
- If artifact shows FAILED: BLOCKING - implementor must fix issues first
- If artifact stale: WARNING - proceed with caution

```powershell
. .\.orchestra\common\scripts\set-env.ps1
.\.orchestra\orchestrator\scripts\accept-signal-check.ps1
```

### `task-coverage.ps1`
**When:** During sprint planning or task prep
**What:** Bidirectional SpecKit ↔ Orchestrator verification
- All SpecKit tasks mapped to orchestrator tasks
- All orchestrator task refs exist in SpecKit
- Completion status in sync

```powershell
.\.orchestra\orchestrator\scripts\task-coverage.ps1
```

### `verification-audit.ps1`
**When:** End of sprint or task completion
**What:** Audits all verification records for completeness
- All completed tasks have verification YAMLs
- YAMLs have required sections
- Screenshot content was actually verified

```powershell
# Audit all completed tasks
.\.orchestra\orchestrator\scripts\verification-audit.ps1

# Audit specific task
.\.orchestra\orchestrator\scripts\verification-audit.ps1 -TaskId 10
```

### `handover-validate.ps1`
**When:** After creating current-task.md, before handoff
**What:** Validates handover document is complete
- Has objective, file operations, TDD section
- No TODOs or placeholders
- Matches progress.yaml current task

```powershell
.\.orchestra\orchestrator\scripts\handover-validate.ps1
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
. .\.orchestra\common\scripts\set-env.ps1
.\.orchestra\implementor\.implementor-only\scripts\validate-handover.ps1
```

### `pre-signal-check.ps1`
**When:** MANDATORY - Before signaling completion (Step 5 in agent_readme.md)
**What:** Verifies all deliverables are ready and CREATES VERIFICATION ARTIFACT
- CREATE files exist with content
- UPDATE files were modified
- Tests pass
- No TODOs in code
- Demo exists (if visual task)
- **WRITES ARTIFACT to `.orchestra/implementor/artifacts/pre-signal/`**

**CRITICAL:** This script creates an artifact that the orchestrator's `accept-signal-check.ps1` will look for.
If you skip this script, the orchestrator WILL block your completion signal.

```powershell
.\.orchestra\implementor\.implementor-only\scripts\pre-signal-check.ps1
```

**Artifact Location:** `.orchestra/implementor/artifacts/pre-signal/pre-signal-check-{task}.txt`

**Artifact Contains:**
- Timestamp
- Task number
- PASSED/FAILED status
- Check results summary

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
