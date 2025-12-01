# Core Workflows

> **Navigation**: [Index](../readme.md) | **Prev**: [Roles](roles.md) | **Next**: [ADR-001](decisions/adr-001-translation-layer.md)

---

## Overview

This document defines the key workflows in Orchestra, with detailed steps and decision points.

## Workflow 1: Sprint Setup

**Actor**: Orchestrator  
**Trigger**: New sprint begins  
**Outcome**: Manifest and verification criteria ready for all tasks

### Steps

```
1. ANALYZE SPECIFICATION
   ├── Read spec artifacts (spec.md, tasks.md, contracts/)
   ├── Understand user stories and acceptance criteria
   └── Identify task categories and dependencies

2. CREATE MANIFEST
   ├── Consolidate granular spec tasks into orchestrator tasks
   ├── Map each orchestrator task to spec task IDs
   ├── Define task phases (foundation, core, rendering, etc.)
   └── Write manifest.yaml with all tasks

3. CREATE VERIFICATION CRITERIA
   ├── For each task in manifest:
   │   ├── Create task-NNN.yaml in .orchestrator-only/verification/
   │   ├── Define structural checks (files exist, exports)
   │   ├── Define functional checks (tests pass)
   │   ├── Define adversarial checks (for critical tasks)
   │   ├── Set severity levels (BLOCKING, MAJOR, MINOR, INFO)
   │   └── Define visual criteria (for INTEGRATION/VISUAL tasks)
   └── Commit verification files

4. INITIALIZE PROGRESS
   ├── Create progress.yaml with all tasks as "pending"
   ├── Record baseline test count
   └── Commit progress file

5. PREPARE FIRST TASK
   └── Proceed to Workflow 2 (Task Handover)
```

## Workflow 2: Task Handover (Orchestrator → Implementor)

**Actor**: Orchestrator  
**Trigger**: Previous task completed OR sprint just started  
**Outcome**: Implementor receives complete task handover

### Pre-Conditions

- [x] Previous task verified and archived (or this is first task)
- [x] `task-closeout-check.ps1` passes
- [x] Environment variables set (`set-env.ps1`)

### Steps

```
1. CLOSEOUT CHECK
   ├── Run: . .orchestra/common/scripts/set-env.ps1
   └── Run: .orchestra/orchestrator/scripts/task-closeout-check.ps1
       ├── PASS: Continue
       └── FAIL: Fix issues first (missing checkmarks, uncommitted changes)

2. IDENTIFY NEXT TASK
   ├── Read manifest.yaml
   ├── Find first task with status "pending"
   └── Note task ID, SpecKit mappings, category

3. READ ORCHESTRATOR README
   ├── Open: .orchestra/docs/readme.md (or orchestrator/readme.md)
   └── Refresh on current process (do NOT work from memory)

4. PREPARE HANDOVER FOLDER
   ├── Delete: handover/* (except .gitkeep)
   ├── Create folder structure from template
   └── Copy templates to handover/

5. FILL TASK DOCUMENT
   ├── Open: common/templates/current-task.md.template
   ├── Copy to: handover/current-task.md
   ├── Fill ALL sections:
   │   ├── Task Overview (objective, deliverables)
   │   ├── SpecKit Traceability (task IDs)
   │   ├── Technical Context (dependencies, existing code)
   │   ├── TDD Requirements (test expectations, sample data)
   │   ├── Code Scaffolds (if helpful)
   │   ├── Visual Verification (category + workflow OR N/A with reason)
   │   ├── Quality Gates (commands, baselines)
   │   └── Completion Protocol (how to signal done)
   └── Verify: No [TODO] or [TBD] markers remain

6. UPDATE TASK CONTEXT
   ├── If phase changed: Update task-context.md
   └── If same phase: Verify context is still accurate

7. UPDATE MANIFEST
   └── Set task status to "in-progress"

8. VALIDATE HANDOVER
   └── Run: .orchestra/orchestrator/scripts/handover-validate.ps1
       ├── PASS: Continue
       └── FAIL: Fix handover document

9. COMMIT AND INVOKE
   ├── git add .orchestra/
   ├── git commit -m "orchestra: prepare handover for task N"
   └── Invoke implementor (new agent session or mode switch)
```

### Handover Completeness Checklist

Before invoking implementor, verify:

- [ ] Can a fresh agent complete without asking questions?
- [ ] Are file paths unambiguous (full relative paths)?
- [ ] For UPDATE files: are specific changes listed?
- [ ] For TDD: is sample test data provided?
- [ ] For INTEGRATION/VISUAL: is demo scaffold provided?
- [ ] Is export/barrel file location specified?
- [ ] Is task category explicitly stated?

