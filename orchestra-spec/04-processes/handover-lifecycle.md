# Handover Lifecycle

> **Navigation**: [Index](../readme.md) | **Prev**: [Failure Handling](failure-handling.md) | **Next**: [Key Discoveries](../05-research/key-discoveries.md)

---

## Overview

The handover folder is the transient exchange zone between orchestrator and implementor. This document describes its lifecycle and file states.

## Key Principle

**Handover folder is empty at rest**.

Between tasks, the handover folder should be empty or contain only templates. All task artifacts move to archive when complete.

## Handover States

### State 1: EMPTY (At Rest)

```
handover/
└── (empty or templates only)
```

**When**: Between tasks, at sprint start
**Who**: Orchestrator responsibility
**Transitions to**: PREPARED (orchestrator prepares task)

### State 2: PREPARED (Task Ready)

```
handover/
├── current-task.md          # Filled with task details
├── task-context.md          # Sprint context
├── completion-signal.md     # Template for implementor
└── verification/            # Empty, ready for artifacts
```

**When**: Orchestrator has prepared handover
**Who**: Orchestrator creates, implementor reads
**Transitions to**: ACTIVE (implementor starts work)

### State 3: ACTIVE (Work In Progress)

```
handover/
├── current-task.md          # Reference
├── task-context.md          # Reference  
├── completion-signal.md     # Template
└── verification/
    ├── implementation.dart  # Work in progress
    ├── tests/               # Being created
    └── (growing artifacts)
```

**When**: Implementor actively working
**Who**: Implementor creates artifacts
**Transitions to**: SIGNALED (implementor signals completion)

### State 4: SIGNALED (Awaiting Verification)

```
handover/
├── current-task.md          # Reference
├── task-context.md          # Reference
├── completion-signal.md     # FILLED - summary of work
└── verification/
    ├── implementation.dart  # Complete
    ├── tests/               # Complete  
    ├── screenshot.png       # Visual proof (if required)
    └── pre-signal.artifact  # Proof of pre-signal check
```

**When**: Implementor signaled "ready for review"
**Who**: Implementor completed, orchestrator verifies
**Transitions to**: 
- EMPTY (verification passed, archived)
- ACTIVE (verification failed, retry)

### State 5: ARCHIVED (Task Complete)

Handover returns to EMPTY, artifacts move to:

```
results/
└── task-NNN/
    ├── metadata.json        # Task metadata
    ├── current-task.md      # Original task
    ├── completion-signal.md # Final signal
    └── verification/
        └── (all artifacts)
```

## File Ownership

### Orchestrator-Owned Files

| File | Created By | Modified By |
|------|------------|-------------|
| `current-task.md` | Orchestrator | Orchestrator only |
| `task-context.md` | Orchestrator | Orchestrator only |
| Hidden verification criteria | Orchestrator | Never |

### Implementor-Owned Files

| File | Created By | Modified By |
|------|------------|-------------|
| `completion-signal.md` | Template | Implementor fills |
| `verification/*` | Implementor | Implementor |
| Pre-signal artifact | Implementor | Never |

### Shared Understanding

Both roles read but neither modifies:
- Architecture documents
- Design specifications
- Test expectations

## Lifecycle Transitions

### Prepare Handover

**Trigger**: Previous task complete
**Actor**: Orchestrator
**Script**: `prepare-handover.ps1`

```powershell
# 1. Verify previous task complete
.\task-closeout-check.ps1

# 2. Clear handover folder
Remove-Item handover\* -Recurse -Force

# 3. Create structure
New-Item handover\verification -Type Directory

# 4. Copy and fill templates
Copy-Item templates\current-task.template.md handover\current-task.md
# Fill with task details from manifest

Copy-Item templates\task-context.template.md handover\task-context.md
# Fill with sprint context

Copy-Item templates\completion-signal.template.md handover\completion-signal.md

# 5. Update manifest status
# Set task status: in-progress

# 6. Commit
git add handover\
git commit -m "Task $taskId: Prepare handover"
```

### Signal Completion

**Trigger**: Implementor finished work
**Actor**: Implementor
**Script**: `pre-signal-check.ps1`

```powershell
# 1. Verify artifacts exist
# (checks per task category)

# 2. Run tests
flutter test $testFiles

# 3. Create pre-signal artifact
$timestamp = Get-Date -Format "o"
@{
    task_id = $taskId
    timestamp = $timestamp
    tests_passed = $true
    artifacts = (Get-ChildItem handover\verification)
} | ConvertTo-Json | Out-File implementor\artifacts\pre-signal-$taskId.json

# 4. Stage changes
git add .
```

Then implementor fills `completion-signal.md` and says "ready for review".

### Accept Signal

**Trigger**: Implementor signaled completion
**Actor**: Orchestrator
**Script**: `accept-signal-check.ps1` + manual verification

