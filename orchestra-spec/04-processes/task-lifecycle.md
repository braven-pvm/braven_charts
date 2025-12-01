# Task Lifecycle

> **Navigation**: [Index](../readme.md) | **Prev**: [Templates](../03-components/templates.md) | **Next**: [Verification Protocol](verification-protocol.md)

---

## Overview

Every task in Orchestra goes through a defined lifecycle from definition through completion. This document describes each state and transition.

## Lifecycle Diagram

```
                    ┌─────────────────────────────────────────────┐
                    │                  SPRINT SETUP                │
                    │  (Orchestrator creates manifest + criteria)  │
                    └─────────────────────────────────────────────┘
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                           PENDING                                │
│                     (Task defined, not started)                  │
└─────────────────────────────────────────────────────────────────┘
                                          │
                        Orchestrator prepares handover
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                         IN-PROGRESS                              │
│                  (Implementor working on task)                   │
└─────────────────────────────────────────────────────────────────┘
                                          │
                        Implementor signals completion
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                     AWAITING-VERIFICATION                        │
│                (Orchestrator verifying work)                     │
└─────────────────────────────────────────────────────────────────┘
                                          │
                    ┌─────────────────────┴────────────────────┐
                    │                                          │
                PASS │                                          │ FAIL
                    │                                          │
                    ▼                                          ▼
┌───────────────────────────┐            ┌───────────────────────────┐
│        COMPLETED          │            │          FAILED           │
│   (Archived, next task)   │            │    (Feedback, retry)      │
└───────────────────────────┘            └───────────────────────────┘
                                                      │
                                                      │ Implementor fixes
                                                      │
                                                      ▼
                                         Back to IN-PROGRESS
                                         (up to 3 attempts)
```

## States

### PENDING

**Definition**: Task is defined in manifest but work has not started.

**Entry conditions**:
- Manifest created with task definition
- Verification criteria created (hidden)
- Previous task completed (or this is first task)

**What exists**:
- `manifest.yaml` entry with `status: pending`
- `task-NNN.yaml` in verification folder (hidden)

**Exit conditions**:
- Orchestrator runs closeout check for previous task
- Orchestrator prepares handover documents
- Orchestrator sets `status: in-progress` in manifest

### IN-PROGRESS

**Definition**: Task has been handed to implementor who is actively working.

**Entry conditions**:
- Handover folder populated with current-task.md
- Task-context.md reflects current phase
- completion-signal.md template ready
- Manifest status updated

**What exists**:
- `handover/current-task.md` - filled with task details
- `handover/task-context.md` - sprint context
- `handover/verification/` - empty, ready for artifacts

**What implementor does**:
1. Validates handover
2. Implements per specification
3. Creates tests, runs tests
4. Creates visual artifacts (if required)
5. Runs pre-signal check
6. Writes completion-signal.md
7. Signals "ready for review"

**Exit conditions**:
- Implementor signals completion → AWAITING-VERIFICATION

### AWAITING-VERIFICATION

**Definition**: Implementation signaled complete, orchestrator verifying.

**Entry conditions**:
- Implementor wrote completion-signal.md
- Implementor ran pre-signal check (artifact exists)
- Implementor signaled "ready for review"

**What exists**:
- All handover artifacts (implementation, tests, screenshots)
- Pre-signal artifact in `implementor/artifacts/`
- Completion signal with summary

**What orchestrator does**:
1. Checks pre-signal artifact
2. Loads hidden verification criteria
3. Executes all checks (structural, functional, adversarial, visual)
4. Documents results
5. Determines pass/fail

**Exit conditions**:
- All BLOCKING/MAJOR checks pass → COMPLETED
- Any BLOCKING/MAJOR check fails → FAILED

### COMPLETED

**Definition**: Task passed verification, archived for audit trail.

**Entry conditions**:
- All verification checks passed
- Orchestrator documented results

**What orchestrator does**:
1. Creates archive folder: `results/task-NNN/`
2. Copies handover folder to archive
3. Adds metadata.json
4. Updates progress.yaml
5. Updates SpecKit tasks.md (if applicable)
6. Clears handover folder
7. Prepares next task

**What exists**:
- `results/task-NNN/` with complete archive
- Updated progress.yaml
- Empty handover folder (ready for next task)

**This is a terminal state** - task does not change from here.

### FAILED

**Definition**: Task did not pass verification, implementor must retry.