## Workflow 3: Task Implementation (Implementor)

**Actor**: Implementor  
**Trigger**: Handover prepared by orchestrator  
**Outcome**: Implementation complete with artifacts

### Pre-Conditions

- [x] `handover/current-task.md` exists and is complete
- [x] Environment variables set

### Steps

```
1. VALIDATE HANDOVER
   ├── Run: .orchestra/implementor/.implementor-only/scripts/validate-handover.ps1
   │   ├── PASS: Continue to implementation
   │   └── FAIL: Stop, report defects in completion-signal.md
   └── Read: handover/current-task.md thoroughly

2. UNDERSTAND TASK
   ├── Identify task category (INFRASTRUCTURE/INTEGRATION/VISUAL)
   ├── Note files to CREATE vs UPDATE
   ├── Note TDD requirements
   ├── Note "MUST USE" utilities (don't duplicate)
   └── Note quality gates (test commands, baselines)

3. IMPLEMENT (TDD if required)
   ├── For TDD tasks:
   │   ├── Create test file first
   │   ├── Write failing tests
   │   ├── Implement to make tests pass
   │   └── Refactor if needed
   ├── For non-TDD tasks:
   │   └── Implement per specification
   ├── Follow existing codebase patterns
   └── Use existing utilities (per MUST USE section)

4. QUALITY CHECKS
   ├── Run static analysis: flutter analyze <affected_paths>
   │   └── Must show "No issues found!"
   ├── Run task tests: flutter test <task_test_file>
   ├── Run sprint tests: flutter test <sprint_test_path>
   └── Fix any failures before proceeding

5. CREATE VISUAL ARTIFACTS (if INTEGRATION/VISUAL task)
   ├── Create demo file: example/lib/demos/task_NNN_demo.dart
   ├── Run via flutter_agent.py:
   │   ├── Start-Process (separate window)
   │   ├── Wait for ready
   │   └── Take screenshot
   ├── Save to: handover/verification/screenshots/
   └── Stop the app

6. CAPTURE TEST OUTPUT
   └── Run tests, redirect output to: handover/verification/test-output.txt

7. PRE-SIGNAL CHECK
   └── Run: .orchestra/implementor/.implementor-only/scripts/pre-signal-check.ps1
       ├── Creates artifact in: implementor/artifacts/pre-signal/
       ├── PASS: Continue
       └── FAIL: Fix issues, re-run

8. WRITE COMPLETION SIGNAL
   ├── Fill: handover/verification/completion-signal.md
   │   ├── Implementation summary
   │   ├── Files created/modified
   │   ├── Test results summary
   │   └── Visual verification notes (if applicable)
   └── Stage changes: git add -A

9. SIGNAL COMPLETION
   └── Say: "Ready for review"
```

## Workflow 4: Task Verification (Orchestrator)

**Actor**: Orchestrator  
**Trigger**: Implementor signals "ready for review"  
**Outcome**: Task verified (PASS or FAIL)

### Steps

```
1. CHECK PRE-SIGNAL ARTIFACT
   ├── Look for: implementor/artifacts/pre-signal/task-NNN-*.txt
   │   ├── EXISTS and shows PASSED: Continue
   │   └── MISSING or FAILED: Task FAILS (implementor skipped checks)
   └── This is a structural gate - cannot proceed without artifact

2. READ COMPLETION SIGNAL
   └── Read: handover/verification/completion-signal.md

3. LOAD VERIFICATION CRITERIA
   └── Read: .orchestrator-only/verification/task-NNN.yaml

4. EXECUTE STRUCTURAL CHECKS
   ├── For each check in structural_checks:
   │   ├── Execute (file exists, export present, etc.)
   │   ├── Record PASS/FAIL with evidence
   │   └── If BLOCKING/MAJOR fails: Task FAILS
   └── Document in verification-results.md

5. EXECUTE FUNCTIONAL CHECKS
   ├── For each check in functional_checks:
   │   ├── Run tests: flutter test <path>
   │   ├── Verify test count meets minimum
   │   ├── Record PASS/FAIL with evidence
   │   └── If BLOCKING/MAJOR fails: Task FAILS
   └── Document in verification-results.md

6. EXECUTE ADVERSARIAL CHECKS (if present)
   ├── For integration tasks:
   │   ├── Verify existing files modified (not just new files)
   │   ├── Grep for actual function calls
   │   └── Confirm integration is real, not fake
   └── Document in verification-results.md

7. EXECUTE VISUAL VERIFICATION (if required)
   ├── Verify screenshot exists
   ├── View screenshot via Chrome DevTools MCP:
   │   ├── mcp_chrome-devtoo_new_page(url: "file:///path/to/screenshot.png")
   │   └── mcp_chrome-devtoo_take_screenshot()
   ├── For EACH criterion in screenshot.verify:
   │   ├── Analyze what's visible in returned image
   │   ├── Determine if criterion is satisfied
   │   └── Document finding (PASS/FAIL with observation)
   ├── Close browser page
   └── If ANY visual criterion fails: Task FAILS

8. DETERMINE RESULT
   ├── IF any BLOCKING or MAJOR check failed:
   │   ├── Task status: FAILED
   │   ├── Write feedback to completion-signal.md
   │   └── Implementor must retry (up to 3 attempts)
   └── IF all BLOCKING/MAJOR checks passed:
       ├── Task status: PASSED
       └── Proceed to archive

9. COMMIT VERIFICATION
   └── git commit with verification results
```