```powershell
# 1. Check pre-signal artifact exists
$artifact = "implementor\artifacts\pre-signal-$taskId.json"
if (-not (Test-Path $artifact)) {
    throw "Pre-signal artifact missing"
}

# 2. Load hidden verification criteria
$criteria = Get-Content ".orchestrator-only\verification\task-$taskId.yaml"

# 3. Execute each check
# (automated + manual as needed)

# 4. Document results
# (in verification results file)

# 5. Make pass/fail decision
```

### Archive Task

**Trigger**: Verification passed
**Actor**: Orchestrator
**Script**: `archive-and-close.ps1`

```powershell
# 1. Create archive folder
$archivePath = "results\task-$taskId"
New-Item $archivePath -Type Directory

# 2. Copy handover contents
Copy-Item handover\* $archivePath -Recurse

# 3. Add metadata
@{
    task_id = $taskId
    completed_at = (Get-Date -Format "o")
    attempts = $attempts
    commit = (git rev-parse HEAD)
} | ConvertTo-Json | Out-File "$archivePath\metadata.json"

# 4. Update progress
# (update progress.yaml with completion)

# 5. Update SpecKit traceability
# (mark corresponding tasks.md items complete)

# 6. Clear handover
Remove-Item handover\* -Recurse -Force

# 7. Commit
git add .
git commit -m "Task $taskId: Archive completion"
```

## File States

### current-task.md

| Phase | State |
|-------|-------|
| EMPTY | Does not exist |
| PREPARED | Filled with task details |
| ACTIVE | Read-only reference |
| SIGNALED | Read-only reference |
| ARCHIVED | Copied to results/ |

### completion-signal.md

| Phase | State |
|-------|-------|
| EMPTY | Does not exist |
| PREPARED | Template (unfilled) |
| ACTIVE | Template being filled |
| SIGNALED | FILLED with summary |
| ARCHIVED | Copied to results/ |

### verification/ folder

| Phase | State |
|-------|-------|
| EMPTY | Does not exist |
| PREPARED | Empty directory |
| ACTIVE | Growing with artifacts |
| SIGNALED | Complete artifacts |
| ARCHIVED | Copied to results/ |

## Validation Rules

### Rule 1: No Orphaned Artifacts

Artifacts must not exist in handover after archival:
```powershell
if (Get-ChildItem handover -Recurse -File) {
    throw "Handover not empty after archive"
}
```

### Rule 2: Complete Before Archive

Cannot archive until:
- Pre-signal artifact exists
- All verification checks pass
- Completion signal filled

### Rule 3: No Modifying Archive

Once in results/, files are immutable:
```powershell
# results/ should be treated as read-only
# Any changes require explicit audit note
```

### Rule 4: Single Active Task

Only one task populates handover at a time:
```powershell
# current-task.md should reference single task
# Not multiple tasks in progress
```

## Error Recovery

### Partial Handover

If handover preparation failed partway:

```powershell
# Clear and restart
Remove-Item handover\* -Recurse -Force
.\prepare-handover.ps1 -TaskId $taskId
```

### Partial Archive

If archival failed partway:

```powershell
# Check what exists
$archiveExists = Test-Path "results\task-$taskId"
$handoverEmpty = -not (Get-ChildItem handover -Recurse -File)

if ($archiveExists -and -not $handoverEmpty) {
    # Archive created but handover not cleared
    Remove-Item handover\* -Recurse -Force
}
```

### Corrupt State

If state is unclear:

```powershell
# Use git to determine truth
git status
git log --oneline -5

# Reset to known good state
git reset --hard <last-good-commit>
```

## Handover Templates

### current-task.md Template

```markdown
# Task {{task_id}}: {{title}}

## Objective
{{objective}}

## Requirements
{{requirements}}

## Deliverables
- [ ] {{deliverable_1}}
- [ ] {{deliverable_2}}

## Technical Notes
{{technical_notes}}

## Files to Create/Modify
{{file_list}}
```

### completion-signal.md Template

```markdown
# Completion Signal

## Task
{{task_id}}: {{title}}

## Summary
<!-- Implementor fills this section -->

## Artifacts Created
- [ ] {{artifact_1}}
- [ ] {{artifact_2}}

## Tests
- [ ] All tests passing
- [ ] Test file: {{test_file}}

## Notes
<!-- Any implementation notes or decisions -->
```

## Folder Structure

```
.orchestra/
├── handover/                   # Transient exchange zone
│   ├── current-task.md        # Current task details
│   ├── task-context.md        # Sprint context
│   ├── completion-signal.md   # Implementor's signal
│   └── verification/          # Task artifacts
│
├── orchestrator/
│   └── results/               # Archived completed tasks
│       ├── task-001/
│       ├── task-002/
│       └── ...
│
└── common/
    └── templates/             # Template source
        ├── current-task.template.md
        ├── task-context.template.md
        └── completion-signal.template.md
```
