# Script Inventory

> **Navigation**: [Index](../readme.md) | **Prev**: [File Specifications](file-specifications.md) | **Next**: [Templates](templates.md)

---

## Overview

Orchestra uses PowerShell scripts to enforce process and create structural gates. Scripts are organized by role.

## Environment Setup

### set-env.ps1

**Location**: `common/scripts/set-env.ps1`  
**Actor**: Both roles (run first in any session)  
**Purpose**: Set environment variables for all other scripts

**Usage**:
```powershell
. .orchestra/common/scripts/set-env.ps1
```

**Variables Set**:
| Variable | Example Value | Purpose |
|----------|---------------|---------|
| `ORCHESTRA_ROOT` | `.orchestra` | Root path |
| `ORCHESTRATOR_PATH` | `.orchestra/orchestrator` | Orchestrator domain |
| `IMPLEMENTOR_PATH` | `.orchestra/implementor` | Implementor domain |
| `HANDOVER_PATH` | `.orchestra/handover` | Exchange zone |
| `MANIFEST_PATH` | `.orchestra/orchestrator/manifest.yaml` | Task list |
| `PROGRESS_PATH` | `.orchestra/orchestrator/progress.yaml` | Progress tracking |
| `CURRENT_TASK` | `10` | Current task number |
| `SPRINT_TEST_PATH` | `test/unit/multi_axis/` | Sprint test location |

### check-utils.ps1

**Location**: `common/scripts/check-utils.ps1`  
**Actor**: Both roles (utility library)  
**Purpose**: Shared PowerShell functions for all scripts

**Functions Provided**:
| Function | Purpose |
|----------|---------|
| `Write-Check` | Format check result output |
| `Write-Pass` | Write green PASS message |
| `Write-Fail` | Write red FAIL message |
| `Get-YamlValue` | Parse simple YAML values |
| `Test-FileContains` | Check if file contains string |
| `Get-GitStatus` | Get current git state |

## Orchestrator Scripts

### task-closeout-check.ps1

**Location**: `orchestrator/scripts/task-closeout-check.ps1`  
**Actor**: Orchestrator  
**Purpose**: Verify previous task is fully closed before preparing next  
**When to Run**: MANDATORY before preparing any new task

**Usage**:
```powershell
.orchestra/orchestrator/scripts/task-closeout-check.ps1
.orchestra/orchestrator/scripts/task-closeout-check.ps1 -TaskToVerify 10
```

**Checks**:
- [x] Git status is clean (no uncommitted changes)
- [x] On correct branch
- [x] Previous task marked completed in progress.yaml
- [x] Previous task has commit hash
- [x] SpecKit tasks marked (if applicable)
- [x] Verification results recorded
- [x] Screenshot exists (if visual task)
- [x] Sprint tests still pass
- [x] completion-signal.md is clear

**Exit Codes**:
- `0`: All checks pass, proceed with next task
- `1`: One or more checks failed, cannot proceed

### prepare-handover.ps1

**Location**: `orchestrator/scripts/prepare-handover.ps1`  
**Actor**: Orchestrator  
**Purpose**: Clear handover folder and populate from templates

**Usage**:
```powershell
.orchestra/orchestrator/scripts/prepare-handover.ps1 -TaskNumber 11
```

**Actions**:
1. Delete all files in `handover/` except `.gitkeep`
2. Create folder structure: `handover/verification/screenshots/`
3. Copy templates:
   - `current-task.md.template` → `current-task.md`
   - `task-context.md.template` → `task-context.md`
4. Create empty `verification/.gitkeep`

### handover-validate.ps1

**Location**: `orchestrator/scripts/handover-validate.ps1`  
**Actor**: Orchestrator  
**Purpose**: Validate handover document is complete before invoking implementor

**Usage**:
```powershell
.orchestra/orchestrator/scripts/handover-validate.ps1
```

**Checks**:
- [x] `current-task.md` exists
- [x] All required sections present
- [x] No `[TODO]` or `[TBD]` markers
- [x] Task category specified (INFRASTRUCTURE/INTEGRATION/VISUAL)
- [x] File paths are unambiguous
- [x] TDD section complete (for TDD tasks)
- [x] Visual section has demo path (for INTEGRATION/VISUAL)
- [x] Matches current task in progress.yaml

**Exit Codes**:
- `0`: Handover is complete
- `1`: Handover has issues

### accept-signal-check.ps1

**Location**: `orchestrator/scripts/accept-signal-check.ps1`  
**Actor**: Orchestrator  
**Purpose**: Verify implementor ran pre-signal check before accepting completion

**Usage**:
```powershell
.orchestra/orchestrator/scripts/accept-signal-check.ps1 -TaskNumber 10
```

**Checks**:
- [x] Pre-signal artifact exists for task
- [x] Artifact shows "PASSED" (not "FAILED")
- [x] Artifact is recent (not stale from previous attempt)

**Exit Codes**:
- `0`: Artifact valid, proceed with verification
- `1`: No artifact or failed artifact - cannot proceed

### archive-and-close.ps1

**Location**: `orchestrator/scripts/archive-and-close.ps1`  
**Actor**: Orchestrator  
**Purpose**: Archive completed task and clear handover for next task

**Usage**:
```powershell
.orchestra/orchestrator/scripts/archive-and-close.ps1 -TaskNumber 10
```

**Actions**:
1. Create `results/task-NNN/`
2. Copy entire `handover/` to archive
3. Create `metadata.json` with timestamps and commit
4. Create/update `verification-results.md`
5. Delete all files in `handover/`
6. Create `handover/.gitkeep`
7. Update progress.yaml