**Entry conditions**:
- One or more BLOCKING/MAJOR checks failed

**What orchestrator does**:
1. Documents failure with specific feedback
2. Updates attempt count
3. Writes feedback to completion-signal.md
4. Invokes implementor for retry

**What exists**:
- Verification results showing failures
- Feedback in completion-signal.md
- Attempt count incremented

**Exit conditions**:
- Implementor addresses feedback → back to IN-PROGRESS
- 3 failed attempts → escalate to human

## Attempt Tracking

Each task can have multiple attempts before succeeding.

| Attempt | On Failure | Action |
|---------|------------|--------|
| 1 | Specific feedback | Implementor retries |
| 2 | Specific feedback | Implementor retries with guidance |
| 3 | Detailed failure analysis | Escalate to human |

**After 3 failed attempts**:
- Task is flagged for human review
- May indicate: spec problem, impossible constraint, agent limitation
- Human decides: fix spec, provide hints, or accept with notes

## State in Files

### manifest.yaml

```yaml
tasks:
  - id: 1
    title: "Create YAxisPosition Enum"
    status: "completed"       # pending | in-progress | completed
    commit: "abc1234"
    
  - id: 2
    title: "Create YAxisConfig Model"
    status: "in-progress"
```

### progress.yaml

```yaml
tasks:
  - id: 1
    status: "completed"
    attempts: 1
    completed_at: "2025-11-28"
    commit: "abc1234"
    
  - id: 2
    status: "in-progress"
    attempts: 1
    started_at: "2025-11-28"
```

## Transitions

### PENDING → IN-PROGRESS

**Trigger**: Orchestrator prepares handover

**Script**: `prepare-handover.ps1`

**Actions**:
1. Verify previous task complete (`task-closeout-check.ps1`)
2. Clear handover folder
3. Copy templates
4. Fill current-task.md
5. Update manifest status
6. Commit handover
7. Invoke implementor

### IN-PROGRESS → AWAITING-VERIFICATION

**Trigger**: Implementor signals "ready for review"

**Script**: `pre-signal-check.ps1` (implementor runs)

**Actions**:
1. Create pre-signal artifact
2. Write completion-signal.md
3. Stage changes
4. Signal completion verbally

### AWAITING-VERIFICATION → COMPLETED

**Trigger**: All verification checks pass

**Script**: `archive-and-close.ps1`

**Actions**:
1. Create results archive
2. Copy handover to archive
3. Add metadata
4. Update progress.yaml
5. Update SpecKit traceability
6. Clear handover
7. Prepare next task handover

### AWAITING-VERIFICATION → FAILED

**Trigger**: Any BLOCKING/MAJOR check fails

**Script**: None (manual orchestrator action)

**Actions**:
1. Document failures
2. Write feedback to completion-signal.md
3. Increment attempt count
4. Notify implementor

### FAILED → IN-PROGRESS

**Trigger**: Implementor acknowledges feedback

**Script**: None (continuation of work)

**Actions**:
1. Implementor reads feedback
2. Addresses specific issues
3. Re-runs pre-signal check
4. Re-signals completion

## Lifecycle Rules

### Rule 1: No State Skipping

Tasks must go through each state in order:
- Cannot go from PENDING to COMPLETED
- Cannot go from IN-PROGRESS to COMPLETED without AWAITING-VERIFICATION

### Rule 2: Single Task Active

Only one task should be IN-PROGRESS at a time:
- Prevents context pollution
- Ensures focus on current work
- Simplifies verification

### Rule 3: Complete Before Next

Previous task must be COMPLETED before next task starts:
- closeout-check.ps1 enforces this
- Prevents accumulated issues

### Rule 4: Archive Is Immutable

Once in results/, task archive is never modified:
- Full audit trail preserved
- Enables retrospective analysis
- Prevents history rewriting

## Phase Boundaries

When moving between phases:

1. **All phase tasks complete** before new phase starts
2. **Task context updated** to reflect new phase
3. **Consider fresh agent** to prevent context pollution
4. **Phase retrospective** to capture learnings

Example phase boundary:

```yaml
phases:
  - id: 1
    name: "Foundation"
    tasks: [1, 2, 3, 4, 5]
    
  - id: 2
    name: "Normalization"
    tasks: [6, 7, 8]
```

When task 5 completes:
- Update task-context.md for phase 2
- Note: "Foundation phase complete, entering Normalization phase"
- Consider: new agent session for fresh context