## Workflow 5: Task Archive (Orchestrator)

**Actor**: Orchestrator  
**Trigger**: Task verification PASSED  
**Outcome**: Task archived, handover cleared

### Steps

```
1. CREATE ARCHIVE FOLDER
   └── Create: orchestrator/results/task-NNN/

2. COPY HANDOVER
   └── Copy entire handover/ to orchestrator/results/task-NNN/handover/

3. ADD VERIFICATION RESULTS
   ├── Copy or create: verification-results.md
   └── Add to archive folder

4. ADD METADATA
   └── Create: metadata.json
       {
         "task_id": N,
         "archived_at": "YYYY-MM-DD HH:MM:SS",
         "commit": "<hash>",
         "verified_by": "orchestrator",
         "attempt": 1,
         "status": "completed"
       }

5. UPDATE PROGRESS
   ├── Update progress.yaml:
   │   ├── task status: "completed"
   │   ├── commit_hash: "<hash>"
   │   └── completed_at: "YYYY-MM-DD"
   └── Update manifest.yaml status

6. UPDATE SPECKIT TRACEABILITY (if applicable)
   ├── Read manifest for speckit_tasks array
   ├── For each SpecKit task ID:
   │   └── Mark as [x] in specs/*/tasks.md with completion reference
   └── Commit updates

7. CLEAR HANDOVER
   ├── Delete: handover/* (except .gitkeep)
   └── Create: handover/.gitkeep

8. COMMIT ARCHIVE
   └── git commit -m "orchestra: archive task N, prepare for next"

9. PREPARE NEXT TASK
   └── Proceed to Workflow 2 (Task Handover)
```

## Workflow 6: Task Retry (On Failure)

**Actor**: Orchestrator (feedback) → Implementor (retry)  
**Trigger**: Task verification FAILED  
**Outcome**: Implementor receives specific feedback and retries

### Steps

```
1. DOCUMENT FAILURE
   ├── Record in verification-results.md:
   │   ├── Failed check(s) with severity
   │   ├── Evidence of failure
   │   ├── Specific fix required
   │   └── Attempt number (1, 2, or 3)
   └── Do NOT archive (task still in progress)

2. WRITE FEEDBACK
   ├── Update: handover/verification/completion-signal.md
   │   ├── Clear previous content
   │   ├── Add: "## Verification Failed - Attempt N"
   │   ├── List specific failures
   │   ├── Provide actionable fix instructions
   │   └── Note what was correct (positive reinforcement)
   └── Commit feedback

3. INVOKE IMPLEMENTOR FOR RETRY
   └── Implementor reads feedback, makes fixes, re-signals

4. RE-VERIFY
   └── Repeat Workflow 4 (Verification)

5. AFTER 3 FAILED ATTEMPTS
   ├── Escalate to human
   ├── Document blocking issue
   └── Consider task redesign
```

## Decision Points

### When to Create Visual Verification

```
Is this an INFRASTRUCTURE task?
├── YES → No screenshot required (N/A with reason)
└── NO → Is this INTEGRATION or VISUAL?
    ├── INTEGRATION → Screenshot REQUIRED (shows wiring works)
    └── VISUAL → Screenshot REQUIRED (shows rendering correct)
```

### When to Require TDD

```
Is this a simple model/enum task?
├── YES → TDD optional (but tests required)
└── NO → Does task involve algorithms or logic?
    ├── YES → TDD REQUIRED (tests first)
    └── NO → Is this an integration task?
        ├── YES → Integration tests required (not strict TDD)
        └── NO → Tests required but TDD optional
```

### When to Use Adversarial Checks

```
Is this an integration task?
├── YES → Adversarial check: "Verify existing files modified"
└── NO → Is this a critical path component?
    ├── YES → Adversarial check: "Verify component is actually called"
    └── NO → Standard verification sufficient
```