### task-coverage.ps1

**Location**: `orchestrator/scripts/task-coverage.ps1`  
**Actor**: Orchestrator  
**Purpose**: Bidirectional sync check between SpecKit and Orchestra tasks

**Usage**:
```powershell
.orchestra/orchestrator/scripts/task-coverage.ps1
```

**Checks**:
- [x] All SpecKit tasks mapped to orchestrator tasks
- [x] All orchestrator task mappings exist in SpecKit
- [x] Completion status synchronized

## Implementor Scripts

### validate-handover.ps1

**Location**: `implementor/.implementor-only/scripts/validate-handover.ps1`  
**Actor**: Implementor  
**Purpose**: Validate orchestrator's handover before starting work

**Usage**:
```powershell
.orchestra/implementor/.implementor-only/scripts/validate-handover.ps1
```

**Checks**:
- [x] `current-task.md` exists
- [x] Objective is clear and specific
- [x] Deliverables section has content
- [x] File paths are unambiguous
- [x] No `[TODO]` or `[TBD]` placeholders
- [x] Task category specified
- [x] TDD section complete (if not N/A)
- [x] Quality gates section has commands

**Exit Codes**:
- `0`: Handover is valid, proceed with implementation
- `1`: Handover has defects, report to orchestrator

**On Failure**: Implementor should NOT proceed. Write defects to completion-signal.md and report.

### pre-signal-check.ps1

**Location**: `implementor/.implementor-only/scripts/pre-signal-check.ps1`  
**Actor**: Implementor  
**Purpose**: Validate own work before signaling completion

**Usage**:
```powershell
.orchestra/implementor/.implementor-only/scripts/pre-signal-check.ps1 -TaskNumber 10
```

**Checks**:
- [x] All CREATE files exist with content
- [x] All UPDATE files were modified (git diff)
- [x] Tests pass
- [x] Static analysis clean
- [x] No TODO markers in created code
- [x] Demo exists (if INTEGRATION/VISUAL task)
- [x] Screenshot exists (if visual task)

**Artifact Created**: `implementor/artifacts/pre-signal/task-NNN-YYYY-MM-DD_HHMMSS.txt`

**Exit Codes**:
- `0`: All checks pass, artifact shows "PASSED"
- `1`: One or more checks failed, artifact shows "FAILED"

**Critical**: Even on failure, artifact is created. Orchestrator's `accept-signal-check.ps1` will verify artifact status.

## Script Execution Order

### Complete Task Workflow

```
SESSION START
│
├── . .orchestra/common/scripts/set-env.ps1
│
ORCHESTRATOR: PREPARE TASK
│
├── .orchestra/orchestrator/scripts/task-closeout-check.ps1
│   └── (verify previous task closed)
│
├── .orchestra/orchestrator/scripts/prepare-handover.ps1 -TaskNumber N
│   └── (populate handover from templates)
│
├── [Fill current-task.md manually]
│
├── .orchestra/orchestrator/scripts/handover-validate.ps1
│   └── (verify handover complete)
│
└── [Invoke implementor]

IMPLEMENTOR: IMPLEMENT TASK
│
├── .orchestra/implementor/.implementor-only/scripts/validate-handover.ps1
│   └── (verify orchestrator's work)
│
├── [Implement task]
│
├── .orchestra/implementor/.implementor-only/scripts/pre-signal-check.ps1 -TaskNumber N
│   └── (creates artifact proving checks ran)
│
├── [Fill completion-signal.md]
│
└── "Ready for review"

ORCHESTRATOR: VERIFY TASK
│
├── .orchestra/orchestrator/scripts/accept-signal-check.ps1 -TaskNumber N
│   └── (verify artifact exists and passed)
│
├── [Execute verification checks from hidden criteria]
│
├── IF PASS:
│   └── .orchestra/orchestrator/scripts/archive-and-close.ps1 -TaskNumber N
│
└── IF FAIL:
    └── [Write feedback, implementor retries]
```

## Script Design Principles

### 1. All Hard Failures

No soft warnings. Every check is either PASS or FAIL, and FAIL means exit code 1.

```powershell
# BAD: Warning that can be ignored
Write-Warning "Task might not be complete"

# GOOD: Hard failure
Write-Error "Task is not complete: missing screenshot"
exit 1
```

### 2. Artifacts Prove Execution

Claims require proof. Scripts create artifacts, orchestrator verifies artifacts exist.

```powershell
# Create proof artifact
$artifact = @"
================================================================
PRE-SIGNAL CHECK ARTIFACT
Task: $TaskNumber
Status: PASSED
================================================================
"@
Set-Content -Path $artifactPath -Value $artifact
```

### 3. Clear Output Formatting

Use consistent formatting for scan-ability:

```powershell
Write-Host "`n📋 Checking Git Status" -ForegroundColor Cyan
Write-Host "  ✅ Working tree is clean" -ForegroundColor Green
Write-Host "  ❌ Uncommitted changes detected" -ForegroundColor Red
```

### 4. Descriptive Exit Codes

Return meaningful exit codes:

```powershell
# Exit 0: Success
# Exit 1: Check failed (actionable)
# Exit 2: Script error (unexpected)
```

### 5. Environment Dependency

All scripts require `set-env.ps1` to be sourced first:

```powershell
if (-not $env:ORCHESTRA_ROOT) {
    Write-Error "Run '. .orchestra/common/scripts/set-env.ps1' first"
    exit 2
}
```
